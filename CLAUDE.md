# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev                         # Rails server + Tailwind CSS watcher (foreman via Procfile.dev)
bin/rails server                # Rails server only (no Tailwind watcher — CSS won't rebuild)
bundle exec rspec               # Run all tests
bundle exec rspec spec/requests/api/mcp_spec.rb  # Run one file
bin/rubocop                     # Lint (rubocop-rails-omakase)
bin/rails db:migrate            # Run pending migrations
bin/rails db:create db:migrate  # First-time setup, after `docker compose up -d`
```

Rails 8.1; Ruby version in `.ruby-version`. Postgres 16 is required locally (`docker compose up
-d`, see `compose.yml`). There is no Redis: rate limiting, jobs, and ActionCable all ride on
Rails 8's Postgres-backed Solid Cache / Solid Queue / Solid Cable.

## Validating changes

After any change under `app/`, `lib/`, `config/` or `spec/`, invoke the **`validate`** skill
(`.claude/skills/validate/SKILL.md`) before reporting the work as done — it runs the specs,
RuboCop and Brakeman as a set, and knows this repo's two recurring false alarms (the Postgres
container being down, and leftover rows in the test database). Escalate to `bin/ci` before a
commit or push.

`config/ci.rb` is the source of truth for what "green" means. Anything added there belongs in the
skill's fast path too, so the local loop and CI can't drift apart.

Always scaffold new Rails components (migrations, models, controllers, mailers, jobs, etc.) with
the Rails CLI generators (`bin/rails generate migration ...`, `bin/rails generate model ...`)
rather than hand-writing the file — they keep migration timestamps, naming conventions and file
layout consistent. Edit the generated file afterward for the specifics this app needs.

## Credentials

There is no `.env`/`dotenv-rails` — all per-environment config lives in Rails' encrypted
credentials, not env vars. Edit with `bin/rails credentials:edit --environment <env>`.

- `config/credentials/development.yml.enc` (key: `config/credentials/development.key`) —
  `database.*` (matching `compose.yml`), `mailer.sender_email`/`recipient_email`, `sentry_dsn`.
  No `better_stack`: the log drain is production-only.
- `config/credentials/production.yml.enc` (key: `config/credentials/production.key`) — same shape,
  plus `mailer.resend_api_key` and `better_stack.source_token`/`ingesting_host`.
- `config/credentials.yml.enc` (the shared file, key: `config/master.key`) — fallback for
  environments without their own, i.e. `test`. Holds `secret_key_base` plus a `mailer` block (test
  needs non-nil values so `mail()` doesn't raise) and deliberately no `sentry_dsn`, so
  `Sentry.init` no-ops there instead of raising.

**Gotcha**: the bare `bin/rails credentials:edit` targets the shared file only if `Rails.env`
(default: `development`) has no per-environment file. Since `development.yml.enc` exists, running
it from a normal shell silently edits *that* file. Use `RAILS_ENV=test bin/rails credentials:edit`
to reach the shared one.

`config/database.yml`, the three mailers, and the `resend`/`sentry` initializers read these via
`Rails.application.credentials.dig(...)`. `test` keeps the ENV-based `default` anchor, whose
fallbacks already equal `compose.yml`'s, so it needs no credentials file or env var at all.
Deploy-side secrets (`RAILS_MASTER_KEY`, `KAMAL_*`) are in [README](README.md#deployment).

## Architecture

This is a Rails 8 personal landing page using Hotwire (Turbo + Stimulus via importmap — no Node,
no JS bundler). It also serves an MCP server so AI agents can read the resume, check availability,
and book a meeting.

```
app/
  controllers/
    application_controller.rb   # @default_description, allow_browser, rate_limit_identifier
    contacts_controller.rb      # POST /contact — JSON response
    static_controller.rb        # AGENTS.md, llms.txt, sitemap.xml
    pages_controller.rb, telemetry_page_controller.rb
    api/
      telemetry_controller.rb   # GET /api/telemetry — last 50 {tool, timestamp}, no auth
      mcp_controller.rb         # POST/GET /api/mcp — see "MCP server" below
      hire_controller.rb        # POST /api/hire — the endpoint /AGENTS.md points agents at
      base_controller.rb        # shared rescue_from + Rails.event error/rate-limit reporting
  mailers/                      # ContactMailer, MeetingMailer
  models/
    booking.rb                  # unique index on slot_start prevents double-booking
    agent_connection.rb         # MCP tool-call telemetry
  use_cases/                    # framework-agnostic business logic, constructor-injected deps
  events/                       # everything that exists to serve Rails.event
  mcp_tools/                    # MCP::Tool subclasses: get_resume, list_services,
                                # check_availability, schedule_meeting
  javascript/controllers/       # Stimulus
  views/                        # layouts/, pages/ (home + partials), telemetry_page/, shared/
