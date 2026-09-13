---
created: 2026-09-11 19:43:20
tags: [engram, architecture]
engram_id: 3885
type: architecture
---

# CRM: validación correlatividad deal→sesión

**What**: Validación de correlatividad: no se puede crear una sesión si no hay al menos un deal activo en el pipeline. Banner de advertencia + botón submit deshabilitado.

**Why**: El usuario pidió que haya correlatividad entre los leads creados y las citas agendadas — una sesión (mentoría, consultoría, demo) debe estar vinculada a un negocio real, no crearse en el vacío.

**Where**:
- `apps/academy-crm/src/pages/Sessions.tsx` — estado `activeDeals` (cuenta deals en estados activos), fetch de deals en refresh(), banner de advertencia si activeDeals === 0, botón submit deshabilitado
- `apps/academy-crm/src/i18n.ts` — claves sessions_no_deals + sessions_no_deals_link (es/en/pt)

**Learned**: (1) La correlatividad es: deal activo → sesión agendada. Sin deal, no hay sesión. (2) El banner muestra "No hay negocios en el pipeline" con link a la página de Negocios. (3) El botón submit se deshabilita con `activeDeals === 0`. (4) La edición de sesiones existentes NO está restringida — solo la creación de nuevas sesiones. (5) typecheck pasa.

---
*Imported from Engram on 2026-09-12*
