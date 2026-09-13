---
created: 2026-09-09 17:54:22
tags: [engram, decision]
engram_id: 3815
type: decision
---

# Academy purgada de vínculos externos (Demo + Prompt Studio)

**What**: Eliminados todos los vínculos a Demo y Prompt Studio de GV Academy. Academy es solo educación/capacitación. Cambios: nav sin "Demo" (queda Cursos + Glosario), hero sin botón Demo ni Prompt Studio (queda Cursos + Glosario), vista #/demo eliminada (~75 líneas), lightbox completo eliminado (~50 líneas + event listeners), i18n sin claves demo/lb*, router sin rama demo, CSS limpio (bloques DEMO GALERÍA, LIGHTBOX, IMG BLUR-UP eliminados de academy-layout.css y academy-motion.css, reduced motion limpio), index.html sin script demo-images.js.
**Why**: "Academy es una app solo de educacion y capacitacion, no deberiamos tener vinculos con otras apps" (usuario).
**Where**: apps/academy-web/app.js (nav, hero, i18n x3 locales, viewDemo, lightbox, bindEffects, router), apps/academy-web/index.html (nav, meta desc, script tag), apps/academy-web/academy-layout.css (bloque DEMO GALERÍA), apps/academy-web/academy-motion.css (bloques LIGHTBOX, IMG BLUR-UP, reduced motion refs).
**Learned**: (1) El diagrama SVG 'apps-map' del curso gentle-vanguard (línea 726 app.js) menciona "Prompt Studio" como parte de la arquitectura del stack — es contenido educativo, NO vínculo. Se dejó intencionalmente. (2) /apps/ es git-ignored por diseño — los cambios de academy son locales, no se commitean al repo del stack. (3) Verificación: Playwright 8/8 PASS (nav 2 items, hero 2 botones, sin 5176, #/demo → not-found, 20 cursos, glosario OK) + smoke 18/18 PASS + grep 0 referencias residuales.

---
*Imported from Engram on 2026-09-09*
