# RAG study guide: the job-fit matcher

This app answers "does Victor fit this job?" with **retrieval-augmented generation (RAG)**. This
guide explains the idea, then walks through this codebase one step at a time. Every concept points
to the file that implements it.

---

## 1. What RAG is, and why it exists

A language model only knows what was in its training data plus whatever you put in the prompt. It
has never seen your résumé or your GitHub READMEs. You can close that gap in three ways:

| Approach | How | Trade-off |
|---|---|---|
| **Stuff everything in the prompt** | Paste all your content into every request | Simple, but cost and latency grow with the corpus, and it stops working once the corpus outgrows the context window |
| **Fine-tuning** | Retrain the model on your data | Expensive, slow to update, and the model can still mix facts up. It teaches *style* better than *facts* |
| **RAG** | Find the few pieces relevant to *this* question and put only those in the prompt | Cheap per request, updates by re-indexing, and answers can cite their sources |

RAG = **R**etrieve relevant text, **A**ugment the prompt with it, **G**enerate an answer grounded in
it. The model doesn't need to *know* your data. It needs to *read* the right slice of it at the
moment you ask.

> **Honest note for this project:** `profile.yml` alone is ~5 experiences and would fit in one
> prompt. The GitHub READMEs are what make retrieval worth having. The real reason for building it
> here is to learn the pipeline on a corpus small enough to understand end to end.

### The two phases

```
 ┌──────────────── OFFLINE: indexing (rake task, run by hand) ────────────────┐
 │                                                                            │
 │  sources ──▶ clean + chunk ──▶ embed each chunk ──▶ store (text + vector)  │
 │  profile.yml   ChunkText       OpenAI embeddings    knowledge_chunks       │
 │  READMEs       UseCase                              (Postgres + pgvector)  │
 └────────────────────────────────────────────────────────────────────────────┘

 ┌──────────────── ONLINE: per request ───────────────────────────────────────┐
 │                                                                            │
 │  job description ──▶ embed ──▶ nearest 8 chunks ──▶ gpt-6-luna reads   ──▶ │
 │                      OpenAI     cosine distance     them + the job, writes │
 │                      embeddings (HNSW index)        a cited assessment     │
 └────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core concepts

### Embeddings
An **embedding model** turns text into a fixed-length list of numbers (a vector). Here it's OpenAI
`text-embedding-3-small`, asked for 1024 numbers. Texts with similar *meaning* land close together in that
1024-dimensional space, even when they share no words. "Laravel background jobs" and "asynchronous
PHP workers" end up near each other. That is why RAG can find relevant text where keyword search
(`LIKE '%laravel%'`) can't.

Generation and embeddings are two separate models, even when one provider (OpenAI) serves both.
The vectors only have to come from the *same* embedding model at index time and query time, so the
generator can be swapped without re-embedding anything. **Changing the embedding model is
different:** old and new vectors live in unrelated spaces, so the whole corpus has to be
re-embedded. That is what happened when this matcher moved from Voyage to OpenAI.

**Symmetric embeddings, shortened.** OpenAI embeds a job description and a README paragraph the
same way. Some providers (Voyage, Cohere) take an `input_type` of `"query"` or `"document"` and
encode the two slightly differently. `text-embedding-3-small` natively returns 1536 numbers, but
its `dimensions` parameter shortens the vector with little quality loss. The app asks for 1024 to
fit the `vector(1024)` column. See `app/clients/openai_embedder.rb`.

### Similarity: cosine distance
Two vectors are compared by the angle between them. **Cosine similarity** is 1 when they point the
same way and 0 when they're unrelated; **cosine distance** is `1 − similarity`, so smaller means
closer. The query is "give me the 8 chunks with the smallest distance to this job description".

```ruby
# app/use_cases/search_knowledge_use_case.rb
KnowledgeChunk.nearest_neighbors(:embedding, vector, distance: "cosine").first(limit * CANDIDATE_MULTIPLIER)
  .select { |chunk| (counts[chunk.title] += 1) <= per_source }
  .first(limit)
