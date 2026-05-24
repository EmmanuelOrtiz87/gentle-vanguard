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
2. **pre-process-input.ps1** BEFORE every response (`-UserInput` param, not `-Prompt`)
3. **SDD FLOW RULE**: new features -> BA/EXPLORE first, no exceptions
4. **Delegation Rules** -> `rules/DELEGATION-RULES.md` mandatory for multi-step
5. **AUTONOMOUS LEARNING** -> `mem_save` after every significant task
6. **TOKEN NOTIFICATION** -> `token-usage-auto.ps1` every 5 turns (per `token-display-config.json`)
7. **CodeGraph** -> `codegraph_context` before modifying code
8. **mem_search "lessons learned"** at session start
9. **Review Workload Guard** -> `review-workload-guard.ps1` before multi-file impl
10. **Tool output discipline** -> limit read/grep/bash results; use `-First 30`, `Select-Object`, `head -50` on large output

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

Temperature: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true)
Lang: es | Engram project: workspace_gentle_vanguard

## Key Refs

See `docs/AGENTS.md#Key-References` for full resource table.
