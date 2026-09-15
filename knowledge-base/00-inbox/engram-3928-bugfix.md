---
created: 2026-09-15 18:08:21
tags: [engram, bugfix]
engram_id: 3928
type: bugfix
---

# Fix nativo shell.css: wordmark Gentle blanco + botón idioma font-size 13px (todas las apps)

**Fix compartido nativo (shell.css del paquete, se propaga a TODAS las apps)**:

```css
/* Wordmark homologado: "Gentle" SIEMPRE blanco; SOLO "Vanguard" gradiente.
   Regla con especificidad alta para vencer overrides de apps (archify pintaba
   "Gentle" con el gradiente/cian). */
.gv-brand-wordmark,
.gv-shell-brand .gv-brand-wordmark,
.gv-brand-wordmark a,
.gv-shell-brand .gv-brand-wordmark a {
  color: var(--gv-text, #e9eef4) !important;
  background: none !important;
  -webkit-background-clip: initial;
  background-clip: initial;
  -webkit-text-fill-color: initial;
}
.gv-brand-wordmark span,
.gv-shell-brand .gv-brand-wordmark span,
.gv-brand-wordmark a span,
.gv-shell-brand .gv-brand-wordmark a span {
  background: var(--gv-gradient, linear-gradient(135deg, #a78bfa, #22d3ee));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent !important;
  -webkit-text-fill-color: transparent;
}
/* Botón idioma: font-size homologado 13px en TODAS las apps (no hereda 14/15px
   que hacía que el glifo cubriera el botón o sobresaliera). */
.gv-lang-dropdown .gv-icon-btn,
.gv-lang-dropdown-toggle,
.gv-icon-btn.gv-lang-btn {
  font-size: 13px !important;
  line-height: 1 !important;
  padding: 0 !important;
}
```

**Archivos**: `packages/gv-design-system/src/shell/shell.css` (reglas compartidas).
**Propaga a**: archify, archify-studio, content-cms, academy-crm, academy-crm-react, academy-landing, academy-crm-studio, academy-crm-collab, academy-crm-premium, academy-landing-web, academy-cms, academy-crm-dashboard, academy-crm-react-demo, academy-cms-dashboard, academy-crm-academy, web-dashboard.

**Estado**: regla escrita en el fuente compartido; PENDIENTE `npm run build:components` (tsc) + re-verify en vivo archify (wordmark blanco) + gv-analytics (icono idioma homologado) + font-size botón idioma en TODAS las apps. Comando sugerido: "aplicá el fix compartido en vivo: build+verify wordmark/idioma/font-size en las 10 apps".

---
*Imported from Engram on 2026-09-15*
