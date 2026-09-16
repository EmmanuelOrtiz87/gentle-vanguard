---
created: 2026-09-15 22:29:32
tags: [engram, bugfix]
engram_id: 3938
type: bugfix
---

# Homologación shell: academy-crm migrado a single source + gate validate:shell + gotcha lightningcss

**What**: Cierre del pendiente de homologación (sesión 2026-09-15). (1) academy-crm migrado al shell.css del paquete gv-design-system (single source): main.tsx importa `packages/gv-design-system/src/shell/shell.css`, App.tsx usa patrón homologado `.gv-brand-wordmark` (antes copia local vieja con patrón `.gv-brand .name`), clases custom CRM (`.crm-nav/.crm-controls/.crm-main/.crm-page*`) movidas a styles.css, shell.css local eliminado. (2) Gate nativo `npm run validate:shell` (packages/gv-design-system/scripts/validate-shell.js) arreglado (bugs ESM: require/path/fs sin importar) + check corregido (verifica clases compartidas gv-lang-* y ausencia de claves por-app, NO gv-cc-lang en CSS que vive en JS) + registrado en package.json. PASS 4/4. (3) Gotcha lightningcss 1.33.0 (vite 8): mergea `backdrop-filter` + `-webkit-backdrop-filter` y emite SOLO el prefijo (Chromium moderno lo rechaza → computed none), sin importar targets. Fix nativo: declarar SOLO la propiedad estándar en src/shell/shell.css.
**Why**: El pendiente explícito de la sesión anterior era verificar en vivo los 3 fixes (wordmark blanco, botón idioma 13px, icono 文A) y academy-crm fallaba (14px). La causa raíz era una copia local vieja del shell. El hallazgo de backdrop-filter surgió al re-verificar tras la migración.
**Where**: packages/gv-design-system/src/shell/shell.css, scripts/validate-shell.js, package.json; apps/academy-crm/src/{main.tsx,App.tsx,styles.css} (apps/* gitignoreado en este repo); docs/stack-manual-full.md (3 entradas nuevas).
**Learned**: (a) lightningcss mergea la dupla estándar+-webkit- y conserva solo el prefijo — regla del stack: solo propiedad estándar en CSS. (b) `/apps/*` está gitignoreado: los cambios de apps no se commitean en este repo. (c) El check de un gate debe validar lo que vive en ese artefacto (clases CSS, no claves localStorage de JS). (d) Verificación final en vivo: archify/content-cms/academy-crm 13px + wordmark blanco + gradiente + backdrop blur OK. Commits: 4f5a52fc (homologación) + 033db066 (docs), push a develop OK.

---
*Imported from Engram on 2026-09-16*
