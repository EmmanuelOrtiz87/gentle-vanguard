# 00 — Stack Inventory para `gv-design-system/`

> Generado: 2026-09-01 · padre: mavis (root) · fuente: explore bg_ee2de367

## 1. Apps nativas (8 totales: 6 workspace + 1 sub-app + 1 utility)

| App                   | package name                                 | Framework                              | UI                                      | Tokens                                                      | Componentes custom             | Readiness DS                                    |
| --------------------- | -------------------------------------------- | -------------------------------------- | --------------------------------------- | ----------------------------------------------------------- | ------------------------------ | ----------------------------------------------- |
| `apps/gv-analytics`   | `@gentle-vanguard/gv-analytics`              | Vite 8.2 + React 18.3 + Node           | CSS plano                               | Custom `--gv-*` (24 vars, 1541 líneas CSS)                  | 4 src (App, main, i18n, types) | MEDIA — ref visual de marca                     |
| `apps/web-dashboard`  | `@gentle-vanguard/web-dashboard`             | Vite + React + WS                      | **Tailwind 3.4** + `--dash-*` (44 vars) | darkMode:class, palette primary 50-700                      | 54 components + 16 tests       | ALTA — único consumidor de `gv:tokens` prebuild |
| `apps/content-cms`    | `@gentle-vanguard/content-cms`               | Vite + React                           | CSS plano                               | Sin tokens                                                  | 8 src                          | BAJA                                            |
| `apps/academy-web`    | `@gentle-vanguard/academy-web`               | **Python http.server** (puerto 4173)   | CSS plano                               | "Referencia viva" per `docs/brand/UI-STANDARD-ECOSYSTEM.md` | n/a (estática)                 | ALTA — drop-in CSS                              |
| `apps/prompt-studio`  | `@gentle-vanguard/prompt-studio`             | Vite + React                           | **Tailwind 4.1** + `@tailwindcss/vite`  | Sin tokens                                                  | 5 src                          | MEDIA                                           |
| `apps/archify`        | `@gentle-vanguard/archify`                   | Vite + React + Node server + `engine/` | CSS plano                               | Sin tokens                                                  | 6 src + engine                 | BAJA-MEDIA                                      |
| `apps/command-center` | (sin package.json — fuera de pnpm-workspace) | Node puro, 0 deps, 0 build             | HTML+JS vanilla                         | Logo + UI sin DS                                            | 1 HTML                         | N/A                                             |

**Inconsistencias estructurales detectadas**:

- `academy-web`, `prompt-studio`, `archify` **NO** están en `pnpm-workspace.yaml` (líneas 1-7)
- `command-center` no tiene `package.json` propio
- `pnpm-workspace.yaml` solo registra: `gv-analytics`, `web-dashboard`, `content-cms` +
  `packages/*` + `src/core`

## 2. Skills de design YA existentes (NO empezar de cero)

| Skill                                                               | Path                                      | Categoría            | Estado                                                                                  |
| ------------------------------------------------------------------- | ----------------------------------------- | -------------------- | --------------------------------------------------------------------------------------- |
| `brand-guidelines-gv`                                               | `skills/brand-guidelines-gv/SKILL.md`     | Brand/tokens         | Reskin de `anthropics/skills/brand-guidelines` con tokens GV. SoT: `assets/tokens.json` |
| `frontend-design`                                                   | `public/skills/frontend-design-skill/`    | UI/UX                | Adoptada                                                                                |
| `canvas-design`                                                     | `public/skills/canvas-design-skill/`      | UI/UX                | Adoptada                                                                                |
| `theme-factory`                                                     | `public/skills/theme-factory-skill/`      | Tokens               | Adoptada                                                                                |
| `ui-taste`                                                          | `skills/ui-taste/` (Leonxlnx)             | UI/UX anti-slop      | Gate transversal                                                                        |
| `huashu-design`                                                     | `skills/huashu-design/` (alchaincyf)      | Design PPTX editable | MIT                                                                                     |
| `design-review`                                                     | `.opencode/skills/design-review/`         | Design review        | Nativo                                                                                  |
| `diagram-design`                                                    | `.opencode/skills/diagram-design/`        | Diagrams 27 tipos    | Nativo                                                                                  |
| `tailwind-4`                                                        | `public/skills/tailwind-4-skill/`         | Tailwind v4          | Adoptada                                                                                |
| `accessibility-design`                                              | `public/skills/*-accessibility-*/`        | a11y                 | 3 skills                                                                                |
| `ux-copy`, `ui-mobile`, `data-visualization`                        | `public/skills/*`                         | UI patterns          | —                                                                                       |
| `design-ux-researcher`, `design-ui-designer`, `design-system-skill` | `public/skills/` + `skills/` (duplicados) | Design roles         | DUPLICACIÓN entre raíces                                                                |

