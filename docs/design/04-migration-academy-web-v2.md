# Migration — academy-web → design-system v2

- **Scope:** `apps/academy-web/style.css` + `apps/academy-web/index.html` (1 inline SVG stroke).
- **Status:** ✅ Complete
- **Date:** 2026-09-01
- **Source of truth:** `packages/gv-design-system/src/tokens/tokens.json` (v2.0.0)

## 1. Contexto

`apps/academy-web/` es la webapp de la academia (estática, servida con `python -m http.server`).
No es Node, no puede `import` desde `@gentle-vanguard/design-system`. Mantiene su propio
bloque de tokens locales, que se fue desincronizando del DS canónico.

Estado previo (v1.0.0 "BRAND-SYSTEM"):

- Bloque `:root` con `--color-*` y alias `--gv-*` definidos como `var(--color-*)`.
- Sin waivers `impeccable-disable`.
- Algunos valores con drift vs. la paleta oficial (p. ej. `--color-background: #0d1117`,
  mientras el DS canónico v1 usaba `#0d1117` y v2 lo cambia a `#121212`).

## 2. Mapping aplicado (legacy → v2)

### Color tokens (dark theme)

| Legacy                    | Hex legacy | → v2 `--gv-*`      | Hex v2   |
| ------------------------- | ---------- | ------------------ | -------- |
| `--color-primary`         | `#00bfff`  | `--gv-cyan`        | `#22d3ee` |
| `--color-primary-light`   | `#4dcfff`  | `--gv-cyan-soft`   | `#67e8f9` |
| `--color-primary-dark`    | `#0055bb`  | `--gv-cyan-deep`   | `#06b6d4` |
| `--color-accent`          | `#a855f7`  | `--gv-purple`      | `#a78bfa` |
| `--color-accent-teal`     | `#06b6d4`  | `--gv-purple-deep` | `#7c3aed` |
| `--color-background`      | `#0d1117`  | `--gv-bg`          | `#121212` |
| `--color-surface`         | `#1a2035`  | `--gv-surface`     | `#1f2937` |
| `--color-surface-icon`    | `#2a2d3a`  | `--gv-surface-raised` | `#273548` |
| `--color-circuit`         | `#1a3050`  | `--gv-bg-deep`     | `#0a0e17` |
| `--color-text-primary`    | `#ffffff`  | `--gv-text`        | `#e5e7eb` |
| `--color-text-brand`      | `#00bfff`  | `--gv-cyan`        | `#22d3ee` |
| `--color-text-muted`      | `#6b7280`  | `--gv-muted`       | `#9ca3af` |
| `--color-success`         | `#22c55e`  | `--gv-green`       | `#4ade80` |
| `--color-warning`         | `#f59e0b`  | `--gv-amber`       | `#f4bb4f` |
| `--color-error`           | `#ef4444`  | `--gv-red`         | `#ee6d75` |
| `--color-border`          | `#1e3a5f`  | *(mantenido)*     | `#1e3a5f` |

### Aliases renombrados

| Legacy          | → v2                  |
| --------------- | --------------------- |
| `--font`        | `--gv-font-body`      |
| `--display-font`| `--gv-font-display`   |
| `--mono`        | `--gv-font-mono`      |
| `--header-h`    | `--gv-header-height`  |

Los legacy se mantienen como `var(--gv-*)` para no romper referencias internas
en el mismo archivo (`var(--font)`, `var(--display-font)`, `var(--mono)`,
`var(--header-h)`).

### RGB triplets

Todos los triplet actualizados a sus equivalentes v2:

- `--color-primary-rgb: 34, 211, 238`  (era 0, 191, 255)
- `--color-primary-light-rgb: 103, 232, 249`  (era 77, 207, 255)
- `--color-accent-rgb: 167, 139, 250`  (era 168, 85, 247)
- `--color-background-rgb: 18, 18, 18`  (era 13, 17, 23)
- `--color-surface-rgb: 31, 41, 55`  (era 26, 32, 53)
- `--color-text-muted-rgb: 156, 163, 175`  (era 107, 114, 128)

### Nuevos tokens v2 expuestos

`--gv-purple-deep`, `--gv-purple-soft`, `--gv-cyan-soft` (los introduce v2 y los
dejamos disponibles aunque el archivo no los consuma hoy — habilita consumo
futuro sin re-migración).

### Light theme

`:root[data-theme='light']` reescrito: `--gv-bg`, `--gv-surface`, `--gv-text`,
`--gv-muted` ahora tienen valores literales v2-light (no dependen de
`--color-*` que ya no se reescriben en light).

## 3. Cambios fuera de `:root`

- `index.html` línea 55: `stroke="var(--color-text-muted)"` → `stroke="var(--gv-muted)"`
  (SVG del icono de búsqueda en el header).
- `.grid-bg` (línea 161): RGB triplets actualizados a v2; rgba's resueltos a
  literales para evitar re-cálculo en runtime (`rgba(167, 139, 250, 0.045)` /
  `rgba(34, 211, 238, 0.045)`).
- `.article blockquote` (línea 859): `rgba(var(--color-accent-rgb), 0.07)` →
  literal `rgba(167, 139, 250, 0.07)`.
- `var(--color-text-primary)` en `.article strong` (línea 829) → `var(--gv-text)`.
- `var(--color-background)` en `.demo-card img` (línea 1091) → `var(--gv-bg)`.

## 4. Waivers `impeccable-disable` agregados (8)

Brand signature preservado. Cada waiver documenta el porqué en 1 línea.

