# My Linktree

Personal landing page with social links, experience history, a contact form, and an MCP server so
AI agents can read the resume, check availability, and book a meeting directly.

## Tech Stack

- **Ruby on Rails 8** — Hotwire (Turbo + Stimulus) via importmap, no Node/JS build step
- **Postgres 16** — primary database, plus Solid Cache (rate limiting), Solid Queue, and Solid Cable
- **Tailwind CSS** — hand-rolled Catppuccin Frappé theme, via the `tailwindcss-rails` gem
- **`mcp`** — official Ruby MCP SDK, driving the MCP server (`/api/mcp`)
- **Resend** — transactional email for the contact form and meeting bookings (`:test` delivery in development)
- **Sentry** (`sentry-ruby`/`sentry-rails`) — exception monitoring, DSN pulled from encrypted credentials
- **Better Stack** (`logtail-rails`) — production log drain plus structured events on the API/MCP endpoints, emitted with Rails 8.1's `Rails.event`
- **RSpec** — model, service, and request specs

## Architecture

The codebase keeps business logic independent from Rails proper, mirroring the layered structure
the app had before this migration:

```
app/
├── controllers/
│   ├── api/                   # telemetry#index, mcp#create, hire#create
│   ├── pages_controller.rb    # home page
│   ├── contacts_controller.rb # POST /contact — JSON response
│   └── telemetry_page_controller.rb
├── use_cases/                 # framework-agnostic business logic (constructor-injected deps)
├── events/                    # everything serving Rails.event: the non-production subscriber,
│                              # and LogRedaction (redacts contacts before they reach a payload)
├── mcp_tools/                 # get_resume, list_services, check_availability, schedule_meeting
├── mailers/                   # ContactMailer, MeetingMailer
├── models/                    # Booking (unique slot_start), AgentConnection
└── javascript/controllers/    # 7 Stimulus controllers (telemetry polling, mobile nav, etc.)

lib/                           # static, request-independent site facts and the text built from
                                # them, autoloaded via config.autoload_lib
├── seo_config.rb              # SeoConfig — plain constants (site URL, MCP endpoint, etc.)
└── agents_content.rb          # renders the two config/agents.yml bodies (AGENTS.md, llms.txt)
```

**Layers:**

- **Use cases** (`app/use_cases/`) hold all business rules as plain Ruby classes with
  constructor-injected collaborators, unit-tested in isolation. Every directory under `app/` is
  its own Zeitwerk root, so these are top-level constants (`ScheduleMeetingUseCase`), not
  namespaced.
- **Models** (`Booking`, `AgentConnection`) replace the old Redis-backed stores; double-booking
  prevention is a DB-level unique index on `slot_start` instead of a Redis `SETNX` reservation key.
- **Controllers** are composition roots — they wire models/services to use cases and translate
  HTTP (or JSON-RPC, for `/api/mcp`) concerns. Rate limiting uses Rails 8's `rate_limit` macro,
  keyed by `ApplicationController#rate_limit_identifier` — Cloudflare's `CF-Connecting-IP` header,
  falling back to `request.remote_ip` only when it's absent (local dev/test). See that method's
  comment for why `X-Forwarded-For` isn't trusted here. Use cases raise plain `ArgumentError` for
  validation/business-rule failures rather than a deep error hierarchy; controllers and MCP tools
  catch it via `rescue_from`/`rescue` and turn it into a user-facing message. The contact and hire
  use cases both raise the shared `ValidationError` subclass of it, which carries a per-field
  `errors` hash.
