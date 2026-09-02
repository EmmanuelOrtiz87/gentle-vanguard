# ADR-0026 — `gv-design-system/`: consolidar 4 design systems divergentes en 1, exponer via MCP

## Status

proposed

- **Date**: 2026-09-01
- **Author**: mavis (root) — sesión del usuario
- **Relacionado**: ADR-0017 (local-first), `docs/brand/UI-STANDARD-ECOSYSTEM.md` v1.0.0,
  `AGENTS.md:99-114` (design-system marca GV)

---

## Context

El stack gentle-vanguard tiene **cuatro sistemas de design coexistiendo** con valores divergentes:

| Sistema                 | Path                                                   | `--gv-cyan` | `--gv-purple` | `--gv-bg` |
| ----------------------- | ------------------------------------------------------ | ----------- | ------------- | --------- |
| **A. Canónico**         | `assets/gv-design-system.css`                          | `#00bfff`   | `#a855f7`     | `#0d1117` |
| **B. Brand book**       | `docs/brand/BRAND-GUIDELINES.md` + `config/brand.json` | `#00BFFF`   | `#A855F7`     | `#0D1117` |
| **C. Ecosystem v1.0.0** | `docs/brand/UI-STANDARD-ECOSYSTEM.md` (2026-08-28)     | `#22d3ee`   | `#a78bfa`     | `#121212` |
| **D. analytics custom** | `apps/gv-analytics/src/styles.css` (líneas 3-25)       | `#22d3ee`   | `#a78bfa`     | `#121212` |

Además, **2 versiones de Tailwind** conviven: `web-dashboard` con v3.4 (tokens `--dash-*` propios),
`prompt-studio` con v4.1. Y `docs/product/DESIGN.md` (YAML `version: alpha`, Consolas/monospace)
está en conflicto con la marca oficial.

El 2026-09-01 incorporamos 5 skills AI de diseño (impeccable, taste-skill, getdesign.md,
ui-skills.com, playwright-cli). Al correr `impeccable detect` contra los CSS existentes, aparecen:

- `codex-grid-background` (advisory) en líneas 71 y 106 (decorative grid-line background) — patrón
  brand intencional
- `gradient-text` (warning) en wordmark "Vanguard" + métricas — patrón brand intencional
- `side-tab-border` (warning) en lesson-row + content cards — patrón brand intencional

El 80% de findings son falsos positivos para brand assets, pero el detector tiene razón: **los
patrones AI-slop son cada vez más visibles en público**. Necesitamos:

1. Consolidar tokens (3 sets → 1).
2. Aplicar waivers explícitos para brand assets.
3. Exponer el sistema via MCP server para consumo cross-agent.
4. Auditar las 7 apps y producir plan de remediación priorizado.
5. Adoptar las skills AI para mejorar el taste (no solo detectar anti-patterns).

## Decision

Crear `packages/gv-design-system/` (paquete monorepo) que:

1. **Consolida tokens** tomando el set v2 (cyan `#22d3ee` + purple `#a78bfa` + bg `#121212`) por ser
   el más reciente y vibrante, alineado con `docs/brand/UI-STANDARD-ECOSYSTEM.md` v1.0.0.
2. **Mantiene `assets/gv-design-system.css` como capa compartida** (sin breaking changes para apps
   ya integradas). v2 se publica como `packages/gv-design-system/dist/gv-design-system.v2.css`.
3. **Expone tokens en 4 formatos**: `tokens.json` (machine-readable, para `gv:tokens` pipeline),
   `tokens.css` (CSS custom props), `tokens.ts` (TS types), `tokens.scss`.
4. **Genera** via `npm run gv:design` (extensión del actual `npm run gv:tokens`): tokens +
   componentes + audit report + DESIGN.md.
5. **Crea MCP server `gv-design-system`** (stdio, `npx tsx`) que expone:
   - `list_tokens` (por categoría, theme, scope)
   - `get_component` (Button, Card, Input, Stack, Text, Tag, IconButton)
   - `audit_design` (corre impeccable detect sobre un path/URL)
   - `sync_design` (regenera tokens en todas las apps)
   - `get_design_md` (devuelve el DESIGN.md canonical)
6. **Skill wrapper** `.agents/skills/gv-design-system/` (frontmatter `name:`, globs para opencode +
   cross-tool via vercel-labs/agent-skills).
7. **Hook `design-lint`** en `.lefthook.yml` que corre `impeccable detect --json` contra archivos
   `.css/.tsx/.jsx` cambiados en pre-commit.
