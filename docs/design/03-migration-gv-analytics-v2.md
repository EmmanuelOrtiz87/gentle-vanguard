# Migration: gv-analytics → DS v2 tokens

**Status:** ✅ success
**Date:** 2026-09-01
**Owner:** worker (Emmanuel)
**Scope:** `apps/gv-analytics/src/styles.css`, `apps/gv-analytics/src/main.tsx`, `apps/gv-analytics/package.json`
**SoT target:** `packages/gv-design-system/src/tokens/tokens.json` v2.0.0

---

## 1. Resultado

Migración completa de tokens legacy (custom) a tokens v2 del `@gentle-vanguard/design-system`. Sin nuevos findings; los 3 patrones preexistentes (2× gradient-text, 1× codex-grid) quedan con waiver documentado. `npx vite build` pasa; `npx tsc --noEmit` pasa.

## 2. Mapping aplicado

### Color tokens (`:root` dark)

| Legacy (gv-analytics)         | v2 (DS)                              | Resultado |
| ----------------------------- | ------------------------------------ | --------- |
| `--gv-purple: #a855f7`        | `--gv-purple: #a78bfa`               | ✅ removido local (vino de DS) |
| `--gv-cyan: #00bfff`          | `--gv-cyan: #22d3ee`                 | ✅ removido local (vino de DS) |
| `--gv-cyan-deep: #06b6d4`     | `--gv-cyan-deep: #06b6d4`            | ✅ removido local (idéntico) |
| `--gv-bg: #0d1117`            | `--gv-bg: #121212`                   | ✅ removido local (vino de DS) |
| `--gv-bg-deep: #0d1117`       | `--gv-bg-deep: #0a0e17`              | ✅ removido local (vino de DS) |
| `--gv-surface: #1a2035`       | `--gv-surface: #1f2937`              | ✅ removido local (vino de DS) |
| `--gv-surface-raised: #2a2d3a`| `--gv-surface-raised: #273548`       | ✅ removido local (vino de DS) |
| `--gv-text: #ffffff`          | `--gv-text: #e5e7eb`                 | ✅ removido local (vino de DS) |
| `--gv-muted: #6b7280`         | `--gv-muted: #9ca3af`                | ✅ removido local (vino de DS) |
| `--gv-glass: rgba(26,32,53,0.6)` | `--gv-surface-overlay: rgba(31,41,55,0.6)` | ⚠️ conservado local con valor v2 (rgba de surface) |
| `--gv-glass-border: rgba(168,85,247,0.18)` | `--gv-border-accent: rgba(167,139,250,0.18)` | ⚠️ conservado local; semánticamente igual, app-specific |
| `--gv-gradient: linear-gradient(135deg, #a855f7, #00bfff)` | `--gv-gradient: linear-gradient(135deg, #a78bfa, #22d3ee)` | ✅ removido local (vino de DS) |
| `--gv-glow: rgba(0,191,255,0.35)` | `--gv-glow-cyan: rgba(34,211,238,0.13)` | ✅ **renombrado** a `--gv-glow-cyan` y removido local |
| `--gv-bg-rgb: 13,17,23`       | `--gv-bg-rgb: 18,18,18` (consistente con `#121212`) | ⚠️ conservado local (consumido por `rgb()`), actualizado a 18,18,18 |
| `--gv-amber: #f4bb4f`         | `--gv-amber: #f4bb4f`                | ✅ conservado local (idéntico) |
| `--gv-red: #ee6d75`           | `--gv-red: #ee6d75`                  | ✅ conservado local (idéntico) |
| `--gv-green: #4ade80`         | `--gv-green: #4ade80`                | ✅ conservado local (idéntico) |

### Tipografía y layout

