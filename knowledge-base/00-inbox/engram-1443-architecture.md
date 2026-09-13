---
created: 2026-06-18 16:22:16
tags: [engram, architecture]
engram_id: 1443
type: architecture
---

# maintenance-watchtower v2 - orquestador central de health + autoheal

**What**: Extendí maintenance-watchtower.ps1 como orquestador central de health checks, auto-healing y monitoreo continuo. V2 unifica maintenance-watchtower (4 componentes) + health-check.ps1 (14 componentes) + stack-health-check.ps1 (30+ checks) en un solo script.

**Why**: El stack tenía múltiples scripts de health check dispersos sin coordinación. Cuando el WS server caía hoy, no había auto-reparación centralizada. Se necesitaba un sistema nervioso central.

**Where**: scripts/maintenance/maintenance-watchtower.ps1 (reescrito completo), AGENTS.md (documentación agregada)

**Learned**:
- El WS server caía porque el watchdog se lanzaba como subproceso del shell tool; al expirar timeout del bash tool, se mataba todo el árbol. Solución: lanzar watchdog como proceso independiente con Start-Process -WindowStyle Hidden.
- Los 42 steps del autostart NO necesitan consolidación agresiva porque lazy:true ya los hace no-bloqueantes.
- @types/react 19 rompe JSX.Element namespace — migrar a React.ReactNode.
- npm update con pnpm funciona pero @types/react salta a 19 aunque el proyecto use React 18 — tener cuidado con major bumps.

---
*Imported from Engram on 2026-09-06*