8. **DESIGN.md canonical** siguiendo Google spec + getdesign.md format, basado en análisis de
   Vercel/Stripe/Tesla (los 3 que el user profile admiraba).
9. **Componentes React** core (Button, Card, Input, Stack, Text, Tag, IconButton) con CSS modules +
   tipado TS estricto + accessibility (WCAG 2.2).
10. **Adaptadores para Tailwind v3 y v4** (`tailwind.v3.config.js`, `tailwind.v4.css`) opcionales,
    no obligatorios — apps que no usan Tailwind siguen con CSS plano.

## Razones

- **Stack ya tiene la base** (`assets/gv-design-system.css`, `docs/brand/`, `config/brand.json`,
  pipeline `gv:tokens`). No es greenfield, es consolidación.
- **Apps ya consumen `gv-design-system.css`** (academy-web, gv-analytics). No breaking change.
- **`pnpm-workspace.yaml` ya tiene `packages/*`** registrado — agregar `packages/gv-design-system/`
  es 1 línea.
- **MCP server es la ruta para cross-agent** (opencode, codex, copilot, antigravity, etc). Skills
  actuales (`.agents/skills/impeccable/`, `.agents/skills/design-taste-frontend/`) son single-file;
  un MCP server da acceso programático a tokens, components, audit.
- **TS-First + Process-hygiene + DAEMON_CLASSES** + npx tsx: ya tenemos todas las reglas para
  implementar el MCP server correctamente desde día 1.
- **`docs/brand/UI-STANDARD-ECOSYSTEM.md`** ya es contrato oficial; este ADR lo respeta y lo
  expande.
- **Anti-slop real**: las 5 skills nuevas detectan y mejoran patrones que el ojo humano no ve
  (gradient text overuse, decorative grids, etc).

## Consecuencias

### Positivas

- **1 sola fuente de verdad** para tokens (antes 3+).
- **Apps consumen del paquete** via `import '@gentle-vanguard/design-system/tokens.css'` o
  equivalente.
- **Auditoría continua**: hook pre-commit + MCP `audit_design` ejecutable desde cualquier agente.
- **Cross-agent ready**: opencode, codex, copilot, antigravity, etc pueden leer tokens via MCP.
- **Visual regression baseline** con playwright-cli (snapshots + screenshots).
- **Refactor de `gv-analytics`** (la app de referencia) al DS v2 da credibilidad al estándar.
- **Reduce AI-slop** en próximas generaciones de UI.

### Negativas / Trade-offs

- **Esfuerzo de migración** de `apps/gv-analytics/src/styles.css` (1541 líneas) y
  `apps/academy-web/style.css` a tokens v2: ~2-4 horas.
- **Waivers de brand** pueden confundir a contribuidores nuevos: deben estar documentados
  explícitamente.
- **`docs/product/DESIGN.md`** debe deprecarse formalmente (move a `docs/archive/` o agregar banner
  "DEPRECATED — use `packages/gv-design-system/`").
- **web-dashboard** se mantiene con su tema por superficie hasta su migración (excepción declarada
  en `UI-STANDARD-ECOSYSTEM.md:115`).
- **3 apps sin tokens** (content-cms, prompt-studio, archify) necesitan migración separada, no en
  este ADR.
- **Token budget**: este ADR + su implementación pueden consumir 3-5M tokens. Aplicar
  `review-workload-guard` antes de implementación multi-file >400 líneas.

## Alternativas consideradas

1. **No hacer nada** — mantener los 4 sistemas divergentes. ❌ Rejected: cost técnico crece, AI-slop
   se propaga, MCP no posible.
2. **Solo refactorizar tokens sin paquete/MCP** — dejar el CSS canónico. ❌ Rejected: no escala
   cross-agent, no hay audit continuo.
3. **Crear app independiente `apps/gv-design-system/`** en lugar de paquete monorepo. ❌ Rejected:
   contradice convención de monorepo (`packages/*` ya en `pnpm-workspace.yaml`), no es "nativo" del
   stack, viola ADR-0017 (local-first), introduce daemon innecesario cuando paquete + MCP son
   suficientes.
4. **Migrar a un design system externo** (Radix, shadcn, Material). ❌ Rejected: contradice
   `docs/brand/UI-STANDARD-ECOSYSTEM.md` (identidad propia), introduce dependencia externa, no
   respeta el brand ya establecido.

## Plan de implementación

Fase 1 (esta sesión):

