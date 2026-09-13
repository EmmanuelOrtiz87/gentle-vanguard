---
created: 2026-09-07 12:32:15
tags: [engram, architecture]
engram_id: 3774
type: architecture
---

# Academy: cursos agentes-ia y marketing-ia completados (7 cursos, 467 lecciones)

**What**: Se completaron los 2 cursos nuevos de apps/academy-web (agentes-ia y marketing-ia, 8 tracks × 6 lecciones = 48 cada uno), replicando el patrón del curso gemini. La academia quedó con 7 cursos y 467 lecciones, validador 100% PASS y smoke test 18/18 PASS (http + file).

**Why**: El usuario pidió terminar los 2 cursos pendientes y potenciar el stack operando con todas las herramientas.

**Where**: apps/academy-web/data/courses/agentes-ia/ (course.json, tracks.js, i18n.js, glossary.js, 8 content files), apps/academy-web/data/courses/marketing-ia/ (ídem), apps/academy-web/data/courses.js (registry regenerado), apps/academy-web/scripts/smoke-academy.mjs (actualizado), apps/academy-web/scripts/validate-multi-course.mjs (referencia).

**Learned**:
1. GOTCHA CRÍTICO: el validador y app.js exigen el footer de agregación `window.GV_CONTENT['<course-id>'] = window.GV_CONTENT['<course-id>'] || { lessons: [] }; window.GV_CONTENT['<course-id>'].lessons.push(...window.GV_CONTENT['<track>'].lessons);` al final de CADA content file. Sin él, el validador reporta "0 lecciones" (clave del curso, no del track). Script usado: C:\Users\emman\AppData\Local\Temp\opencode\add-course-footer.mjs.
2. GOTCHA de rutas: el router de app.js tiene Legacy Redirects que redirigen `#/lesson/<cid>/<track>/<lesson>` a `#/course/gentle-vanguard/lesson/...`. Las rutas modernas correctas son `#/course/<cid>/lesson/<track>/<lesson>`. El smoke test original usaba rutas legacy → falsos positivos (el título del curso aparece en el breadcrumb). Corregido con checks robustos (títulos reales de lecciones).
3. Formato de content files: strings md en UNA línea física con \n literales, sin comillas dobles dentro del md, syntax check inmediato tras cada write con $LASTEXITCODE (PowerShell no captura exit codes con try/catch).
4. data/courses.js es GENERADO por scripts/build-courses-registry.mjs (no editar a mano); smoke-academy.mjs hardcodea cards === 7 y stat === '7'.

---
*Imported from Engram on 2026-09-08*
