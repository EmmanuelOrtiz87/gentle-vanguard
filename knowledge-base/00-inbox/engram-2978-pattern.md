---
created: 2026-08-23 20:06:51
tags: [engram, pattern]
engram_id: 2978
type: pattern
---

# Cierre WIP CMS-dashboard + resiliencia bulk migration

**What**: Cierre del WIP heredado del CMS-dashboard: revisados y commiteados en 4 unidades coherentes — paneles ContentOps/Audit con React Router (f99debfe), upgrade Vite 5→6 con overrides pnpm (ca552af4), docs de auditoría/planning (a6d678bc), refactor launchers anti-conhost node+tsx directo (da22c9a1). Además: retry/backoff async nativo en applyAllMigrations (absorbe sharing violations de AV/indexer sin bloquear el event loop) y limpieza de 6 MIGRATION.json DRAFT obsoletos.
**Why**: El usuario pidió avanzar todo lo pendiente; el WIP sin commitear era riesgo de pérdida y bloqueaba trabajo futuro limpio.
**Where**: apps/web-dashboard/src/App.tsx, components/AuditPanel.tsx, ContentOpsPanel.tsx, server/real-data.ts, src/dashboard-ws-launcher.ts, src/start-monitor-daemon.ts, apps/web-dashboard/server/marketplace-api.ts
**Learned**: (1) Los launchers del stack usaban cadenas cmd.exe→npx.cmd que dejaban consolas huérfanas visibles — el patrón correcto es spawn directo de node_modules/tsx/dist/cli.mjs vía process.execPath en Windows. (2) applyAllMigrations debe ser async: busy-wait sincrónico bloquearía los broadcasts WS de 5s. (3) Los archivos docs/sessions/metrics/*y reports/optimization/* son churn de daemons — no commitearlos en unidades de feature. (4) dashboard-start.ts adopta el WS ya corriendo vía detectRunningWs — relanzarlo es seguro con watchdog activo.

---
*Imported from Engram on 2026-09-06*
