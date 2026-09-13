---
created: 2026-09-09 07:20:43
tags: [engram, bugfix]
engram_id: 3807
type: bugfix
---

# Academy 18 cursos: cache-busting + git-github y patrones-diseno

**What**: (1) Diagnóstico de "no veo los cursos nuevos": el server SÍ servía el registry actualizado (9/9 cursos nuevos, HTTP 200) — era caché del navegador de data/courses.js (python http.server no envía no-cache). Fix nativo: cache-busting con ?v=YYYYMMDD en los script tags de apps/academy-web/index.html (incrementar v en cada release de cursos). (2) 2 cursos nuevos creados por agente: git-github (46 lecciones, 7 tracks, 37 términos) y patrones-diseno (49 lecciones, 7 tracks, 38 términos). Academy ahora: 18 cursos. (3) Bug del agente corregido: content-patrones-datos.js tenía el push sin la línea de init window.GV_CONTENT['patrones-diseno'] = ... || { lessons: [] } — el validador lo detectó, fix aplicado, validate 0 failures, smoke 18/18.
**Why**: Usuario reportó cursos nuevos invisibles tras reiniciar + pidió git/github y patrones de diseño.
**Where**: apps/academy-web/index.html (cache-busting ?v=20260908b); apps/academy-web/data/courses/{git-github,patrones-diseno}/; apps/academy-web/data/courses.js (18 cursos).
**Learned**: (1) python http.server cachea JS en el browser — TODO release de cursos requiere bump del ?v= en index.html. (2) El cierre del content file DEBE tener las 2 líneas (init + push); el validador multi-course detecta el patrón roto. (3) El agente general funcionó bien esta vez (2 cursos completos, 20/20 node --check) pero siempre verificar con el validador central.

---
*Imported from Engram on 2026-09-09*
