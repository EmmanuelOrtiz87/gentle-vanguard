---
created: 2026-08-08 05:18:34
tags: [engram, architecture]
engram_id: 2644
type: architecture
---

# Hotspots SVG interactivos en 5 diagramas + 105 claves multi-idioma

**What**: Implementados hotspots SVG interactivos en el libro de presentaciones (docs/presentations/). 35 zonas clicables totales: architecture-layers (6 gv-node convertidos), executive-loop (11), pipeline-flow (8), data-architecture (5), stack-dashboard (5). Cada hotspot abre el modal info multi-idioma (en/es/pt-BR) vía `window.__gvShowInfo(data-i18n-title)`.

**Why**: Los diagramas ampliados en el lightbox eran estáticos; se quería hacerlos interactivos reutilizando el patrón info-trigger `data-i18n-title` + diccionario `tip_*` ya nativo.

**Where**: docs/presentations/diagrams/*.svg (5 archivos), docs/presentations/assets/js/gv.js (initDiagramModal: carga SVG inline via fetch + delegación clicks .gv-hotspot + _*gvShowInfo), gv.css (.gv-lightbox-svg + .gv-hotspot), i18n.js (+105 claves tip_hs** ×3 idiomas). Scripts en .opencode/skills/presentations-maintenance/scripts/: homologate-svg.ps1 (gv-node→hotspot), inject-hotspots.ps1 (rects transparentes desde svg-zones.json), insert-zones.ps1 (aplana JSON + delega en insert-tips), cdp-verify-hotspots-all.cjs (verificación 4 diagramas × 3 idiomas).

**Learned**: (1) `"\n"` en PowerShell es backslash-n literal, NO salto de línea — usar "`n". (2)`$args` es variable automática de PS — no usarla como nombre propio. (3) CDP `Runtime.evaluate` con returnByValue:true devuelve objeto YA deserializado — no hacer JSON.parse doble. (4) Interpolación en template literals de scripts CDP: usar `${var}`, nunca`' + var + '` (queda literal en navegador). (5) localStorage `gv-lang` persiste entre páginas CDP — forzar idioma base al inicio. (6) El repo es ESM ("type":"module") → scripts node con require('ws') deben ser .cjs.

---
*Imported from Engram on 2026-09-06*
