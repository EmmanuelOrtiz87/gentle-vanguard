# Gentle-Vanguard — Stack Manual (Slim)

> Manual completo: `docs/stack-manual-full.md` (arquitectura, 96 checks, migraciones, ADRs). Este
> archivo es la versión de bajo contexto para inyección diaria. Cargar el manual completo solo
> cuando la tarea lo requiera.

## SESSION START (MANDATORY)

Antes de responder al usuario, ejecutar:

```bash
npm run session:autostart:detached   # fire-and-forget, ~1.3s, pipeline completo en background
```

Alternativa bloqueante: `npx tsx src/session/session-autostart.ts`. Es idempotente y no pide permiso. El
pipeline inicializa: session ID, engram, security orchestrator, codegraph, token budget, watchtower
auto-heal, dashboard WS, Nexus DB (lazy steps). Log: `.runtime/autostart-detached-*.log`.

## Multi-Tool Integration (ZCode, Codex, MiniMax Code)

- **Agentes**: 21 subagentes del stack sincronizados a `~/.zcode/agents/` vía
  `npx tsx src/zcode-sync.ts --sync` (re-ejecutar tras editar `.opencode/agents/`).
- **Skills críticas** (19): `zcode-sync.ts --sync` las copia a las 3 herramientas —
  `~/.zcode/skills/`, `~/.codex/skills/`, `~/.minimax/agents/mavis/skills/` (pi-agent). Filtrar con
  `--tools zcode,codex,minimax`. NO copiar todas (~120): ZCode degrada el auto-trigger si se excede
  su presupuesto de metadata.
- **Comandos ZCode**: `.zcode/commands/` — `/graphify`, `/token-status`, `/db-health`,
  `/watchtower`, `/delegate`, `/web-research`.
- **MCP**: `.zcode/config.json` → `mcp.servers`: codegraph, engram, chrome-devtools, filesystem,
  memory.
- **Hooks ZCode**: `~/.zcode/cli/config.json` — SessionStart (autostart, guard por repo) +
  PostToolUse Write|Edit (graphify update). Scripts en `src/zcode-hooks/`.
- **Codex/MiniMax leen AGENTS.md nativamente** (estándar), por eso este archivo es slim.
- **Token tracking multi-tool**: `src/tokens/token-ingest.ts` ingiere 4 fuentes — opencode (SQLite),
  zcode (`~/.zcode/cli/rollout/`), codex (`~/.codex/sessions/`), minimax
  (`~/.minimax/v2/sqlite/runtime-state.sqlite`, tabla `local_runtime_token_usage`).
- Cambios requieren nueva sesión en cada herramienta (no hot-reload).

## graphify

Grafo de conocimiento nativo en `graphify-out/` (AST, sin LLM, determinista).

- Si falta `graphify-out/graph.json`: `npm run graphify -- build` primero.
- Preguntas de código: `npm run graphify -- query "<pregunta>"` (siempre preferir query sobre
  path/explain para búsquedas).
- Nodo exacto: `npm run graphify -- explain "<node_id>"` (IDs underscore-separated, usar query para
  encontrarlos).
- `path`/`affected` son limitados (solo edges contains/calls sin LLM).
- Tras modificar código: `npm run graphify -- update .`.
- Navegación amplia: `graphify-out/wiki/index.md` (si fue generado); arquitectura:
  `graphify-out/GRAPH_REPORT.md`.
- Labeling usa Gemini free tier (20 req/día); 429 → esperar reset.
- Viz: `$env:GRAPHIFY_VIZ_NODE_LIMIT=40000` antes de `cluster-only`/`label`.

## dashboard

Observabilidad LLM en `apps/web-dashboard/` (React/TS/Vite). **Sin mock data** — todo deriva de
trazas reales.

| Acción                          | Comando                                 |
| ------------------------------- | --------------------------------------- |
| Start full (WS + Vite + Chrome) | `npx tsx src/ops/dashboard-start.ts`        |
| Start WS only                   | `npx tsx src/ops/dashboard-ws-autostart.ts` |
| Stop                            | `npx tsx src/ops/dashboard-stop.ts`         |

- WS server: `server/websocket-server.ts` (puerto dinámico vía `Get-FreePort()`, persistido en
  `.runtime/dashboard-ports.json`), push cada 5s, REST `/api/metrics|traces|alerts|feedback|health`.
- Watchdog con auto-restart (10 intentos); stop mata watchdog primero. Frontend tolera caídas via
  HTTP polling.
- Build verification: `cd apps/web-dashboard && npm run build` (debe salir 0 sin errores TS).
- i18n en/pt/es, 8 alert rules en `config/dashboard-alerts.json`.

### Modelo operativo

Gentle-Vanguard es **LOCAL-FIRST / SERVER-OPTIONAL** (ADR-0017). CLI/orquestación, SQLite/Nexus,
`.session/`, Engram, CodeGraph, MCP local y dashboard loopback son la ruta principal soportada.
Cloud/Kubernetes/Cosign/CNI/sandbox/OIDC/LDAP son opt-in o inputs futuros de promoción externa, no
requisitos de operación local.

