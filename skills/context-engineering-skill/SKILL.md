---
name: context-engineering-skill
description:
  'Trigger: context pack, compact start, session handoff, token efficiency, context budget, context
  engineering, reduce context, @/context. Context engineering patterns for token-efficient AI
  sessions: context packing, compact-start, session handoff, and metrics tracking.'
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
---

# Context Engineering

## Activation Contract

Load when: starting a new AI session that continues from a previous one, context window >60% used,
handing off between sessions or agents, measuring token usage, or building session summaries/review
artifacts.

## Hard Rules

- MUST reference files by path instead of repeating file contents already in context
- MUST NOT include full file trees when only 2-3 files changed — use `git diff --stat`
- MUST NOT re-explain prior decisions already made — reference the session artifact
- MUST NOT load all skills and all docs at once when only 1-2 are needed

## Decision Gates

| Context Used | Action                                              |
| ------------ | --------------------------------------------------- |
| < 40%        | Work normally                                       |
| 40-60%       | Consider `context-pack` for next session            |
| > 60%        | Run `compact-start` before next message             |
| > 80%        | Must compact or start new session with context pack |

## Execution Steps

1. **Session Start (resuming work)**: `gv compact-start -Objective "..."` (or
   `.\scripts\utilities\compact-start.ps1 -Objective "..."`) → paste output into new session. Output
   includes git diff, last N commits, branch+status, objective.
2. **Mid-Session Context Pack**: `gentle-vanguard context-pack -Objective "..."` (or
   `.\scripts\utilities\context-pack.ps1 -Objective "..." -MaxChangedFiles 12 -MaxCommits 8`)
3. **Token Metrics**: `.\scripts\utilities\context-metrics-report.ps1` (stored in
   `docs/sessions/metrics/context-usage.csv`)
4. **Session Handoff**: Run `gv end-session` → `context-pack` → save objective + next steps → new
   session starts with `compact-start -Objective "..."`

## Output Contract

- **compact-start**: Structured prompt <8000 chars with git diff, commits, branch, objective
- **context-pack**: Snapshot file <15000 chars tracking event, prompt_chars, changed_count
- **metrics**: `docs/sessions/metrics/context-usage.csv` with `event`, `prompt_chars`,
  `changed_count`

## Activation Policy (compact-start)

| Condition                      | Action                                                  |
| ------------------------------ | ------------------------------------------------------- |
| Context health RED (>60% used) | Run `compact-start` before next message                 |
| Starting new thread/session    | Run `compact-start` OR check `.session/.compact-marker` |
| Health GREEN or YELLOW         | Skip — no handoff needed yet                            |
| `.compact-marker` <60 min old  | Skip — already ran recently                             |

**Objective rules:**

- MUST be ≤100 chars — one sentence, no filler
- MUST describe what to resume, not how
- Examples: ✅ `"fix ci noise in build pipeline"` — ❌
  `"we need to continue working on the issue with the CI pipeline where..."`

## When to Use the Reference Files

Read `references/scripts.md` when you need:

- exact script paths, parameters, defaults, and usage examples

Read `references/decision-gates.md` when you need:

- threshold values for context usage, token budgets per task, objective rules

Read `references/session-handoff-protocol.md` when you need:

- the full handoff sequence and marker-based dedup protocol

## References

- Scripts: `scripts/utilities/compact-start.ps1`, `context-pack.ps1`, `context-metrics-report.ps1`
- Metrics: `scripts/utilities/token-efficiency-estimator.ps1`
- Config: `config/context-efficiency.json`


