---
created: 2026-09-15 18:21:43
tags: [engram, bugfix]
engram_id: 3933
type: bugfix
---

# Fix shell visual homologación: wordmark Gentle blanco nativo + botón idioma 13px homologado + icono 文A (paquete compartido)

**Fix shell visual homologación — cierre (2026-09-15)**.

**What**: 3 fixes nativos en el shell compartido (gv-shell.css del paquete gv-design-system) que se propagan a las 10 apps vía rebuild del paquete + `npm run shell:validate`:
1. **Wordmark "Gentle" blanco** (antes aplicaciones como archify lo pintaban cian/turquesa con su propio override en `App.css`, rompiendo el homologado). Fix: regla nativa con alta especificidad `.gv-brand-wordmark` (base blanca) + `.gv-brand-wordmark span` (solo "Vanguard" con gradiente, `-webkit-background-clip / background-clip / -webkit-text-fill-color`) + `!important` para vencer overrides por-app.
2. **Icono de idioma homologado `文A`** (13px, dropdown nativo `.gv-lang-dropdown` con claves compartidas `gv-cc-lang` y banderas 🇪🇸🇬🇧🇧🇷) — reemplaza los botones custom/icono equivocado que usaba gv-analytics (globo).
3. **Font-size del botón idioma fijo 13px** en el shell compartido (igual que academy-web/command-center/prompt-studio) — evita que el glifo sobresalga/agrande el botón en algunas apps (archify lo tenía a 14-15px).

**Where**: `packages/gv-design-system/src/shell/shell.css` (reglas `.gv-brand-wordmark`, `.gv-lang-dropdown .gv-icon-btn`, font-size). Build paquete: OK. `validate.js` (Design Hub): PASS. Smoke test Playwright: archify (8097) wordmark blanco + lang dropdown + font-size 13px verificados en vivo; academy-crm (8099) lang/theme ok; gv-analytics build ok.

**Learned** (absorbido nativo para no repetir): el problema de fondo NO era el CSS por-app sino el **override hardcodeado en App.css de cada app** (`ar-brand-name span`, `gv-*` con gradiente) que vencía al shell. Solución correcta = **fix en el fuente nativo del shell (1 solo archivo compartido) + alta especificidad + !important**, no editar App.css por app (eso rompía la homologación). Regla: "TODO overriding de identidad visual va en el shell compartido, NO en App.css de la app". Para apps en vivo navegadas con Playwright: usar SIEMPRE `playwright-cli goto http://127.0.0.1:<port>/` + `playwright-cli eval` para verificar sin abrir ventanas fantasma (documentado en docs/stack-manual-full.md §Playwright nativo).

---
*Imported from Engram on 2026-09-15*
