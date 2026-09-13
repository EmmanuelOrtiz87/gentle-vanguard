---
created: 2026-08-06 03:23:49
tags: [engram, decision]
engram_id: 2559
type: decision
---

# HANDOFF: Portabilidad PS1→TS — Estado validado 2026-08-06

**What**: Validación completa del estado de la portabilidad PS1→TS (run-command.ts + adapters). Estado real verificado: src/ 100% convertido (~130 archivos), dashboard server 4/6, scripts 0/19, Fase 3 pendiente.
**Why**: Cerrar sesión con trazabilidad. El doc HANDOFF-portabilidad-fase2.md declaraba datos incorrectos (mcp-gateway-api "ya convertido" — FALSO; metrics incompletas).
**Where**: HANDOFF-portabilidad-fase2.md (actualizado con estado real), src/core/run-command.ts (fix), apps/web-dashboard/server/{mcp-gateway-api, database/metrics-writer}.ts (pendientes), scripts/ (19 pendientes con sqlite3).
**Learned**:
1) Bug EINVAL de Windows: spawnSync('npx.cmd') falla sin shell. Fix: runNpxTsxSync ejecuta node <tsx-cli> (dist/cli.mjs via require.resolve('tsx/package.json')) — sin shell ni DEP0190. runSync/run detectan .cmd/.bat y usan shell construyendo la línea ellos mismos.
2) Los 6 matches restantes en src/ son falsos positivos (regex/comentarios/código generado) — complete-stack-fix.ts ya usa runSyncShell.
3) sqlite3 requiere runSyncShell (sintaxis shell exacta, NO argv arrays).
4) Test runner usa runSyncShell por expansión de globs — intencional.
5) Pendiente: 2 dashboard + 19 scripts + Fase 3 (lint ~54 errores pre-existentes, tests, health, commit ~200 archivos).

---
*Imported from Engram on 2026-09-06*
