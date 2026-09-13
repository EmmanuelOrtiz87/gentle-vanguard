---
created: 2026-08-08 04:28:09
tags: [engram, architecture]
engram_id: 2640
type: architecture
---

# Homologación info-triggers en 6 páginas + modales multi-idioma

**What**: Homologación completa de info-triggers en TODO el libro de presentaciones: 149 tds → `span + info-trigger` en 6 páginas (agents-pipeline 33, health 48, operations-cloud 6, quickstart 13, security-governance 49) + generación automática de 435 claves `tip_c_*` (145×3 idiomas) en i18n.js desde i18n-content.js. Verificado en Chrome real (CDP): modales traducidos EN/ES correctamente. Commit 78f57049.

**Why**: El usuario pidió operar con todas las herramientas y absorber conocimiento nativo; los modales multi-idioma eran el estándar del stack (index.html ya los tenía), las demás páginas no.

**Where**: docs/presentations/{agents-pipeline,health,operations-cloud,quickstart,security-governance}.html; docs/presentations/assets/js/i18n.js (693 claves tip_= 48 genéricos + 38 fm + 145 c_ ×3 idiomas); .opencode/skills/presentations-maintenance/scripts/{homologate-pages.ps1, gen-tips-c.ps1 (nuevos), dedupe-i18n.ps1 (fix)}; SKILL.md (gotcha #10 + flujo completo).

**Learned**: (1) GOTCHA DOBLE CONVENCIÓN: i18n.js declara bloques `en: {`, `es: {`, `'pt-BR': {` (pt-BR CON comillas simples) mientras i18n-content.js usa `__GV_CONTENT.en = {`, `__GV_CONTENT['pt-BR'] = {` (corchetes). Regex que asume un solo formato rompe: recorrer todos los bloques sobrescribe con el último (pt-BR); buscar fin de bloque con formato equivocado captura todo el resto del archivo. Fix: extraer bloque `en` delimitado entre su apertura y el siguiente bloque. (2) Mi propio dedupe-i18n.ps1 reportó 353 "duplicados fantasma" en es por este bug — probar SIEMPRE los scripts en seco y verificar conteos. (3) El validador estructural no captura el idioma del modal; solo CDP lo confirma (modal ES muestra "Servidor WS del Dashboard..."). (4) Estado sano i18n.js: 353 claves/bloque en/es, 357 pt-BR (4 extra de window.__i18n, benignas). (5) `node cdp-verify-page.js --page=X.html` requiere `--page=` con signo igual (el script usa startsWith('--page=')).

---
*Imported from Engram on 2026-09-06*
