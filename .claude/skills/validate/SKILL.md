---
name: validate
description: Run this project's full change gate — RSpec, RuboCop and Brakeman — and fix what it finds. Use this after editing anything under app/, lib/, config/ or spec/, before reporting work as done, and before any commit or push. Also use it whenever the user says "validate", "check my changes", "run the tests", "is this green", "ready to commit?", or asks whether a change broke anything. Prefer this over running rspec or rubocop ad hoc, since it also covers the Brakeman security scan and knows this repo's specific failure modes (Postgres container down, polluted test database).
---

# Validate changes

This project gates every change on three things: the specs pass, RuboCop is clean, and Brakeman
finds no new warnings. Run them as a set — a green suite with a Brakeman warning is still broken.

## Fast path

The per-change loop. Run all three even if an early one fails — one report listing every problem
beats three round-trips.

```bash
bundle exec rspec
bin/rubocop -a
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
```

`bin/rubocop -a` applies **safe** autocorrections only; don't reach for `-A`, whose unsafe cops can
change behavior. If `-a` changes files, say so explicitly and re-run the specs.

## Full gate

Before a commit, before a push, or when the user asks for the real CI run:

```bash
bin/ci
```

Configured in `config/ci.rb`: setup, RuboCop, the gem and importmap audits, Brakeman, the Tailwind
build, the specs. Slower because it starts with `bin/setup --skip-server`. Keep `config/ci.rb` the
single source of truth — a check added there belongs in the fast path above too.

## Two false alarms to rule out first

**Postgres must be running.** Every spec run needs the Postgres 16 container from `compose.yml`,
which doesn't survive a reboot. The symptom is `ActiveRecord::ConnectionNotEstablished`, not a code
failure:

```bash
docker compose ps --status running --format '{{.Service}}'   # expect: postgres
docker compose up -d                                          # if it's not listed
```

**System specs need the Tailwind build.** `app/assets/builds/` is gitignored, so a fresh clone or
`git worktree` has no CSS and the five Cuprite system specs drive a headless browser against an
unstyled page — failures like `expect(page).not_to have_button("Reach Out")` read like a broken
feature but aren't. Fix with `bin/rails tailwindcss:build` (`bin/ci` and `bin/dev` handle it).

## Reading the results

Report what happened, including the counts the run prints — not just "tests pass". On a failure,
read it before changing anything, and show the failing example names and the relevant part of the
error rather than summarizing it away.

**Leftover rows, not a regression.** If `spec/models/agent_connection_spec.rb` ("recent returns the
most recent entries first") and `spec/requests/api/telemetry_spec.rb` ("returns recent connections
as JSON", "returns an empty array when there are no connections") fail together, the test database
has leftover rows — nothing truncates it between runs, and only these three assert absolute counts:

```bash
RAILS_ENV=test bin/rails runner 'puts "connections=#{AgentConnection.count} bookings=#{Booking.count}"'
RAILS_ENV=test bin/rails runner 'AgentConnection.delete_all; Booking.delete_all'
```

Re-run; if they still fail, it really is the change. Clean up after any `bin/rails runner` of your
own against the test environment.

**Coverage floor, not a broken spec.** `SimpleCov failed with exit 2 due to a coverage related
error`, printed after `0 failures`, means the whole suite passed but line coverage fell under 99%
or branch coverage under 98% (configured at the top of `spec/spec_helper.rb`). The output lists
the files that dropped. Add the missing spec rather than lowering the floor. A run given a path
(`rspec spec/foo_spec.rb`) skips the check, but a filtered run *without* one (`-e "..."`,
`--only-failures`) does not: it enforces the floor against the handful of examples it ran and
exits 2. Re-run the whole suite before believing that number.

**Date-sensitive specs.** `CheckAvailabilityUseCase` and `GetXpYearsUseCase` depend on the current
date and their specs use `travel_to`. A failure that appears only today, in a spec you didn't
touch, is worth checking against the clock first.

**If Brakeman warns**, read the warning and the flagged line before acting — it finds real bugs but
also false positives. Fix genuine ones, and never make a warning disappear by weakening the check
that triggered it. For a false positive, say so with your reasoning and ask before adding an ignore
entry: that writes `config/brakeman.ignore` (which doesn't exist yet) and silences it permanently.

**If RuboCop still reports offenses after `-a`**, what's left needs a judgment call — usually
`Metrics/*` or a cop whose autocorrection is unsafe. Fix it if the fix is obvious and small,
otherwise report the offense and your proposed fix rather than reaching for an inline
`rubocop:disable`.

## Scope

Run the whole suite, not a subset: it takes seconds, and this app's layers are coupled through
`Rails.event` and the MCP tools in ways a targeted run misses. A single file is fine while
iterating, but finish with a full run before reporting the work as done.