lib/                            # static, request-independent site facts and the text built from
                                # them. Autoloaded via `config.autoload_lib` — no `Lib::`
                                # namespace, since these sit directly under lib/.
  seo_config.rb                 # SeoConfig — plain constants (site URL, author, MCP endpoint)
  agents_content.rb             # renders the two config/agents.yml bodies. Response bodies only:
                                # the homepage snippet keeps its own copy, deliberately decoupled
config/
  profile.yml                   # static resume/services data
  availability.yml              # timezone, weekly windows, slot duration, booking horizon
  agents.yml                    # two bodies: `content` (/AGENTS.md) and `llms_content` (/llms.txt)
  initializers/
    logtail.rb                  # scopes the logtail-rails railtie (prod: logrageify!, else off)
    event_reporter.rb           # registers the local Rails.event subscriber outside production
    mcp.rb                      # MCP.configure around_request/exception_reporter -> Rails.event
```

### Key design decisions

- **Use cases** (`app/use_cases/`) contain all business logic and have no controller/view
  dependency. They're unit-tested in isolation with doubles/instance_doubles for collaborators.
  `GetProfileUseCase` and `ListServicesUseCase` load `config/profile.yml` directly via
  `Rails.application.config_for(:profile)` — there's no `ConfigDatabase` wrapper class.
- **Errors**: no error hierarchy to speak of — use cases raise plain `ArgumentError` (messages like
  `"Missing required fields"` or `"Slot unavailable"`) for validation/business-rule failures. The
  one exception is `ValidationError` (`app/use_cases/validation_error.rb`), which subclasses it and
  carries a per-field `errors` hash so the contact and hire forms can highlight the offending
  inputs. Controllers catch it via `rescue_from ArgumentError`, `ScheduleMeetingTool` via a direct
  `rescue`; `ContactsController` adds a `rescue_from ActionController::InvalidAuthenticityToken` so
  an expired session redirects with a flash instead of a raw 422, and anything else falls through
  to a generic `rescue_from StandardError`.
- **Rate limiting**: Rails 8's declarative `rate_limit` macro in `ContactsController` and
  `Api::McpController`, backed by `Rails.cache` (Solid Cache in dev/production, `MemoryStore` in
  test). `ApplicationController#rate_limit_identifier` prefers the `CF-Connecting-IP` header,
  falling back to `request.remote_ip` only when absent (local dev/test) — `X-Forwarded-For` arrives
  corrupted in production, collapsing every visitor into one bucket. Trusting `CF-Connecting-IP`
  unconditionally is safe only because the origin firewall restricts inbound 80/443 to Cloudflare's
  ranges, so nobody can reach the app to forge it. `Api::McpController` declares two named limiters
  on the same action — a general one and a `schedule_meeting`-specific one whose `unless:` proc
  parses and rewinds the JSON-RPC body so it only counts calls by that name. Both controllers catch
  `ActionController::TooManyRequests` via `rescue_from` rather than the macro's `with:`.
