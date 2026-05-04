# Workspace Agent Bootstrap (Agnostic)

This file defines agent-agnostic startup behavior for this workspace.

## Startup Rule

Before substantial work in a new conversation, run:

1. `scripts/utilities/session-autostart.cmd` on Windows, or
2. `bash ./scripts/utilities/session-autostart.sh` on Linux/macOS/WSL.

Default behavior is controlled by `scripts/utilities/session-autostart.config.json`.

## Session Tracking Rule

When session tracking capability exists, initialize a session early using:

1. `project = workspace_local`
2. `directory = .`
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
For agent-to-agent transfers, use `scripts/utilities/handoff-compress.ps1`:
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