## procesos-ocultos (regla de oro)

Todo spawn de procesos debe ser **invisible en Windows** — cero ventanas cmd.exe (ni flashes ni
ventanas persistentes). Reglas:

- Scripts TS del stack: SIEMPRE `runNpxTsx`/`runNpxTsxSync` de `src/core/run-command.ts` — usan
  `node --import tsx <script>`: el script corre EN el proceso spawned. NUNCA invocar el CLI de tsx
  (`cli.mjs`) ni `npx tsx` directamente: el CLI relanza el script como proceso NIETO sin
  `windowsHide` y cada launcher oculto/detached abre una consola visible (ráfagas + daemons con
  ventana que rompen el stack al cerrarlas).
- Daemons/launchers directos:
  `spawn(process.execPath, ['--import','tsx', script], {stdio:'ignore', detached:true, windowsHide:true})` +
  `child.unref()`; el PID spawned ES el PID real (no requiere re-resolución por puerto).
- Prohibido: `exec/execSync` con string de comando (cmd.exe visible; usar `runSync`/`runSyncShell`),
  `spawn('npx.cmd')` sin shell (EINVAL en Node moderno; usar `run`/`runNpxTsx`), `cmd /k`,
  `start /B` con cadenas npx.
- Tareas programadas (schtasks): acción `node.exe --import tsx` directa + principal S4U (oculto); si
  el registro S4U es denegado, fallback con wrapper wscript oculto
  (`.runtime/codegraph-sync-hidden.vbs`, generado por `src/infrastructure/bootstrap.ts`).
- Test de regresión: `tests/unit/run-command-hidden.test.ts` — PID del hijo debe ser PID del script
  (falla si vuelve el nieto del CLI de tsx).

## process-hygiene (reaper nativo)

`src/core/process-hygiene.ts` — detección y limpieza de basura de procesos. Los daemons detached
sobreviven a su padre POR DISEÑO, así que "padre muerto" NO identifica basura; el reaper clasifica
por shape: daemons duplicados (keeper = pidfile/port owner), one-shots colgados (padre muerto
>15min), daemons envejecidos (>24h adoptados de sesiones previas, solo si autostart los re-spawnea),
pidfiles stale y chrome headless residual.

```bash
npm run process:hygiene   # dry-run (exit 1 si hay basura)
npm run process:reap      # limpia de verdad
```

- Wired: paso 1 del pipeline autostart (ANTES de los lazy daemons), check+autoheal del watchtower
  (componente `process-hygiene`), sweep en session-close (fase 5.3b).
- Registro de clases en `DAEMON_CLASSES` (misma lista = fuente de verdad). Reporte:
  `.runtime/process-hygiene-report.json`. Tests: `tests/unit/process-hygiene.test.ts`.
- Daemons nuevos DEBEN: escribir su PID en `.runtime/<name>.pid` al arrancar (ver token-ingest) y
  limpiarlo en SIGTERM/SIGINT.

## maintenance-watchtower

Orquestador de health/auto-healing: **96 checks / 22 componentes**, 6 modos (health, rebuild,
report, autoheal, continuous, all). Corre `autoheal -Quiet` lazy al inicio de sesión.

```bash
npm run watchtower:health   # 96/96 PASS esperado
```

CLI Guard: check anti-regresión del patrón roto
`import.meta.url === \`file://${process.argv[1]}\``(ver`src/auto-url-fix.ts`).

## Nexus — DB operacional

SQLite WAL en `.runtime/gentle-vanguard.db`, 23 tablas, singleton DatabaseManager
(`apps/web-dashboard/server/database/manager.ts`). Converge: métricas, sesiones, trazas, eventos,
alertas, feedback, response cache, skills, tokens, routing, scoring.

```bash
npm run db:init && npm run db:health   # verificación rápida
```

- Lifecycle completo: `db:backup|db:restore|db:list|db:optimize|db:prune|db:prune:backup`.
- Pipeline: steps lazy `db-init`, `db-health-check`, `db-prune`.
- Normativa: `rules/NEXUS-NORMATIVA.md`; skill: `skills/nexus-database/SKILL.md`.
- Monitoreado por watchtower (integridad, WAL, tamaño).

## Token Tracking (real, agnóstico)

Daemon `src/tokens/token-ingest.ts` lee datos persistidos por cada herramienta (opencode.db,
**zcode** `~/.zcode/v2/`, extensible) y consolida en Nexus: `token_usage`, `token_transactions` (por
mensaje/agente), `token_savings` (cache + compresión).

```bash
npm run token:ingest   # una pasada
npm run token:trace    # trazabilidad
npm run token:status   # budget real: usado/presupuesto/%
```

Presupuestos en `config/token-budget-guard.json` (daily 5M, perSession 3M).

## Adaptive Steps + Delegación

Steps auto-escalados por complejidad (señales de texto + archivos + historial). Routing table
aprendible en `.session/routing/routing-table.json` (17 dominios + overrides). Auto-reassignment +20
steps (máx 80) cuando un agente reporta "maximum steps reached".