```

`nearest_neighbors` comes from the `neighbor` gem and compiles to pgvector's `<=>` operator:
`ORDER BY embedding <=> '[...]' LIMIT 24`. The app fetches 3× the chunks it needs, then keeps at
most 2 per source. Without that cap, a job ad that leans on Rust filled 7 of 8 slots with Rust
competition repos, leaving no room for evidence on its secondary requirements.

### Vector storage and indexes (pgvector, HNSW)
You don't need a dedicated vector database. **pgvector** adds a `vector(n)` column type and
distance operators to the Postgres this app already runs.

Without an index, Postgres compares the query against *every* row, which is exact but O(n). An
**HNSW** index (Hierarchical Navigable Small World) is a layered graph that finds *approximately*
the nearest neighbours in about O(log n). It trades a little recall for a lot of speed. With a few
hundred chunks this makes no measurable difference, but it's what you'd use at scale, and seeing it
in the migration is instructive:

```ruby
# db/migrate/…_create_knowledge_chunks.rb
t.vector :embedding, limit: 1024, null: false
add_index :knowledge_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
```

The operator class (`vector_cosine_ops`) must match the distance used in queries, or Postgres
ignores the index.

### Chunking
You embed **chunks**, not whole documents, for two reasons:
1. One vector for a 5,000-word README blurs every topic in it together, so it matches everything a
   little and nothing well.
2. You want to put *only the relevant part* in the prompt.

Chunk size is a trade-off. Too small, and a chunk loses the context needed to understand it. Too
big, and it's back to blurry vectors and wasted tokens. `ChunkTextUseCase` uses a common recipe:

- **Split on structure first** (markdown headings), because authors already grouped related ideas.
- **Pack paragraphs** up to ~2,000 characters (≈500 tokens).
- **Overlap by one paragraph**, so an idea that straddles a boundary appears whole in at least one chunk.
- **Prefix every chunk with its title and heading** (`GitHub project my_linktree — Setup`). A
  chunk that just says "run `bin/dev`" means nothing on its own. The prefix is embedded *with* the
  text, so it also helps retrieval.
- **Clean the noise**: badges, HTML tags and comments carry no meaning but still get embedded.
  Code spans and fences are matched first and kept, so `Vec<u8>` isn't stripped as a tag.
- **Respect code fences**: `# comment` inside a bash block isn't a heading.

### Grounding and citations
Retrieval only helps if the model actually *uses* what it retrieved instead of inventing a match.
Two mechanisms work together here:

1. **The system prompt** (`MatchJobUseCase::SYSTEM_PROMPT`) says to base every claim on the
   documents only and never invent experience. It pitches the fit (direct matches, then
   transferable experience) rather than listing gaps, but every claim still has to be backed.
2. **Numbered documents + structured output.** The Responses API has no native citations for
   documents you pass in, so the app builds them itself. Each chunk goes into the prompt as a
   numbered document, and the model must answer with JSON matching `RESPONSE_SCHEMA`. OpenAI
   enforces the schema with `strict: true`, which in turn requires every property to be `required`
   and `additionalProperties: false`. The answer is a list of paragraphs, each with the numbers of
   the documents that back it.

```text
<document number="1" title="my_bar_decoder">
...chunk text...
</document>
```

```json
{ "paragraphs": [ { "text": "Victor has shipped Rails apps...", "sources": [1, 3] } ] }
```

`MatchJobUseCase#present` maps each number back to a chunk, then to a **deduplicated** source list,
so three chunks of the same README become one footnote. The numbers are *model-written*, so any that
is out of range or not an integer is dropped rather than trusted.

