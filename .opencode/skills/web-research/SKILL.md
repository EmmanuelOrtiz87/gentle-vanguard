---
name: web-research
description:
  Unified web research skill — Firecrawl crawling/scraping, Last30Days trend aggregation across
  GitHub/HN/SO/Dev.to/Reddit, and document research (PDF/DOCX). Use for web research, crawling,
  scraping, trend discovery, GitHub trending, and finding documentation.
triggers:
  - web research
  - crawl
  - scrape
  - trends
  - github trending
  - find documentation
  - firecrawl
  - search the web
---

# Web Research Skill — Gentle-Vanguard

## Overview

One skill for every external-information need. Three complementary engines work together:

| Engine         | Purpose                                  | Output                                 |
| -------------- | ---------------------------------------- | -------------------------------------- |
| **Firecrawl**  | Scrape/crawl/search/map any live website | Clean LLM-ready markdown + JSON        |
| **Last30Days** | Aggregate trends from 5 dev sources      | Themed trend report (hottest/emerging) |
| **Document**   | Extract text/tables from PDF, DOCX, TXT  | Structured document content            |

Firecrawl turns any URL into token-efficient markdown. Last30Days tells you what the ecosystem is
excited about. Document processing turns offline files (specs, whitepapers, contracts) into usable
context.

## When to Use

| Task                               | Tool to use                                  |
| ---------------------------------- | -------------------------------------------- |
| Answer a question from the web     | `web:search` — search with full page content |
| Read a single article/docs page    | `web:scrape` — one URL → clean markdown      |
| Build a knowledge base from a site | `web:crawl` — async crawl of an entire site  |
| Discover a site's URL structure    | `web:map` — cheap sitemap replacement        |
| "What's trending?" for a topic     | `trends:fetch` + `trends:themes`             |
| Read a PDF/DOCX offline            | document-processor skill (`npm run doc:...`) |

## Prerequisites

- **Firecrawl**: API key from <https://firecrawl.dev> set as `FIRECRAWL_API_KEY` env var or in
  `config/web-crawler.json` (`apiKey` field).
- **Trends**: no key required for GitHub (optional `GITHUB_TOKEN` raises rate limits), HN, SO,
  Dev.to, Reddit.
- **Documents**: `pdf-parse` and `docx-parser` dependencies (installed).

## CLI Commands

| Task                        | Command                                                              |
| --------------------------- | -------------------------------------------------------------------- |
| Search + full pages         | `npm run web:search -- --query "topic" --limit 5`                    |
| Scrape one URL              | `npm run web:scrape -- --url https://example.com --formats markdown` |
| Crawl a whole site          | `npm run web:crawl -- --url https://docs.example.com --limit 10`     |
| Discover URLs               | `npm run web:map -- --url https://example.com`                       |
| Firecrawl health check      | `npm run web:status`                                                 |
| Fetch live trends           | `npm run trends:fetch -- --timeframe 7d --sources github,hackernews` |
| Search trends by theme      | `npm run trends:themes -- --query "typescript OR rust"`              |
| Render trend report         | `npm run trends:report -- --output markdown [--json]`                |
| Browse trends interactively | `npm run trends:browse`                                              |
| Trends cache status         | `npm run trends:status`                                              |
| Process a PDF/DOCX document | Load the `document-processor` skill (PDF, DOCX, TXT extraction)      |

Direct invocations are equivalent:

```bash
npx tsx src/web/web-crawler-cli.ts search --query "firecrawl api" --limit 5
npx tsx src/research-trends-cli.ts fetch --timeframe 7d --sources github,hackernews
npx tsx src/research-trends-cli.ts themes --query "typescript OR rust"
```

## Workflow — Firecrawl

### 1. Search the web with full page content

```bash
npm run web:search -- --query "retrieval augmented generation best practices" --limit 5
```

Returns top results each with title, URL, description and the full page markdown (already
compressed). Use the markdown directly as context — it is clean, token-efficient and ready to
inject.

### 2. Scrape a single URL to LLM-ready markdown

```bash
npm run web:scrape -- --url https://example.com/blog/post --formats markdown
```

Options:

