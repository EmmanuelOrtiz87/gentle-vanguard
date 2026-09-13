---
created: 2026-08-19 02:29:18
tags: [engram, bugfix]
engram_id: 2883
type: bugfix
---

# COE CMS fixes: edit/reset jobs + solid popup backgrounds

**What**: Resueltos los 2 bugs del CMS de marketing (docs/presentations/resources-index.html) reportados por el usuario: (1) ventanas popup con efecto translúcido, (2) imposibilidad de editar/reiniciar jobs del COE en estados finales.
**Why**: El usuario reportó que las popups (social-post, image-studio, video-studio, contract-viewer, product-doc-gentle) se veían translúcidas y que los jobs del Content Operations Engine no podían editarse ni reiniciarse una vez llegaban a MEASURED/PUBLISHED.
**Where**: docs/presentations/assets/js/coe-cms.js, docs/presentations/{social-post,image-studio,video-studio,contract-viewer,product-doc-gentle}.html
**Learned**:
- Bug 1: las 5 popups tenían body{background} pero NO html{background} → fondo blanco visible a través cuando el contenido es corto. Fix: html{background:var(--bg0)} en las 5. También alineé el overlay del modal showDetail de rgba(0,0,0,0.7)→0.85 (consistente con el modal de edición).
- Bug 2: MEASURED (estado final del COE) tenía TRANSITIONS: [] → sin salida. Fix: MEASURED:['DRAFT'], métodos reset(jobId) y edit(jobId)+saveEdit(jobId), _writeOverrides ampliado para persistir title/date/platform/theme/copy/cta en localStorage, helpers_escAttr/_escTextarea, botones Editar (todas filas) + Reiniciar (status≠DRAFT) en tabla y modal detalle.
- Commits: f393b022 (fixes) + 012d08d2 (artefactos pipeline). Pusheados a main + develop + sync public (2026-08-19).

---
*Imported from Engram on 2026-09-06*