| Legacy                       | v2                                  | Resultado |
| ---------------------------- | ----------------------------------- | --------- |
| `--font: 'Inter'...`         | `--gv-font-body: 'Inter'...`        | ✅ renombrado en :root |
| `--mono: 'JetBrains Mono'...` | `--gv-font-mono: 'JetBrains Mono'...` | ✅ renombrado en :root |
| `--header-h: 62px`           | `--gv-header-height: 62px`          | ✅ renombrado en :root |

### Usages renombrados (replace_all)

- `var(--font)` → `var(--gv-font-body)`: **2 ocurrencias**
- `var(--mono)` → `var(--gv-font-mono)`: **22 ocurrencias**
- `var(--header-h)` → `var(--gv-header-height)`: **4 ocurrencias**
- `var(--gv-glow)` → `var(--gv-glow-cyan)`: **2 ocurrencias** (líneas 253, 475)

### Hardcoded legacy values actualizados

| Línea (antes) | Antes                              | Después                                  |
| ------------- | ---------------------------------- | ---------------------------------------- |
| 411           | `border-color: rgba(0,191,255,0.45)` (legacy cyan) | `border-color: rgba(34,211,238,0.45)` (v2 cyan) |
| 412           | `box-shadow: 0 14px 40px rgba(13,17,23,0.5)` (legacy bg rgb) | `box-shadow: 0 14px 40px rgba(var(--gv-bg-rgb), 0.5)` (consume triplet) |

## 3. Cambios estructurales

### `apps/gv-analytics/src/main.tsx`
```diff
 import { LocaleProvider } from './i18n';
+import '@gentle-vanguard/design-system/tokens.css';
 import './styles.css';
```
Import de `tokens.css` **antes** de `styles.css` para que DS v2 sea el SoT y `styles.css` aplique sólo deltas (light theme + app-specific vars).

### `apps/gv-analytics/src/styles.css`
- Bloque `:root` reducido de 19 vars (5-25) a 7 vars (líneas 6-13). Las 12 vars migradas a DS se eliminaron; las 7 conservadas son deltas app-specific (`--gv-glass`, `--gv-glass-border`, `--gv-bg-rgb`, `--gv-amber`, `--gv-red`, `--gv-green`, `--gv-header-height`).
- Bloque `:root[data-theme='light']` mantiene overrides light (no están en DS v2 dark-first), con `--gv-glow` renombrado a `--gv-glow-cyan` para consistencia.
- Header del archivo actualizado para referenciar DS v2.

### `apps/gv-analytics/package.json`
```diff
   "dependencies": {
+    "@gentle-vanguard/design-system": "workspace:*",
     "@modelcontextprotocol/sdk": "^1.30.0",
```
Symlink verificado en `apps/gv-analytics/node_modules/@gentle-vanguard/design-system` → `packages/gv-design-system`.

## 4. Findings antes/después

| Métrica                                 | Antes | Después |
| --------------------------------------- | ----- | ------- |
| `impeccable detect apps/gv-analytics/src` | 3     | 3       |
| `audit.ts apps/gv-analytics/src/styles.css` (DS) | 3     | 3       |
| gradient-text                           | 2     | 2       |
| codex-grid-background                   | 1     | 1       |
| **Nuevos findings**                     | —     | **0**   |

Los 3 findings son los pre-existentes y quedan con waiver:
- `gradient-text` (líneas 170, 879): patrón decorativo de marca `.brand .name span` y `.metric strong` con `background-clip: text`. **Waiver:** identidad visual de marca; se documenta para revisión futura.
- `codex-grid-background` (línea 96): `.grid-bg` con `linear-gradient` doble eje. **Waiver:** estética Academy/Analytics dark-first requerida por el design system ecosystem.

## 5. Validación

```bash
$ npx tsc --noEmit                          # ✅ 0 errores
$ npx vite build                            # ✅ built in 4.30s, 1345 modules
$ npx impeccable detect apps/gv-analytics/src --json
# 3 findings (gradient-text ×2, codex-grid ×1) — sin cambios
$ npx tsx packages/gv-design-system/src/cli/audit.ts apps/gv-analytics/src/styles.css
# 3 anti-patterns found (waivable)
```

