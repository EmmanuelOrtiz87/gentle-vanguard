---
name: watchtower
description: Run the maintenance watchtower (154 health checks / 29 components)
---

Run the central health/auto-heal orchestrator:

- Default: `npm run watchtower:health` (154 checks, 29 components incl. `apps-registry` que vigila
  las 9 apps vía Command Center; expect full PASS — WARN/FAIL solo si hay basura real).
- If the user asks to fix/heal: `node --import tsx src/maintenance-watchtower.ts -Action autoheal`.
- If they ask to rebuild indices: `-Action rebuild`.
- Report per-component status, highlighting any WARN/FAIL with its causal chain.