**What you lose compared with native citations** (e.g. Claude's `citations: { enabled: true }`):
there, the API itself returns the exact span it quoted, so a citation can't point at a document
that doesn't exist. Here the model *claims* which document supports a paragraph, and nothing proves
the paragraph actually follows from it. The footnote tooltip shows the start of the cited chunk,
not a verified quote. Exercise 9 is about closing that gap. (The web page currently shows only the
prose; MCP clients get the citations and sources.)

---

## 3. What was built, file by file

Read in this order. It follows the data.

| Step | File | What to look at |
|---|---|---|
| Storage | `db/migrate/…_enable_vector.rb`, `…_create_knowledge_chunks.rb` | `enable_extension "vector"`, the `vector(1024)` column, the HNSW index, unique `content_hash` |
| Model | `app/models/knowledge_chunk.rb` | `has_neighbors :embedding` |
| Corpus config | `config/knowledge.yml` | Which GitHub repos to index |
| HTTP clients | `app/clients/openai_embedder.rb`, `app/clients/github_readme_client.rb`, `app/clients/openai_client.rb` | Batching (≤128 texts/request), `dimensions`, errors raised with the HTTP status |
| Chunking | `app/use_cases/chunk_text_use_case.rb` | Heading split → paragraph packing → overlap |
| Indexing | `app/use_cases/ingest_knowledge_use_case.rb` | Building documents from `profile.yml` and READMEs, hashing, incremental re-embedding |
| Running it | `lib/tasks/knowledge.rake` | `bin/rails knowledge:ingest`, run by hand after the sources change (no scheduled job) |
| Retrieval | `app/use_cases/search_knowledge_use_case.rb` | Embed the job description, top-8 by cosine distance |
| Generation | `app/use_cases/match_job_use_case.rb` | Validation, numbered documents, system prompt, JSON schema, block handling, citation mapping |
| Web | `app/controllers/api/job_matches_controller.rb`, `app/views/pages/_job_match.html.erb`, `app/javascript/controllers/job_match_controller.js` | JSON endpoint (summary text only), rate limit, plain-text rendering |
| Agents | `app/mcp_tools/match_job_tool.rb`, `Api::McpController::TOOLS`, `config/agents.yml` | The same use case exposed as MCP tool `match_job` |

### Indexing is incremental and idempotent
Every chunk is keyed by a SHA-256 of its source type, title, url and content, so a renamed repo or
moved URL is replaced even when the text is identical. On each run:

1. Build every chunk the sources produce *now*.
2. Embed only the chunks whose hash isn't in the table yet. Unchanged text costs no API call.
3. Delete rows whose hash nothing produces any more (an edited or removed README).

Running it twice in a row embeds nothing the second time. That property is what makes
re-running it whenever something changes safe and cheap.

**The failure-mode detail:** a README that returns **404** is treated as "gone" and its chunks are
deleted. Any **other** GitHub error *raises* and aborts the run. If errors were treated like 404s,
a brief GitHub outage would wipe half the corpus. `spec/clients/github_readme_client_spec.rb` pins
this behaviour.

### The generation call
```ruby
@client.respond(
  body: {
    model: "gpt-6-luna",
    instructions: SYSTEM_PROMPT,
    input: user_prompt(chunks, job_description),
    reasoning: { effort: "low" },               # a little thinking helps pick the right sources
    max_output_tokens: 8192,                    # includes the reasoning tokens
    text: { format: { type: "json_schema", name: "job_match", strict: true, schema: RESPONSE_SCHEMA } }
  }
)
```
- `OpenaiClient` is a small `Net::HTTP` wrapper around `POST /v1/responses`, the same style as
  `OpenaiEmbedder`. It has a 5 s connect and 60 s read timeout, because a Puma thread is waiting on it.
- Documents come **before** the question: models do better when the reference material comes first.
- The job description is wrapped in `<job_description>` tags. That separates *untrusted input*
  from instructions and makes a pasted "ignore previous instructions" less effective. The model
  also has no tools, so the worst a prompt injection can do is produce odd text.
- **Declined answers**: if the message contains a `refusal` part, or the response is `incomplete`
  because of the content filter, the use case raises `ArgumentError`, which the controller turns
  into a polite 422. Any other non-`completed` status (e.g. `incomplete` from the token cap, or
  `failed`) raises `OpenaiClient::Error`: that's a provider problem, reported as `job_match.error`.
- **Reasoning items**: `output` holds a `reasoning` item before the `message`. Only the message's
  `output_text` parts are parsed as JSON.
- **Cost**: every call is billed, about $0.0005 at gpt-6-luna's prices for ~3k tokens in and ~400
  out. The global 100/day cap, shared by the web form and MCP, bounds the worst case.

### Safety and cost guardrails
| Concern | Guardrail |
|---|---|
| Abuse / cost | Web: 3 per 10 min **and** 10 per day per IP. MCP: 5 `match_job` calls per 10 min **and** 10 per day per IP, on top of the general 30/min. Then one **global 100 per day** shared by both surfaces (`rate_limit ... scope: :job_match`), which bounds the daily OpenAI spend. Input that fails validation skips the global counter |
| Huge inputs | Job descriptions are capped at 6,000 characters, which keeps even CJK text under the embedding model's 8,191-token limit (validated server-side; `maxlength` in the form is only a convenience) |
| XSS from model output | The Stimulus controller writes the answer with `textContent`, never `innerHTML` (a system spec checks this) |
| PII in logs | Events log sizes, token counts and latency, never the job description |
| Log redaction gotcha | `filter_parameters` redacts any key containing `token`, so the events use `llm_input`/`llm_output` |

---

## 4. How it's tested without calling any API

- **Clients** (`spec/clients/`): WebMock stubs OpenAI and GitHub at the HTTP level to check
  headers, bodies, batching and error handling.
- **Use cases**: constructor injection (`embedder:`, `client:`, `search:`) lets the specs pass
  `instance_double`s instead of live clients.
- **Vector search** (`spec/use_cases/search_knowledge_use_case_spec.rb`, `spec/models/knowledge_chunk_spec.rb`):
  runs *real* pgvector queries with hand-made **unit vectors** (`unit_vector(0)` is `[1, 0, 0, …]`),
  so the expected ordering can be worked out by hand.
- **Controller, MCP tool and browser**: stub `MatchJobUseCase.new` and check the JSON shape,
  events, rate limits, locale and the rendered text.

What these specs **don't** measure is *answer quality*. That needs an eval (see §6).

---

## 5. Try it

```bash
docker compose up -d                       # Postgres with pgvector
bin/rails credentials:edit --environment development
#   rag:
#     openai_api_key: sk-...              # from platform.openai.com
#     github_token: ghp_...                # optional
bin/rails db:migrate
bin/rails knowledge:ingest                 # "N chunks: N embedded, 0 removed"
bin/rails knowledge:ingest                 # again: "N chunks: 0 embedded, 0 removed"
```

Look at retrieval on its own, which is where most RAG bugs live:

```ruby
# bin/rails console
SearchKnowledgeUseCase.new.execute(query: "Rust high-performance HTTP API", limit: 5).map(&:title)
KnowledgeChunk.group(:source_type).count
```

Then run `bin/dev` and paste a real job description into the "Do I fit your role?" section.

---

## 6. Exercises and next steps

Roughly in order of learning value:

1. **Inspect distances.** In the console,
   `KnowledgeChunk.nearest_neighbors(:embedding, v, distance: "cosine").first(8).map { [_1.title, _1.neighbor_distance.round(3)] }`.
   See how quickly relevance drops off. Try adding a distance cutoff so weak matches never reach the prompt.
2. **Change the chunk size** (`ChunkTextUseCase.new(max_chars: 800)` vs `4000`), re-ingest, and
   compare what retrieval returns for the same query.
3. **Build a tiny eval.** Collect ~10 real job descriptions and write down which sources a good
   answer *should* cite. Score retrieval with recall@8 ("did the right chunks come back?")
   separately from generation ("was the answer faithful and honest?"). You can't improve what you
   don't measure.
4. **Hybrid search.** Combine vector similarity with Postgres full-text search (`tsvector`) using
   reciprocal rank fusion. Embeddings miss exact tokens like "PHP 8.3" or "FrankenPHP"; keyword
   search catches them.
5. **Reranking.** Retrieve 30 chunks cheaply, then have a reranker (e.g. Cohere Rerank or Voyage `rerank-2.5`)
   pick the best 8. This is often the single biggest quality jump in a RAG pipeline.
6. **Query rewriting.** Job descriptions are long and full of boilerplate ("we offer great
   benefits"). Have a cheap model extract the required skills first, then embed *those*.
7. **Grow the corpus.** Blog posts (`my_blog`), case studies, or the pt-BR descriptions, with a
   `locale` column and a filter.
8. **Count only real API calls.** The shared 100/day cap skips input `MatchJobUseCase.acceptable?`
   rejects, but still counts refusals and provider errors, which may or may not have been billed.
   Moving the budget into `MatchJobUseCase`, after the call, would count exactly what OpenAI
   bills, at the cost of more code than a declarative macro.
9. **Verify the citations.** Add a `quote` field to each paragraph in `RESPONSE_SCHEMA` and keep a
   citation only when that quote really appears in the cited chunk (after normalising whitespace).
   That turns "the model says document 3 supports this" into something the app has checked,
   close to what a native citations API gives you.

---

## 7. Glossary

- **Chunk**: a passage of a source document, sized for retrieval.
- **Embedding**: a vector representing a text's meaning.
- **Vector search / kNN**: finding the *k* stored vectors nearest to a query vector.
- **ANN / HNSW**: *approximate* nearest-neighbour search with a graph index; fast, with slightly imperfect recall.
- **Grounding**: making the model answer from the provided sources rather than its own memory.
- **Hallucination**: a fluent claim not supported by any source. Grounding and citations exist to reduce it.
- **Recall@k**: the share of the relevant chunks that appear in the top *k* results.
- **Reranker**: a slower, more accurate model that re-orders a retrieved candidate list.
- **Hybrid search**: vector and keyword search combined.
- **Structured output**: constraining a model to reply with JSON that matches a schema, so the app parses data instead of prose.
