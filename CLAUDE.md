# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev                  # Rails server + Tailwind CSS watcher (foreman via Procfile.dev)
bin/rails server           # Rails server only (no Tailwind watcher — CSS won't rebuild on change)
bundle exec rspec          # Run all tests
bin/rubocop                # Lint (rubocop-rails-omakase)
bin/rails db:migrate        # Run pending migrations
bin/rails db:create db:migrate  # First-time setup, after `docker compose up -d`
```

Run a single test file:

```bash
bundle exec rspec spec/requests/api/mcp_spec.rb
```

Ruby version: see `.ruby-version`. Rails 8.1.

Postgres 16 is required for local development — run `docker compose up -d` (see `compose.yml`).
There is no Redis anywhere in this app: rate limiting, background jobs, and (in production)
ActionCable all ride on Rails 8's Postgres-backed Solid Cache / Solid Queue / Solid Cable.

## Credentials

There is no `.env`/`dotenv-rails` anymore — all per-environment config (database connection,
mailer sender/recipient, Resend API key) lives in Rails' per-environment encrypted credentials
under `config/credentials/`, not env vars:

- `config/credentials/development.yml.enc` (key: `config/credentials/development.key`) — holds
  `database.host/port/username/password` (matching `compose.yml`'s `my_linktree`/`my_linktree`)
  and `mailer.sender_email`/`mailer.recipient_email`. Edit with
  `bin/rails credentials:edit --environment development`.
- `config/credentials/production.yml.enc` (key: `config/credentials/production.key`) — same shape,
  plus `mailer.resend_api_key`. Edit with `bin/rails credentials:edit --environment production`.
- `config/credentials.yml.enc` (the shared file, key: `config/master.key`) — only used as a
  fallback for environments without their own file, i.e. `test`. Holds `secret_key_base` plus a
  `mailer` block (test doesn't need a real inbox, just non-nil values so `mail()` doesn't raise).
  Edit with `bin/rails credentials:edit` (no `--environment` flag) — but see the gotcha below.

**Gotcha**: `bin/rails credentials:edit` with no `--environment` flag targets the shared file only
if `Rails.env` (which defaults to `development` when `RAILS_ENV` is unset) has no matching
per-environment file. Since `config/credentials/development.yml.enc` exists, running the bare
command from a normal shell silently edits *that* file instead of the shared one. To edit the
shared file specifically, `RAILS_ENV=test bin/rails credentials:edit` works, or use
`ActiveSupport::EncryptedConfiguration` directly with explicit `config_path`/`key_path`.

`config/database.yml`'s `development` block and `production` block both read connection details via
`Rails.application.credentials.dig(:database, :host)` etc. `test` deliberately keeps the original
ENV-based `default` anchor (`ENV.fetch("DATABASE_HOST") { "localhost" }`, etc.) — its fallback
values already equal `compose.yml`'s, so it needs no credentials file or env var at all. Mailers
(`app/mailers/application_mailer.rb`, `contact_mailer.rb`, `meeting_mailer.rb`) read
`Rails.application.credentials.dig(:mailer, :sender_email)` / `:recipient_email` in every
environment. `config/initializers/resend.rb` reads `Rails.application.credentials.dig(:mailer,
:resend_api_key)`.

`config.action_mailer.delivery_method` is `:test` in development (mail is captured in
`ActionMailer::Base.deliveries`, nothing is sent) and `:resend` in production (via the `resend`
gem's Railtie-registered ActionMailer delivery method).

Kamal only needs `RAILS_MASTER_KEY` (set to the *production* credentials key's contents, not the
shared master key — see `.kamal/secrets`) to decrypt `production.yml.enc` at boot, plus
`KAMAL_REGISTRY_PASSWORD` to pull the image; see `config/deploy.yml`.

## Architecture

This is a Rails 8 personal landing page using Hotwire (Turbo + Stimulus via importmap — no Node,
no JS bundler). It also serves an MCP server so AI agents can read the resume, check availability,
and book a meeting — see `docs/testing-mcp.md` for what MCP is and how to exercise it manually.

```
app/
  controllers/
    application_controller.rb   # sets @default_description, allow_browser :modern
    pages_controller.rb         # GET / (home)
    contacts_controller.rb      # POST /contact — redirect + flash
    telemetry_page_controller.rb # GET /telemetry
    static_controller.rb        # AGENTS.md, llms.txt, sitemap.xml
    api/
      telemetry_controller.rb   # GET /api/telemetry — last 50 {tool, timestamp}, no auth
      mcp_controller.rb         # POST/GET /api/mcp — see "MCP server" below
      profile_controller.rb     # GET /api/profile
  mailers/
    contact_mailer.rb           # new_contact
    meeting_mailer.rb           # confirmation, notification
  models/
    booking.rb                  # unique index on slot_start prevents double-booking
    agent_connection.rb         # MCP tool-call telemetry
  services/
    use_cases/                  # framework-agnostic business logic, constructor-injected deps
      get_profile_use_case.rb
      list_services_use_case.rb
      get_xp_years_use_case.rb
      check_availability_use_case.rb   # timezone-aware slot generation (ActiveSupport::TimeZone)
      schedule_meeting_use_case.rb     # composes CheckAvailabilityUseCase, books + emails
      send_contact_email_use_case.rb
      record_agent_connection_use_case.rb
      list_recent_connections_use_case.rb
    seo_config.rb
    agents_content.rb           # AGENTS.md content, shared by the UI snippet and /AGENTS.md route
  mcp_tools/                    # MCP::Tool subclasses: get_resume, list_services,
                                 # check_availability, schedule_meeting
  javascript/controllers/       # Stimulus: telemetry_feed, mobile_nav, experiences_tabs,
                                 # hire_from_agent
  views/
    layouts/application.html.erb
    pages/                      # home.html.erb + partials (hero, experiences, contact, etc.)
    telemetry_page/show.html.erb
    shared/                     # header, footer, flash, external_link, person_json_ld partials