- [x] Audit baseline con impeccable detect (delegado a worker)
- [x] Persistir inventario en `docs/design/00-stack-inventory.md` (delegado a worker)
- [x] ADR-0026 (este archivo)
- [ ] Crear `.impeccable/config.json` con waivers para brand assets
- [ ] `packages/gv-design-system/` scaffold (package.json, tsconfig, src/)
- [ ] Tokens v2 consolidados (`tokens.json/css/ts/scss`)
- [ ] DESIGN.md canonical (Google spec)
- [ ] Componentes core (Button, Card, Input, Stack, Text, Tag, IconButton)
- [ ] MCP server `gv-design-system` con 5 tools
- [ ] Skill wrapper `.agents/skills/gv-design-system/`
- [ ] Hook `design-lint` en `.lefthook.yml`
- [ ] Skill sync a `~/.zcode/skills/`, `~/.codex/skills/`, `~/.minimax/agents/mavis/skills/`
- [ ] Migrar `apps/gv-analytics` (parcial: tokens + 2-3 componentes)
- [ ] Visual regression baseline con `playwright-cli`
- [ ] `docs/design/02-architecture.md`, `03-components.md`, `04-mcp-server.md`
- [ ] `mem_save` + engram + nexus event

Fase 2 (próximas sesiones):

- [ ] Migrar `apps/academy-web` y `apps/prompt-studio` (Tailwind 4 bridge)
- [ ] Migrar `apps/content-cms` y `apps/archify` (cuando priorizado)
- [ ] Adaptadores `tailwind.v3.config.js` (para `web-dashboard`) y `tailwind.v4.css` (para
      `prompt-studio`)
- [ ] Deprecar `docs/product/DESIGN.md` (alpha conflictivo)
- [ ] Storybook o catálogo interactivo de componentes
- [ ] Theming dark/light unificado (con `prefers-color-scheme`)

## Métricas de éxito

- **Consolidación**: 1 sola fuente de tokens en `assets/tokens.v2.json` +
  `packages/gv-design-system/src/tokens/`. Cero `grep` de `#00bfff`, `#a855f7`, `#a78bfa`, `#22d3ee`
  fuera de `packages/gv-design-system/`.
- **Audit**: `impeccable detect` en CI pasa con 0 critical, 0 warning (con waivers), ≤3 advisory.
- **MCP**: `gv-design-system` server registrado en `config/mcp-registry.json`. `list_tokens` retorna
  24+ tokens. `audit_design` corre en <5s sobre una app.
- **Skill wrapper**: presente en `.agents/skills/`, abierto sin errores por opencode, codex,
  copilot.
- **Migración**: `gv-analytics` consume `@gentle-vanguard/design-system` (no más CSS custom 1541
  líneas).
- **Visual regression**: 0 diffs no intencionales entre baseline y HEAD en `gv-analytics` con
  `playwright-cli snapshot`.

## Riesgos y mitigaciones

| Riesgo                                                                     | Probabilidad | Impacto | Mitigación                                                                |
| -------------------------------------------------------------------------- | ------------ | ------- | ------------------------------------------------------------------------- |
| Migración breaking change para apps que ya consumen `gv-design-system.css` | Media        | Alto    | Mantener v1 como `gv-design-system.v1.css` deprecated; v2 como default.   |
| Waivers confunden contribuidores                                           | Alta         | Bajo    | Documentar en `docs/design/03-components.md` sección "brand assets".      |
| `web-dashboard` Tailwind 3.4 incompatible con v4 adapter                   | Media        | Medio   | Adaptador v3 independiente, sin tocar `prompt-studio` v4.                 |
| Token budget excedido en implementación                                    | Media        | Medio   | Aplicar `npm run workload-guard` antes de >400 LOC; scope-down.           |
| `playwright-cli` falla en Windows (assertion error visto)                  | Alta         | Bajo    | Usar `playwright-cli` con `--headed` o saltar visual regression si falla. |

## Referencias

- `docs/brand/UI-STANDARD-ECOSYSTEM.md` v1.0.0 (contrato oficial)
- `docs/brand/BRAND-GUIDELINES.md` (brand book)
- `assets/gv-design-system.css` (capa compartida actual)
- `assets/tokens.json` (machine-readable tokens actuales)
- `config/brand.json` (brand SoT)
- `AGENTS.md:99-114` (sección design-system marca GV)
- `AGENTS.md:19-37` (multi-tool integration pattern)
- ADR-0017 (local-first / server-optional)
- `.opencode/skills/diagram-design/` (template para ADR visuales)
- impeccable v4.1.2 SKILL.md (23 comandos)
- taste-skill v2 (Leonxlnx)
- frontend-design (anthropics)
- getdesign.md spec (Google DESIGN.md format)
- ui-skills.com meta-catálogo
