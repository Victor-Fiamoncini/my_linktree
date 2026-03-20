# My Linktree

Personal landing page with social links, experience history, and a contact form.

## Tech Stack

- **Next.js 16** / **React 19** — App Router, React Compiler enabled
- **Tailwind CSS** — neo-brutalism UI style
- **Resend** — transactional email for the contact form
- **Upstash Redis** — sliding window rate limiting on the contact API
- **Vitest** — unit and integration tests

## Architecture

The codebase follows a layered architecture that keeps business logic independent from the Next.js framework.

```
src/
├── app/                     # Next.js App Router — routes, layout, global CSS
│   └── api/contact/         # POST /api/contact — email submission endpoint
├── components/              # React client components
├── core/
│   ├── application/
│   │   └── use-cases/       # Framework-agnostic business logic
│   └── infrastructure/      # Adapters for external services
│       ├── database/        # In-memory profile data store
│       ├── mailer/          # Resend email adapter
│       └── rate-limiter/    # Upstash sliding window rate limiter
```

**Layers:**

- **Use cases** (`core/application/use-cases/`) hold all business rules as plain JS classes. They have no dependency on Next.js and receive collaborators via constructor injection, making them straightforward to unit test with mocks.
- **Infrastructure** (`core/infrastructure/`) wraps external services behind implicit interfaces. `ResendMailer` is injected into `SendContactEmailUseCase`; `UpstashRateLimiter` is used directly in the API route.
- **API route** (`app/api/contact/route.js`) is the composition root — it wires infrastructure to use cases and handles HTTP concerns. Rate limiting runs before validation: requests without a forwarded IP header skip the limiter entirely.

## Getting Started

```bash
cp .env.example .env.local   # fill in the required variables
npm install
npm run dev
```

Required environment variables (see `.env.example`):

| Variable | Description |
|---|---|
| `MAILER_RESEND_API_KEY` | Resend API key |
| `MAILER_SENDER_EMAIL` | From address for contact emails |
| `MAILER_RECIPIENT_EMAIL` | Destination for contact form submissions |
| `STORAGE_KV_REST_API_URL` | Upstash Redis REST URL |
| `STORAGE_KV_REST_API_TOKEN` | Upstash Redis REST token |

## Testing

```bash
npm run test                                      # run all tests
npx vitest src/app/api/contact/route.test.js      # run a single file
```

Tests are co-located with their source files. The contact API has three test layers: unit tests for the route (dependencies mocked), unit tests for `UpstashRateLimiter` (Ratelimit mocked), and integration tests that wire the real `UpstashRateLimiter` class against a fake in-memory Redis backend.

---

Released in 2021.

By [Victor B. Fiamoncini](https://github.com/Victor-Fiamoncini) ☕️
