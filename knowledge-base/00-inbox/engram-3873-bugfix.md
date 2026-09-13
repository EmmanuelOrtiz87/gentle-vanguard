---
created: 2026-09-11 14:06:35
tags: [engram, bugfix]
engram_id: 3873
type: bugfix
---

# CRM Studio: DB schema fix + i18n keys + vistas calendario con grid

**What**: CRM Studio fixes: (1) DB schema corregida — tenant_id agregado a crm_events y crm_deal_status_history, contact_id/deal_id agregados a crm_events, índices de tenant agregados, (2) key i18n `dash_import_leads` renombrada a `dash_import` para match con Dashboard.tsx, (3) nav_deals traducido a "Negocios" en español, (4) vistas día/mes muestran calendario incluso sin datos, (5) nombre en command-center confirmado como "CRM Studio".

**Why**: El usuario reportó: error HTTP 500 al crear contacto (crm_events sin columna tenant_id), "dash_import" mostrado como texto raw (key mismatch), "Deals" en inglés en nav español, y vistas día/mes sin calendario visible.

**Where**:
- `apps/academy-crm/server/db.ts` — crm_deal_status_history + crm_events con tenant_id, contact_id, deal_id; índices idx_crm_history_tenant + idx_crm_events_tenant
- `apps/academy-crm/src/i18n.ts` — dash_import_leads → dash_import (es locale); nav_deals 'Deals' → 'Negocios' (es locale)
- `apps/academy-crm/src/pages/Sessions.tsx` — vista día: panel de un solo día con crm-day--today; vista mes: grid de 7 columnas con días del mes, sessions por día, botón + por día
- `apps/command-center/server.ts` — nombre confirmado "CRM Studio"

**Learned**: (1) El error "table crm_events has no column named tenant_id" ocurrió porque la DB standalone (db.ts) no incluía tenant_id en crm_events ni crm_deal_status_history — el repo standalone sí lo usa. Al crear una DB nueva, SIEMPRE verificar que el schema coincida con las queries del repo. (2) Los keys i18n deben ser consistentes entre locales — si es locale usa `dash_import_leads` pero el componente usa `t('dash_import')`, el usuario ve el key raw. (3) La vista de mes usa un grid de 7 columnas con celdas vacías para los días antes del día 1 del mes (startDow). (4) Start-Process con WorkingDirectory absoluto funciona mejor que Set-Location + Start-Process relativo. (5) El command-center muestra "partial" cuando solo uno de los procesos (server o vite) está corriendo.

---
*Imported from Engram on 2026-09-12*
