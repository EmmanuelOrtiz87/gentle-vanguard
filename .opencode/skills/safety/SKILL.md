---
name: safety
description: Safety Skill — Gentle-Vanguard
triggers:
  - safety
---

# Safety Skill — Gentle-Vanguard

Safety guardrails, prompt injection detection, and mutation safety scoring for agent mutations.

## Trigger

"safety", "guardrail", "injection", "seguridad", "mutacion", "mutation safety", "seguro", "validar"

## Workflow

### 1. Check safety status

```
scripts/utilities/SAFETY/safety-guardrails.ps1 -Action status
```

Shows active guardrails, blocked patterns, resource limits, and recent audit logs.

### 2. Validate a mutation

```
scripts/utilities/SAFETY/safety-guardrails.ps1 -Action validate -AgentId "<agent>" -ProposedMutation '{"strategy":"...","changes":[],"target":"..."}'
```

Checks constitutional rules, blocked patterns, and resource limits.

### 3. Scan for prompt injection

```
scripts/utilities/SAFETY/prompt-injection-guard.ps1 -Action scan -Text "<text>"
scripts/utilities/SAFETY/prompt-injection-guard.ps1 -Action sanitize -Text "<text>" -Strictness high
```

### 4. Score mutation safety

```
scripts/utilities/SAFETY/mutation-safety-scorer.ps1 -Action score -AgentId "<agent>" -Mutation '{"strategy":"...","target":"...","changeCount":N}'
```

Returns 0.0-1.0 score. Below 0.5 requires human approval.

## Resources

- `scripts/utilities/SAFETY/safety-guardrails.ps1`
- `scripts/utilities/SAFETY/prompt-injection-guard.ps1`
- `scripts/utilities/SAFETY/mutation-safety-scorer.ps1`
- `config/safety-layer.json`
- `apps/web-dashboard/server/websocket-server.ts` — `/api/safety` endpoint
