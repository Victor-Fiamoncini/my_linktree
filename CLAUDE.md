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

- `RESEND_API_KEY` — API key for the Resend email service
- `SENDER_EMAIL` — From address for contact emails
- `RECIPIENT_EMAIL` — Where contact form submissions are sent

## Architecture

This is a Next.js 16 / React 19 personal landing page. The codebase follows a layered architecture separating core business logic from the Next.js framework.

```
src/
  app/                        # Next.js App Router (routes, layout, global CSS)
    api/contact/
      route.js                # POST handler — returns 204 on success
      route.test.js           # API route integration tests
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
      errors.js               # MissingRequiredFieldsError, InternalServerError
      mailer/resend-mailer.js
  e2e-setup.js                # Global test setup (jest-dom matchers + RTL cleanup)
```

### Key design decisions

- **Use cases** (`src/core/application/use-cases/`) contain all business logic and are plain JS classes with no Next.js dependency. They are unit-tested in isolation using Vitest with mocked dependencies.
- **Infrastructure** (`src/core/infrastructure/`) wraps external services. `ResendMailer` implements an implicit mailer interface consumed by `SendContactEmailUseCase` via constructor injection.
- **API route** (`src/app/api/contact/route.js`) wires dependencies and translates HTTP concerns. Returns `204 No Content` on success, `400` for validation errors (`MissingRequiredFieldsError`), and `500` for mailer failures.
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

### Mocking `ResendMailer` in API route tests

Vitest 4 requires `function` or `class` syntax (not arrow functions) for mocks used as constructors. Use `vi.hoisted()` to share the mock reference between the factory and test assertions:

```js
const mockSendEmail = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.sendEmail = mockSendEmail
		}
	},
}))
```

## Code Style

Prettier is enforced (no semicolons, single quotes, trailing commas ES5, 120-char print width). ESLint uses `eslint-config-next/core-web-vitals`.