- **Agent-facing surface** — `/AGENTS.md` (prose) and `/llms.txt` (a link index in the
  [llmstxt.org](https://llmstxt.org) shape) are two bodies in `config/agents.yml`, both leading
  with the MCP endpoint and its four tools and keeping `POST /api/hire` as the fallback for
  clients that don't speak MCP. Specs assert neither drifts from the tools the server registers
  or links a URL that doesn't route. `robots.txt` disallows `/api/` but explicitly allows
  `/api/mcp`.
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
fresh clone can't read it yet. Get it from whoever holds it (e.g. a password manager) and drop it in
`config/credentials/` before running `bin/rails credentials:edit` or booting the app. The one
exception is `config/credentials/test.key`: it's committed, since `test.yml.enc` holds only dummy
values, so the specs run on a fresh clone (and in CI) with no key setup.

If you're setting the app up standalone with no access to the original keys, delete
`config/credentials/development.yml.enc` and regenerate it with real content — none of the
development values are actual secrets, they just need to exist:

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
| `sentry_dsn`                  | placeholder, or a real DSN from your own Sentry project if you want local errors reported |

No `better_stack` key here: the log drain is production-only. Locally the same structured events
are printed to the Rails log instead (lines like `[mcp.request] {...}`), so you can see exactly
what production would ship without sending anything.

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
  the Resend `resend_api_key`, `sentry_dsn`, and `better_stack.source_token` /
  `better_stack.ingesting_host`. These are per-environment credentials, separate
  from the dev/test keys — a leaked dev/test key can't
  decrypt production secrets. Edit with:

  ```bash
  bin/rails credentials:edit --environment production
  ```

  `config/database.yml`'s production block, the mailer classes, `config/initializers/resend.rb`,
  and `config/initializers/sentry.rb` all read these via `Rails.application.credentials.dig(...)`.
  None of it is a plain env var. `test` has no `sentry_dsn` (`config/credentials/test.yml.enc`
  doesn't define one), so Sentry is a silent no-op there rather than sending events. Better Stack
  behaves the same way: with no `better_stack.source_token` the app keeps its plain STDOUT logger,
  which is also what happens during `assets:precompile` in the Docker build (it runs without the
  credentials key).

- **Kamal secrets** (`.kamal/secrets`) hold what's needed *before* the app can decrypt anything:
  `KAMAL_REGISTRY_PASSWORD` (a Docker Hub access token, exported in your shell before deploying) and
  `RAILS_MASTER_KEY` (read straight from `config/credentials/production.key` on disk — note this is
  the production-scoped key). This is what lets the container decrypt the
  credentials file above at boot — it's the only env var `config/deploy.yml` injects into the app
  container. `KAMAL_SERVER_IP` is also exported here — not a credential, but kept out of
  `config/deploy.yml` (`servers: web: - <%= ENV.fetch("KAMAL_SERVER_IP") %>`) since that file is
  committed to a public repo and the origin otherwise isn't discoverable except through Cloudflare's
  proxy — see the origin firewall note under Cloudflare below.

Before the first deploy: export `KAMAL_REGISTRY_PASSWORD` and `KAMAL_SERVER_IP` locally, fill in
the Docker Hub username placeholder in `config/deploy.yml`, and fill in the production credentials
above with real database connection details.

### Better Stack

Production logs are shipped to [Better Stack](https://betterstack.com/logs). To wire up a new
source:

1. In the Better Stack dashboard, go to **Telemetry → Sources → Connect source** and pick platform
   **Ruby**. The source's setup page then shows a **Source Token** and an **Ingesting host**
   (`sNNNNNN.<region>.betterstackdata.com`).
2. Put both in the production credentials:

   ```bash
   bin/rails credentials:edit --environment production
   ```

   ```yaml
   better_stack:
     source_token: <source token>
     ingesting_host: <ingesting host>
   ```

3. `kamal deploy`. No new env var and no change to `config/deploy.yml` or `.kamal/secrets` —
   `RAILS_MASTER_KEY` already decrypts the file.

To verify: **Live tail** on the source should show one `http.request` entry per request, plus the
app's own structured events (`mcp.request`, `api.rate_limited`, `contact.message.sent`, …).
`kamal app logs -f` keeps working in parallel — the Better Stack logger broadcasts to STDOUT, so
the container log is not sacrificed for the drain.

Logs are shipped in a background thread and dropped rather than queued if the queue fills, so an
unreachable Better Stack slows nothing down and takes nothing offline. Leaving `better_stack` out
of the credentials entirely disables the drain and falls back to plain STDOUT logging.

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
- **IP Geolocation** (Rules → Settings) must stay **on**, or `CF-IPCountry` never reaches Rails and
  `PagesController#root_redirect` silently falls back to `Accept-Language` — nothing looks broken.
  Safe to trust unconditionally for the same reason as `CF-Connecting-IP`: the origin firewall
  below restricts inbound 80/443 to Cloudflare's ranges, so no outside client can forge it.

  ```bash
  curl -s -o /dev/null -w "%{redirect_url}\n" -H 'Accept-Language: pt-BR' \
    https://www.victorfiamon.com.br/
  ```

  The Portuguese header is the whole point: from a non-Brazilian network expect `.../en`, which
  can only happen if a country header arrived and vetoed it. `.../pt-BR` means no country
  arrived — IP Geolocation is off. Without that header the command returns `.../en` either way
  and proves nothing. From a Brazilian IP or VPN exit, expect `.../pt-BR`.
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
