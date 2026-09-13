---
created: 2026-09-11 18:21:02
tags: [engram, bugfix]
engram_id: 3882
type: bugfix
---

# CRM: puerto 4792 (fix conflicto con Archify) + sesiones completadas no editables

**What**: (1) Conflicto de puertos resuelto — CRM Studio cambiado de puerto 4790 a 4792 porque Archify ya usaba 4790. (2) Sesiones completadas ya NO se pueden editar (solo eliminar). (3) Procesos fantasma eliminados — solo corren las apps explícitamente iniciadas desde command-center.

**Why**: El usuario reportó: (1) "Failed to fetch" intermitente, (2) ventanas fantasmas (procesos corriendo sin ser iniciados), (3) dashboard en estado "partial" en command-center sin ser activado. La causa raíz era un conflicto de puertos entre Archify (4790) y CRM Studio (4790) + procesos iniciados automáticamente por el session autostart.

**Where**:
- `apps/academy-crm/server/server.ts` — PORT cambiado de 4790 a 4792
- `apps/academy-crm/vite.config.ts` — proxy target cambiado de 4790 a 4792
- `apps/command-center/server.ts` — puerto del CRM en definitions() cambiado de 4790 a 4792
- `apps/academy-crm/src/pages/Sessions.tsx` — botón "Editar" solo visible si !s.completed

**Learned**: (1) CONFLICTO DE PUERTOS: Archify usa puerto 4790 (ARCHIFY_PORT ?? 4790) y el CRM también usaba 4790 — al arrancar ambos, uno falla silenciosamente. Solución: CRM en 4792. (2) Las "ventanas fantasmas" son procesos iniciados por el session autostart pipeline que corren en background sin que el usuario los active explícitamente. La solución es matarlos y solo usar command-center para iniciar apps. (3) El estado "partial" en command-center significa que solo algunos procesos de la app están corriendo (ej: server sin vite). (4) Las sesiones completadas NO se pueden editar — solo eliminar. El botón "Editar" solo aparece si !s.completed. (5) Siempre verificar puertos antes de asignar uno nuevo a una app.

---
*Imported from Engram on 2026-09-12*
