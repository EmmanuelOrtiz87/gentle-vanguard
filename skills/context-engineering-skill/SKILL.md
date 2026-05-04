---
name: context-engineering-skill
description: >
  Context engineering patterns for token-efficient AI sessions: context packing,
  compact-start, session handoff, and metrics tracking.
  Trigger: "context pack", "compact start", "session handoff", "token efficiency",
  "context budget", "context engineering", "reduce context", "@/context".
license: Apache-2.0
metadata:
  author: workspace-foundation
  versión: "1.0"
---

## When to Use

- Starting a new AI session that continues from a previous one
- Context window is approaching limits (>60% used)
- Handing off work between sessions or agents
- Measuring token usage and efficiency gains
- Building session summaries or review artifacts

## Core Tools Available

| Script | Purpose | When to Use |
|---|---|---|
| `scripts/utilities/compact-start.ps1` | Generate a compact context prompt from recent git state | At session start when resuming work |
| `scripts/utilities/context-pack.ps1` | Pack current state: changed files + recent commits | Before handing off or compacting |
| `scripts/utilities/context-metrics-report.ps1` | Report token usage metrics | End of session or weekly review |
| `scripts/utilities/token-efficiency-estimator.ps1` | Estimate ROI of context optimization | Planning and governance reviews |
| `scripts/utilities/token-efficiency-estimator.ps1` | Workspace-level token efficiency | Cross-project analysis |

## Critical Patterns

### Session Start (resuming work)
```powershell
# Generate compact context for a new session
wf compact-start -Objective "implement X feature"
# OR direct:
.\scripts\utilities\compact-start.ps1 -Objective "implement X feature"
```
The output is a structured prompt that summarizes:
- Recent git diff (changed files)
- Last N commits
- Current branch + status
- Stated objective

Paste this prompt at the start of a new AI session to restore context without re-explaining everything.

### Mid-session Context Pack
```powershell
# Pack current work state to a file for handoff
wf context-pack -Objective "what I was doing"
.\scripts\utilities\context-pack.ps1 -Objective "implementing auth" -MaxChangedFiles 12 -MaxCommits 8
```
Use when:
- The AI context window is getting large (>60K tokens)
- You need to start a `/compact` or new session
- You want a snapshot of current work state

### Token Metrics
```powershell
# Report context usage stats
.\scripts\utilities\context-metrics-report.ps1
# Metrics are stored in docs/sessions/metrics/context-usage.csv
```

## Context Budget Guidelines

| Context Size | Action |
|---|---|
| < 40% used | Work normally |
| 4060% used | Consider `context-pack` for next session |
| > 60% used | Run `compact-start` before next message |
| > 80% used | Must compact or start new session with context pack |

## Session Handoff Checklist

Before ending a session or triggering `/compact`:
1. Run `wf end-session` to generate the closure summary
2. Run `context-pack` to snapshot current state
3. Save the objective + next steps in session summary
4. New session starts with `compact-start -Objective "..."`

## What NOT to Do

- Do NOT repeat large file contents when they're already in context  reference them by path
- Do NOT include full file trees when only 23 files changed  use `git diff --stat`
- Do NOT re-explain prior decisións already made  reference the session artifact
- Avoid loading all skills and all docs at once when only 12 are needed

## Metrics Interpretation

The `context-usage.csv` tracks:
- `event`: `compact-start` or `context-pack`
- `prompt_chars`: size of generated context prompt
- `changed_count`: number of changed files included

Target: `prompt_chars` < 8000 for compact-start, < 15000 for context-pack.


