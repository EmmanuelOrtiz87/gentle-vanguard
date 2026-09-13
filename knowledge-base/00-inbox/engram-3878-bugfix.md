---
created: 2026-09-11 17:43:19
tags: [engram, bugfix]
engram_id: 3878
type: bugfix
---

# CRM: papelera en pipeline + Revenue→Ingresos + paid→cobrado

**What**: Papelera de eliminación individual en los deals del pipeline + traducción completa de términos en inglés restantes (Revenue→Ingresos, paid→cobrado).

**Why**: El usuario pidió poder eliminar negocios individuales del pipeline (no del historial) con un icono de papelera, y reportó que seguía viendo términos en inglés (Revenue, paid).

**Where**:
- `apps/academy-crm/src/pages/Deals.tsx` — botón 🗑 en cada card del pipeline (solo en activos, no en historial), con confirm() antes de eliminar. Las transiciones disponibles ahora excluyen los estados del historial (paid/lost/cancelled) para que solo se pueda avanzar en el pipeline.
- `apps/academy-crm/src/i18n.ts` — dash_won 'Ganado (paid)' → 'Ganado (cobrado)', dash_revenue 'Revenue' → 'Ingresos', hist_revenue 'Revenue del período' → 'Ingresos del período', deals_delete + deals_delete_confirm agregados (es/en/pt)

**Learned**: (1) El botón de papelera 🗑 solo aparece en los deals del PIPELINE (estados activos), no en el historial. (2) Las transiciones disponibles en cada card ahora excluyen los estados del historial (paid/lost/cancelled) — solo se puede avanzar dentro del pipeline. (3) "Revenue" es un término inglés que debe traducirse a "Ingresos" en español. (4) "paid" dentro de "Ganado (paid)" también debe traducirse a "cobrado". (5) El deleteDeal usa la API existente `api.deleteDeal(id)` que hace DELETE en la DB standalone.

---
*Imported from Engram on 2026-09-12*
