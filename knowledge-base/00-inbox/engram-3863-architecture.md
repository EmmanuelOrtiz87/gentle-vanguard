---
created: 2026-09-10 20:36:03
tags: [engram, architecture]
engram_id: 3863
type: architecture
---

# Dashboard: alerts CSV + academy-catalog endpoint + Overview panel

**What**: 3 nuevas capacidades de integración Academy↔Dashboard: (1) export CSV de alertas (`/api/alerts?format=csv`), (2) endpoint `/api/academy-catalog` que expone el catálogo de productos al dashboard (escanea los manifests de apps/academy-web/data/), (3) panel `AcademyOverviewPanel` que consolida catálogo + exports + leads en una vista.

**Why**: El usuario pidió seguir conectando el stack. El CSV de alertas completa el patrón de operatividad; el catálogo le da al dashboard visibilidad del inventario de productos Academy sin duplicar datos.

**Where**:
- `apps/web-dashboard/server/handlers/observability.ts` — CSV de alerts (antes del JSON response) + endpoint academy-catalog (scan de ebook.json/toolkit.json/course.json con readdirSync)
- `apps/web-dashboard/src/components/AcademyOverviewPanel.tsx` — NUEVO: 5 stats (cursos/ebooks/toolkits/leads/exports) + badge premium + featured list
- `apps/web-dashboard/src/components/Dashboard.tsx` — panel agregado a la grilla SQLite Stack Tables
- `apps/web-dashboard/src/i18n/ui-strings.ts` — claves academy_overview/courses/ebooks/toolkits/featured (es/en/pt)

**Learned**: (1) El endpoint de catálogo lee directamente los manifests de apps/academy-web/data/ (cross-app pero mismo ROOT) — cero duplicación de datos, el dashboard siempre ve el catálogo real. (2) El patrón CSV es consistente: quoted fields + escape de comillas + Content-Disposition attachment. (3) El Overview usa Promise.all de 3 fetches con un solo AbortController compartido. (4) Verificado end-to-end: catalog devuelve counts correctos (20/20/10/12/52), alerts CSV con headers correctos, 3 paneles renderizan con datos. (5) typecheck + build (942ms) pasan.

---
*Imported from Engram on 2026-09-12*
