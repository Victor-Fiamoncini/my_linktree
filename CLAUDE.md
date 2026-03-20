# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev              # Start development server
npm run build            # Build for production
npm run start            # Run production build
npm run test             # Run all tests (Vitest)
npm run lint             # Run ESLint
npm run lint:prettier:check   # Check formatting
npm run lint:prettier:fix     # Auto-fix formatting
npm run commit           # Commitizen interactive commit
```

Run a single test file:

```bash
npx vitest src/components/contact-form.test.jsx
```

Node version: 22.21.1 (see `.nvmrc`).

## Environment Variables

Copy `.env.example` to `.env.local` for local development. Required vars:

- `MAILER_RESEND_API_KEY` — API key for the Resend email service
- `MAILER_SENDER_EMAIL` — From address for contact emails
- `MAILER_RECIPIENT_EMAIL` — Where contact form submissions are sent
- `STORAGE_KV_REST_API_URL` — Upstash Redis REST URL (rate limiting)
- `STORAGE_KV_REST_API_TOKEN` — Upstash Redis REST token (rate limiting)

## Architecture

This is a Next.js 16 / React 19 personal landing page. The codebase follows a layered architecture separating core business logic from the Next.js framework.

```
src/
  app/                        # Next.js App Router (routes, layout, global CSS)
    api/contact/
      route.js                # POST handler — returns 204 on success
      route.test.js           # API route unit tests (mailer + rate limiter mocked)
    layout.js                 # Root layout with metadata/SEO
    page.js                   # Home page (server component)
  components/                 # React client components (co-located with tests)
    contact-form.js
    contact-form.test.jsx
    external-link.js
    external-link.test.jsx
  core/
    application/use-cases/    # Business logic (framework-agnostic, co-located with tests)
    infrastructure/           # External service adapters and error classes
      errors.js               # MissingRequiredFieldsError, InternalServerError, TooManyRequestsError
      mailer/resend-mailer.js
      rate-limiter/
        upstash-rate-limiter.js               # Sliding window via @upstash/ratelimit
        upstash-rate-limiter.test.js          # Unit tests (Ratelimit mocked)
        upstash-rate-limiter.integration.test.js  # Integration tests (fake in-memory Ratelimit)
        in-memory-rate-limiter.js             # Kept for local/test use
  e2e-setup.js                # Global test setup (jest-dom matchers + RTL cleanup)
```

### Key design decisions

- **Use cases** (`src/core/application/use-cases/`) contain all business logic and are plain JS classes with no Next.js dependency. They are unit-tested in isolation using Vitest with mocked dependencies.
- **Infrastructure** (`src/core/infrastructure/`) wraps external services. `ResendMailer` implements an implicit mailer interface consumed by `SendContactEmailUseCase` via constructor injection. `UpstashRateLimiter` wraps `@upstash/ratelimit` with a sliding window algorithm backed by Upstash Redis.
- **API route** (`src/app/api/contact/route.js`) wires dependencies and translates HTTP concerns. Returns `204 No Content` on success, `400` for validation errors, `429` when the rate limiter blocks the request (only when an IP header is present — requests without `x-forwarded-for` or `x-real-ip` skip rate limiting), and `500` for mailer failures.
- **`@/` alias** maps to `src/` (configured in `jsconfig.json`).
- React Compiler is enabled (`reactCompiler: true` in `next.config.mjs`).

## Testing

Tests are co-located with the source files they cover (e.g. `contact-form.test.jsx` lives next to `contact-form.js`).

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
