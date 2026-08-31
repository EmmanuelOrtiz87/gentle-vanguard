# gentle-vanguard — Entry Point for Claude-Compatible Tools

**Loaded by**: OpenCode, Claude Code, Windsurf, Claude | Canonical entry: `AGENTS-fast.md`
(completo: `AGENTS.md`)

## CRITICAL: First Action — Tool Detection

Run BEFORE any action:

```bash
# Tool detection via TypeScript
npx tsx src/detect-tool.ts --json | jq -r '.name'  # opencode|claude-code|cline|cursor|windsurf|unknown
npx tsx src/detect-tool.ts --json | jq -r '.os.platform'  # windows|linux|macos
npx tsx src/detect-tool.ts --json | jq -r '.os.shell'  # powershell|bash|zsh
```

Load config from `config/orchestrator.json#toolProfiles.<name>`.

**Why**: Correct routing + OS detection prevents wasted tokens from wrong-platform commands.

## Startup Sequence

Run `AGENTS-fast.md` — no shortcuts.

## Core Rules (condensed)

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
12. Goal-Driven: For multi-step tasks, state a brief plan: `1. [Step] -> verify: [check]` format.
    Every changed line must trace to the user's request.
13. TypeScript-First: ALL scripts are TS via `npx tsx`. No PowerShell scripts. See
    `rules/TYPESCRIPT-FIRST-POLICY.md`.

## Break Glass — Auto-Override Harmful Config

If 3+ turns w/o completion, loop detected, or output truncated:

```powershell
npx tsx src/resilience/self-diagnosis.ts --profile "<p>" --chat-level "<l>" --turn-count <N>
```

Override to `lleno/chat-balanced`, notify: `[BREAK GLASS] motivo: {reason}`

## Response Profile

Profile: **ultra** | Detail: **simple** | Chat: **chat-compact** (max 4 lines text)

NO preamble/postamble — just do it. No echoing user's question Batch independent tool calls in
parallel. Answer THEN act: 1-3 line answer, then tools Abbreviations: db/auth/config/req/res/fn/impl
Output guard: max 200 tokens per response unless generating code Tool output: pipe large results
through `Select-Object -First 30`, `head -50` Code blocks: only include relevant lines, not entire
files

## Settings

Temperature: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true) Lang: es | Engram project:
workspace_gentle_vanguard

## Key Refs

See `AGENTS-fast.md` for full resource table.
