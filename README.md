# My Linktree

Personal landing page with social links, experience history, a contact form, and an MCP server so
AI agents can read the resume, check availability, and book a presentation directly.

## Tech Stack

- **Next.js 16** / **React 19** — App Router, React Compiler enabled
- **Tailwind CSS** — neo-brutalism UI style
- **mcp-handler** / **zod** — MCP server (`/api/mcp`) and tool input validation
- **Resend** — transactional email for the contact form and presentation bookings
- **Upstash Redis** — sliding window rate limiting, booking storage, and agent connection telemetry
- **Lenis** — smooth scrolling
- **Vitest** — unit and integration tests

## Architecture

The codebase follows a layered architecture that keeps business logic independent from the Next.js framework.

```
src/
├── app/                       # Next.js App Router — routes, layout, global CSS
│   ├── api/contact/           # POST /api/contact — contact form email submission
│   ├── api/mcp/               # POST/GET /api/mcp — MCP server (see docs/testing-mcp.md)
│   ├── api/telemetry/         # GET /api/telemetry — recent agent connections, as JSON
│   └── telemetry/             # /telemetry — live-polling UI for agent connections
├── components/                # React client components
│   ├── hire-from-agent.js     # AGENTS.md snippet + copy button, shown on the homepage
│   └── telemetry-feed.js      # Polls /api/telemetry every 5s
├── core/
│   ├── application/
│   │   └── use-cases/         # Framework-agnostic business logic
│   └── infrastructure/        # Adapters for external services
│       ├── database/          # In-memory profile data store
│       ├── mailer/            # Resend adapter + ConsoleMailer stub + createMailer() factory
│       ├── rate-limiter/      # Upstash sliding window rate limiter
│       ├── scheduling/        # Availability config + Upstash-backed booking store
│       └── telemetry/         # Upstash-backed agent connection log
```

**Layers:**

- **Use cases** (`core/application/use-cases/`) hold all business rules as plain JS classes. They have no dependency on Next.js and receive collaborators via constructor injection, making them straightforward to unit test with mocks.
- **Infrastructure** (`core/infrastructure/`) wraps external services behind implicit interfaces. `ResendMailer`/`ConsoleMailer` are selected by `createMailer()` and injected into `SendContactEmailUseCase` / `SchedulePresentationUseCase`; `UpstashRateLimiter`, `UpstashBookingStore`, and `UpstashConnectionLog` are used directly where needed.
- **API routes** are composition roots — each wires infrastructure to use cases and handles HTTP (or JSON-RPC, for `/api/mcp`) concerns. Rate limiting runs before validation; requests without a forwarded IP header skip the limiter entirely.
- **MCP server** (`app/api/mcp/route.js`) registers four tools via `mcp-handler`: `get_resume`, `list_services`, `check_availability`, `schedule_presentation`. Every tool call is recorded through `RecordAgentConnectionUseCase` so it shows up on `/telemetry`. `schedule_presentation` has its own, stricter rate limit on top of the general one. See [`docs/testing-mcp.md`](docs/testing-mcp.md) for what MCP is and how to call it by hand.

## Getting Started

```bash
cp .env.example .env.local   # fill in the required variables
npm install
docker compose up -d         # local Redis, for rate limiting / bookings / telemetry
npm run dev
```

Required environment variables (see `.env.example`):

| Variable                    | Description                                                        |
| --------------------------- | ------------------------------------------------------------------ |
| `MAILER_RESEND_API_KEY`     | Resend API key                                                     |
| `MAILER_SENDER_EMAIL`       | From address for outgoing emails                                   |
| `MAILER_RECIPIENT_EMAIL`    | Destination for contact form submissions and booking notifications |
| `STORAGE_KV_REST_API_URL`   | Upstash Redis REST URL                                             |
| `STORAGE_KV_REST_API_TOKEN` | Upstash Redis REST token                                           |

Optional:

| Variable        | Description                                                                                                                        |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `MAILER_DRIVER` | Set to `console` to log emails instead of sending them — use this locally so testing bookings/contact form doesn't send real email |

## Testing

```bash
npm run test                                      # run all tests
npx vitest src/app/api/contact/route.test.js      # run a single file
```

Tests are co-located with their source files. The contact API has three test layers: unit tests for the route (dependencies mocked), unit tests for `UpstashRateLimiter` (Ratelimit mocked), and integration tests that wire the real `UpstashRateLimiter` class against a fake in-memory Redis backend. The MCP server follows the same pattern — see `src/app/api/mcp/route.test.js`.

For manually exercising the MCP server (sending raw requests, listing tools, booking a slot, checking telemetry), see [`docs/testing-mcp.md`](docs/testing-mcp.md).

---

Released in 2021.

By [Victor B. Fiamoncini](https://github.com/Victor-Fiamoncini) ☕️
