# Continuous Evaluation (F3.1)

Continuous evaluation pipeline over **real traces** from the stack's own Nexus DB
(`.runtime/gentle-vanguard.db`). Deterministic and fully local — no LLM calls.

## Usage

```bash
npm run eval:continuous          # run + persist + trend vs previous run
npm run eval:gate                # same, but exit 1 if aggregate regresses > 5%
npx tsx src/eval/continuous-eval-cli.ts --gate --threshold 10 --limit 500 --json
npx tsx src/cli/gv.ts eval --gate            # gv subcommand (delegates to the same CLI)
npx tsx src/eval/continuous-eval-cli.ts --db path/to/other.db
npm run eval:continuous:test     # unit tests (in-memory SQLite)
```

Options: `--gate`, `--threshold N` (regression % allowed, default 5), `--limit N` (max recent
sessions, default 200), `--token-budget N` (default 50 000), `--duration-budget-ms N` (default 120
000), `--json`, `--db PATH`.

## Golden dataset

Built from the most recent sessions in Nexus:

- **positive**: sessions with status `completed`/`success`/`succeeded`, or positive feedback
  (`positive`, `thumbs_up`, `upvote`, `like`) on their traces.
- **negative**: sessions with status `failed`/`error`/`aborted`, negative feedback, or any trace
  with status `error`.
- Sessions still `active`/`idle` without any signal are skipped.

Per item: tokens = sum of `token_transactions.input_tokens + output_tokens` for the session
(fallback `sessions.tokens_used`); duration = max trace `duration` (fallback
`updated_at - created_at`).

## Scoring model

All heuristics, deterministic:

| Metric               | Definition                                               | Weight |
| -------------------- | -------------------------------------------------------- | ------ |
| `successRate`        | positives / dataset size                                 | 0.5    |
| `tokenEfficiency`    | `min(1, tokenBudget / avgTokens)` (avg across all items) | 0.3    |
| `durationEfficiency` | `min(1, durationBudgetMs / p95DurationMs)`               | 0.2    |

`aggregateScore = 0.5·successRate + 0.3·tokenEfficiency + 0.2·durationEfficiency` (0..1).

## Trend

Each run is persisted to Nexus table **`eval_runs`**:
`(id INTEGER PK AUTOINCREMENT, created_at TEXT, dataset_size INTEGER, scores_json TEXT, trend_json TEXT)`.

The table is created lazily by `src/eval/continuous-eval.ts` with `CREATE TABLE IF NOT EXISTS` —
canonical Nexus migrations live in
`apps/web-dashboard/server/database/repositories/MigrationRunner.ts` (owned by the dashboard
workstream), so this module keeps its own idempotent DDL.

Trend compares the current `aggregateScore` against the last `eval_runs` row:

- `direction`: `first-run` (no baseline) / `improved` / `stable` (±0.01%) / `regressed`
- `deltaPercent`: relative change in % (positive = improvement).

## Gate

`--gate` (or `npm run eval:gate` / `gv eval --gate`) exits **1** when `deltaPercent < -threshold`
(default threshold 5%). First runs always pass.

## Reading the trend

- Success rate drops → recent sessions are failing (check watchtower/loop-guard).
- `tokenEfficiency < 1` → avg tokens per session exceeds the budget; consider routing/compression
  tuning.
- `durationEfficiency < 1` → p95 session duration exceeds the budget.
- A one-off negative `deltaPercent` after a big batch of error sessions is expected;
- consecutive `regressed` runs are a real signal.

Inspect history:
`sqlite3 .runtime/gentle-vanguard.db "SELECT id, created_at, dataset_size, json_extract(scores_json,'$.aggregateScore') FROM eval_runs ORDER BY id"`
