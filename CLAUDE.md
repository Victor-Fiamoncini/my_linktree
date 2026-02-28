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
```

Run a single test file:
```bash
npx vitest src/core/application/use-cases/get-xp-years-use-case.test.js
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
  app/                    # Next.js App Router (routes, layout, global CSS)
    api/contact/route.js  # POST handler for the contact form
    layout.js             # Root layout with metadata/SEO
    page.js               # Home page (server component)
  components/             # React client components
  core/
    application/use-cases/  # Business logic (framework-agnostic)
    infrastructure/         # External service adapters (e.g., ResendMailer)
```

### Key design decisions

- **Use cases** (`src/core/application/use-cases/`) contain all business logic and are plain JS classes with no Next.js dependency. They are unit-tested in isolation using Vitest with mocked dependencies.
- **Infrastructure** (`src/core/infrastructure/`) wraps external services. `ResendMailer` implements an implicit mailer interface consumed by `SendContactEmailUseCase` via constructor injection.
- **API route** (`src/app/api/contact/route.js`) wires dependencies and translates HTTP concerns; it instantiates the use case with real infra and maps domain errors to HTTP responses.
- **`@/` alias** maps to `src/` (configured in `jsconfig.json`).
- React Compiler is enabled (`reactCompiler: true` in `next.config.mjs`).

## Code Style

Prettier is enforced (no semicolons, single quotes, trailing commas ES5, 120-char print width). ESLint uses `eslint-config-next/core-web-vitals`. Commits use Commitizen (`npm run commit`).