- `--formats markdown,html,json,screenshot` — output formats
- `--include-tags h1,p,article` / `--exclude-tags nav,footer,script` — tag filtering
- `--action '{"type":"wait","milliseconds":2000}'` — browser action before extraction for JS-heavy
  pages

### 3. Crawl an entire website

```bash
npm run web:crawl -- --url https://docs.example.com --limit 10
```

Firecrawl runs the crawl as an async job; the client polls until completion and returns every page
as compressed markdown. Use for documentation sites, knowledge bases and changelogs.

### 4. Map a website to discover URLs

```bash
npm run web:map -- --url https://example.com
```

Returns the full URL list instantly — use before a crawl to decide `includePaths` / `excludePaths`.

## Workflow — Last30Days Trends

### 1. Fetch live trends across sources

```bash
npm run trends:fetch -- --timeframe 7d --sources github,hackernews,stackoverflow,devto,reddit
```

Aggregates repositories (by stars), HN stories (by points), Stack Overflow questions (by score),
Dev.to articles, and Reddit posts from `programming`, `javascript`, `typescript` subreddits into a
unified themed report. Cached 24h by default; use `--force` to bypass.

### 2. Search trends by theme

```bash
npm run trends:themes -- --query "typescript OR rust"
```

Filters the cached report by tag/theme keywords — fast, no network.

### 3. Render a report

```bash
npm run trends:report -- --output markdown --json
```

Writes `.session/trends/report-<timeframe>.md` and `.json`.

## Integration Points

| Skill / System         | Link / role                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| `document-processor`   | Load for PDF/DOCX/TXT extraction — complements scraped web content |
| `knowledge-base`       | Store research findings for future retrieval                       |
| `data-analyst`         | Analyze/summarize crawled datasets and trend reports               |
| Nexus DB               | Every operation logs `web-crawler.usage` events to `events` table  |
| Watchtower             | `web-crawler` component checks config/API key/cache on each cycle  |
| Structural compression | Large pages run through `compressStructural` (lossless input mode) |

## Examples

### Example 1 — Research a competitor's docs site

```bash
npm run web:crawl -- --url https://competitor.example.com/docs --limit 50
npm run trends:themes -- --query "ai agents"
```

Crawl their documentation, then cross-reference what the ecosystem is moving toward.

### Example 2 — Decide what to build next (trend-driven)

```bash
npm run trends:fetch -- --timeframe 30d
npm run trends:report -- --output markdown
```

The report surfaces hottest + emerging themes with engagement metrics, guiding roadmap decisions.

### Example 3 — Build an answer from docs + a PDF spec

```bash
npm run web:scrape -- --url https://docs.example.com/api --formats markdown
# then load the document-processor skill for the offline PDF spec
```

Combine live API docs with an offline contract/spec for a complete answer.

## Cost Considerations

- **Firecrawl** is a paid API (per-request credits). Search/scrape/crawl/map all consume credits.
  Mitigations:
  - Default to `--formats markdown` — the smallest LLM-ready format.
  - Prefer `map` + targeted `scrape` over a full `crawl` for large sites.
  - Results are cached (SHA256-keyed JSON, default TTL 24h) in `.session/response-cache/firecrawl/`
    — repeat calls are instant and free.
  - Screenshot/raw-HTML formats cost more — use only for visual/structured tasks.
- **Last30Days** hits public APIs (GitHub 10 req/min unauthenticated, 60 with token; Stack Exchange
  300 req/day; HN Algolia generous; Reddit rate-limited). Cached 24h; configurable `maxRetries` /
  `retryDelayMs` in `config/research-trends.json`.
- **Token efficiency**: every compressed scrape includes `originalTokens` / `compressedTokens` /
  `tokenSavings` so you can see exactly how many tokens were saved.

## Resources

- `src/web/web-crawler.ts` — core Firecrawl API client (`WebCrawlerClient` class)
- `src/web/web-crawler-cli.ts` — Firecrawl CLI wrapper
- `src/research-trends.ts` — Last30Days aggregation engine
- `src/research-trends-cli.ts` — trends CLI wrapper
- `config/web-crawler.json` — Firecrawl configuration
- `config/research-trends.json` — trends configuration (sources, caches, rate limits)
- `tests/unit/web-crawler.test.ts`, `tests/unit/research-trends.test.ts` — unit tests
