---
created: 2026-09-11 18:08:01
tags: [engram, bugfix]
engram_id: 3880
type: bugfix
---

# CRM: pipeline 5 columnas, cobrado va a historial automáticamente

**What**: Pipeline del CRM restaurado a 5 columnas (Prospecto → Contactado → Cotizado → Vendido → Entregado). Cuando un deal llega a 'Cobrado', desaparece del pipeline y aparece automáticamente en el tab Historial. El botón "Reabrir" en el Historial lo devuelve al pipeline como Prospecto.

**Why**: El usuario reportó que los deals cobrados seguían visibles en el pipeline. El comportamiento correcto es: al llegar a Cobrado, el deal sale del pipeline y solo es visible en el Historial (con filtros por período). El botón "Reabrir" lo regresa al pipeline.

**Where**: `apps/academy-crm/src/pages/Deals.tsx` — COLUMNS sin 'paid' (5 columnas), HISTORY con paid/lost/cancelled.

**Learned**: (1) El flujo correcto es: Pipeline muestra solo deals ACTIVOS (5 estados). Cuando un deal llega a 'paid', 'lost' o 'cancelled', sale del pipeline y va al Historial. (2) El botón "Reabrir" en el Historial hace transitionDeal(d.id, 'lead') que lo devuelve al pipeline como Prospecto. (3) Las transiciones en las cards del pipeline permiten mover a CUALQUIER estado incluyendo 'paid' — al mover a 'paid', el deal desaparece del kanban y aparece en el Historial. (4) El tipo de cambio es: pipeline = activos, historial = cerrados. No se superponen.

---
*Imported from Engram on 2026-09-12*
