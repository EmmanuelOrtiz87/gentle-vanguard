---
created: 2026-09-10 04:23:04
tags: [engram, architecture]
engram_id: 3850
type: architecture
---

# Academy: Landing como home + captura de leads

**What**: Landing como home (#/ → landing) + captura de leads en Academy. El home ahora es la puerta de entrada comercial (antes era el catálogo de cursos, que vive en #/courses). El formulario de leads (nombre + email + audiencia) se guarda en localStorage y se sincroniza al stack vía /api/academy-leads.

**Why**: El usuario pidió seguir potenciando el stack. La landing como home alinea la experiencia con la estrategia de venta (atraer personas/estudiantes/empresas); la captura de leads es la herramienta de venta que faltaba.

**Where**:
- `apps/academy-web/app.js` — router: `#/` → viewLanding, `#/courses` → viewCourses; `recordLead()`/`syncLeadsToStack()` (localStorage key `gv-academy-leads`, sync best-effort vía command-center → dashboard); formulario en viewLanding (lead-form con name/email/audience, success message); i18n lead (es/en/pt, ~10 claves)
- `apps/academy-web/index.html` — nav: "Inicio" → #/, "Cursos" → #/courses
- `apps/web-dashboard/server/handlers/observability.ts` — endpoint `/api/academy-leads` (POST → `.runtime/academy-leads.jsonl`, GET → stats por audiencia)
- `apps/web-dashboard/server/websocket-server.ts` — `/api/academy-leads` público (junto a academy-exports)
- `apps/academy-web/scripts/smoke-academy.mjs` — checks actualizados: home (landing) verifica stat de cursos >=16, catálogo verificado en #/courses (20/20 PASS)

**Learned**: (1) El smoke test asumía home = catálogo; al cambiar home a landing, 2 checks fallaron — se actualizaron para verificar la landing en #/ y el catálogo en #/courses. (2) El endpoint de leads sigue el mismo patrón que academy-exports (JSONL + público + CORS). (3) Verificado: home muestra landing con form, POST/GET de leads OK. (4) Estado: 20 cursos + 12 ebooks + 9 toolkits + 9 paquetes + Landing (home) con leads + Store + dashboard.

---
*Imported from Engram on 2026-09-10*