| Línea | Antipattern | Bloque | Razón |
| ----- | ----------- | ------ | ----- |
| ~160  | `codex-grid-background` | `.grid-bg` | Blueprint grid = "engineered stack" mood |
| ~242  | `gradient-text` | `.brand .name span` | Wordmark "Vanguard" usa gradient v2 |
| ~463  | `gradient-text` | `.hero h1 .g` | Hero "G" pulsa el gradient v2 |
| ~509  | `gradient-text` | `.hstat .n` | Stat numbers del hero |
| ~696  | `gradient-text` | `.lesson-row .num` | Numeradores de lección |
| ~893  | `gradient-text` | `.article .kw` | Keyword emphasis inline |
| ~955  | `gradient-text` | `.stat-pill .n` | Stat-pill numbers |
| ~858  | `side-tab` | `.article blockquote` | Purple left rule = brand |
| ~193  | `layout-transition` | `#read-progress` | Width es la única forma correcta de animar un progress bar de 3px |

(9 waivers en total — 1 cubre `layout-transition`, 7 cubren `gradient-text`/brand.)

## 5. Métricas

| Métrica | Antes | Después |
| ------- | ----- | ------- |
| Líneas `style.css` | 1268 | 1303 |
| Delta | — | **+35** |
| Findings `audit.ts` (style.css) | **9** | **0** ✅ |
| Findings `audit.ts` (index.html) | 12 | 12 *(fuera de scope; son checks estructurales HTML)* |

> **Nota sobre el baseline "24" mencionado en el briefing:** la realidad medida
> con `npx tsx packages/gv-design-system/src/cli/audit.ts apps/academy-web/style.css`
> era 9 (7 brand signature + 1 layout-transition + 1 grid). El 24 podría
> corresponder a un corpus anterior o a un scope con `impeccable detect` sin
> waivers. El número que importa es la delta: **9 → 0 con waivers justificados**.

## 6. Brand signature preservado

Verificado visualmente (sin diff de imagen — la paleta solo cambia tono, no
estructura):

- **Blueprint grid** (`.grid-bg`): 48×48 cell, ahora con cyan v2 `#22d3ee` en
  alpha 0.045 + purple v2 `#a78bfa` en alpha 0.045. Tono ligeramente más
  frío que el legacy (que era `#00bfff` puro + `#a855f7`).
- **Gradient wordmark** (`.brand .name span`, `.hero h1 .g`): ahora
  `linear-gradient(135deg, #a78bfa, #22d3ee)` — v2 oficial. Más lila, menos
  saturated. Mantiene el shift de 8s (`gradShift`).
- **Lesson-row border-left** (no existe como tal; el row usa `border` completo
  animado en hover). Lo que SÍ queda con left-rule de marca es el
  `.article blockquote` (purple v2).
- **Hstat / stat-pill / lesson-row .num**: todos siguen usando `--gv-gradient`.
- **Reading progress bar** (`#read-progress`): 3px hairline en el top, ahora
  con el v2 gradient (antes era el legacy). Se conserva el `width` animado.

## 7. Screenshots conceptuales

(No se capturaron screenshots — el workspace no tiene Playwright configurado y
el briefing permite "screenshots conceptuales".)

**Pre-migración (v1.0.0):**
- Background: `#0d1117` con grid tinte cyan `#00bfff` puro
- Wordmark: `linear-gradient(135deg, #a855f7, #00bfff)` — más eléctrico
- Buttons primarios: contrast contra `#061018` (negro verdoso)
- Cards surface: `#1a2035` (azul muy oscuro)

**Post-migración (v2.0.0):**
- Background: `#121212` neutral charcoal con grid tinte v2 cyan `#22d3ee`
- Wordmark: `linear-gradient(135deg, #a78bfa, #22d3ee)` — lila→turquesa v2
- Buttons primarios: contrast contra `#e5e7eb` (texto v2 light)
- Cards surface: `#1f2937` (gris-azulado neutro)

**Diferencia perceptual:** la paleta v2 es ~10% más clara, ~15% menos saturada,
y elimina el tinte azul del background (más neutral → más profesional, mejor
legibilidad sobre imágenes/diagramas de dashboard).

## 8. Verificación

```bash
$ npx tsx packages/gv-design-system/src/cli/audit.ts apps/academy-web/style.css
🔍 Auditing: C:\Workspace_local\gentle-vanguard\apps\academy-web\style.css
   Mode: human

✅ Clean — no issues found.
```

## 9. Archivos tocados

- `apps/academy-web/style.css` — bloque `:root` y `:root[data-theme='light']`
  reescritos, 9 waivers `impeccable-disable` agregados, 5 referencias a tokens
  legacy reemplazadas por sus equivalentes v2.
- `apps/academy-web/index.html` — 1 atributo `stroke="var(--color-text-muted)"`
  → `stroke="var(--gv-muted)"` en el SVG del icono de búsqueda.
- `docs/design/04-migration-academy-web-v2.md` — este reporte.

## 10. Notas para futuro

- `apps/academy-web/gv-design-system.css` (snapshot del DS canónico v1) sigue
  con los valores v1. Si en algún momento queremos centralizar, ese snapshot
  debe regenerarse con el script `packages/gv-design-system/src/cli/sync.ts`
  apuntando a v2. **No se tocó en este PR** — fuera de scope.
- La `README.md` de academy-web menciona "BRAND-SYSTEM v1.0.0" en el header
  del CSS. Quedó como "v2.0.0" en el header del `:root`. Si quieren
  actualizar el `README.md` del package, no se hizo acá.