```bash
npx tsx src/orchestration/adaptive-steps.ts --status
npx tsx src/orchestration/recommend-agent.ts --task "code review" --topn 3
npm run delegate:run -- --task "audit gdpr compliance"
```

## Skills y capacidades nativas (resumen)

- **Secret scanner** (`npm run scan:secrets -- --scan .`): 80 patrones, entropy opcional, redacción.
  Integrado a pre-commit (lefthook) y watchtower.
- **25 skills ciberseguridad** (Apache-2.0) en `.opencode/skills/` — red-team solo en entornos
  autorizados. Mapeo por rol en `config/subagent-mapping.json`.
- **diagram-design** (27 tipos, HTML/SVG self-contained) — usar para ADRs/reportes en vez de
  Mermaid-slop.
- **ai-provenance**: modo INSPECCIÓN default; REMOCIÓN solo con petición explícita del usuario sobre
  contenido propio.
- **Compresión estructural** (`src/compression/structural-compression.ts`): 5 estrategias;
  `mode:'input'` = lossless-only (protege razonamiento), `mode:'output'` = lossy OK.
- **Perfiles SDD**: `npm run profile:list|status|apply -- <perfil>` (cheap/balanced/premium en
  `config/model-router.json`).
- **Hash-chained audit** (`src/event-sourcing.ts`): eventos con prevHash+hash SHA-256; `verify`
  detecta manipulación.
- **Skills adoptadas Fases 1-3 (2026-08-27)**: `frontend-design`, `canvas-design`, `theme-factory`,
  `doc-coauthoring` (anthropics/skills, Apache-2.0), `huashu-design` (alchaincyf/huashu-design, MIT, PPTX editable),
  `ui-taste` (Leonxlnx/taste-skill, MIT, gate transversal anti-slop), `brand-guidelines-gv` (re-skin tokens GV) +
  familia marketing `copywriting`, `product-marketing`, `cro`, `marketing-plan`, `launch`, `emails`,
  `marketing-psychology`, `content-strategy` (coreyhaines31/marketingskills, MIT) — en `skills/` con
  atribución en frontmatter (`source: external-adopted`). Plan: `docs/reference/SKILL-UPGRADE-SHORTLIST-2026-08.md`.
- **CRAG retrieval grader** (`src/retrieval/retrieval-grader.ts`): BM25 + keyword-fallback.
- **SDD research lane** (`npm run sdd:research -- run -f <feature> -q "q1;q2" [--deep]`):
  evidencia externa versionada (`gentle-vanguard.sdd-research/v1`) ligada al caso SDD — busca,
  gradea BM25 y persiste `.sdd/<feature>/RESEARCH/{artifact.md,research.json}`; PROPOSE la
  cita automáticamente. Comando ZCode: `/sdd-research`. Retención RDD:
  `npx tsx src/rdd/rdd-core.ts prune --retention-days=30` (lazy en autostart).
- **Web crawler dual-provider** (`src/web/web-crawler-cli.ts`): Firecrawl → Jina Reader +
  DuckDuckGo + Bing RSS. GOTCHA: Jina bloquea UA de navegador; decodificar `uddg` de DDG; Bing solo
  vía RSS.
- **Web research select** (`npm run web:select -- --query "..." [--deep]`): busca → gradea BM25 →
  persiste top-N.
- **witr** (`src/web/witr-cli.ts`): traza causal de procesos/puertos (process|port).
- **Research trends** (`src/research/research-trends-cli.ts`): GitHub/HN/SO/Dev.to/Reddit →
  TrendReport.
- **Humanizer / Design tokens / Planning templates / Animations**: `npm run humanize:*`, `design:*`,
  `animation:*`.
- **v4.0 infra**: tracing (`.telemetry/`, OTLP), checkpoints/snapshots/rollback (`.session/`), audit
  pipeline, event sourcing + saga, health API (7 componentes); cloud connectors con circuit breaker
  son opt-in para promoción externa.

## CI/CD y Testing

- CI (`.github/workflows/ci.yml`): lint-typecheck, test, dashboard-tests, dashboard-build,
  security-scan, workflow-lint. Security: gitleaks, secretlint, trivy.
- Suites: `npm run test:config` (6), `test:workflows` (2), `test:research` (5).
- Scripts PS1 core migrados a TS (`health-check.ts`, `session-autostart.ts`,
  `maintenance-watchtower.ts`); los `npm run` apuntan solo a versiones TS.
- Research scripts consolidados:
  `python research/rlhf-dataset-search/search_datasets.py --source all --query "..."`.

## Reglas rápidas

- `$var:` en PowerShell strings → escribir `${var}:` (parser error si no).
- Graphify CLI = `npm run graphify --` local; NO instalar el paquete npm `graphify@1.0.0` (no
  relacionado).
- Config consolidada: `config/model-router.json` (no `model-routing.json`).
- Detalle completo de todo lo anterior: `docs/stack-manual-full.md`.
