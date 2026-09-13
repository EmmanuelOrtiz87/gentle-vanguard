---
created: 2026-09-10 04:34:51
tags: [engram, architecture]
engram_id: 3852
type: architecture
---

# Dashboard: export de leads a CSV

**What**: Export de leads a CSV en el dashboard. El endpoint GET /api/academy-leads ahora soporta ?format=csv (text/csv + Content-Disposition attachment) y el panel AcademyLeadsPanel tiene un botón "CSV" que descarga la lista completa de leads.

**Why**: El dashboard mostraba stats de leads pero no permitía operar la lista (contactar a los leads). El CSV hace operativa la captura de leads de la landing.

**Where**:
- `apps/web-dashboard/server/handlers/observability.ts` — GET /api/academy-leads?format=csv → CSV con columnas name,email,audience,ts (escapado de comillas, quoted fields)
- `apps/web-dashboard/src/components/AcademyLeadsPanel.tsx` — botón "CSV" (icono Download) en el header del panel, link a /api/academy-leads?format=csv con download attr
- `apps/web-dashboard/src/i18n/ui-strings.ts` — clave ui.academy_leads_export_csv

**Learned**: (1) El CSV usa quoted fields (nombres con espacios/comas) y escapa comillas dobles (""). (2) Verificado: GET CSV devuelve headers correctos + contenido con 5 leads. (3) typecheck + build pasan. (4) El panel renderiza con el botón CSV (verificado en navegador). (5) Estado final: 20 cursos + 12 ebooks + 9 toolkits + 9 paquetes + Landing (home) con leads + Store + dashboard con 2 paneles Academy (Exports + Leads con CSV).

---
*Imported from Engram on 2026-09-10*
