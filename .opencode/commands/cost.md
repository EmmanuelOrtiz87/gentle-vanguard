---
description: Analyze current costs and token usage across providers
agent: gov-agent
---

Analyze token costs and usage:

1. Read `.session/token-budget.json` for current session
2. Read `.session/metrics/` for historical data
3. Run cost tracker:
   `pwsh scripts/utilities/telemetry/TELEMETRY-METRICS/cost-tracker.ps1 -Action status -Quiet`
4. Check model router: `config/model-router.json` for cost rates
5. Display per-model cost breakdown
6. Show daily budget remaining (30K daily limit)
7. Show session budget remaining (15K per-session limit)
8. Flag any over-budget models or agents

Display a cost dashboard with:

- Current session spend
- Daily spend vs budget
- Per-model breakdown
- Per-agent breakdown (if available)
- Recommendations for cost optimization

$ARGUMENTS
