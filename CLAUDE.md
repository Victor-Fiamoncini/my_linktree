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

## Environment Variables

Copy `.env.example` to `.env` for local development (loaded via `dotenv-rails`). Required vars:

- `DATABASE_HOST` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` — Postgres connection, matching `compose.yml`
- `MAILER_SENDER_EMAIL` — From address for contact/meeting emails
- `MAILER_RECIPIENT_EMAIL` — Where contact form submissions and meeting notifications are sent
- `MAILER_RESEND_API_KEY` — Resend API key, only used in production

`config.action_mailer.delivery_method` is `:test` in development (mail is captured in
`ActionMailer::Base.deliveries`, nothing is sent) and `:resend` in production (via the `resend`
gem's Railtie-registered ActionMailer delivery method, configured in
`config/initializers/resend.rb`). There is no more `MAILER_DRIVER` env var — the switch is purely
per-environment now.

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
    rate_limiter.rb             # Rails.cache (Solid Cache)-backed; blank identifier = always allowed
    config_database.rb          # loads config/profile.yml (static resume/services data)
    seo_config.rb
    agents_content.rb           # AGENTS.md content, shared by the UI snippet and /AGENTS.md route
  mcp_tools/                    # MCP::Tool subclasses: get_resume, list_services,
                                 # check_availability, schedule_meeting
  errors/                       # ApplicationError + 4 subclasses (see "Errors" below)
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
  collaborators.
- **Errors** (`app/errors/`): `ApplicationError` is a `StandardError` subclass with an `action`
  message and a custom `#as_json` returning `{ name, message, action }`. Four subclasses:
  `MissingRequiredFieldsError` (400), `SlotUnavailableError` (surfaced as MCP `isError: true`, not
  an HTTP status), `TooManyRequestsError` (429), `InternalServerError` (500).
- **Rate limiting**: `RateLimiter` wraps `Rails.cache` (`Rails.cache.increment` with `expires_in`),
  which is Solid Cache (Postgres-backed) in both development and production, and `MemoryStore` in
  test. Used explicitly inside `ContactsController` and `Api::McpController` rather than
  Rails' declarative `rate_limit` class macro, because the `schedule_meeting`-specific throttle
  needs to inspect the parsed JSON-RPC body before deciding which limiter(s) apply. A blank
  identifier (no `x-forwarded-for`/`x-real-ip` header) always returns `allowed? == true` — rate
  limiting is skipped entirely for such requests, matching the original behavior.
- **MCP server** (`Api::McpController`): builds a fresh `MCP::Server` + stateless
  `MCP::Server::Transports::StreamableHTTPTransport` per request (official `mcp` gem), and proxies
  its Rack `[status, headers, body]` triple straight through the Rails response (`self.status=`,
  `response.set_header`, `self.response_body=`) rather than using `render`, so both the plain-JSON
  and SSE response shapes pass through untouched. The 4 `MCP::Tool` subclasses deliberately don't
  declare `required:` in their `input_schema` — the gem short-circuits before calling the tool when
  required args are missing, but the original behavior (and this port's) records the agent
  connection *before* validating, even for calls that go on to fail. Validation instead happens
  inside the use cases, with domain errors caught in the tool's `call` and turned into
  `MCP::Tool::Response.new(..., error: true)` rather than raised.
- **`@/` alias**: none — this is a standard Rails app, autoloaded via Zeitwerk from `app/*`.
  `app/services/use_cases/*.rb` autoloads as `UseCases::*` (the `use_cases` subdirectory becomes an
  implicit namespace under the `app/services` root).

## Testing

RSpec, with specs co-located by type under `spec/` (`spec/models`, `spec/services/use_cases`,
`spec/requests`, `spec/requests/api`).

- `Rails.cache.clear` runs before every example (`spec/rails_helper.rb`) — `RateLimiter` instances
  are memoized as controller-level constants and share the process-wide cache, so state must be
  reset between examples or one spec's requests would count toward another spec's rate limit.
- The `mcp` gem's DNS-rebinding protection only allows loopback `Host` headers by default; request
  specs against `/api/mcp` need `host! "127.0.0.1"` (Rails' request-spec default host,
  `www.example.com`, gets rejected with 403).
- Use `travel_to`/`around { |example| travel_to(...) { example.run } }`
  (`ActiveSupport::Testing::TimeHelpers`, included globally) for anything touching
  `CheckAvailabilityUseCase` or `GetXpYearsUseCase` — both are date-sensitive.

## Code Style

Rubocop with `rubocop-rails-omakase` (Rails' default Omakase style — no custom `.rubocop.yml`
rules beyond what the generator added). Run `bin/rubocop -A` to auto-correct.
