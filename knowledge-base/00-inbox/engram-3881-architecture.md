---
created: 2026-09-11 18:14:56
tags: [engram, architecture]
engram_id: 3881
type: architecture
---

# CRM: conflictos de horario + editar/eliminar sesiones

**What**: Sistema de detección de conflictos de horario en el calendario de Sessions + botones de editar y eliminar en cada sesión agendada.

**Why**: El usuario pidió: (1) alertas si se agendan citas en el mismo lapso horario, (2) poder editar o eliminar cada sesión agendada además de completarla.

**Where**:
- `apps/academy-crm/src/pages/Sessions.tsx` — función `hasConflict(newStart, newDuration, existing, excludeId?)` que detecta solapamiento de horarios (start < end && end > start). CreateSessionModal y EditSessionModal muestran banner de conflicto y deshabilitan el botón submit. EditSessionModal permite editar todos los campos. Botones 🗑 (eliminar) y "Editar" en cada card de sesión.
- `apps/academy-crm/src/i18n.ts` — claves sessions_conflict, sessions_conflict_msg, sessions_edit_title, sessions_delete_confirm (es/en/pt)

**Learned**: (1) La detección de conflictos compara start < existingEnd && newEnd > existingStart (algoritmo de solapamiento de intervalos). (2) El excludeId permite editar una sesión sin que se detecte conflicto consigo misma. (3) El botón submit se deshabilita cuando hay conflicto — el usuario DEBE resolver el conflicto antes de agendar. (4) El banner de conflicto muestra el título y horario de la sesión que causa el conflicto. (5) useState(session.type) infiere el tipo literal de SessionType — cambiar a useState<string>(session.type) para permitir que el select cambie.

---
*Imported from Engram on 2026-09-12*
