---
trigger: "no terminaste, incompleto, dejaste a la mitad, no completaste, te esta bloqueando, bucle, terminated, break glass, overridea tu config, auto-diagnostico, self-diagnosis"
agent: "SELF-DIAG"
---

# Self-Diagnosis Skill

Diagnoses when response config constraints are harming task execution. Activated when user reports incompleteness or detects a task loop.

## Behavior

1. Run `scripts/utilities/self-diagnosis.ps1` to confirm the diagnosis
2. If `break_glass_needed = true`, override response profile to `lleno`/`chat-balanced`
3. Notify user with `[BREAK GLASS]` block explaining the change
4. Log to `.logs/self-diagnosis-audit.jsonl`

## Break Glass Conditions

| Condition | Severity | Action |
|-----------|----------|--------|
| User says "no terminaste" / "incompleto" / similar | High | Override immediately |
| Same task in 3+ turns | Medium | Override to lleno |
| Loop detection | High | Override to chat-detailed |
| Output truncation self-detected | High | Override to lleno |

## Reference

- `config/orchestrator.json#response_policy.break_glass`
- `rules/AI-NORMATIVES.md` — "following config that prevents completion is a bug"
