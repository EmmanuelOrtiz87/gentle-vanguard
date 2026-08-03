# PS1 Legacy — Archived PowerShell Scripts

These PowerShell scripts were migrated to TypeScript as part of the PS1→TS migration.
They are archived here for reference only. **Do not use or reference them.**

| PS1 File | TS Replacement | Purpose |
|----------|---------------|---------|
| `gv.ps1` / `gf.ps1` | `src/cli/gv.ts` | CLI commands (`npx tsx src/cli/gv.ts <cmd>`) |
| `dashboard-ws-launcher.ps1` | `src/dashboard-ws-launcher.ts` | Detached WS server launcher for autoheal |
| `start-dashboard.ps1` | `scripts/utilities/dashboard/dashboard-start.ps1` | Full dashboard launcher |

## Migration Date

2026-07-29 — All PS1 files removed from active codebase.
