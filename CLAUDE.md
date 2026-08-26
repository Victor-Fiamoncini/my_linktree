# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev              # Start development server
npm run build            # Build for production
npm run start            # Run production build
npm run test             # Run all tests (Vitest)
npm run lint             # Run ESLint
npm run format:check     # Check formatting
npm run format           # Auto-fix formatting
npm run commit           # Commitizen interactive commit
```

Run a single test file:

```bash
npx vitest src/components/contact-form.test.jsx
```

Node version: 22.21.1 (see `.nvmrc`).

Rate limiting, the booking store, and agent connection telemetry are all backed by Upstash Redis.
For local development, run `docker compose up -d` (see `compose.yml`) and point `STORAGE_KV_REST_API_URL`/`STORAGE_KV_REST_API_TOKEN` at it — `.env.example` has the exact values to use.

## Environment Variables

Copy `.env.example` to `.env.local` for local development. Required vars:

- `MAILER_RESEND_API_KEY` — API key for the Resend email service
- `MAILER_SENDER_EMAIL` — From address for contact emails
- `MAILER_RECIPIENT_EMAIL` — Where contact form submissions are sent
- `STORAGE_KV_REST_API_URL` — Upstash Redis REST URL (rate limiting)
- `STORAGE_KV_REST_API_TOKEN` — Upstash Redis REST token (rate limiting)

Optional:

- `MAILER_DRIVER` — Set to `console` to log emails instead of sending them via Resend. Use this locally to avoid sending real email when testing the contact form or MCP `schedule_meeting` tool. `createMailer()` (`src/core/infrastructure/mailer/create-mailer.js`) selects the mailer; both API routes use it instead of instantiating `ResendMailer` directly.

## Architecture

This is a Next.js 16 / React 19 personal landing page. The codebase follows a layered architecture separating core business logic from the Next.js framework. It also serves an MCP server so AI agents can read the resume, check availability, and book a meeting — see `docs/testing-mcp.md` for what MCP is and how to exercise it manually.

```
src/
  app/                        # Next.js App Router (routes, layout, global CSS)
    api/contact/
      route.js                # POST handler — returns 204 on success
      route.test.js           # API route unit tests (mailer + rate limiter mocked)
    api/mcp/
      route.js                # POST/GET handler — registers 4 tools via mcp-handler, wraps 2 rate limiters
      route.test.js
    api/telemetry/
      route.js                # GET handler — recent agent connections as JSON
      route.test.js
    telemetry/page.js         # /telemetry — renders <TelemetryFeed />
    layout.js                 # Root layout with metadata/SEO
    page.js                   # Home page (server component)
  components/                 # React client components (co-located with tests)
    contact-form.js
    contact-form.test.jsx
    external-link.js
    external-link.test.jsx
    hire-from-agent.js        # AGENTS.md snippet + copy button, shown on the homepage
    hire-from-agent.test.jsx
    telemetry-feed.js         # Client component, polls /api/telemetry every 5s
    telemetry-feed.test.jsx
    smooth-scroll.js          # Wires up Lenis smooth scrolling
  core/
    application/use-cases/    # Business logic (framework-agnostic, co-located with tests)
      get-profile-use-case.js
      list-services-use-case.js
      check-availability-use-case.js
      schedule-meeting-use-case.js
      record-agent-connection-use-case.js
      list-recent-connections-use-case.js
      send-contact-email-use-case.js
    infrastructure/           # External service adapters and error classes
      errors.js               # MissingRequiredFieldsError, SlotUnavailableError, TooManyRequestsError, InternalServerError
      mailer/
        resend-mailer.js       # Real Resend adapter
        console-mailer.js      # Logs the email instead of sending it (local dev)
        create-mailer.js       # Factory: picks Resend vs. console mailer via MAILER_DRIVER
      rate-limiter/
        upstash-rate-limiter.js               # Sliding window via @upstash/ratelimit
        upstash-rate-limiter.test.js          # Unit tests (Ratelimit mocked)
        upstash-rate-limiter.integration.test.js  # Integration tests (fake in-memory Ratelimit)
      scheduling/
        availability-config.js       # Timezone, weekly windows, slot duration, booking horizon
        upstash-booking-store.js     # Reads/writes booked slots in Upstash Redis
      telemetry/
        upstash-connection-log.js    # Appends/reads MCP tool-call records in Upstash Redis
  e2e-setup.js                # Global test setup (jest-dom matchers + RTL cleanup)