- **MCP server** (`Api::McpController`): builds a fresh `MCP::Server` + stateless
  `MCP::Server::Transports::StreamableHTTPTransport` per request (official `mcp` gem) and proxies
  its Rack `[status, headers, body]` triple straight through the Rails response (`self.status=`,
  `response.set_header`, `self.response_body=`) rather than using `render`, so both the plain-JSON
  and SSE shapes pass through untouched. The transport sets `dns_rebinding_protection: false` — the
  gem's default `Host`/`Origin` allow-listing guards a *loopback-bound* server, which this isn't:
  it's a public, unauthenticated, cookie-free endpoint called by arbitrary external MCP clients
  whose `Origin` values can't be enumerated, and `Host` is already validated by Rails'
  `config.hosts`. `set_cors_headers` reflects whatever `Origin` is present for the same reason —
  safe because the endpoint never sets `Access-Control-Allow-Credentials`. The 4 `MCP::Tool`
  subclasses deliberately don't declare `required:` in their `input_schema`: the gem would
  short-circuit before calling the tool, but this app records the agent connection *before*
  validating, even for calls that go on to fail. Validation happens inside the use cases, with
  domain errors caught in the tool's `call` and turned into `error: true` responses, not raised.
- **Locale routing**: every user-facing page sits under `scope "/:locale"` (`en|pt-BR`), and
  `ApplicationController#switch_locale` reads `params[:locale]` generically, serving both the route
  segment and the `locale` field in the contact form's JSON body. The bare `/` has no locale, so
  `PagesController#root_redirect` 302s it to whatever `DetectLocaleUseCase` picks: `CF-IPCountry`
  first, then `Accept-Language` when there's no country (`XX`/`T1` count as none), then `:en`.
  Country *vetoes* `Accept-Language` rather than outranking it, and only `BR` maps to Portuguese —
  Portugal and the rest get English on purpose, since the one translation is Brazilian. Nothing is
  persisted, so a visitor who switches to `/en` is sent back to `/pt-BR` on their next bare-`/`
  entry; locale-scoped links (`root_path`) keep the locale they're already on. The redirect is
  `:found` with `Cache-Control: private, no-store` — a cached 301 would pin a browser to one
  language forever. Only `/` is detected, so canonical, `hreflang`, `x-default` and the sitemap
  need no geo awareness.
