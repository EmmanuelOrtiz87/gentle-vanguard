---
created: 2026-09-07 10:40:19
tags: [engram, architecture]
engram_id: 3772
type: architecture
---

# Curso gemini completado — 48 lecciones, 100% validado

**What**: Curso "gemini" completado en apps/academy-web (8 tracks × 6 lecciones = 48, ~14h, plan gratis de Google). Validador `node scripts/validate-multi-course.mjs` → 100% PASS con 5 cursos (365 lecciones: 103+96+69+49+48). Verificación final: 48 lessons con heading `##`, 0 typos `::>`, 3 diagramas existen en app.js DIAGRAMS (gemini-workspace→google-apps, productivity-stack→proyectos, ai-tools-ecosystem→futuro).

**Why**: Completar la academia con un curso práctico de Gemini gratis, replicando la estructura de los 4 cursos existentes.

**Where**: apps/academy-web/data/courses/gemini/ — tracks.js, 8 content-*.js, glossary.js (21 términos), i18n.js (es/en/pt), course.json. Registrado en data/courses.js. Scripts de diagnóstico en C:\Users\emman\AppData\Local\Temp\opencode\ (find-stray-quotes.mjs, check-md-endings.mjs, fix-md-newlines.mjs, verify-gemini-final.mjs).

**Learned**:
1. GOTCHA CRÍTICO: strings `md` en content-*.js deben estar en UNA sola línea física con `\n` literales (backslash-n). Newlines reales dentro de un string JS de comillas dobles = SyntaxError "Invalid or unexpected token". El tool write puede insertar newlines reales en secciones largas (checklist) → verificar SIEMPRE con syntax check inmediato tras escribir.
2. La comilla de cierre del string md es la PRIMERA `"` después de `"md": "` (el contenido no debe tener comillas dobles — usar comillas simples dentro del md). El cierre puede ser el último char de la línea, con `,` en la línea siguiente.
3. PowerShell NO captura exit codes con try/catch — usar `$LASTEXITCODE` tras node.
4. Línea `"md":` válida = exactamente 4 comillas dobles (`"md"` + apertura + cierre).

---
*Imported from Engram on 2026-09-08*