```

### Key design decisions

- **Use cases** (`src/core/application/use-cases/`) contain all business logic and are plain JS classes with no Next.js dependency. They are unit-tested in isolation using Vitest with mocked dependencies.
- **Infrastructure** (`src/core/infrastructure/`) wraps external services. `createMailer()` picks `ResendMailer` or `ConsoleMailer` (via `MAILER_DRIVER`) and is injected into `SendContactEmailUseCase` / `ScheduleMeetingUseCase` via constructor injection. `UpstashRateLimiter` wraps `@upstash/ratelimit` with a sliding window algorithm; `UpstashBookingStore` and `UpstashConnectionLog` similarly wrap Upstash Redis for bookings and agent-connection telemetry.
- **API routes** (`src/app/api/*/route.js`) are composition roots — they wire infrastructure to use cases and translate HTTP (or JSON-RPC, for `/api/mcp`) concerns.
  - `/api/contact`: `204` on success, `400` for validation errors, `429` when rate-limited, `500` for mailer failures.
  - `/api/mcp`: registers `get_resume`, `list_services`, `check_availability`, `schedule_meeting` as MCP tools via `mcp-handler`; each call is recorded through `RecordAgentConnectionUseCase`. Has its own general rate limiter (30/min) plus a stricter one (3/10min) specifically for `schedule_meeting`.
  - Both routes: rate limiting only applies when an IP header is present — requests without `x-forwarded-for` or `x-real-ip` skip rate limiting entirely.
- **`@/` alias** maps to `src/` (configured in `jsconfig.json`).
- React Compiler is enabled (`reactCompiler: true` in `next.config.mjs`).

## Testing

Tests are co-located with the source files they cover (e.g. `contact-form.test.jsx` lives next to `contact-form.js`).

For manually calling the MCP server (raw JSON-RPC requests, listing tools, booking a slot, checking rate limits and telemetry), see [`docs/testing-mcp.md`](docs/testing-mcp.md) — it also explains what MCP is and how it differs from plain HTTP/REST.

### Vitest configuration (`vitest.config.js`)

A custom esbuild plugin transforms JSX in all `.js`/`.jsx` source files. This is necessary because `@vitejs/plugin-react` skips SSR-mode transforms, which is the mode Vitest always uses — without this, Next.js components written with `.js` extensions (containing JSX) would fail to load.

### jsdom environment

Component tests that render React require the jsdom environment. Add this docblock as the **first line** of any `.jsx` test file that calls `render`:

```js
// @vitest-environment jsdom
```

`environmentMatchGlobs` in the Vitest config does not work reliably for this project (absolute path matching issue), so the per-file docblock is the required approach.

### Mocking constructors in API route tests

Vitest 4 requires `function` or `class` syntax (not arrow functions) for mocks used as constructors. Use `vi.hoisted()` to share the mock reference between the factory and test assertions:

```js
const mockSendEmail = vi.hoisted(() => vi.fn())
const mockIsAllowed = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.sendEmail = mockSendEmail
		}
	},
}))

vi.mock('@/core/infrastructure/rate-limiter/upstash-rate-limiter', () => ({
	UpstashRateLimiter: class {
		constructor() {
			this.isAllowed = mockIsAllowed
		}
	},
}))
```

`mockIsAllowed` must return a promise (`mockResolvedValue`) since `isAllowed` is async.

### Integration tests with `vi.resetModules()`

`upstash-rate-limiter.integration.test.js` uses `vi.resetModules()` in `beforeEach` to force `route.js` to re-execute on each test, creating a fresh `UpstashRateLimiter` instance. The `@upstash/ratelimit` and `@upstash/redis` modules are mocked at the top of the file with an in-memory sliding window implementation, so the real `UpstashRateLimiter` class code is exercised without a live Redis connection.

## Code Style

Prettier is enforced (no semicolons, single quotes, trailing commas ES5, 120-char print width). ESLint uses `eslint-config-next/core-web-vitals`.
