---
created: 2026-08-07 18:00:39
tags: [engram, pattern]
engram_id: 2623
type: pattern
---

# Reconstrucción presentaciones con design system gv.css/gv.js

**What**: Modernicé docs/presentations/architecture.html y quickstart.html con el nuevo design system compartido (gv.css v2.0 + gv.js v2.0), siguiendo el patrón de index.html.
**Why**: Tarea solicitada: eliminar bloques <style> duplicados y actualizar datos reales del stack.
**Where**: docs/presentations/architecture.html, docs/presentations/quickstart.html
**Learned**:
- gv.css ya cubre: section-card, hero, glow, nav-blur, fade-in, stat-n, badge-gv/*, feature-table, info-trigger, arch-layer, progress-bar-custom/fill, section-title, cmd-block, flow-step/arrow, card-glow, gv-timeline, bento, marquee, tilt, svg-diagram, btn-gv/alt, scroll-progress, aurora, hero-badge.
- En architecture.html conservé SOLO .card-dao y .sh en el <style> específico. En quickstart.html solo .step-num y .table-cmd.
- Patrón body: <body class="grain"> + .scroll-progress + .aurora (3 spans).
- gv.js reemplaza el IntersectionObserver inline (initReveal) — eliminar script inline.
- gv.js va DESPUÉS de bootstrap.bundle.min.js; i18n.js se mantiene en <head>.
- Datos actualizados: v3.5.0, 328 TS, 97 tests, 112/112 health (18 comp), 21 agents, 170 skills, 65 norm, 101 enabled/70 lazy (31 Phase 1 paralelos), CodeGraph 10663/21746/677, Engram 2078 obs, Graphify 18MB, Nexus 11 repos/7 mig/21 tablas.
- OJO prettier: cierra tags multi-línea como `</span\n>`; al validar balance hay que tolerar whitespace dentro de tags (regex con /gs), si no da falsos positivos.

---
*Imported from Engram on 2026-09-06*
