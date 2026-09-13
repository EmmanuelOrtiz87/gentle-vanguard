---
created: 2026-09-08 16:00:12
tags: [engram, bugfix]
engram_id: 3785
type: bugfix
---

# Fixes identidad v2.0: favicon gradient, ancho 1180px, Brand Editor

**What**: Fixes aplicados tras feedback del usuario sobre la identidad v2.0: (1) favicon con gradiente ahora usa monograma blanco sobre fondo gradiente 2-stop (como el oficial app-icon-gradient.svg), (2) homologación del ancho del Design Hub a 1180px (topbar + main + footer), (3) renombrado "v3 Editor" → "Brand Editor" para edición permanente general.
**Why**: El usuario validó la identidad v2.0 pero reportó que el favicon con gradiente no se veía bien, que el gv-topbar-inner tenía ancho inconsistente con otras apps, y que la capacidad de edición debía ser permanente (no solo para v3).
**Where**: apps/design-hub/src/asset-generator/index.html (favicon fix + precarga gv-white.svg), apps/design-hub/src/styles/main.css (1180px en 3 lugares), apps/design-hub/src/scripts/shell.js (Brand Editor), apps/design-hub/src/v3-editor/index.html (título Brand Editor), apps/design-hub/index.html (tarjeta Brand Editor), docs/adr/ADR-0033 (actualizado)
**Learned**:
- El favicon oficial con gradiente usa monograma BLANCO sobre gradiente 2-stop (#6E4DEB → #06B6D4), no monograma con gradiente sobre fondo gradiente
- El estándar canónico de ancho es 1180px (assets/gv-design-system.css y academy-web); web-dashboard usa 1500px (excepción)
- Verificado por muestreo de píxeles: centro del favicon gradient = #FFFFFF, topbar y main = 1180px
- validate.js pasa con 0 failures después de los cambios

---
*Imported from Engram on 2026-09-08*
