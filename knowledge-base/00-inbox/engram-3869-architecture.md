---
created: 2026-09-11 03:32:13
tags: [engram, architecture]
engram_id: 3869
type: architecture
---

# CRM i18n es/en/pt + pruebas funcionales end-to-end

**What**: CRM de Academy con i18n es/en/pt (español default) + pruebas funcionales end-to-end completadas. El selector de idioma ES/EN/PT está en el sidebar. Todos los labels traducidos (nav, dashboard, deals, contacts, sessions, modales).

**Why**: El usuario pidió que el CRM tenga la misma visual, estructura y formato que las otras apps GV, con español por defecto y traductor como las otras apps.

**Where**:
- `apps/academy-crm/src/i18n.ts` — NUEVO: ~120 claves × 3 idiomas, persistencia localStorage (gv-crm-lang), selector ES/EN/PT
- `apps/academy-crm/src/App.tsx` — nav con i18n, selector de idioma en sidebar
- `apps/academy-crm/src/pages/Dashboard.tsx` — todos los labels con t()
- `apps/academy-crm/src/pages/Deals.tsx` — kanban con estados traducidos, modal traducido
- `apps/academy-crm/src/pages/Contacts.tsx` — cards, toolbar, modal traducidos
- `apps/academy-crm/src/pages/Sessions.tsx` — calendario, modal traducidos
- `apps/academy-crm/src/styles.css` — .crm-lang + .crm-lang-btn agregados

**Learned**: (1) Colisión de nombres: `productLabel` era tanto función global como estado — renombrar el estado a `label` resolvió el TS7022/TS7024. (2) Las pruebas funcionales end-to-end pasaron: crear contacto → crear deal → transicionar lead→contacted→quoted→sold → verificar historial (4 transiciones) → crear sesión → completar sesión → dashboard actualizado (5 contactos, $80 pipeline, 2 sesiones). (3) El borrado en cascada funciona (FK CASCADE borra deals y sesiones del contacto). (4) El import de leads funciona pero el JSONL estaba vacío (los leads de prueba se habían limpiado). (5) El UI renderiza todos los labels en español con el selector ES/EN/PT visible.

---
*Imported from Engram on 2026-09-12*
