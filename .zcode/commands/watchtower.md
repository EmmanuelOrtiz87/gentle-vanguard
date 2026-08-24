---
name: watchtower
description: Run the maintenance watchtower (95 health checks / 21 components)
---

Run the central health/auto-heal orchestrator:

- Default: `npm run watchtower:health` (95 checks, 21 components; expect 95/95 PASS).
- If the user asks to fix/heal: `npx tsx src/maintenance-watchtower.ts -Action autoheal`.
- If they ask to rebuild indices: `-Action rebuild`.
- Report per-component status, highlighting any WARN/FAIL with its causal chain.
