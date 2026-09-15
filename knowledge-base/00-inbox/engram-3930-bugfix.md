---
created: 2026-09-15 18:17:06
tags: [engram, bugfix]
engram_id: 3930
type: bugfix
---

# 3 fixes homologación visual nativos en shell.css (wordmark blanco + icono idioma 文A + font 13px)

**3 fixes de homologación visual — aplicados NATIVOS en shell.css compartido (paquete gv-design-system)**:

1. **Wordmark "Gentle-Vanguard"**: `.gv-brand-wordmark` → "Gentle" SIEMPRE blanco (`.gv-brand-wordmark` color base blanco) + `.gv-brand-wordmark span` (solo "Vanguard") con el gradiente oficial. Reglas con `!important` + especificidad alta para vencer overrides por-app (archify pintaba "Gentle" cian por un `.gv-brand-wordmark span` propio). Fix nativo → se propaga a las 10 apps homologadas, sin tocar cada App.css.

2. **Icono idioma homologado**: `.gv-lang-dropdown` comparte el patrón `文A` (glifo GV canónico) con `.gv-lang-check` (✓) y `.gv-icon-btn` — ya es el estándar en el shell compartido para es/en/pt.

3. **Font-size del botón idioma homologado 13px**: `.gv-lang-dropdown .gv-icon-btn` fijado a `font-size: 13px` para que NO sobresalga ni cubra el botón en ninguna app (archify tenía 14px+, rompía el layout del topbar).

**Verificación**: `npm run build` del paquete ✅ (build:mcp tsc + shell dist). Servidores dev de 8097/8098/8099 terminados (ventanas fantasma cerradas). Cada app se levanta nativamente con su `start.sh` al operar.

**Aprendizaje nativo para el stack**: para cambiar la identidad visual compartida (wordmark, idioma, tema) en TODAS las apps a la vez → editar ÚNICAMENTE el CSS/JS del paquete `packages/gv-design-system` (shell.css/shell.js) y rebuild del paquete; las apps homologadas que importan del paquete lo absorben automáticamente. NO editar los App.css por-app (eso era lo que rompía la homologación).

---
*Imported from Engram on 2026-09-15*
