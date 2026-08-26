# Testing the MCP Server

This project exposes an MCP (Model Context Protocol) server at `/api/mcp` with four tools:
`get_resume`, `list_services`, `check_availability`, and `schedule_meeting`. This doc covers
what MCP is, the automated test suite, and how to exercise the live endpoint by hand.

## 0. What is MCP?

[MCP](https://modelcontextprotocol.io) is an open protocol, originally published by Anthropic,
that standardizes how an AI agent (or any LLM-driven client — Claude, an IDE assistant, a custom
agent) discovers and calls "tools" exposed by a server. Instead of every integration inventing its
own API shape, an MCP server describes its capabilities in a format a model can read and act on
directly, at runtime, without a human writing glue code for that specific API first.

Under the hood it's [JSON-RPC 2.0](https://www.jsonrpc.org/specification): every request is
`{ jsonrpc: "2.0", id, method, params }`, every response is `{ jsonrpc: "2.0", id, result | error }`.
This project uses the **Streamable HTTP** transport — plain HTTP POST requests, with the server
replying as a single Server-Sent Event (hence the `Accept: application/json, text/event-stream`
header you'll see in every example below).

### MCP vs. plain HTTP/REST

|                             | REST / plain HTTP                                               | MCP                                                                                                                                                    |
| --------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Endpoint shape              | One URL + verb per resource (`GET /services`, `POST /bookings`) | One URL, one verb (`POST /api/mcp`); the _method_ lives inside the body (`tools/call`, `tools/list`)                                                   |
| How a client learns the API | Out-of-band docs, an OpenAPI spec, or reading source            | In-band: call `tools/list` and get back names, descriptions, and JSON Schemas for every tool, live from the running server                             |
| Who's the client            | Humans and hand-written app code, using a fixed contract        | Primarily LLMs — tool descriptions are written to be read and reasoned about by a model deciding _whether_ and _how_ to call something                 |
| Session setup               | None — a `GET` is just a `GET`                                  | Handshake first: `initialize` negotiates protocol version + capabilities before any tool call                                                          |
| Response shape              | Whatever the endpoint returns (JSON, HTML, etc.)                | Always a JSON-RPC envelope; tool results are wrapped in `{ content: [...] }` so text, images, etc. can be mixed                                        |
| Errors                      | HTTP status codes (`404`, `422`, `500`)                         | Usually HTTP `200` with `isError: true` inside the JSON-RPC result — the _transport_ succeeded even if the _tool_ failed (see §3's validation example) |

In this repo, `/api/mcp` (`src/app/api/mcp/route.js`) and `/api/telemetry` (a plain REST-style
`GET` returning JSON) sit side by side as a concrete example of the difference: `/api/telemetry`
is a normal endpoint you'd curl or `fetch()` from code that already knows its shape; `/api/mcp` is
built to be pointed at from an agent's config (see `HireFromAgent`'s AGENTS.md snippet on the
homepage) which then discovers `get_resume`, `list_services`, etc. on its own.

## 1. Automated tests

```bash
npm run test                                # everything
npx vitest src/app/api/mcp/route.test.js    # just the MCP route
```

These mock every collaborator (mailer, booking store, connection log, rate limiter), so they
never hit Redis, Resend, or the network. Good for verifying logic changes; not a substitute for
poking the real endpoint below.

## 2. Local setup

```bash
cp .env.example .env.local   # if you haven't already
docker compose up -d         # local Redis, backs the rate limiter + booking store
npm run dev
```

Set this in `.env.local` before doing any manual testing:

```
MAILER_DRIVER="console"
```

`schedule_meeting` sends real confirmation emails via Resend. With `MAILER_DRIVER=console`,
`createMailer()` (`src/core/infrastructure/mailer/create-mailer.js`) swaps in a `ConsoleMailer`
that logs the email to your terminal instead of sending it. **Without this, every booking test
sends two real emails.** Watch the `npm run dev` terminal output to see the logged emails.

Stop everything when you're done:

```bash
docker compose down
```

## 3. Talking MCP over curl

MCP runs JSON-RPC 2.0 over HTTP. Every request needs both `Content-Type: application/json` and
`Accept: application/json, text/event-stream` — the server replies as a Server-Sent Event even
for a single response. `npm run dev` prints the port (3000, or the next free one).

### Handshake

Not strictly required for manual testing (the tool calls below work without it), but this is
what a real client sends first:

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-06-18",
      "capabilities": {},
      "clientInfo": { "name": "curl-test", "version": "1.0" }
    }
  }'
```

### List available tools

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
```

Returns each tool's name, description, and input schema.

### Get the resume

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_resume","arguments":{}}}'
```

### List services

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"list_services","arguments":{}}}'
```

### Check availability

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"check_availability","arguments":{}}}'
```

Returns `{ timezone, slots: [...] }` — an array of open slot start times (ISO 8601, UTC). Copy one
of these `slots` values for the next step; booked/past slots won't be in the list.

### Book a meeting

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{
    "jsonrpc": "2.0",
    "id": 6,
    "method": "tools/call",
    "params": {
      "name": "schedule_meeting",
      "arguments": {
        "name": "Test Agent",
        "email": "test@example.com",
        "company": "Acme",
        "slotStart": "PASTE_A_SLOT_FROM_check_availability_HERE"
      }
    }
  }'
```

`company` is optional; `name`, `email`, and `slotStart` are required. `slotStart` must be one of
the values `check_availability` returned — anything else fails with a `SlotUnavailableError`.
After a successful booking, run `check_availability` again to confirm that slot is gone.

### Trigger a validation error

```bash
curl -s -X POST http://localhost:3000/api/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"schedule_meeting","arguments":{"name":"No Email","slotStart":"2026-08-26T12:30:00.000Z"}}}'
```

Missing/invalid arguments come back as `{"result":{"content":[...],"isError":true}, ...}` rather
than an HTTP error — the JSON-RPC call still "succeeds" at the transport level.

## 4. Testing rate limits

Two limiters guard the endpoint, keyed by `x-forwarded-for` / `x-real-ip` (requests with neither
header skip rate limiting entirely):

- **General**: 30 requests/minute for any MCP call
- **Schedule**: 3 requests/10 minutes, specifically for `schedule_meeting`

Simulate a client IP and hammer the general limiter:

```bash
for i in $(seq 1 32); do
  curl -s -o /dev/null -w "%{http_code} " -X POST http://localhost:3000/api/mcp \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    -H 'x-forwarded-for: 9.9.9.9' \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
done
```

You should see `200` for the first 30 and `429` after that.

## 5. Using a real MCP client instead of curl

curl works for smoke-testing but a real client is nicer for exploring interactively:

```bash
npx @modelcontextprotocol/inspector
```

Open the printed URL, set the server URL to `http://localhost:3000/api/mcp` (transport: HTTP),
connect, and call tools from the UI.

## 6. Verifying telemetry

Every tool call records `{ tool, timestamp }` to the connection log. Check it directly:

```bash
curl -s http://localhost:3000/api/telemetry
```

Or watch it live in the browser at `http://localhost:3000/telemetry` — `TelemetryFeed` polls
`/api/telemetry` every 5 seconds.
