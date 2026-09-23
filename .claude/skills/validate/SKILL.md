---
name: validate
description: Run this project's full change gate — RSpec, RuboCop and Brakeman — and fix what it finds. Use this after editing anything under app/, lib/, config/ or spec/, before reporting work as done, and before any commit or push. Also use it whenever the user says "validate", "check my changes", "run the tests", "is this green", "ready to commit?", or asks whether a change broke anything. Prefer this over running rspec or rubocop ad hoc, since it also covers the Brakeman security scan and knows this repo's specific failure modes (Postgres container down, polluted test database).
---

# Validate changes

This project gates every change on three things: the specs pass, RuboCop is clean, and Brakeman
finds no new security warnings. Running them as a set matters because they fail for unrelated
reasons — a green suite with a Brakeman warning is still a broken change.

There are two tiers. Use the **fast path** for the per-change loop and the **full gate** before a
commit or push. The fast path is what you'll run almost always; it takes ~15 seconds.

## Fast path

Run these three from the project root. Run them all even if an early one fails — the user gets
more value from one report listing every problem than from three round-trips.

```bash
bundle exec rspec
bin/rubocop -a
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
```

`bin/rubocop -a` applies **safe** autocorrections only. Do not reach for `-A`: it includes
unsafe cops that can change behavior, and this repo uses `rubocop-rails-omakase` with no custom
rules, so almost everything `-a` touches is formatting. Note that omakase is deliberately lenient
— it won't flag inconsistent indentation, for instance — so a clean RuboCop run means "no rule
broken", not "well formatted". Match the surrounding code by eye; don't lean on the linter for it. If `-a` changes files, say so explicitly
in your report and re-run the specs, because even a safe correction is still a change the user
didn't write.

## Full gate

Before a commit, before a push, or when the user asks for the real CI run:

```bash
bin/ci
```

`bin/ci` (Rails 8's `ActiveSupport::ContinuousIntegration`, configured in `config/ci.rb`) runs
setup, RuboCop, the gem audit, the importmap audit, Brakeman, and the specs. It is slower because
its first step is `bin/setup --skip-server`, which runs `bundle install` and `db:prepare`. That's
the right trade before a push and the wrong one after every edit.

Keep `config/ci.rb` as the single source of truth. If a check is added there, add it to the fast
path here too, so the two tiers can't drift apart.

## System specs need the Tailwind build

`app/assets/builds/` is gitignored, so a fresh clone or a `git worktree` has no CSS. The five
Cuprite system specs then drive a headless browser against an unstyled page and fail on things
like `expect(page).not_to have_button("Reach Out")` — which reads like a broken feature but isn't.
`bin/dev` keeps the build current while you work, so this only bites in a fresh checkout. Fix it
with `bin/rails tailwindcss:build`; `bin/ci` runs that step for you.

## Before you start: Postgres must be running

Every spec run needs the Postgres 16 container from `compose.yml`. It does not survive a reboot,
and the failure is noisy but unambiguous — `ActiveRecord::ConnectionNotEstablished`, "connection
to server at ::1, port 5432 failed". Check first rather than misreading it as a code failure:

```bash
docker compose ps --status running --format '{{.Service}}'   # expect: postgres
docker compose up -d                                          # if it's not listed
```

Give it a few seconds to accept connections before running the specs.

## Reading the results

Report what actually happened, including the counts. "201 examples, 0 failures" is more useful
than "tests pass", and if something fails, show the failing example names and the relevant part of
the error rather than summarizing it away.

### If specs fail

Read the failure before changing anything. Two failure shapes in this repo mean something other
than "your change broke it":

**Absolute `AgentConnection` counts.** If these three fail together —
`spec/models/agent_connection_spec.rb` ("recent returns the most recent entries first"),
and `spec/requests/api/telemetry_spec.rb` ("returns recent connections as JSON", "returns an empty
array when there are no connections") — the test database almost certainly has leftover rows.
Nothing truncates it between runs, so any `RAILS_ENV=test bin/rails runner` that wrote a record
leaves them behind, and only these three specs assert absolute counts. Confirm and clear it:

```bash
RAILS_ENV=test bin/rails runner 'puts "connections=#{AgentConnection.count} bookings=#{Booking.count}"'
RAILS_ENV=test bin/rails runner 'AgentConnection.delete_all; Booking.delete_all'
```

Then re-run. If they still fail, it really is the change. The same applies to your own debugging:
if you use `bin/rails runner` against the test environment, clean up after yourself.

**Date-sensitive specs.** `CheckAvailabilityUseCase` and `GetXpYearsUseCase` depend on the current
date, and the specs around them use `travel_to`. A failure that only appears today, in a spec you
didn't touch, is worth checking against the clock before assuming a regression.

### If Brakeman warns

Brakeman finds real classes of bug (SQL injection, unsafe redirects, mass assignment) but also
raises false positives. Read the warning and the flagged line before acting. Fix the code when the
warning is genuine. When it's a false positive, say so in your report with the reasoning and ask
the user before adding an ignore entry — `config/brakeman.ignore` silences the warning
permanently, which is the user's call, not yours.

Never make a warning disappear by weakening the check that triggered it.

### If RuboCop still reports offenses after `-a`

What's left needs a judgment call — usually `Metrics/*` or a cop whose autocorrection is unsafe.
Fix it properly if the fix is obvious and small. If it isn't, report the offense and your proposed
fix rather than reaching for an inline `rubocop:disable`; a disable comment is a decision the user
should make knowingly.

## Scope

Run the whole suite, not a subset. It's ~5 seconds for 201 examples, and this app's layers are
coupled through `Rails.event` and the MCP tools in ways a targeted run will miss — the four MCP
tools, for instance, are covered both by their own specs and by `spec/requests/api/mcp_spec.rb`.

A single spec file is fine while iterating on one failure, but always finish with a full run
before reporting the work as done.
