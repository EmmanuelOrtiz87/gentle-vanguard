# Workspace Agent Bootstrap (Agnostic)

This file defines agent-agnostic startup behavior for this workspace.

## Startup Rule

Before substantial work in a new conversation, run:

1. `scripts/utilities/session-autostart.cmd` on Windows, or
2. `bash ./scripts/utilities/session-autostart.sh` on Linux/macOS/WSL.

Default behavior is controlled by `config/orchestrator.json`.

## Session Tracking Rule

When session tracking capability exists, initialize a session early using:

1. `project = workspace_local`
2. `directory = c:\Workspace_local`
3. session id pattern `session-YYYY-MM-DD-XX`

## Reliability Rule

1. Treat `READY` as pass.
2. Treat `PARTIAL` as actionable and resolve before deep implementation.
3. Use `full` mode before release-critical work.

## Routing

- Canonical trigger→skill mappings: `config/auto-delegation.json#keywordMappings`
- Agent profiles: `config/auto-delegation.json#agentProfiles`
- Pre-processing hook (mandatory): `tools/pre-process-input.ps1`
- Parse output: `TRIGGER_MATCH_FOUND` → load skill | `PLAN_MODE_REQUIRED` → activate BA | `NO_TRIGGER_MATCH` → continue

## Context Optimization

- Memory tiering: Hot (active) → Warm (1 day, 90%) → Cold (7 days, 70%)
- Handoff compression: `tools/handoff-compress.ps1` (~30% size reduction)
- Pre-compact hook: `tools/pre-compact-hook.ps1 -ProjectName "workspace_local" -CompressionRatio 0.90`

## Workspace-Specific Skills

| Skill | Trigger | Path |
|-------|---------|------|
| `workspace-automation` | PowerShell scripts, scheduled tasks, automation | `skills/workspace-automation/SKILL.md` |
| `session-lifecycle` | Session start/end, hooks, session state | `skills/session-lifecycle/SKILL.md` |
