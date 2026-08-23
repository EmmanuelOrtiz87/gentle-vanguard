---
name: safety
aliases: ["safety"]
description: >
  Safety Skill — Gentle-Vanguard
triggers:
  - safety
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.085Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\safety\SKILL.md
  version: "1.0.0"
---

# Safety Skill — Gentle-Vanguard

Safety guardrails, prompt injection detection, and mutation safety scoring for agent mutations.

## Trigger

"safety", "guardrail", "injection", "seguridad", "mutacion", "mutation safety", "seguro", "validar"

## Workflow

### 1. Check safety status

```
C:/Workspace_local/gentle-vanguard/src/safety-guardrails.ts -Action status
```

Shows active guardrails, blocked patterns, resource limits, and recent audit logs.

### 2. Validate a mutation

```
C:/Workspace_local/gentle-vanguard/src/safety-guardrails.ts -Action validate -AgentId "<agent>" -ProposedMutation '{"strategy":"...","changes":[],"target":"..."}'
```

Checks constitutional rules, blocked patterns, and resource limits.

### 3. Scan for prompt injection

```
C:/Workspace_local/gentle-vanguard/src/prompt-injection-guard.ts -Action scan -Text "<text>"
C:/Workspace_local/gentle-vanguard/src/prompt-injection-guard.ts -Action sanitize -Text "<text>" -Strictness high
```

### 4. Score mutation safety

```
C:/Workspace_local/gentle-vanguard/src/mutation-safety-scorer.ts -Action score -AgentId "<agent>" -Mutation '{"strategy":"...","target":"...","changeCount":N}'
```

Returns 0.0-1.0 score. Below 0.5 requires human approval.

## Resources

- `C:/Workspace_local/gentle-vanguard/src/safety-guardrails.ts`
- `C:/Workspace_local/gentle-vanguard/src/prompt-injection-guard.ts`
- `C:/Workspace_local/gentle-vanguard/src/mutation-safety-scorer.ts`
- `config/safety-layer.json`
- `apps/web-dashboard/server/websocket-server.ts` — `/api/safety` endpoint

## Examples

Concrete usage drawn from this skill's own documentation:

```
C:/Workspace_local/gentle-vanguard/src/safety-guardrails.ts -Action status
```
