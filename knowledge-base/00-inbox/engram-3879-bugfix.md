---
created: 2026-09-11 18:01:15
tags: [engram, bugfix]
engram_id: 3879
type: bugfix
---

# CRM: pipeline restaurado a 6 columnas + transiciones completas

**What**: Pipeline restaurado a 6 columnas completas (Prospecto → Contactado → Cotizado → Vendido → Entregado → Cobrado). Las transiciones permiten mover a CUALQUIER estado (incluyendo Cobrado/Perdido/Cancelado). El Historial sigue disponible como tab separado con filtros por período.

**Why**: El usuario reportó que se perdieron columnas del pipeline y que no podía pasar ventas a estado final. La causa fue que cuando agregué el Historial, eliminé 'paid' de COLUMNS y bloqueé las transiciones a estados del historial con `!HISTORY.includes(s)`.

**Where**: `apps/academy-crm/src/pages/Deals.tsx` — COLUMNS restaurado a 6 estados, transiciones sin filtro de HISTORY.

**Learned**: (1) El pipeline debe mostrar TODOS los estados incluyendo los finales (Cobrado). El Historial es una VISTA adicional con filtros por período, no un reemplazo de las columnas del pipeline. (2) Las transiciones deben permitir mover a CUALQUIER estado — nunca bloquear estados finales. (3) Cuando agregues una nueva vista (como Historial), NO elimines elementos existentes — agrégala como complemento.

---
*Imported from Engram on 2026-09-12*
