---
created: 2026-09-09 17:42:29
tags: [engram, pattern]
engram_id: 3814
type: pattern
---

# Feature catálogo academy: filtro por letra + buscador de cursos

**What**: Feature de catálogo en GV Academy: filtro por letra del abecedario + buscador de cursos en vivo. Toolbar con input de búsqueda (título+desc+id+tags), chips de letras A-Z + "Todas" (normaliza acentos: "Introducción"→I, "Páginas"→P), contador de resultados, estado vacío con "Limpiar filtros". i18n es/en/pt (5 cadenas nuevas). Verificado con Playwright: 11/12 PASS funcionales (el único "FAIL" fue expectativa errónea del test: hay 9 cursos con letra P, no 8 — 6 "P..." + 3 "Páginas Web").
**Why**: El usuario pidió poder filtrar/buscar cursos ya que academy creció a 20 cursos (~1000 lecciones).
**Where**: apps/academy-web/app.js (viewCourses + catalogSummaries/catalogQuery/catalogLetter + normalizeLetter/catalogFiltered/renderCatalogGrid/renderLetterChips), apps/academy-web/academy-components-v2.css (.catalog-toolbar, .catalog-search, .letter-chip, .catalog-empty)
**Learned**: (1) /apps/ está git-ignored en el repo del stack (commit 09ecd09e "apps untracked from stack repo") y academy-web NO tiene repo propio — los cursos y cambios de academy son locales por diseño. (2) Solo opencode.json y config/model-fallback.json se commitean al repo del stack (commit 9f504a5e). (3) La verificación funcional con Playwright (assertions DOM) es superior al screenshot para este modelo (no lee imágenes). (4) El patrón de estilos usa rgba(var(--gv-bg-deep-rgb), 0.7) para adaptarse a tema claro/oscuro.

---
*Imported from Engram on 2026-09-09*
