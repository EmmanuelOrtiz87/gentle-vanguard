# Plan de migración — v2 Premium + Logo v1 (oficial)

> Decisión: `docs/brand/BRAND-DECISION-2026-09-01.md`. Fuente de tokens:
> `docs/brand/TOKENS-v2.json`. Logo oficial: `assets/logo.svg` (monograma v1, gradiente v2).

## Etapa 0 — Consolidación (hoy) ✅

- [x] Decisión registrada (BRAND-DECISION-2026-09-01.md).
- [x] Logo oficial: forma v1 + gradiente v2 en `assets/logo.svg` + monos.
- [x] Design Hub: comparadores v1v2v3 → **Labs** (ocultos del nav principal).
- [x] Design Hub: UX de especialista (Save/Cancel/Close/Delete, modales, toasts, dirty state).

## Etapa 1 — Academy (app inicial) ✅ 2026-09-01

**Objetivo**: primera app 100% v2 premium + logo oficial, para validar el patrón de migración.

- [x] Activar CSS v2 existente en `index.html` (tokens→atmosphere→style→components +
      `academy-layout.css` para clases estructurales de app.js).
- [x] Logo oficial en topbar + favicon; `logo-horizontal.svg` con gradientes v2; 24 colores de
      diagramas SVG actualizados.
- [x] Verificación de tokens: 35/35 valores vs TOKENS-v2.json, 0 divergencias.
- [x] Regresión visual OK: home, lección, diagrama, glosario, móvil 390x844
      (`.runtime/academy-v2-*.png`); 0 colores v1 en CSS activos.

## Etapa 2 — Apps nativas ✅ 2026-09-02

Patrón por app: swap de custom properties de tema → logo oficial → grep de colores v1 → capturas
headless → build/smoke.

- [x] `web-dashboard` (:5173): override `src/styles/gv-tokens-v2.css`, eliminado
      `generated-tokens.css`+prebuild v1, heatmap→rampa cyan v2. Build 0 err, 5 capturas OK.
- [x] `gv-analytics` (:5174/:4754): ya v2 de sesión previa; validado (grep 0, 3 capturas OK). Fix:
      `packages/gv-design-system/dist/tokens.css` stale v3.0.0 resincronizado (rompía build
      lightningcss).
- [x] `content-cms` (:5175/:3787): favicon+theme-color, superficies/badges/PALETTE→v2. Build 0,
      capturas OK.
- [x] `prompt-studio` (:5176/:5177) · [x] `archify` (:5179/:4790): overrides v2, logos oficiales.
      Capturas OK.
- [x] `command-center` (:8090): `assets/gv-design-system.css` — custom properties `--gv-*`
      actualizadas a v2 (clases intactas); widget.js tokens v2; reiniciado. Captura grid OK.
- Verificación global: grep de 9 hex v1 en CSS activo = 0 en todas las apps; capturas en
  `.runtime/*-v2-*.png` (muestreo de píxeles: 0 azul v1).

## Etapa 3 — Design system canónico y docs oficiales ✅ 2026-09-02

- [x] `packages/gv-design-system` v2.0.0: `src/tokens/tokens.json` mapeado al canon v2 (solo
      valores, esquema/nombres `--gv-*` congelados + `meta.version` 2.0.0 y `meta.canon` →
      `docs/brand/TOKENS-v2.json`; adiciones canon: gold, bg-elevated, glass/glassBorder, text
      secondary/disabled, monoAccent, epic, smooth/outExpo — sin bounce). `build-tokens.ts`
      reescrito como CLI valida+regenera (cierra el gap de docs/design/03): src css/ts + dist
      css/ts/tailwind/figma/css-modules. Fixes: ya no se emite `--gv-$schema` (claves reservadas
      excluidas) y `dist/tokens.ts` inválido reemplazado por TS válido; `dist/` sin `#121212`
      (Orbitron solo como fallback de Space Grotesk). README: status oficial + logo oficial
      (`assets/logo.svg`). `package.json` → 2.0.0 (fix `build:tokens` → `src/cli/build-tokens.ts`;
      `scripts/build-tokens.mjs` ahora delega). MCP verificado por JSON-RPC stdio: `list_tokens`
      sirve v2 (#0f1115/#151921/#1a1f2a/#0891b2/gold) y `get_design_md` sirve el DESIGN.md
      actualizado (nota "Official since 2026-09-02 (BRAND-DECISION-2026-09-01)"); `sync.ts`
      re-mapeado al esquema real del JSON. Verificación: builds 0 err `gv-analytics` + `content-cms`
      (CSS construido sin #121212), `impeccable detect src/tokens/` → 0 issues, tsc sin errores
      nuevos (los de `src/components/*` son preexistentes).
- [x] `assets/gv-design-system.css` (legacy v1): congelado con header FROZEN que apunta al paquete
      canónico (sobrevive solo para shell primitives de apps estáticas: command-center,
      content-cms).
- [x] AGENTS.md / docs/brand/BRAND-GUIDELINES-v2.md: sección design-system v2 actualizada al canon
      oficial (fuera el "#121212/alpha deprecado"); guidelines con link a Design Hub + decisión.
- [x] Catalog del paquete: `apps/gv-design-system-catalog` ya no existe en el repo (eliminado
      previo); la referencia visual viva es el Design Hub (`apps/design-hub/`, :8095).

## Etapa 4 — Limpieza y cierre

- [ ] Borrar CSS v1 no referenciado tras migración (por app, con grep de verificación).
- [ ] Deprecar definitivamente gv-design-studio y gv-design-system-catalog (remover de repos en el
      siguiente major).
- [ ] Session-close: screenshots finales, memoria, commits.

## Reglas transversales

- Cada etapa = commits atómicos (`feat(brand): ...`), verificación visual obligatoria (screenshot +
  lectura), sin mezclar apps en un commit.
- Los tokens v2 son la única fuente; si un valor falta, se agrega al JSON (no hardcode en apps).
- Logo siempre desde `assets/logo.svg`; nunca SVGs inline duplicados.
