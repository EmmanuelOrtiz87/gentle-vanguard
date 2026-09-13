---
created: 2026-09-10 04:37:55
tags: [engram, architecture]
engram_id: 3853
type: architecture
---

# Dashboard: CSV de exports + badge leads nuevos

**What**: Export de exports a CSV + indicador de leads nuevos en el dashboard. GET /api/academy-exports?format=csv (mismo patrón que leads CSV) + botón CSV en AcademyExportsPanel + badge "+N NEW" en AcademyLeadsPanel cuando llegan leads entre polls (15s).

**Why**: El usuario pidió seguir potenciando el stack. El CSV de exports completa la operatividad (descargar el historial de exportaciones); el badge NEW da visibilidad inmediata de leads nuevos.

**Where**:
- `apps/web-dashboard/server/handlers/observability.ts` — GET /api/academy-exports?format=csv → CSV (kind,id,title,ts, quoted fields)
- `apps/web-dashboard/src/components/AcademyExportsPanel.tsx` — botón CSV (icono Download)
- `apps/web-dashboard/src/components/AcademyLeadsPanel.tsx` — badge "+N NEW" (emerald, animate-pulse) cuando payload.total > prevTotalRef entre polls
- `apps/web-dashboard/src/i18n/ui-strings.ts` — clave ui.academy_exports_export_csv

**Learned**: (1) El badge NEW usa prevTotalRef (useRef) para comparar entre polls — en el primer load no muestra NEW (correcto). (2) typecheck + build pasan. (3) Verificado en navegador: ambos CSV buttons + ambos paneles renderizan. (4) Estado final: 20 cursos + 12 ebooks + 9 toolkits + 9 paquetes + Landing (home) con leads + Store + dashboard con 2 paneles Academy (Exports + Leads, ambos con CSV + badge NEW).

---
*Imported from Engram on 2026-09-10*
