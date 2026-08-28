# My Linktree

Personal landing page with social links, experience history, a contact form, and an MCP server so
AI agents can read the resume, check availability, and book a meeting directly.

## Tech Stack

- **Ruby on Rails 8** — Hotwire (Turbo + Stimulus) via importmap, no Node/JS build step
- **Postgres 16** — primary database, plus Solid Cache (rate limiting), Solid Queue, and Solid Cable
- **Tailwind CSS** — hand-rolled Catppuccin Frappé theme, via the `tailwindcss-rails` gem
- **`mcp`** — official Ruby MCP SDK, driving the MCP server (`/api/mcp`)
- **Resend** — transactional email for the contact form and meeting bookings (`:test` delivery in development)
- **RSpec** — model, service, and request specs

## Architecture

The codebase keeps business logic independent from Rails proper, mirroring the layered structure
the app had before this migration:

```
app/
├── controllers/
│   ├── api/                   # telemetry#index, mcp#create, profile#show
│   ├── pages_controller.rb    # home page
│   ├── contacts_controller.rb # POST /contact — redirect + flash
│   └── telemetry_page_controller.rb
├── services/
│   ├── use_cases/             # framework-agnostic business logic (constructor-injected deps)
│   └── seo_config.rb
├── mcp_tools/                 # get_resume, list_services, check_availability, schedule_meeting
├── mailers/                   # ContactMailer, MeetingMailer
├── models/                    # Booking (unique slot_start), AgentConnection
└── javascript/controllers/    # 4 Stimulus controllers (telemetry polling, mobile nav, etc.)
```

**Layers:**

- **Use cases** (`app/services/use_cases/`) hold all business rules as plain Ruby classes with
  constructor-injected collaborators, unit-tested in isolation.
- **Models** (`Booking`, `AgentConnection`) replace the old Redis-backed stores; double-booking
  prevention is a DB-level unique index on `slot_start` instead of a Redis `SETNX` reservation key.
- **Controllers** are composition roots — they wire models/services to use cases and translate
  HTTP (or JSON-RPC, for `/api/mcp`) concerns. Rate limiting uses Rails 8's `rate_limit` macro,
  keyed by `request.remote_ip` (Rails' trusted-proxy-aware IP resolution — a client can't spoof
  or omit headers to dodge the limit). Use cases raise plain `ArgumentError` for validation/
  business-rule failures instead of a custom error hierarchy; controllers and MCP tools catch it
  via `rescue_from`/`rescue` and turn it into a user-facing message.
- **MCP server** (`Api::McpController`) drives the `mcp` gem's `StreamableHTTPTransport` in
  stateless mode with 4 registered tools. Every tool call is recorded through
  `RecordAgentConnectionUseCase` before validation runs, so even failed calls show up on
  `/telemetry`. `schedule_meeting` has its own, stricter rate limit on top of the general one. See
  [`docs/testing-mcp.md`](docs/testing-mcp.md) for what MCP is and how to call it by hand.

## Getting Started

```bash
bundle install
docker compose up -d          # local Postgres 16
bin/rails db:create db:migrate
bin/dev                       # Rails server + Tailwind watcher
```

No `.env` file needed — database connection and mailer sender/recipient are pulled from Rails'
encrypted credentials at `config/credentials/development.yml.enc`, prefilled to match
`compose.yml` (`my_linktree`/`my_linktree` on `localhost:5432`). To change any of it:

```bash
bin/rails credentials:edit --environment development
```

Development always uses `:test` mail delivery (captured in `ActionMailer::Base.deliveries`,
nothing sent), so there's no Resend API key to configure locally — that only exists in production
credentials (see below).

### First-time key setup

`config/credentials/development.yml.enc` is committed (encrypted, safe for git), but the key that
decrypts it — `config/credentials/development.key` — is gitignored like every `*.key` file, so a
fresh clone can't read it yet. Same for `config/master.key`, which backs the shared
`config/credentials.yml.enc` (`secret_key_base`, plus `test`'s mailer fallback — see `CLAUDE.md`).
Get both key files from whoever holds them (e.g. a password manager) and drop them in `config/` and
`config/credentials/` respectively before running `bin/rails credentials:edit` or booting the app.

If you're setting the app up standalone with no access to the original keys, delete the two `.enc`
files and regenerate them with real content — none of the development values are actual secrets,
they just need to exist:

```bash
bin/rails credentials:edit --environment development
```

should contain:

| Key                          | Example value (matches `compose.yml`) |
| ----------------------------- | -------------------------------------- |
| `database.host`               | `localhost`                            |
| `database.port`               | `5432`                                 |
| `database.username`           | `my_linktree`                          |
| `database.password`           | `my_linktree`                          |
| `mailer.sender_email`         | `dev@example.com`                      |
| `mailer.recipient_email`      | any address you want test emails addressed to |
| `mailer.resend_api_key`       | placeholder (unused locally — `:test` delivery never calls Resend) |

`config/credentials/production.yml.enc` has the same shape, but with real production values
(external Postgres connection, real sender/recipient addresses, and a real
`mailer.resend_api_key` — this one *is* used, since production delivers mail through Resend). See
[Deployment](#deployment) below.

## Commands

```bash
bin/dev                  # Rails server + Tailwind CSS watcher
bin/rails server          # Rails server only
bundle exec rspec         # Run the test suite
bin/rubocop               # Lint (rubocop-rails-omakase)
bin/rails db:migrate       # Run pending migrations
```

## Deployment

Deployed with [Kamal](https://kamal-deploy.org) (`config/deploy.yml`) to a single VPS, pulling a
Docker Hub image built from the repo's `Dockerfile`.

Secrets split across two mechanisms, depending on who needs them and when:

- **Rails encrypted credentials** (`config/credentials/production.yml.enc`, decrypted by
  `config/credentials/production.key`) hold everything the *app* needs once it's running:
  production Postgres `host`/`port`/`username`/`password`, mailer `sender_email`/`recipient_email`,
  and the Resend `resend_api_key`. These are per-environment credentials, separate from the shared
  `config/master.key` used as `test`'s fallback — a leaked dev/test key can't decrypt production
  secrets. Edit with:

  ```bash
  bin/rails credentials:edit --environment production
  ```

  `config/database.yml`'s production block, the mailer classes, and `config/initializers/resend.rb`
  all read these via `Rails.application.credentials.dig(...)`. None of it is a plain env var.

- **Kamal secrets** (`.kamal/secrets`) hold what's needed *before* the app can decrypt anything:
  `KAMAL_REGISTRY_PASSWORD` (a Docker Hub access token, exported in your shell before deploying) and
  `RAILS_MASTER_KEY` (read straight from `config/credentials/production.key` on disk — note this is
  the production-scoped key, not `config/master.key`). This is what lets the container decrypt the
  credentials file above at boot — it's the only env var `config/deploy.yml` injects.

Before the first deploy: export `KAMAL_REGISTRY_PASSWORD` locally, fill in the placeholders in
`config/deploy.yml` (Docker Hub username, VPS IP), and fill in the production credentials above
with real database connection details.

---

Released in 2021.

By [Victor B. Fiamoncini](https://github.com/Victor-Fiamoncini) ☕️