**Skills NUEVAS incorporadas HOY** (2026-09-01) en `.agents/skills/` (cross-tool: Antigravity,
Cline, Codex, Gemini CLI, GitHub Copilot, Claude Code, etc):

- `impeccable` v4.1.2 (pbakaus, MIT/Apache) — 23 comandos
- `design-taste-frontend` (Leonxlnx v2)
- `gpt-taste`, `redesign-existing-projects`, `minimalist-ui`, `high-end-visual-design`,
  `image-to-code`, `imagegen-frontend-web`, `brandkit`

## 3. Patrones de design system actuales

**Archivos clave**:

- `assets/gv-design-system.css` (380+ líneas) — canónico, tokens `--gv-*` (24 vars)
- `assets/tokens.json` (22 color + 3 typography + 8 CLI) generado 2026-09-01T10:17 desde
  `config/brand.json`
- `assets/tokens.css`, `assets/tokens.scss` — mismo set
- `config/brand.json` — brand SoT
- `docs/brand/UI-STANDARD-ECOSYSTEM.md` v1.0.0 (2026-08-28) — **contrato oficial**
- `docs/brand/BRAND-GUIDELINES.md` — brand book
- `docs/brand/assets/` — 7 SVG (logos + banners)
- `docs/product/DESIGN.md` — **CONFLICTIVO** (YAML alpha, Consolas/monospace, paleta neutral, NO
  alineado con brand)
- `src/design/{design-tokens,design-token-pipeline,design-system-cli}.ts` — pipeline
  `npm run gv:tokens`
- `apps/web-dashboard/tailwind.config.js` — único `tailwind.config.*`
- `apps/web-dashboard/src/styles/{index.css, generated-tokens.css}` — 44 `--dash-*` tokens

**Convención de prefijos (REGLA)**:

- `--gv-*` y `.gv-*` son **canónicos y reservados** al DS compartido (AGENTS.md:108)
- Cada app usa su propio prefijo (`--dash-*` para dashboard)
- Breakpoints: 640px (mobile), 1024px (tablet)

## 4. CONFLICTO DE TOKENS (raíz del problema)

**apps/gv-analytics/src/styles.css** (líneas 3-25):

```css
--gv-purple: #a78bfa;
--gv-cyan: #22d3ee;
--gv-bg: #121212;
--gv-bg-deep: #0a0e17;
--gv-amber: #f4bb4f;
--gv-red: #ee6d75;
--gv-green: #4ade80;
--gv-gradient: linear-gradient(135deg, #a78bfa 0%, #22d3ee 100%);
--gv-glow: rgba(34, 211, 238, 0.35);
```

**assets/gv-design-system.css** (líneas 11-50) — más antiguo:

```css
--gv-primary: #00bfff; /* vs #22d3ee en analytics */
--gv-primary-light: #4dcfff;
--gv-primary-dark: #0055bb;
--gv-accent: #a855f7; /* vs #a78bfa en analytics */
--gv-accent-teal: #06b6d4;
--gv-bg: #0d1117; /* vs #121212 en analytics */
--gv-gradient: linear-gradient(135deg, #a855f7 0%, #00bfff 100%);
```

**docs/brand/BRAND-GUIDELINES.md** — tercera versión:

```json
"primary": "#00BFFF", "primaryLight": "#4DCFFF", "primaryDark": "#0055BB",
"accent": "#A855F7", "accentTeal": "#06B6D4",
"background": "#0D1117", "surface": "#1A2035"
```

**3 sets de tokens con valores distintos** conviven. Resolución propuesta: **adoptar el set de
`apps/gv-analytics/src/styles.css` + `docs/brand/UI-STANDARD-ECOSYSTEM.md`** (paleta más vibrante y
reciente) y migrar el canónico + brand.json.

## 5. MCP servers actuales (5 builtin + 1 user)

| Nombre                                | Tipo           | Transport              | Descripción                              |
| ------------------------------------- | -------------- | ---------------------- | ---------------------------------------- |
| `skill-server`                        | builtin stdio  | —                      | 143+ skills vía MCP: list/get/search     |
| `engram-mcp`                          | builtin stdio  | `npx engram@0.0.1 mcp` | Memoria persistente                      |
| `lsp-server`                          | builtin stdio  | TS LSP                 | go_to_def, find_refs, hover, completions |
| `fetch-server`                        | builtin stdio  | Jina Reader + DDG/Bing | fetch_url, search_web                    |
| `sequential-thinking`                 | builtin stdio  | —                      | think_sequential, get_chain              |
| `gv-analytics-atlassian`              | user stdio     | Atlassian MCP          | status + delivery analysis               |
| `filesystem`, `memory` (profile `sd`) | external stdio | —                      | —                                        |

