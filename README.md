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
│   ├── rate_limiter.rb        # Rails.cache (Solid Cache)-backed sliding-window-ish limiter
│   ├── config_database.rb     # static profile/services data (config/profile.yml)
│   └── seo_config.rb
├── mcp_tools/                 # get_resume, list_services, check_availability, schedule_meeting
├── errors/                    # ApplicationError + 4 subclasses, serialize to {name,message,action}
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
  HTTP (or JSON-RPC, for `/api/mcp`) concerns. Rate limiting runs before validation; requests
  without a forwarded IP header skip the limiter entirely.
- **MCP server** (`Api::McpController`) drives the `mcp` gem's `StreamableHTTPTransport` in
  stateless mode with 4 registered tools. Every tool call is recorded through
  `RecordAgentConnectionUseCase` before validation runs, so even failed calls show up on
  `/telemetry`. `schedule_meeting` has its own, stricter rate limit on top of the general one. See
  [`docs/testing-mcp.md`](docs/testing-mcp.md) for what MCP is and how to call it by hand.

## Getting Started

```bash
cp .env.example .env          # fill in the required variables
bundle install
docker compose up -d          # local Postgres 16
bin/rails db:create db:migrate
bin/dev                       # Rails server + Tailwind watcher
```

Required environment variables (see `.env.example`):

| Variable                | Description                                                          |
| ------------------------ | --------------------------------------------------------------------- |
| `DATABASE_HOST`           | Postgres host (defaults to `localhost`, matching `compose.yml`)       |
| `DATABASE_USERNAME`       | Postgres role                                                         |
| `DATABASE_PASSWORD`       | Postgres password                                                     |
| `MAILER_SENDER_EMAIL`     | From address for contact/meeting emails                               |
| `MAILER_RECIPIENT_EMAIL`  | Where contact form submissions and meeting notifications are sent     |
| `MAILER_RESEND_API_KEY`   | Resend API key (only used in production — development uses `:test` delivery) |

## Commands

```bash
bin/dev                  # Rails server + Tailwind CSS watcher
bin/rails server          # Rails server only
bundle exec rspec         # Run the test suite
bin/rubocop               # Lint (rubocop-rails-omakase)
bin/rails db:migrate       # Run pending migrations
```

## Testing the MCP server

See [`docs/testing-mcp.md`](docs/testing-mcp.md) for manually calling the MCP server (raw JSON-RPC
requests, listing tools, booking a slot, checking rate limits and telemetry) — it also explains
what MCP is and how it differs from plain HTTP/REST.
