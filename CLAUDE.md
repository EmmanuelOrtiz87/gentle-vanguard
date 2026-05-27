# gentle-vanguard — Entry Point for Claude-Compatible Tools

**Loaded by**: OpenCode, Claude Code, Windsurf, Claude | Canonical entry: `docs/AGENTS.md`

## CRITICAL: First Action — Tool Detection

Run BEFORE any action:

```powershell
$detected = pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson | ConvertFrom-Json
$detected.name  # opencode|claude-code|cline|cursor|windsurf|unknown
$detected.os.platform  # windows|linux|macos
$detected.os.shell     # powershell|bash|zsh
```

Load config from `config/orchestrator.json#toolProfiles.<name>`.

**Why**: Correct routing + OS detection prevents wasted tokens from wrong-platform commands.

## Startup Sequence

Run `docs/AGENTS.md#Mandatory-Startup-Sequence` — no shortcuts.

## Core Rules (condensed)

1. **LOCAL-FIRST**: project knowledge before external sources
2. **pre-process-input.ps1** BEFORE every response (`-UserInput`, `-PrevInputTokens`, `-PrevOutputTokens`, `-PrevContextChars`, `-Model`). Track token usage from previous turn: estimate input as `[Math]::Floor(contextChars/4)`, output as actual response length/4. On first turn omit prev params.
3. **SDD FLOW RULE**: new features -> BA/EXPLORE first, no exceptions
4. **Delegation Rules** -> `rules/DELEGATION-RULES.md` mandatory for multi-step
5. **AUTONOMOUS LEARNING** -> `mem_save` after every significant task
6. **TOKEN NOTIFICATION** -> Automatico via `pre-process-input.ps1` hook. Se ejecuta CADA turno sin intervención. User puede `/notif off` para silenciar. Toggles individuales: `/notif token on/off`, `/notif context on/off`, `/notif cost on/off`, `/notif accumulated on/off`, `/notif compact on/off`. Estado persiste entre sesiones.
7. **CodeGraph** -> `codegraph_context` before modifying code
8. **mem_search "lessons learned"** at session start
9. **Review Workload Guard** -> `review-workload-guard.ps1` before multi-file impl
10. **Tool output discipline** -> limit read/grep/bash results; use `-First 30`, `Select-Object`,
    `head -50` on large output
11. **JSON VALIDITY** -> Verify quotes/braces/brackets balanced BEFORE any tool call with JSON params.
    See `rules/NORMATIVAS-JSON-CONSTRUCTION.md`

## Break Glass — Auto-Override Harmful Config

If user reports incompleteness, task spans 3+ turns, loop detected, or output truncated:

```powershell
pwsh -NoProfile -File scripts/utilities/self-diagnosis.ps1 -CurrentProfile "<p>" -CurrentChatLevel "<l>" -TurnCount <N>
```

Override to `lleno`/`chat-balanced`, notify: `[BREAK GLASS] motivo: {reason}`

## Response Profile

Profile: **ultra** | Detail: **simple** | Chat: **chat-compact** (max 4 lines text)

1. NO preamble/postamble — just do it
2. No echoing user's question
3. Batch independent tool calls in parallel
4. Answer THEN act: 1-3 line answer, then tools
5. Use abbreviations (db/auth/config/req/res/fn/impl)
6. **Output guard**: max 200 tokens per response unless generating code
7. **Tool output**: pipe large results through `Select-Object -First 30`, `head -50`
8. **Code blocks**: only include relevant lines, not entire files
9. **Subagent delegation**: send minimal context in `prompt` — only task info, not full history

## Settings

Temperature: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true) Lang: es | Engram project:
workspace_gentle_vanguard

## Key Refs

See `docs/AGENTS.md#Key-References` for full resource table.