- **Agent-facing surface**: `/AGENTS.md` (prose, `text/markdown`) and `/llms.txt` (a link index in
  the [llmstxt.org](https://llmstxt.org) shape, `text/plain`) are two *different* bodies for two
  conventions, both in `config/agents.yml` and rendered by `AgentsContent`. Both lead with the MCP
  endpoint and its four tools and keep `POST /api/hire` as the fallback for clients that don't
  speak MCP. URLs are never typed by hand — they interpolate `%{site_url}`/`%{mcp_endpoint}`/
  `%{github_url}`/`%{linkedin_url}` from `SeoConfig`, so **a literal `%` in either body raises on
  render**. Two hand-written bodies means two chances to drift, so `spec/requests/static_spec.rb`
  guards both: every `Api::McpController::TOOLS` name must appear, and every `SeoConfig::SITE_URL`
  link must recognize under some HTTP verb.
- **Edge WAF (Cloudflare)**: production sits behind Cloudflare with **Block AI bots** on site-wide,
  which would 403 agent traffic before it reaches this app. `/api/mcp` is exempted by a
  dashboard-only Custom Rule (Skip) that must have **both** "All managed rules" and "All Super Bot
  Fight Mode Rules" checked — the AI-bots block runs under Bot Management, so checking only the
  first still 403s. It does *not* check "All rate limiting rules", so `/api/mcp` shares the single
  zone-wide edge rate limit. See [README's Cloudflare section](README.md#cloudflare) to verify.
- **Error monitoring (Sentry)**: `config/initializers/sentry.rb` reads the DSN from credentials
  rather than hardcoding it. There is deliberately no `enabled_patches = [:logger]`, so
  `Rails.logger` output is *not* mirrored into Sentry — application logs go to Better Stack and
  Sentry stays scoped to exceptions. The layout emits `Sentry.get_trace_propagation_meta` into
  `<head>`, ready for a browser-side SDK that isn't wired up yet.
- **Log drain + structured events (Better Stack)**: production only — dev/test never ship anywhere.
  Application logs are emitted with **Rails 8.1's `Rails.event.notify`**, never the `logtail-rails`
  API, so no app code names Logtail; the comments in `config/environments/production.rb`,
  `config/initializers/logtail.rb` and `event_reporter.rb` cover how each environment is wired.
  `ApplicationController#set_event_context` attaches `request_id`/`ip`/`path`/`user_agent` to every
  event in a request. PII never goes in a payload raw — `LogRedaction.contact` redacts it, and its
  key names are load-bearing (see the comment in `app/events/log_redaction.rb`).

  The events: `mcp.request`/`mcp.exception` (`config/initializers/mcp.rb`, covering all four
  tools), `mcp.meeting.booked`/`mcp.meeting.rejected` (`ScheduleMeetingTool`), `api.error`/
  `api.rate_limited` (`Api::BaseController`, the latter extended per-endpoint via
  `rate_limited_event_payload`), `hire.request.received`/`hire.request.rejected`, and
  `contact.message.sent`/`.rejected`/`contact.rate_limited`/`contact.csrf_rejected`/`contact.error`.
- **`@/` alias**: none — this is a standard Rails app, autoloaded via Zeitwerk from `app/*`. Every
  directory under `app/` (bar `assets`, `javascript`, `views`) is its own autoload root, so
  `app/use_cases/*.rb` and `app/events/*.rb` define *top-level* constants — `ScheduleMeetingUseCase`,
  `LogRedaction` — with no namespace. Adding a directory under `app/` needs no config change;
  nesting a file one level deeper does introduce a namespace.

## Testing

RSpec, with specs co-located by type under `spec/`, mirroring `app/` and `lib/`. Every production
file has a spec, bar three empty Rails base classes (`ApplicationRecord`, `ApplicationJob`,
`ApplicationHelper`). Controllers are covered by `spec/requests/*` rather than controller specs —
`ApplicationController#rate_limit_identifier` and `Api::BaseController`'s shared `rescue_from`
handlers are pinned in `spec/requests/api/telemetry_spec.rb` and `spec/requests/api/mcp_spec.rb`.

There are **no view specs** and `config.infer_spec_type_from_file_location!` stays commented out,
so a file under `spec/views/` wouldn't even get `type: :view` without saying so. Templates are
covered through the layer that renders them: mailer views by `spec/mailers/*`, `sitemap.xml.erb`
by `spec/requests/static_spec.rb`, the contact form and telemetry feed by `spec/system/*`, and the
`<head>` SEO block by `spec/requests/pages_spec.rb` (JSON-LD, hreflang and canonical fail silently
— a broken one looks fine on the page). The rest of `app/views/` is smoke-covered only: it renders
during `get /en`, so a raise fails the suite, but nothing pins its content, since markup
assertions churn on cosmetic edits.

**Coverage**: SimpleCov is configured at the top of `spec/spec_helper.rb` (line *and* branch), so
a plain `bundle exec rspec` prints the numbers and writes `coverage/index.html`. It uses
`track_files "{app,lib}/**/*.rb"` because Zeitwerk doesn't eager-load in test — without it a file
no spec touches would be missing from the report instead of counted as 0%. The floor
(`minimum_coverage line: 99, branch: 98`) is a ratchet set just under the current numbers, and it
only applies to a whole-suite run: a single-file run covers almost nothing by definition, so the
config skips the check when RSpec was given a path. A breach exits **2** with
`SimpleCov failed with exit 2 due to a coverage related error` *after* the specs have all passed —
it reads like a suite failure but isn't.

Nothing truncates the test database between runs, so a stray `RAILS_ENV=test bin/rails runner`
that writes a row will break the specs asserting absolute `AgentConnection` counts. Clean up after
ad-hoc runner use.

Use `travel_to` (`ActiveSupport::Testing::TimeHelpers`, included globally) for anything touching
`CheckAvailabilityUseCase` or `GetXpYearsUseCase` — both are date-sensitive.

## Code Style

Rubocop with `rubocop-rails-omakase` (Rails' default Omakase style — no custom `.rubocop.yml`
rules beyond what the generator added). Run `bin/rubocop -A` to auto-correct.
