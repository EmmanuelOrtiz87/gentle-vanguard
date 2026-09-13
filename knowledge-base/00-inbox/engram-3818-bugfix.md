---
created: 2026-09-09 18:14:47
tags: [engram, bugfix]
engram_id: 3818
type: bugfix
---

# Fix track apps-del-stack vacío: mismatch filename→trackId + enriquecimiento

**What**: Bug corregido en GV Academy: el track "Apps del stack" del curso gentle-vanguard no renderizaba contenido. Causa: mismatch de nombres — el track se llama `apps-del-stack` pero el archivo de contenido se llamaba `content-apps.js`. El loader de app.js (loadCourse) deriva el trackId del NOMBRE del archivo (`content-apps.js` → `apps`), guardando el contenido bajo `content['apps']`, mientras la página del track busca `content['apps-del-stack']` → 0 lecciones. Fix: renombrar a `content-apps-del-stack.js` + actualizar course.json + regenerar registry. Además se enriquecieron las 8 lecciones (899-2377 → 2238-4008 chars) con detalle real del stack (analogías, gotchas ❌/✅, ejercicios, arquitectura interna, datos Nexus) vía agente general.
**Why**: Usuario reportó "la seccion dice app del stack y no tiene contenido" y pidió dejarla completa o quitarla.
**Where**: apps/academy-web/data/courses/gentle-vanguard/content-apps-del-stack.js (renombrado + enriquecido), course.json, data/courses.js (registry regenerado), index.html (?v=20260909b)
**Learned**: (1) GOTCHA CRÍTICO: en el patrón de contenido por-archivo, el archivo DEBE llamarse `content-<trackId>.js` EXACTO — el loader deriva el trackId del filename, no del contenido. Un mismatch silencioso = track vacío sin error. (2) El curso gentle-vanguard usa template literals (backticks) para el campo md (a diferencia de los cursos nuevos que usan strings JSON de una línea con \n) — ambos formatos funcionan en el renderer. (3) Verificación: Playwright 8/8 lecciones renderizan (2868-4185 chars body), smoke 18/18, sin HTML crudo, solo diagramas válidos (apps-map, sdd-cycle).

---
*Imported from Engram on 2026-09-09*
