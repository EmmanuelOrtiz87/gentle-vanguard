---
created: 2026-09-11 15:16:06
tags: [engram, bugfix]
engram_id: 3877
type: bugfix
---

# CRM: 10 tests funcionales pasan + deal→negocio en español

**What**: Suite de 10 pruebas funcionales end-to-end del CRM Studio, todas pasando. Traducción completa de "deal" a "negocio" en el locale español. DB recreada limpia con schema corregido.

**Why**: El usuario reportó: (1) "deal" en inglés en la pantalla de negocios, (2) error al mover una card (HTTP 502), (3) después del error todo dejaba de funcionar. La causa era que la DB tenía un schema incorrecto (sin tenant_id en crm_events) y el server se quedaba en estado corrupto después del error.

**Where**:
- `apps/academy-crm/src/i18n.ts` — todos los "deal" traducidos a "negocio" en es locale (deals_title, deals_total, deals_search, deals_new, deals_empty, deals_create, deals_new_title, hist_empty, dash_deals_active, dash_deals_paid, dash_deals_paid_count)
- `apps/academy-crm/data/crm.db` — recreada limpia con schema corregido

**Learned**: (1) HTTP 502 ocurre cuando el server backend se crashea y el proxy de Vite no puede alcanzarlo — la solución es reiniciar el server. (2) Después de un error de DB, el server puede quedar en estado corrupto — es mejor recrear la DB limpia y reiniciar. (3) Las 10 pruebas funcionales pasan: crear contacto → crear deal → transicionar por los 6 estados del pipeline (lead→contacted→quoted→sold→delivered→paid) → verificar historial (6 transiciones) → crear sesión → completar sesión → dashboard final (1 contacto, $0 pipeline, $40 won, 1 sesión). (4) El pipeline_value_usd baja a 0 cuando el deal llega a 'paid' porque 'paid' no está en la lista de estados activos del pipeline. (5) El historial registra TODAS las transiciones incluyendo la creación (NULL → lead).

---
*Imported from Engram on 2026-09-12*