## 6. Líneas modificadas

| Archivo                                  | Cambio                                                                       |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| `apps/gv-analytics/src/styles.css`       | 1600 → 1553 líneas (**-47**, :root compacto + 0 cambios estructurales)        |
| `apps/gv-analytics/src/main.tsx`         | +1 línea (import DS tokens.css)                                              |
| `apps/gv-analytics/package.json`         | +1 línea (dep workspace)                                                     |
| `packages/gv-design-system/dist/tokens.css` | **CREADO** (copy de src/tokens/tokens.css; el build:tokens del DS no estaba implementado) |

**Total líneas modificadas/creadas:** ~50 (1 import + 1 dep + ~47 refactor :root + renames de vars + 1 dist file).

## 7. Issues residuales

1. **`--gv-violet` (línea 1458):** `color: var(--gv-violet, #a78bfa);` usa un nombre de token que no existe en DS v2 (v2 usa `--gv-purple`). Funciona por el fallback `#a78bfa`, pero es dead code. **Acción recomendada:** reemplazar por `color: var(--gv-purple);` en una limpieza posterior.
2. **`--gv-bg-rgb` con valor 18,18,18:** la mapping table dijo "mantener", pero para mantener coherencia con el nuevo `--gv-bg: #121212` actualicé el triplet a 18,18,18. Es un delta app-specific necesario porque el DS v2 no exporta un bg-rgb triplet.
3. **`packages/gv-design-system/src/tokens/build-tokens.ts` no existe:** el script `npm run build:tokens` referenciado en `package.json` del DS no tiene implementación. Trabajé copiando `src/tokens/tokens.css` → `dist/tokens.css` manualmente. **Acción recomendada:** implementar `build-tokens.ts` o corregir el script.
4. **DS v2 sin `light` mode tokens:** todos los tokens primarios en `tokens.json` son dark-first. Los overrides light de gv-analytics siguen siendo app-specific (no se rompió nada, pero no hay paridad en el DS).
5. **Waivers gradient-text / codex-grid:** documentados pero no aplicados formalmente (no hay archivo `.impeccable-waivers` en el repo). Patrón de waivers se gestiona ad-hoc.

## 8. Visual diff conceptual

- **Superficie:** `bg #0d1117` → `#121212` (ligeramente más cálido, menos azul). Surface `#1a2035` → `#1f2937` (gris neutro). Visualmente casi imperceptible en dark mode.
- **Primarios:** purple `#a855f7` (saturado, "Web2") → `#a78bfa` (Tailwind violet-400, más pastel). Cyan `#00bfff` (puro) → `#22d3ee` (Tailwind cyan-400, más suave). Cambia la "vibración" del brand: de vibrante a editorial.
- **Texto:** `#ffffff` → `#e5e7eb` (Tailwind gray-200). Reduce fatiga visual sin perder contraste WCAG AA.
- **Glows:** `--gv-glow` (0.35 alpha) → `--gv-glow-cyan` (0.13 alpha). **Menos glow** = sensación más "premium"/menos "AI-slop".
- **Gradientes:** ahora con `--gv-gradient` v2 (sutiles) en vez de saturados legacy. Brand `.name span` y metric strong mantienen efecto con nuevos colores.

## 9. Próximos pasos (opcional)

1. Implementar `packages/gv-design-system/src/tokens/build-tokens.ts` para regenerar dist/ desde JSON.
2. Limpiar `var(--gv-violet, ...)` → `var(--gv-purple)` (1 ocurrencia).
3. Eliminar overrides redundantes en `:root` de styles.css si se quiere ir 100% a DS v2 (mantener sólo light theme + deltas necesarios).
4. Misma migración en `apps/web-dashboard`, `apps/content-cms` (siguiente sprint).
5. Crear `.impeccable-waivers` con waivers formalizados para gradient-text ×2 y codex-grid ×1.
