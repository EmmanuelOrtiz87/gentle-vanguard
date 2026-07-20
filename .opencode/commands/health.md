---
description: Run full stack health check and display results
agent: orchestrator
---

Run the complete stack health verification:

1. TypeScript compilation: `npm run typecheck`
2. Health check: `npm run health:check`
3. Watchtower: `npx tsx src/maintenance-watchtower.ts --action health --quiet`
4. DB health: `scripts/recovery/db-health-check.ts`
5. Dashboard build: `cd apps/web-dashboard && npm run build`

Display a summary table with component status (PASS/WARN/FAIL) and any actionable items.

$ARGUMENTS
