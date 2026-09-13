---
created: 2026-09-11 14:23:38
tags: [engram, architecture]
engram_id: 3875
type: architecture
---

# CRM: autocompletado de contacto en Nuevo Deal

**What**: Campo de contacto en el modal de Nuevo Deal convertido de `<select>` a autocompletado. Al escribir, muestra coincidencias de contactos (nombre + email). Al seleccionar, setea el contactId. Si no hay coincidencias, muestra link para crear contacto.

**Why**: El usuario pidió que el campo de contacto sea autocompletado (no un combo de selección) para que sea más fácil ingresar los datos y le vaya mostrando los contactos ya creados.

**Where**:
- `apps/academy-crm/src/pages/Deals.tsx` — estado `contactSearch` + `contactId` (nullable), `contactMatches` (filtra por nombre/email/empresa), `selectContact()`, input con dropdown `.crm-autocomplete`
- `apps/academy-crm/src/i18n.ts` — claves `deals_contact_placeholder`, `deals_no_contact_match` (es/en/pt)

**Learned**: (1) El patrón de autocompletado es consistente: input + dropdown `.crm-autocomplete` + estado nullable para el ID seleccionado. (2) El contacto se busca por nombre, email O empresa. (3) El `contactId` es `null` hasta que el usuario selecciona de la lista — el form valida que no sea null antes de submit. (4) typecheck pasa. (5) Tanto el campo de contacto como el de producto usan el mismo patrón de autocompletado en el modal de Nuevo Deal.

---
*Imported from Engram on 2026-09-12*
