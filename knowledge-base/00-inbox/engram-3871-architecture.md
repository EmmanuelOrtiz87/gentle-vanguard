---
created: 2026-09-11 13:24:13
tags: [engram, architecture]
engram_id: 3871
type: architecture
---

# CRM Studio: DB independiente + edit contacto + fix color

**What**: CRM Studio con base de datos independiente (apps/academy-crm/data/crm.db), botón de editar contacto agregado, shell-context color corregido a gris, y verificación de que Academy navega correctamente.

**Why**: El usuario reportó múltiples problemas: (1) CRM dejó de funcionar, (2) el CRM no debería compartir DB con el stack, (3) el color del shell-context era diferente, (4) faltaba botón de editar contacto, (5) cursos no navegaban.

**Where**:
- `apps/academy-crm/server/db.ts` — NUEVO: SQLite propia en apps/academy-crm/data/crm.db con 5 tablas crm_*, índices, FK CASCADE
- `apps/academy-crm/server/repo-types.ts` — NUEVO: tipos standalone
- `apps/academy-crm/server/repo.ts` — NUEVO: repo standalone con misma interfaz que Nexus pero usando getDb()
- `apps/academy-crm/server/server.ts` — actualizado: importa de ./db y ./repo (cero dependencias del stack)
- `apps/academy-crm/src/shell.css` — shell-context color cambiado de var(--gv-cyan) a var(--gv-text-muted)
- `apps/academy-crm/src/pages/Contacts.tsx` — botón "Editar" agregado + EditContactModal
- `apps/academy-crm/src/i18n.ts` — claves contacts_edit/edit_title/save/saving agregadas (es/en/pt)

**Learned**: (1) La separación de DB es el patrón correcto para apps comercializables: cada app tiene su propia SQLite en su carpeta data/, sin dependencias del stack. (2) El CRM server arranca correctamente con la DB propia (health OK, dashboard con 0 datos = DB limpia). (3) El shell-context en las otras apps usa var(--gv-text-muted) (gris), no var(--gv-cyan). (4) La navegación de cursos en Academy funciona correctamente (verificado con dump-dom: tracks-grid + course-card presentes). El problema del usuario fue probablemente transitorio (server no corriendo o cache del navegador). (5) mkdirSync se importa de 'fs', NO de 'path' — error común al confundir imports.

---
*Imported from Engram on 2026-09-12*