**OPORTUNIDAD**: añadir `gv-design-system` MCP server (stdio, npx tsx). Sería el 7mo server. Expone
tokens, components, audit, sync.

## 6. Hooks y pre-commit (lefthook v3.1)

`.lefthook.yml` activo con 11 hooks: opencode-validation, json-lint, workflow-lint, lockfile-lint,
skill-scan, secretlint, secret-scanner, metrics-check, prepush-gate, commitlint,
commit-msg-session-track, codegraph-sync, hashline-snapshot.

**OPORTUNIDAD**: añadir hook `design-lint` que corra `impeccable detect` contra archivos cambiados
en `pre-commit`.

## 7. Convenciones operativas (reglas del stack)

De `AGENTS.md` + `rules/*.md`:

1. Pre-response hook obligatorio (`pre-process-input.ts`)
2. Session start obligatorio (`npm run session:autostart:detached`)
3. LOCAL-FIRST / server-optional (ADR-0017) — loopback-only
4. **TypeScript-First Policy** — TS para todo el stack
5. **No PowerShell-only** — TS via `npx tsx` es el shell del sistema
6. SDD flow: BA/EXPLORE primero
7. CodeGraph MCP antes de modificar código
8. Multi-tool: 21 subagentes + 19 skills críticas sincronizadas a `~/.zcode/`, `~/.codex/`,
   `~/.minimax/`
9. `mem_save` después de cada tarea significativa
10. Process-hygiene: `runNpxTsx`/`runNpxTsxSync` + `.runtime/<name>.pid`
11. DAEMON_CLASSES registrado
12. Token budget: 5M daily, 3M perSession
13. Naming: PascalCase funciones TS, camelCase JSON, kebab-case archivos, type/description branch
14. `tests/{unit,integration,e2e,performance,security}/`
15. 80% min coverage, code review obligatorio
16. sin secrets hardcoded, sin catch vacíos, sin Write-Host en libs

## 8. Apps que consumirían el DS (impacto)

| App              | LOC src             | Componentes   | UI lib       | Readiness  | Acción                                        |
| ---------------- | ------------------- | ------------- | ------------ | ---------- | --------------------------------------------- |
| `web-dashboard`  | ~70 .tsx + 16 tests | 54            | Tailwind 3.4 | ALTA       | Reconciliar `--dash-*` con DS; mover prebuild |
| `gv-analytics`   | 4 src + server      | 1 root        | CSS plano    | MEDIA      | Ya implementa estándar manualmente            |
| `content-cms`    | 12 src              | 1 + sub-mods  | CSS plano    | BAJA       | Extraer primitivos reusables                  |
| `prompt-studio`  | 5 src               | 1 root        | Tailwind 4.1 | MEDIA      | Theme bridge a Tailwind 4                     |
| `archify`        | 6 src + engine      | 1 + library   | CSS plano    | BAJA-MEDIA | Engine agnóstico, opcional                    |
| `academy-web`    | n/a                 | HTML estática | CSS plano    | ALTA       | Drop-in CSS                                   |
| `command-center` | 3 TS + HTML         | 1 HTML        | vanilla JS   | N/A        | No consumiría DS                              |

## 9. Bloqueos y riesgos

1. **3 versiones de tokens** coexistiendo — debe consolidarse
2. **`docs/product/DESIGN.md` alpha** conflictivo con brand oficial
3. **Tailwind v3 vs v4** en distintas apps — decisión de soporte
4. **Pipeline `gv:tokens`** solo consumido por `web-dashboard`
5. **Apps en `apps/` no registradas** en `pnpm-workspace.yaml` (academy-web, prompt-studio, archify)
6. **`command-center` sin package.json**
7. **`docs/design/` no existe** — debe crearse
8. **Duplicación de skills** entre `public/skills/`, `.opencode/skills/`, `skills/` raíz
9. **No CONTRIBUTING.md**
10. **Apps excluidas** (`web-dashboard` con tema propio "hasta migración")

## 10. PRÓXIMOS PASOS sugeridos

1. **Decisión arquitectural** (ADR-0026) sobre consolidación de tokens
2. **SDD-design** del DS con `sdd-explore` BA
3. **Implementación**:
   - Consolidar 3 sets de tokens → 1 (`assets/tokens.v2.json`)
   - Actualizar `assets/gv-design-system.css` con tokens v2 + waivers de brand
   - Crear `packages/gv-design-system/` con:
     - `src/tokens/` (TypeScript types)
     - `src/components/` (React + CSS)
     - `src/mcp/` (MCP server)
     - `src/cli/` (CLI sync/audit)
   - Wire `gv:design` prebuild hook en lefthook
4. **Auditar** las 7 apps con `impeccable detect` y triage findings
5. **Skill wrapper** `.agents/skills/gv-design-system/` (cross-tool)
6. **Documentar** en `docs/design/` (00..05) + ADR-0026
