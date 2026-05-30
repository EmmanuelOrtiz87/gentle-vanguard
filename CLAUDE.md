# gentle-vanguard — Entry Point

Canonical entry: `docs/AGENTS.md`

## Tool Detection (turn 1)
`pwsh -NoProfile -File scripts\utilities\DETECT\detect-tool.ps1 -AsJson | ConvertFrom-Json`

## Pre-response Hook (every turn)
`pwsh -NoProfile -File scripts\utilities/pre-process-input.ps1 -UserInput "<msg>" -WorkspaceRoot "."`

## Core Rules
1. LOCAL-FIRST: project knowledge before external sources
2. pre-process-input.ps1 BEFORE every response
3. SDD FLOW: new features -> BA/EXPLORE first, no exceptions
4. Delegation Rules -> `rules/DELEGATION-RULES.md` mandatory for multi-step
5. `mem_save` after every significant task
6. CodeGraph -> `codegraph_context` before modifying code
7. `mem_search "lessons learned"` at session start
8. Review Workload Guard (`review-workload-guard.ps1`) before multi-file impl >400 lines
9. Tool output discipline: limit read/grep/bash results to 50 lines
10. JSON validity: verify balanced quotes/braces/brackets before tool calls (see `rules/NORMATIVAS-JSON-CONSTRUCTION.md`)
11. Subagent delegation: send minimal context in `prompt` — only task info, not full history

## Break Glass
If 3+ turns w/o completion, loop detected, or output truncated:
`pwsh -NoProfile -File scripts\utilities\self-diagnosis.ps1 -CurrentProfile "<p>" -ChatLevel "<l>" -TurnCount <N>`
Override to `lleno`/`chat-balanced`. Notify: `[BREAK GLASS] motivo: {reason}`

## Response Profile
Profile: **ultra** | Detail: **simple** | Chat: **chat-compact** (max 4 lines text)
1. NO preamble/postamble — just do it. No echoing user's question
2. Batch independent tool calls in parallel. Answer THEN act: 1-3 line answer, then tools
3. Abbreviations: db/auth/config/req/res/fn/impl
4. Output guard: max 200 tokens per response unless generating code
5. Tool output: pipe large results through `Select-Object -First 30`, `head -50`
6. Code blocks: only include relevant lines, not entire files

## Settings
Temp: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true) | Lang: es | Engram: workspace_gentle_vanguard

## Refs
See `docs/AGENTS.md#Key-References` for full resource table.
