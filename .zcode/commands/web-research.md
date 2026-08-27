---
name: web-research
description: Search the web, grade results by relevance (BM25/CRAG), persist best subset
argument-hint: <research question>
---

Research "$ARGUMENTS" with the stack's web pipeline:

1. Quick: `npm run web:select -- --query "$ARGUMENTS" --limit 5` (snippet grading).
2. Deep: add `--deep` to scrape top candidates and re-grade full markdown (cap 20K chars).
3. For trend context, optionally
   `npx tsx src/research/research-trends-cli.ts themes --query "$ARGUMENTS"`.

Report the graded results (scores, verdict), where they were persisted
(`.session/web-research/<slug>.json`), and a synthesized answer.
