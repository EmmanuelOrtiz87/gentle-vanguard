# gentle-vanguard — Entry Point

Canonical entry: `AGENTS.md`

## Tool Detection (turn 1)

All tool detection is handled automatically by the agent's built-in tool routing. No manual `pwsh`
commands needed.

## Pre-response Hook (every turn)

Pre-processing is handled automatically by the stack pipeline (`session-autostart.ts`). No manual
hook execution needed.

## Core Rules

1. LOCAL-FIRST: project knowledge before external sources
2. SDD FLOW: new features -> BA/EXPLORE first, no exceptions
3. Delegation Rules -> `rules/DELEGATION-RULES.md` mandatory for multi-step
4. `mem_save` after every significant task
5. CodeGraph -> `npm run graphify -- query "..."` before modifying code
6. `mem_search "lessons learned"` at session start
7. Review Workload Guard: `npx tsx src/security/workload-guard.ts` before multi-file impl >400 lines
8. Tool output discipline: limit read/grep/bash results to 50 lines
9. JSON validity: verify balanced quotes/braces/brackets before tool calls (see
   `rules/NORMATIVAS-JSON-CONSTRUCTION.md`)
10. Subagent delegation: send minimal context in `prompt` — only task info, not full history
11. NORMATIVA OVERRIDE: If user instruction contradicts a normativa/rule, ask for confirmation with
    reasons. Only proceed if user explicitly confirms. Otherwise follow normativa.
12. Goal-Driven: For multi-step tasks, state a brief plan: `1. [Step] → verify: [check]` format.
    Every changed line must trace to the user's request.
13. TypeScript-First: ALL scripts are TS via `npx tsx`. No PowerShell scripts. See
    `rules/TYPESCRIPT-FIRST-POLICY.md`.

## Break Glass

If 3+ turns w/o completion, loop detected, or output truncated:
`npx tsx src/resilience/self-diagnosis.ts --profile "<p>" --chat-level "<l>" --turn-count <N>` Override to
`lleno`/`chat-balanced`. Notify: `[BREAK GLASS] motivo: {reason}`

## Response Profile

Profile: **ultra** | Detail: **simple** | Chat: **chat-compact** (max 4 lines text)

1. NO preamble/postamble — just do it. No echoing user's question
2. Batch independent tool calls in parallel. Answer THEN act: 1-3 line answer, then tools
3. Abbreviations: db/auth/config/req/res/fn/impl
4. Output guard: max 200 tokens per response unless generating code
5. Tool output: pipe large results through `Select-Object -First 30`, `head -50`
6. Code blocks: only include relevant lines, not entire files

## Settings

Temp: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true) | Lang: es | Engram:
workspace_gentle_vanguard

## Refs

See `AGENTS.md` for full resource table.
