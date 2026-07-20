# Key Concepts

## Real Data (No Mock)

- Source: `.session/context-log/*/.state.json` — real model names, tokens, costs, latencies.
- `MODEL_PRICING` in `real-data.ts` computes `estimatedCost` vs `actual`.
- 4 models detected, 21+ traces.

## Metric Info & i18n

- `useLocale.ts` — 14 metrics × 3 languages (en, es, pt-BR).
- Each metric: `label`, `description`, `what` (what it measures), `how` (calculation).
- `MetricsCard` accepts `infoKey` prop → ℹ icon → `InfoPopup`.
- `SectionHeader` helper with info icon for section titles.

## Dynamic Port Allocation

```
Get-FreePort algorithm (dashboard-common.ps1):
  1. Start from preferred port (config, env, or default)
  2. Scan upward (+100 ports max)
  3. Check if port is in Listen/Established/Bound state
  4. Return first free port
```

Ports persisted to `.runtime/dashboard-ports.json`:
```json
{ "wsPort": 8081, "vitePort": 5199, "updated": "2026-06-18T..." }
```

Both stop and start scripts read this file for port reuse.

## Alert System

- `config/dashboard-alerts.json` — 8 rules with `direction` ("above" or "below").
- Rules: high_token_usage, budget_limit, high_latency_p95, high_error_rate, low_feedback_score, low_sla, high_active_sessions, cost_spike.
- Fixed `direction: "below"` evaluation: `actual <= threshold`.