config/
  profile.yml                  # static resume/services data (was memory-database.js)
  availability.yml             # timezone, weekly windows, slot duration, booking horizon
  database.yml                 # dev/test use ENV-driven Postgres connection
```

### Key design decisions

- **Use cases** (`app/services/use_cases/`) contain all business logic and have no controller/view
  dependency. They're unit-tested in isolation using RSpec with doubles/instance_doubles for
  collaborators. `GetProfileUseCase` and `ListServicesUseCase` load `config/profile.yml` directly
  via `Rails.application.config_for(:profile)` — there's no `ConfigDatabase` wrapper class.
- **Errors**: no custom error hierarchy — use cases raise plain `ArgumentError` (with a message
  like `"Missing required fields"` or `"Slot unavailable"`) for validation/business-rule failures.
  Controllers catch it via `rescue_from ArgumentError` (`ContactsController`); `ScheduleMeetingTool`
  catches it directly (`rescue ArgumentError => e`) and turns it into an MCP `isError: true`
  response using `e.message`. `ContactsController` also has a dedicated
  `rescue_from ActionController::InvalidAuthenticityToken` (Rails' default CSRF protection raises
  this on a missing/stale token) so an expired session redirects with a flash message instead of
  a raw 422. Anything else falls through to a generic `rescue_from StandardError`
  (`ContactsController`, `Api::BaseController`) for a 500-equivalent response.
- **Rate limiting**: uses Rails 8's declarative `rate_limit` class macro
  (`ActionController::RateLimiting`) in `ContactsController` and `Api::McpController`, backed by
  `Rails.cache` — Solid Cache (Postgres-backed) in development/production, `MemoryStore` in test.
  `ApplicationController#rate_limit_identifier` returns `request.remote_ip` — Rails' own
  trusted-proxy-aware IP resolution — rather than reading `X-Forwarded-For`/`X-Real-IP` directly, so
  a client can't spoof or omit those headers to dodge the limit; every request is rate-limited by
  its real connection IP (or the proxy-forwarded IP, only when the connection comes from a trusted
  proxy — see `config.action_dispatch.trusted_proxies` if this app ever sits behind a public-IP
  reverse proxy/CDN, which needs to be added to that list to be trusted).
  `Api::McpController` declares two named limiters on the same action — a general one and a
  `schedule_meeting`-specific one — and the schedule-specific limiter's `unless:` proc calls
  `schedule_meeting_call?` (which parses and rewinds the JSON-RPC request body) so it only counts
  against requests calling the `schedule_meeting` tool. Both controllers catch the resulting
  `ActionController::TooManyRequests` via `rescue_from` rather than using the macro's `with:` option,
  to keep the handling consistent with their other `rescue_from`-based error handling.
- **MCP server** (`Api::McpController`): builds a fresh `MCP::Server` + stateless
  `MCP::Server::Transports::StreamableHTTPTransport` per request (official `mcp` gem), and proxies
  its Rack `[status, headers, body]` triple straight through the Rails response (`self.status=`,
  `response.set_header`, `self.response_body=`) rather than using `render`, so both the plain-JSON
  and SSE response shapes pass through untouched. The transport is constructed with
  `dns_rebinding_protection: false` — the gem's default protection (`Host`/`Origin` allow-listing)
  guards against DNS-rebinding attacks on a *loopback-bound* server, which doesn't apply here: this
  is a public, unauthenticated, cookie-free endpoint meant to be called by arbitrary external MCP
  clients (Claude, ChatGPT, etc.) whose `Origin` values can't be enumerated in advance, and `Host`
  is already validated independently by Rails' own `config.hosts` in
  `config/environments/production.rb`. `set_cors_headers` reflects whatever `Origin` header is
  present (rather than allow-listing) for the same reason — safe because the endpoint never sets
  `Access-Control-Allow-Credentials`. The 4 `MCP::Tool` subclasses deliberately don't declare `required:` in their
  `input_schema` — the gem short-circuits before calling the tool when required args are missing,
  but the original behavior (and this port's) records the agent connection *before* validating,
  even for calls that go on to fail. Validation instead happens inside the use cases, with domain
  errors caught in the tool's `call` and turned into `MCP::Tool::Response.new(..., error: true)`
  rather than raised.
- **`@/` alias**: none — this is a standard Rails app, autoloaded via Zeitwerk from `app/*`.
  `app/services/use_cases/*.rb` autoloads as `UseCases::*` (the `use_cases` subdirectory becomes an
  implicit namespace under the `app/services` root).

## Testing

RSpec, with specs co-located by type under `spec/` (`spec/models`, `spec/services/use_cases`,
`spec/requests`, `spec/requests/api`).

- `Rails.cache.clear` runs before every example (`spec/rails_helper.rb`) — Rails' `rate_limit`
  macro shares the process-wide cache for its counters, so state must be reset between examples or
  one spec's requests would count toward another spec's rate limit.
- Use `travel_to`/`around { |example| travel_to(...) { example.run } }`
  (`ActiveSupport::Testing::TimeHelpers`, included globally) for anything touching
  `CheckAvailabilityUseCase` or `GetXpYearsUseCase` — both are date-sensitive.

## Code Style

Rubocop with `rubocop-rails-omakase` (Rails' default Omakase style — no custom `.rubocop.yml`
rules beyond what the generator added). Run `bin/rubocop -A` to auto-correct.
