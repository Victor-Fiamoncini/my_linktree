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
│   ├── api/                   # telemetry#index, mcp#create, hire#create
│   ├── pages_controller.rb    # home page
│   ├── contacts_controller.rb # POST /contact — redirect + flash
│   └── telemetry_page_controller.rb
├── services/
│   ├── use_cases/             # framework-agnostic business logic (constructor-injected deps)
│   └── agents_content.rb      # renders config/agents.yml into AGENTS.md / llms.txt
├── mcp_tools/                 # get_resume, list_services, check_availability, schedule_meeting
├── mailers/                   # ContactMailer, MeetingMailer
├── models/                    # Booking (unique slot_start), AgentConnection
└── javascript/controllers/    # 4 Stimulus controllers (telemetry polling, mobile nav, etc.)

lib/
└── seo_config.rb              # SeoConfig — plain constants (site URL, MCP endpoint, etc.),
                                # autoloaded via config.autoload_lib; not a use case, so it lives
                                # outside app/services/
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
  `/telemetry`. `schedule_meeting` has its own, stricter rate limit on top of the general one.

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
  credentials file above at boot — it's the only env var `config/deploy.yml` injects into the app
  container. `KAMAL_SERVER_IP` is also exported here — not a credential, but kept out of
  `config/deploy.yml` (`servers: web: - <%= ENV.fetch("KAMAL_SERVER_IP") %>`) since that file is
  committed to a public repo and the origin otherwise isn't discoverable except through Cloudflare's
  proxy — see the origin firewall note under Cloudflare below.

Before the first deploy: export `KAMAL_REGISTRY_PASSWORD` and `KAMAL_SERVER_IP` locally, fill in
the Docker Hub username placeholder in `config/deploy.yml`, and fill in the production credentials
above with real database connection details.

### Cloudflare

`victorfiamon.com.br` is proxied through Cloudflare (Free plan). Two settings matter for this app:

- **SSL/TLS mode** must be **Full** (not Flexible), so Cloudflare-to-origin traffic is encrypted —
  see the note in `config/deploy.yml`.
- **Block AI bots** (Security → AI Crawl Control) is enabled site-wide, which would otherwise 403
  every AI-agent request to `/api/mcp` (Claude, ChatGPT, etc. connector infra) at the edge, before
  it ever reaches Rails. A Custom Rule ("Allow AI agents on MCP endpoint", under Security →
  Security rules → Custom rules) exempts just that path: `http.request.uri.path eq "/api/mcp"` →
  **Skip**, with both **All managed rules** and **All Super Bot Fight Mode Rules** checked — both
  are required, since the AI-bots block runs under Cloudflare's Bot Management ruleset, not the
  general managed-rules category — checking only "All managed rules" looks correct but still
  403s. This rule lives only in the Cloudflare dashboard; there's no Terraform/API config for it
  in this repo.

  Verify it's still active:

  ```bash
  curl -s -o /dev/null -w "%{http_code}\n" -X POST https://www.victorfiamon.com.br/api/mcp \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    -H 'User-Agent: Claude-User' \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
  ```

  `200` means it's working; `403` means the exception rule is missing, disabled, or the Skip
  checkboxes regressed to just "All managed rules".

  **Note**: Cloudflare is deprecating the standalone "Block AI bots" toggle on 2026-09-15 in favor
  of a "mixed-purpose crawlers" preference under AI Crawl Control. Re-check this exemption still
  passes the `curl` above after that date.

- **Rate limiting rule** ("Flood protection (all paths)", Security → Security rules → Rate
  limiting rules) throttles floods at the edge before they reach Rails: expression `true` (every
  path, `/api/mcp` included) → block an IP for 10 seconds once it crosses 60 requests/10 seconds.
  Free plan allows only **one** rate limiting rule per zone, so `/api/mcp` can't get its own
  separately-tuned rule without upgrading — it shares this one. That's deliberately safe for
  legitimate AI-agent traffic: the "Allow AI agents on MCP endpoint" Skip rule above does **not**
  check "All rate limiting rules" (so it can't exempt `/api/mcp` from this one even if we wanted
  it to), but 60 req/10s per IP is far more than a normal agent session's handful of tool calls
  would ever hit — only an actual flood trips it. App-level rate limiting
  (`ContactsController`/`Api::McpController`'s `rate_limit` macro, see Architecture below) still
  layers on top for `/api/mcp` and `/contact` with tighter, tool-aware thresholds (e.g. a stricter
  limit specifically on `schedule_meeting` calls) that this coarse edge rule can't express.
- **Bot Fight Mode** (Security → Settings, under "Bot traffic") is safe to enable here specifically
  *because* the MCP exemption rule already checks "All Super Bot Fight Mode Rules" — confirm that
  checkbox is still checked before turning this on, or it will 403 AI-agent traffic to `/api/mcp`
  the same way "Block AI bots" would.
- **Origin firewall**: none of the above matters if the origin VPS accepts direct connections —
  Cloudflare's proxy, DDoS protection, and every rule above are bypassed by anyone who requests the
  IP directly instead of the domain (Kamal auto-provisions a real Let's Encrypt cert on the VPS
  itself, so the origin answers with a valid 200 to any `Host: victorfiamon.com.br` request, cert
  included — that cert is also logged in public Certificate Transparency logs, independently of
  whether the IP ever leaks elsewhere). The origin's firewall (Hetzner Cloud Firewall, or `ufw` on
  the box) should allow inbound 80/443 **only** from
  [Cloudflare's published IP ranges](https://www.cloudflare.com/ips/), plus SSH from a trusted IP.
  This isn't configured from this repo — set it up in the Hetzner console or over SSH. Verify with:

  ```bash
  curl -s -o /dev/null -w "%{http_code}\n" -k -H "Host: victorfiamon.com.br" https://<VPS_IP>/
  ```

  A connection timeout/refusal means the firewall is working; a `200` means direct-to-origin access
  is still open.

---

Released in 2021.

By [Victor B. Fiamoncini](https://github.com/Victor-Fiamoncini) ☕️
