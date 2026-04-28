
## Response Mode (Token Efficiency)

### Concise Output Rule
You MUST answer concisely with fewer than 10 lines (not including tool use or code generation), unless user asks for detail.
Answer the user's question directly, without elaboration, explanation, or details.
One word answers are best. Avoid introductions, conclusions, and explanations.
You MUST avoid text before/after your response, such as "The answer is...", "Here is...", "Based on...".

### Prohibited Patterns (Automatic Token Waste)
- NO introductions: "I'll help you...", "Let me...", "Sure, I can..."
- NO conclusions: "I hope this helps...", "Let me know if...", "Feel free to..."
- NO explanations unless explicitly asked
- NO repeated context from user's question
- NO redundant confirmations: "Yes, I understand...", "The file is..."

### Output Format Rules
1. Direct answers only
2. Code blocks when needed (no surrounding text)
3. Bullet points for lists (no preamble)
4. Error messages: state the error only

### Enforcement
Response mode is MANDATORY. Violations detected by token-guard will trigger auto-compact.
# Workspace Agent Bootstrap (Agnostic)

This file defines agent-agnostic startup behavior for this workspace.

## Startup Rule

Before substantial work in a new conversation, run:

1. `tools/session-autostart.cmd` on Windows, or
2. `bash ./tools/session-autostart.sh` on Linux/macOS/WSL.

Default behavior is controlled by `tools/session-autostart.config.json`.

## Session Tracking Rule

When session tracking capability exists, initialize a session early using:

1. `project = workspace_local`
2. `directory = c:\Workspace_local`
3. session id pattern `session-YYYY-MM-DD-XX`

## Reliability Rule

1. Treat `READY` as pass.
2. Treat `PARTIAL` as actionable and resolve before deep implementation.
3. Use `full` mode before release-critical work.

## Context Optimization (Token Efficiency)

### Memory Tiering
- **Hot**: Active session, no compression
- **Warm**: Recent (1 day), 90% retention
- **Cold**: Archive (7 days), 70% retention

### Handoff Compression Mode
For agent-to-agent transfers, use `tools/handoff-compress.ps1`:
- Preserves: decisions, results, FIXMEs, status flags
- Truncates: verbose outputs, repeated patterns
- Output: state-only handoff (~30% size reduction)

### Pre-Compact Hook
Before context compaction (every ~25k tokens), run:
```powershell
.\tools\pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90
```
Preserves anchored content (FIXME, TODO, BUG, DECISION, RESULT).

### Adaptive Skill Loading
Skills auto-load based on project context:
| Signal | Skill |
|--------|-------|
| Angular component | angular-core, angular-spa |
| React TSX | react-19 |
| Go files | golang-api |
| Docker files | docker-devops |
| PowerShell scripts | workspace-automation |
| Session management | session-lifecycle |

See: `rules/adaptive/` for dynamic rule configuration.

## Workspace-Specific Skills

### Automation Skills

| Skill | Trigger | Path |
|-------|---------|------|
| `workspace-automation` | When creating PowerShell scripts, configuring scheduled tasks, or automating workspace tasks | [`skills/workspace-automation/SKILL.md`](skills/workspace-automation/SKILL.md) |
| `session-lifecycle` | When managing session start/end, implementing session hooks, or tracking session state | [`skills/session-lifecycle/SKILL.md`](skills/session-lifecycle/SKILL.md) |

**Usage**: These skills are automatically loaded when working with workspace automation. Load manually with:
```
Read skills/workspace-automation/SKILL.md before creating automation scripts
Read skills/session-lifecycle/SKILL.md before modifying session management
```

