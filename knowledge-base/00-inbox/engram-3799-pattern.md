---
created: 2026-09-09 02:42:26
tags: [engram, pattern]
engram_id: 3799
type: pattern
---

# Cursos GV Academy: alfabetizacion-digital, sql, pl-sql creados (138 lecciones)

**What**: 3 cursos nativos GV Academy creados en apps/academy-web/data/courses/ siguiendo el contrato .opencode/skills/academy-course-authoring/SKILL.md: alfabetizacion-digital (8 tracks, 54 lecciones, 38 términos de glosario), sql (7 tracks, 46 lecciones, 32 términos), pl-sql (6 tracks, 38 lecciones, 32 términos). 33 archivos: course.json + tracks.js + content-*.js + glossary.js + i18n.js por curso. estimatedHours 14/16/14, version 1.0.0, language es, sin :::diagram (omitidos por regla del contrato).
**Why**: Petición explícita de autoría de contenido didáctico completo (3 cursos) con verificación node --check obligatoria antes de terminar; el registry central (build-courses-registry.mjs) se corre después, centralizado.
**Where**: apps/academy-web/data/courses/{alfabetizacion-digital,sql,pl-sql}/
**Learned**: GOTCHA crítico: al escribir content-*.js vía Write tool, los \n dentro de los strings JSON "md" a veces se emiten como saltos de línea REALES (96 casos en los 13 archivos de contenido de sql/pl-sql), rompiendo la sintaxis JS. Solución: sanitizador Node (scan de strings "md" con escape-tracking que reemplaza saltos reales por \n) guardado en C:\Users\emman\AppData\Local\Temp\opencode\fix-md-newlines.mjs — correrlo SIEMPRE tras escribir content-*.js antes del node --check. Verificación adicional: script verify-courses.mjs (vm sandbox con window shim) que valida conteo de lecciones por track, unicidad de ids, glosario e i18n 3-locales con key por track.

---
*Imported from Engram on 2026-09-09*
