# Absorción nativa de gentle-ai v2.7.0 — 2026-09-09

> Fuente: [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai)
> Release analizada: `v2.7.0` (estable, 2026-09-08) — "We Count, We Assess, We Ask Less of You".
> Complementa la absorción previa de v2.5.0/v2.4.0 (`ABSORPTION-GENTLE-AI-V2.5.md`).
> Nada se copió como dependencia: cada patrón se reimplementó nativo en TypeScript.

## Contexto del repo

- **6.5K stars / 733 forks**, Go, MIT. Configurador de agentes de coding (Claude Code, OpenCode,
  Codex, Cursor, Pi…) con memoria persistente (Engram), SDD, skills, MCP, personas y RDD opcional.
- Nuestro stack **ya tenía RDD nativo maduro** (`src/rdd/`, `src/review/`) con las mismas 4R
  (security/maintainability/reliability/resilience) y los skills portables ya absorbidos
  (branch-pr, chained-pr, work-unit-commits, cognitive-doc-design, comment-writer).
- El gap real de v2.7.0: **`review assess` standalone** y **risk-aware delegation**.

## Qué se absorbió (2 features + 2 bugs propios corregidos)

### 1. `gv rdd assess` — risk assessment standalone (v2.7.0 headline)

Lección v2.7.0: "The review tells you how risky a change is before anything starts." RDD era
all-or-nothing; ahora `gentle-ai review assess --json` responde "how careful should we be?" con
`passive | medium | high` sin abrir review ni tocar nada.

Nativo: `gv rdd assess` (case `rdd` en `src/cli/gv.ts`) delega a `src/rdd/risk-classifier.ts`
con `classify --json`. Expone también `classify`, `explain`, `factors`, `review` (→
`rdd-4r-review.ts`) y `gates` (→ `rdd-gates.ts`).

- Exit codes: 0=low · 1=standard · 2=high
- Salida JSON: `{ tier, score, factors[], rationale, recommendation, reviewLenses }`

### 2. Risk-aware delegation (v2.7.0 "risk tier decides whether a separate verifier runs")

Lección v2.7.0: el orchestrator usa el risk tier para decidir cuánta verificación merece una tarea
delegada. Small harmless changes stop paying for ceremony; risky ones get two sets of eyes.

Nativo: `recommend-agent.ts --risk-aware` — clasifica el diff actual con `classifyRisk()` y
enriquece la recomendación:

| Risk tier | Verificación |
| :--- | :--- |
| `low` | `none` — delegación directa sin verificación extra |
| `standard` | `sdd-verify` — 1 lens |
| `high` | `rdd-4r-review` — 4R review |

Solo aplica a dominios de código (`code-apply`, `code-review`, `testing`, `general`).

### 3. Context7 MCP — docs de frameworks en vivo (componente opcional)

Lección: el agente necesita documentación actualizada de frameworks sin salir del flujo.

Nativo: server `context7` registrado en `config/mcp-registry.json` (type `external`,
`npx @upstash/context7-mcp`, `autoStart: false` — opt-in, requiere red). Complementa a
codegraph (símbolos del repo) con docs externas en vivo (React, Next.js, FastAPI, LangChain…).

### 4. Bug crítico corregido: `\u005c` en regex literales de `risk-classifier.ts`

**21 ocurrencias** de `\u005c` (escape de barra invertida) dentro de regex literales rompían todos
los patrones:

- `/(\u005c).env/i` matcheaba `\` + cualquier char + `env` en vez de `\.env` (punto literal).
- `/^(\d+)\u005cs+(\d+)\u005cs+(.+)$/` matcheaba `\s` **literal** (barra+s) en vez de whitespace →
  el numstat de git (con tabs reales) nunca matcheaba → el classifier siempre reportaba
  "No changes to classify".
- `'\u005ct'` buscaba `\t` literal en vez del tab real → renamed files rotos.

**Gotcha documentado**: en un regex literal, `\u005c` se interpreta como la barra invertida `\`,
pero **NO se combina con la letra siguiente** — `\u005cs` es `\` + `s` (matchea la secuencia
literal `\s`), no el whitespace `\s`. Para whitespace real hay que escribir `\s` directo.

### 5. Bug corregido: suma vs max en `categoryScores`

El comentario decía "Take max category risk (not sum)" pero el código **sumaba** los scores por
categoría (`categoryScores[cat] += CATEGORY_RISK[cat]`). Un diff con 9 archivos que mencionan
"token" sumaba 810/100. Corregido a `Math.max(...)`: el riesgo se mide por la categoría más
peligrosa presente, no por cuántos archivos la comparten.

Además se refinaron los patrones de auth para reducir falsos positivos: `/token/i` → específicos
(`access_token`, `api_token`, `refresh_token`, `csrf_token`, `bearer`), quitados `/permission/i`,
`/role/i`, `/session/i` (→ `session_id/token/key`).

### 6. `adaptive-steps --risk-aware` — presupuesto de steps según risk tier

El orchestrator ahora puede ajustar el presupuesto de steps de una tarea delegada según el riesgo
del diff actual: `low` → +0, `standard` → +8 (sdd-verify), `high` → +16 (rdd-4r-review). Se
combina con `recommend-agent --risk-aware` para una delegación completa consciente del riesgo.

### 7. `smallest-route-router` — risk-aware verification automática

El routing orgánico (direct/delegated/sdd) ahora clasifica el diff actual automáticamente y
agrega `verification` a la `RouteAnalysis` para rutas que tocan código (delegated/sdd/
collaborative): `low` → `none`, `standard` → `sdd-verify`, `high` → `rdd-4r-review`. El
orchestrator no necesita flags: la verificación post-apply se decide sola por risk tier.

## Verificación en vivo (todo ejecutado)

| Verificación | Resultado |
| :--- | :--- |
| `tsc --noEmit` | 0 errores |
| eslint (gv.ts, risk-classifier.ts, recommend-agent.ts) | 0 errores |
| `gv rdd assess --json` | Clasifica el diff real (10-11 archivos), tier HIGH score 90, rationale claro |
| `recommend-agent --risk-aware` | `{ riskTier: high, riskScore: 90, verification: rdd-4r-review }` |
| Grep `\u005c` en src/rdd, src/review, src/orchestration | 0 ocurrencias (bug solo en risk-classifier) |

## Qué NO se absorbió (y por qué)

- **Telemetría anónima de instalación** (v2.7.0 "We Count") — nuestro stack ya tiene telemetría de
  correlación OTel-compatible (`src/telemetry/`); la telemetría de instalación con campos fijos es
  un patrón interesante pero de bajo valor para un stack local-first. Backlog.
- **SDD archive compose** (`sdd-archive-compose`) — composición determinística del spec final;
  nuestro SDD ya persiste artifacts en `.sdd/`. Backlog.
- **Skill registry dinámico** (`skill-registry refresh`) — escaneo de skills + convenciones;
  nuestro stack tiene `src/plugins/skill-cli.ts`. Backlog.
- **Freeze expansion policy / cross-repo root continuity** — refinamientos del lifecycle RDD que
  nuestro `rdd-core.ts` ya cubre en su modelo.

## Próximos pasos naturales (backlog)

- Cablear `--risk-aware` en el orchestrator (`src/orchestration/adaptive-steps.ts`) para que la
  verificación post-apply se decida por risk tier automáticamente.
- Evaluar telemetría anónima de instalación con campos fijos (opt-out, sin paths/IPs).
- Evaluar Context7 MCP como server opcional para docs de frameworks.
