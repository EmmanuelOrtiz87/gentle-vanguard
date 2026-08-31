# Plan de Evolución del Stack — Gentle Vanguard 2026

**Fecha:** 2026-08-22 · **Versión:** 1.1 · **Autor:** Revisión integral autónoma (arquitectura +
DevOps + docs + comercial) **Alcance:** `gentle-vanguard` (stack) + `GENTLE_VANGUARD_MASTER` (rama
comercial) **Tipo:** Plan de acción estratégico y táctico — el qué, el por qué, el cómo y el cuándo.

---

## ⚡ Registro de progreso

### Ejecutado — Sesión 8 (2026-08-31, Apps Control Panel + F2.3 cierre de scope library)

- ✅ **Apps Control Panel** (commit `7b80dc68`): `apps-control-api.ts` + `AppsControlPanel`
  (ruta `/apps`) para lifecycle de dashboard/analytics/cms/academy desde la UI. Dashboard WS ahora
  persiste entre sesiones (el panel es dueño del lifecycle; session-close ya no lo mata). MCP
  `gv-analytics-atlassian` registrado en `opencode.json` (pendiente de gv-analytics cerrado).
- ✅ **F2.3 batch 2 — scope library CERRADO** (commit `9e5f091c`): codemod mejorado (archivos
  mixtos library+CLI ya no se saltan enteros; fix de reporte multiArg; SKIP ampliado con los
  reversions batch-1) + 9 multi-arg migrados a mano (ResilienceManager, session-context-log,
  response-cache/sqlite, event-sourcing-api). **Conclusión de fase**: los ~5.400 `console.*`
  restantes en `src/` están en código CLI por diseño (shebang, `src/cli/`, bloques main() con
  stdout parseable) — la superficie library está 100% en logger estructurado. tsc 0, eslint 0,
  test:config 24/24, test:workflows 4/4.
- ✅ **F2.7 COMPLETADO — meta ≥16 superada**: 17 componentes con tests (9 archivos nuevos, 32
  tests: ActivityTimeline, AppsControlPanel, AuditPanel, ErrorBoundary, GuardrailsPanel,
  LoopGuardPanel, NotificationToast, SessionTable, TokenUsagePanel). Suite dashboard 97/97, build
  exit 0. Pendiente opcional: alineación de versiones via `catalog:` pnpm.

### Ejecutado — Sesión 7 (2026-08-31, anti-loop nativo + métricas vivas + gv potentiation)

- ✅ **F4.1 live metrics (single source of truth)**: `config/stack-metrics.json` creado (199 skills,
  551 src, 161 tests, 33 tablas Nexus, 104 checks/24 comps) + `src/tools/metrics-verify.ts` + npm
  scripts `metrics:verify/check` + `loop-guard:check/test`. Política: no hardcodear conteos en docs
  — citar este archivo o `gv info`/`gv metrics`.
- ✅ **Guard anti-loop nativo (ADR-0022)**: `src/core/orchestrator-loop-guard.ts` puro stateful con
  4 detectores (intent-loop 3×, tool-loop 3×, ping-pong A-B-A-B, stalled-progress 8 pasos) +
  `tests/unit/orchestrator-loop-guard.test.ts` 5/5 pass. Resuelve los bucles degenerativos de F2.3
  (30+ intents idénticos sin tool). Research Azure AI Agent Design Patterns absorbido nativamente
  via `src/web/web-crawler-cli.ts` dual-provider (Jina+DDG+Bing, sin API key): iteration caps +
  fallback para cada patrón.
- ✅ **F2.8 CLI `gv` potentiation**: `src/cli/gv.ts` v8.0 → 27 comandos
  (+`loop-guard`, +`metrics`, +`web`). `gv loop-guard`, `gv metrics`, `gv web search|scrape|health`
  operativos y verificados. Watchtower 102/104 → 106/108 PASS tras wiring, tsc 0, eslint 0,
  metrics-verify PASS. `gv web health` fix (runSync stdout) + `gv web search` nativo Jina+DDG+Bing.
- ✅ **PR #174 MERGED** (`feat/stack-potentiation-loop-guard-metrics` → `main`, `388964d7`) y **PR
  #175 MERGED** (`fix/gv-web-watchtower-wiring` → `main`, `c5561bad`) con bypass admin (ruleset
  21824110). PR #173 ya MERGED (`965d7c41`). Commit Lint ahora PASS (body <100 chars).
- ✅ **Wiring completado (F2.8/F4.1)**: `checkLoopGuard` cableado en `checks-infra.ts` +
  `maintenance-watchtower.ts` (25 comps, 108 checks, 106 PASS, `loop-guard: OK`) +
  `adaptive-steps.ts` resume loop detection (`.runtime/adaptive-steps-resume.log`, WARN +
  `loopGuard` JSON) + `.lefthook.yml` `metrics-check` pre-commit para `config/stack-metrics.json`.

### Ejecutado — Sesión 6 (2026-08-31, F2.3 batch 1: 22 módulos library → logger)

- ✅ **F2.3 batch 1 — 22 módulos library migrados a logger estructurado** (commit `3b839d64`):
  watchtower checks (config/dashboard/data/infra/security/context/rebuild), ResilienceManager,
  session-context-log, session-metrics-tracker, response-cache (cache/sqlite),
  research-trends/fetch, smart-task-wrapper, model-error-interceptor, knowledge-synthesizer/config,
  language-service, token-ingest/nexus, session-close/phases, event-sourcing-api,
  adaptive-router/config.
- ✅ **Codemod `scripts/codemod-console-to-logger.ts` creado y corregido**: maneja imports
  multilínea, aliasing de colisiones `log`, y se añadió `scripts/*.ts` al tsconfig para que quede
  lint-clean. Reutilizable para futuros batches de F2.3.
- ✅ **CLIs conservan `console.*` por diseño**: revertidas las migraciones en secciones CLI
  (`main()`/`cli()`) que producen stdout parseable (JSON/status): version-sync, setup-branch-
  protection, complete-stack-fix, rescue-database, zcode-sync, post-edit-graphify, delivery/gate,
  adaptive-router/index, static-gates, deployment-prerequisites, credentials-inventory,
  knowledge-synthesizer/index.
- ✅ Typecheck + lint + 6/6 suites de test en verde.
- 🔲 **F2.3 en curso**: quedan ~5.000 `console.*` en src/ para próximos batches (usar el codemod).

### Ejecutado — Sesión 5 (2026-08-31, F2.4 completado a 0 `any` + PR #172)

- ✅ **PR #172 MERGED** a `main` (bypass admin, CI 100% verde incluido Production Gate); merge
  commit `67fe87a9`. PR #171 cerrado como supersedido. Rama local reseteada a `origin/main`.
- ✅ **F2.4 COMPLETADO — 0 `any` en `src/`** (objetivo del plan: 0). Erradicados los últimos 38
  `any` en 23 archivos (commit `3fe142a0`): interfaces de dominio reales (`AlertActions`,
  `GraphNode`, `CacheHookSystem`, `CacheModule`, `StackConfig`, `ReceiptFinding`, `AgentConfig`),
  resultados de better-sqlite3 tipados, `DatabaseManager` lazy-load tipado, `unknown` + narrowing en
  catch/deepMerge/getTimeout, anotaciones redundantes eliminadas. Typecheck + lint pasan.
- ✅ **Watchtower**: 102 PASS / 2 WARN / 0 FAIL (24 componentes).
- 🔲 **F2.3 en curso**: migrar `console.*` → logger en módulos library (5.331 `console.*` en src/;
  ~120 en ~23 archivos library reales; CLIs conservan `console.*` por diseño).

### Ejecutado — Sesión 4 (2026-08-22, dominios ×8 + tipado -84% + skills)

- ✅ **F2.2: 8 dominios completados** (35 archivos fuera de la raíz): `src/tokens/` (13),
  `src/retrieval/` (3), `src/compression/` (3), `src/web/` (6), `src/research/` (2), `src/design/`
  (3), `src/humanize/` (2), `src/planning/` (3). ~120 referencias reescritas (scripts npm, configs
  pipeline, hooks, rutas por segmentos, docs, tests); grafo regenerado; tests por dominio
  verificados (web 14/14, witr 10/10, domains 53/53, retrieval 5/5). Quedan ~250 archivos raíz para
  ~10 dominios más (security, orchestration, ops, content…).
- ✅ **F2.4 batch 3: 218 → 35 `any` (-84%)** — 100 eliminados en 28 archivos (interfaces
  SecurityIssue, filas SQLite ×4, skill-loader re-tipado con paridad de 175 skills, trust-layer
  contracts, global tipado). Los 35 restantes viven en archivos pendientes de su propia migración de
  dominio.
- ✅ **F4.3 completo — skills sin duplicación**: 60 duplicadas resueltas (43 merges de frontmatter —
  se recuperaron 31 descripciones que el migrador perdía por un bug de YAML multilinea —, 7 merges
  de cuerpo, 60 stubs DEPRECATED en .opencode, cero borrados); `skills/INDEX.md` regenerado (263
  filas) por `src/skills-index-generator.ts` + `npm run skills:index`; 11 links rotos `[eferences/`
  reparados.
- Commits sesión 4: `7052c976` (web), `8b6dd659` (research/design/humanize/planning), `7b5d5d6a`
  (any batch 3 + parte de skills), `b9a3e2d8` (skills F4.3 + index).

### Ejecutado — Sesión 3 (2026-08-22, dominios + Sprint A/B comercial)

- ✅ **F2.2 iniciado de verdad — 3 dominios movidos** con patrón replicable (git mv → fix imports →
  rewrite refs string+segment → typecheck/tests/smoke): `src/tokens/` (13 archivos, 58 refs),
  `src/retrieval/` (3, 12), `src/compression/` (3, 17). 19 archivos fuera de la raíz; grafo
  regenerado tras cada move. Quedan ~10 dominios (security, orchestration, ops, content…).
- ✅ **F2.4 batch 2**: 65 `any` eliminados en 17 archivos (interfaces de filas SQLite en backlog,
  DbManagerLike facades, Severity unions + type-guards, catch-unknown). Total: **218 → 128 (-41%)**.
- ✅ **Fix ESM preexistente**: `model-fallback-runtime.ts` crasheaba al ejecutarse directo
  (`require.main` en ESM) — reemplazado por el check canónico `import.meta.url` del stack.
- ✅ **F5 Sprint A 100%**: A2 manifiesto auto-consistente (fixed-point, idempotente, 383 archivos),
  A3 rutas 15D reparadas (65/65 assets verifican con gv_publisher), A4 kit 06 HISTÓRICO, A5 verdad
  de métricas (`99_METRICS_TRUTH`, 0 publicaciones reales documentadas).
- 🔄 **F5 Sprint B drafts completos** (`11-SPRINT-B-SELL-ENABLE/`): modelo de pricing con benchmarks
  verificados (USD 495/4h Improving, Maven/MIT/JHU como comparables de academia), sección 13 de
  propuesta lista, 3 borradores legales (25.326/24.240 citadas, disclaimer profesional), landing
  self-contained con contador honesto "casos: 0". Pendiente del dueño: números finales, beachhead,
  revisión legal, demo 90s, payment links (B4).
- Commits sesión 3: `20a02875` (tokens), `40bef389` (retrieval), `466676a4` (compression), tipados
  batch 2, fix ESM.

### Ejecutado — Sesión 2 (2026-08-22, "cero errores/warnings/inactivos")

- ✅ **Watchtower 95/95 — 0 WARN — 0 FAIL** (primera vez): ml-embeddings arreglado de raíz (el
  directorio `.atl/ml-embeddings/` que la watchtower vigilaba no lo generaba nadie — ahora
  `skill-embedder.ts` escribe 419 archivos de embedding por skill); daemons codegraph/dashboard-ws
  revividos; check security valida `renovate.json` (política single-bot).
- ✅ **F0.6 resuelto de verdad — graphify NATIVO**: `src/cli/graphify-build.ts` construye el grafo
  desde cero (TypeScript compiler API, dos pasadas para resolución completa de calls, comunidades
  por label propagation). Grafo: **4.435 nodos / 8.500 edges** (histórico: 1.410/1.763). `build` y
  `update` son el mismo comando nativo; query/explain verificados; 4 tests unit propios; AGENTS.md
  reactivado.
- ✅ **F1.5 completo**: baseline de cobertura real medido (62% agregado src/) y umbral subido 30→40%
  (branches 30) en `tests/coverage-config.json`.
- ✅ **F2.4 batch 1**: singletons DB tipados con `DatabaseManager` real (error-memory,
  token-tracker, event-sourcing, adaptive-router), rows Nexus tipadas en compare-tokens-sessions,
  severidad como union. 218→193 `any` (erradicación incremental continúa).
- ✅ Commit checkpoint fase 0+1: `2267d6eb` (91 archivos).
- ✅ **F5 Sprint A (dedup MASTER)**: 488 → **401 archivos activos**, 87 duplicados exactos (SHA-256)
  movidos a backup (cero borrados, backup íntegro verificado), **0 hashes duplicados** fuera del
  backup, 18 MB liberados, manifiesto auditable `99_DEDUP_MANIFEST_2026-08-22.json`. Corrección del
  estimado: el piso del dedup exacto es 401 (no ~300) — las 78 canónicas de los grupos duplicados
  son contenido único; bajar más requiere retirar generaciones enteras (decisión de contenido del
  dueño, documentada en el plan del MASTER).
- ✅ Commit sesión 2: `d3ac8fea` (graphify nativo + watchtower 95/95 + cobertura 40% + tipados).

### Ejecutado — Sesión 1 (2026-08-22, verificado: typecheck ✓ · eslint ✓ · full test suite 5/5 ✓ · vitest 52/52 ✓ · markdownlint ✓ · lefthook ✓ · dashboard build ✓)

- ✅ **F0.1** — `VERSION`=3.8.2 sincronizado; entrada 3.8.2 + nota 3.6/3.7 en CHANGELOG;
  `releases/latest-version.json` reparado contra el release real v3.8.2 del repo público (sha256
  `6adbee59…ba75` verificado descargando el binario); `RELEASE-v4.0.0.md` y `ARCHITECTURE-STATUS.md`
  archivados en `docs/releases/` como snapshots fechados.
- ✅ **F0.1b** — `src/tools/version-sync.ts` + `npm run version:check` + job `version-sync` en CI
  (gate).
- ✅ **F0.2** — Purgados del índice: `.pnpm-store/`, `.local/root-files-20260812/` (15 archivos),
  `sbom.json`/`sbom/` (gitignored ahora, CI genera el canónico), fixtures de debug movidos a
  `tests/fixtures/`, governance audit a `docs/governance/`.
- ✅ **F0.3** — Workspace pnpm real (`packages:` con `apps/web-dashboard` + `packages/*`; las apps
  retiradas quedan fuera del workspace); lockfile único; `better-sqlite3` en `dependencies` (raíz) y
  declarado en el dashboard; dashboard `3.3.3`→`3.8.2`.
- ✅ **F0.4** — Dockerfile: usuario non-root `app` (chown completo), `pnpm rebuild --pending` para
  nativas (better-sqlite3/esbuild), pnpm global fuera del runner. Compose: sin `version:` obsoleta,
  imágenes observabilidad pineadas (jaeger 1.62.0, prometheus v2.53.0, otel 0.108.0), comandos de
  websocket-server/health-api apuntando a artefactos reales (`npx tsx` en vez de `server/dist/`
  inexistente).
- ✅ **F0.5** — Onboarding reparado: `gv verify`→`gv check` (12 archivos), paso 3 del
  getting-started → `npm run setup:complete`, prerrequisitos realistas (Node 20+, pnpm 11+), guía
  duplicada archivada, 6 referencias a `docs/AGENTS.md` inexistente corregidas (21 archivos en
  total).
- ✅ **F0.6** — Graphify declarado INACTIVE en AGENTS.md (grafo nunca commiteado, sin builder en el
  código; follow-up: `graphify.ts build` nativo).
- ✅ **F1.1** — `ci.yml` es el único entrypoint (absorbe pr.yml, push-checks.yml, security.yml —
  eliminados; labeler.yml dedicado se mantiene); concurrency + cancel-in-progress + permissions +
  timeout-minutes en todos los jobs; docker/governance solo en push.
- ✅ **F1.2** — Gates reales: `pnpm audit` sin `|| echo`; Trivy `exit-code: 1`; pseudo-SAST
  eliminado; SRE checks renombrados "informational, non-gating" (decisión explícita); trufflehog
  decorativo eliminado del pre-commit; workflow-validator estricto; container-scan del pre-push
  regenera el SBOM antes de escanear.
- ✅ **F1.4** — Job `node-compat` matriz Node 22/24 (baseline sigue en 22); 12 actions pineadas por
  SHA resuelto contra la API de GitHub (setup-node, gitleaks, trivy, codeql, codecov v4→v5, labeler,
  markdownlint); SHAs de checkout/pnpm unificados.
- ✅ **F1.5 (parcial)** — e2e en CI (job dedicado `npx tsx --test tests/e2e/*.test.ts`); vitest del
  dashboard integrado al job dashboard. Umbral de cobertura 30→40% queda pendiente de medir
  baseline.
- ✅ **F1.6** — Dependabot eliminado (Renovate queda como único bot).
- ✅ **F2.1 (parcial)** — Paquete `packages/shared` (`@gentle-vanguard/shared`): BM25 canónico
  (opciones `longTokenBonus`/`maxScore` preservan el comportamiento histórico de cada consumidor),
  `parse-args` (sucesor de las 29 copias), `fs-json` (84 copias), `Result<T,E>`; 11 tests propios;
  `retrieval-grader.ts` y `structural-compression.ts` ya consumen el BM25 compartido (drift
  eliminado); logger tipado sin `any`. Pendiente: codemod de los 29 `parseArgs` y migración del
  resto.
- ✅ **F4.1** — Cifras vivas corregidas en 11 archivos (Nexus 23/7, watchtower 95/21) con comando de
  verificación anti-deriva.

### Pendiente inmediato (siguiente sesión)

- F1.3 changesets/release-please (version-sync.ts es el interino).
- F1.5 subir umbral cobertura 30→40% (medir baseline full-mode primero).
- F2.2 reorganización de `src/` por dominios (un PR por dominio, barriles de compatibilidad).
- F2.3 ✅ cerrado (scope library completo; console.* restantes = CLI por diseño); F2.4 ✅ 0 `any`;
  consolidación modular nativa (mantenimiento); F2.6 ConfigService/DI; F2.8 ✅ CLI `gv` unificada;
  F2.7 en curso (tests dashboard).
- F5 Sprints A-D comerciales (ver `GENTLE_VANGUARD_MASTER/00-EVOLUTION-ACTION-PLAN-2026-08.md`).

---

## 0. Resumen ejecutivo

El stack está **técnica y funcionalmente sano** (watchtower 93/95 PASS, Nexus healthy con 23 tablas
y 7 migraciones, 120 archivos de test, seguridad de supply chain seria) y su fundación estratégica
comercial está en un percentil alto. Pero tiene **cuatro deudas estructurales** que hoy limitan su
escalado horizontal y vertical, y su capacidad de monetización:

| #   | Deuda estructural                                                                                                                                                       | Impacto                                                                                                              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1   | **Confianza falsa en CI/CD**: gates de seguridad silenciadas (`\|\| echo`, `exit-code: 0`), workflows triplicados, versionado divergente en 4 fuentes                   | El pipeline aparenta proteger pero no bloquea; supply chain del `.exe` sin verificación de integridad                |
| 2   | **Monolito plano de 452 archivos TS**: 63% sueltos en raíz de `src/`, 29 `parseArgs` duplicados, 5.293 `console.*`, 218 `any`, 16 archivos >800 líneas                  | Cada feature nueva cuesta más; el duplicado con drift (BM25 ×2) genera comportamiento inconsistente                  |
| 3   | **Deriva documental masiva**: 4 corrientes de versión (3.5.0/3.8.x/4.0.0), cifras hardcodeadas caducadas en 10+ docs, onboarding roto, 60 skills duplicadas divergentes | Un newcomer (o un cliente que evalúa el repo) recibe información contradictoria; los agentes heredan cifras erróneas |
| 4   | **Comercial sin órganos de captura**: 0 pricing, 0 legal, 0 landing, 34% de archivos duplicados en el MASTER, lecciones esqueleto (180 palabras)                        | Madurez comercial 5/10: hoy no se puede cobrar formalmente pese a estrategia excelente                               |

**Veredicto:** la inversión en tooling es excepcional; el cuello de botella NO es "más
funcionalidad" sino **consolidar, automatizar la confianza, y completar la superficie comercial**.
Este plan se organiza en 5 fases + 1 workstream comercial paralelo, con quick wins inmediatos.

### Scores actuales (diagnóstico 2026-08-22)

| Dimensión                       | Score | Nota                                                                  |
| ------------------------------- | ----- | --------------------------------------------------------------------- |
| Salud operativa                 | 9/10  | 93/95 PASS; solo ml-embeddings FAIL y codegraph WARN                  |
| Arquitectura de datos/dashboard | 7/10  | Repository pattern + migraciones correctas; server WS monolítico      |
| Arquitectura de src/            | 4/10  | Flat, duplicado, sin DI, logging no estructurado                      |
| CI/CD                           | 5/10  | Duplicado, gates decorativas, sin versionado automático               |
| Seguridad                       | 7/10  | 4 scanners + SLSA + SBOM; pero allowlists amplias y gates silenciadas |
| Testing                         | 6/10  | 120 files; cobertura 30%, e2e fuera de CI, 3 runners mezclados        |
| Documentación                   | 4/10  | 283 docs con deriva severa y 3 onboardings rivales                    |
| Comercial (MASTER)              | 5/10  | Estrategia 9/10; ejecución de venta 1-3/10                            |

---

## 1. Principios base que se preservan (no negociables)

Todo cambio de este plan debe respetar las definiciones base del stack:

1. **TypeScript-first** (ADR-0002): nada de PowerShell nuevo; lo PS1 restante es legacy a archivo.
2. **No mock data**: todo dato del dashboard/observabilidad deriva de trazas reales.
3. **Security-first**: defense-in-depth de secret scanning, SLSA provenance, SBOM — se consolida, no
   se relaja.
4. **Evidence-based** (del propio plan comercial): no reclamar "production ready" sin log de
   instalación limpia, health report y rollback verificados.
5. **Agnóstico a la herramienta**: token tracking y skills funcionan con
   opencode/codex/claude/cursor.
6. **Compresión segura por modo**: `input` lossless-only, `output` lossy-ok (protege el razonamiento
   del modelo).
7. **Human-in-the-loop en publicación**: nada se publica remotamente sin approval (ContentJob gate).
8. **Canonical source única**: un mensaje/oferta/visual = una fuente de verdad (hoy violado; se
   restaura).

---

## 2. Diagnóstico consolidado (evidencia clave)

### 2.1 Salud operativa (verificado hoy)

- Watchtower: **93 PASS / 1 WARN / 1 FAIL** — FAIL: `ml-embeddings` (ISSUES); WARN: codegraph daemon
  booteando. `witr` no puede trazar puertos (binario ausente).
- Nexus: healthy — 23 tablas, 45.829 filas, 7,73 MB, 7 migraciones, WAL 0 MB.
- **`graphify-out/graph.json` NO EXISTE** (`graphify status` → `exists: false`): todo el workflow de
  knowledge graph documentado en AGENTS.md está inoperante en este clon.
- Dashboard WS: API 200 OK, watchdog vivo.

### 2.2 Arquitectura (src/ — 452 archivos .ts, ~125.540 líneas)

- **286 archivos (63%) sueltos en raíz de `src/`**; `src/logs/` vacío y `src/tools/` solo tiene un
  .md (directorios muertos); `src/review/auto-code-review.ts` convive con
  `src/autonomous-review/auto-code-review.ts`.
- **Duplicación**: `parseArgs()` definido **29 veces**; `process.argv.slice(2)` en 227 archivos;
  `tokenize()` ×6; **BM25 duplicado con drift funcional** (`src/retrieval/retrieval-grader.ts:66` vs
  `src/compression/structural-compression.ts:207` — el segundo suma un bonus `+0.3` que el primero
  no tiene, con las mismas constantes duplicadas); 84 helpers `ensureDir/readJson/writeJson`
  repetidos.
- **Logging**: existe `src/utils/logger.ts` estructurado pero solo **4 archivos lo importan** vs
  **5.293 llamadas `console.*`**; ~46 `catch {}` vacíos tragan errores.
- **Tipado**: 218 `any`/`as any` (`eslint.config.js:41` tiene `no-explicit-any` apagada);
  `noUnusedLocals/Parameters: false` (`tsconfig.json:15-16`).
- **16 archivos >800 líneas**; peores: `src/core/maintenance-watchtower.ts` (1.958),
  `apps/web-dashboard/server/websocket-server.ts` (1.722), `src/session-close-orchestrator.ts`
  (1.217).
- **12+ singletons** con `getInstance()` dispersos y sin contenedor/DI; 249 `process.env` y 751
  `process.exit` sin capa de configuración tipada.
- **Workspace pnpm roto**: `pnpm-workspace.yaml` raíz sin `packages:`; dashboard con su propio
  lockfile → dos instalaciones independientes con node_modules duplicados.
- **Dependencia fantasma**: `better-sqlite3` se usa en runtime (`server/database/manager.ts:11`)
  pero está en `devDependencies` de la raíz y no está declarado en el dashboard.
- **Frontend**: React 18 correcto (lazy routes, 10 hooks, i18n) pero solo 7/40+ componentes con
  tests; toolchain fragmentada (ESLint 8 vs 10, TS 6 vs 5.9, vitest 3.2 vs 3.1).
- **package.json raíz**: 303 scripts npm (uno por archivo suelto), sin CLI unificada pese a que
  `src/cli/gv.ts` ya existe con 23 comandos.

### 2.3 CI/CD, testing y seguridad

- **Triple disparo**: `ci.yml` + `pr.yml` + `push-checks.yml` + `security.yml` → en un PR a main
  corren lint, tests, gitleaks, secretlint, Trivy y coverage **dos veces**.
- **Gates que nunca fallan**: `pnpm audit ... || echo "Audit found issues"`; Trivy `exit-code: 0`;
  "SAST" que en realidad es `pnpm lint` con `continue-on-error: true` (`ci.yml:164-166`); SLO checks
  con `|| true`.
- **Versiones**: `VERSION`=3.8.1, `package.json`=3.8.2, `CHANGELOG` sin entrada 3.8.2 (y saltos
  3.6/3.7 faltantes), `releases/latest-version.json`=3.5.0 con **`sha256` vacío** (el auto-updater
  distribuye un `.exe` sin verificación de integridad), `RELEASE-v4.0.0.md` anuncia 4.0.0
  inexistente.
- **Node**: `.nvmrc` = v24.15.0 pero CI fija Node 22 — nadie prueba lo que se desarrolla. Sin
  matriz.
- **Actions**: mezcla de 3 SHAs de checkout, tag-pinning mutable en ~12 actions, `codecov-action@v4`
  desactualizada.
- `ci.yml` sin `concurrency`, sin `timeout-minutes`, sin `permissions`.
- **Docker**: multi-stage alpine pero **corre como root** (sin `USER`); runtime interpreta TS vía
  `npx tsx`; compose con `version:` obsoleta e imágenes `:latest`.
- **Duplicidad de bots**: Dependabot + Renovate activos simultáneamente.
- **Artefactos trackeados que no deberían estar**: `.pnpm-store/v11/index.db`,
  `.local/root-files-20260812/` (11 archivos de sesión personal),
  `tests/gga-comprehensive-output.log`, `test-agent-broken*.json` en raíz, `sbom.json` (511 KB,
  caduca al commitearse).
- **Testing**: 120 files (83 unit, 11 integration, 8 security, 5 eval, 2 e2e…); cobertura agregada
  30%/25% branches; **e2e no corre en CI** (solo con `--all`); 3 runners conviven (node:test,
  vitest, runner custom).
- **Allowlists amplias**: gitleaks allowlista `tests/` completo y regex genérica `master.key`;
  `keys/master.key` existe en disco (no trackeado, correcto) pero referenciado desde
  `config/model-router.json:273`.

### 2.4 Documentación y gobernanza

- **Cifras caducadas repetidas en cadena**: "12 tablas/3 migraciones" en 6 ubicaciones (AGENTS.md,
  NEXUS-NORMATIVA.md, ADR-007, 2 skills validate-stack, material de presentación) vs realidad 23/7;
  "95 checks/13 componentes" en 5+ docs vs 21 componentes reales; skills contadas como
  135/127/263/419 según el doc.
- **Onboarding roto**: `README.md:56` usa `gv verify` (no existe → `gv check`);
  `docs/getting-started/README.md:31` manda ejecutar un `.ps1` eliminado; `CLAUDE.md:75` referencia
  `docs/AGENTS.md` inexistente (7 archivos lo citan); 3 onboardings rivales (QUICK-START,
  getting-started, guides/GETTING-STARTED) con 3 sets de cifras.
- **Skills**: 60 de 263 duplicadas entre `skills/` y `.opencode/skills/` con contenido divergente;
  `public/skills/` (385) sin política de sincronización documentada; `SKILL_INDEX.md` eliminado pero
  aún referenciado.
- **Normativas**: 144 comentarios `REF-OBSOLETA` en `rules/` apuntando a scripts PS1 eliminados;
  `NORM-TS-001` prohíbe PowerShell mientras `POWERSHELL-STANDARDS.md` sigue vigente;
  `README-GOVERNANCE.md` exige secciones que el README actual no tiene (política violada
  silenciosamente); `openspec/config.yaml` aún declara "PowerShell 7.4+, 135 skills" (congelado en
  la era pre-migración).
- **Deuda marcada en código**: 63 TODO/FIXME/HACK, 49% concentrados en session-close (17) y review
  RDD (14).

### 2.5 GENTLE_VANGUARD_MASTER (comercial) — madurez 5/10

**Fortalezas**: plan comercial v1.0 de calidad inusual (3 productos, 5 audiencias, escalera de 7
peldaños, funnel completo, guardrails anti-sobrepromesa, release gates de evidencia); control
maestro XLSX de 11 hojas; currículo 12 módulos × 22h estructuralmente impecable; certificados con
prudencia regulatoria argentina; automatización nivel 0 (empaquetado con gate de revisión) honesta
sobre sus límites.

**Debilidades (bloqueantes de venta)**:

1. **Pricing cero** — ni un número en 487 archivos; la plantilla de propuesta tiene la sección
   "Inversión" vacía.
2. **Legal inexistente** — sin T&C, privacidad, reembolsos, ni licenciamiento del currículo.
3. **Sin superficie web** — no hay landing, ni demo 90s (marcada "Pendiente" por el propio control),
   ni captura de leads.
4. **Evidencia social en 0** — KPIs y feedback vacíos; calendario dice "18 publicados" vs métricas
   reales 0.
5. **34% de archivos duplicados** (165/487, verificado por hash): 01↔02 (32), 01↔03 (16), 01↔04
   (15), flyers ×3; dos generaciones de decks de oferta (6 slides vs 10 slides) sin marcador de
   vigencia.
6. **Lecciones esqueleto**: los 12 DOCX "FINAL" tienen ~180-195 palabras con secciones idénticas
   copiadas; son guiones para instructor experto, no material autocontenido.
7. **Manifiesto 15D con rutas rotas** (`/mnt/data/...` de un contenedor que ya no existe); kit 06
   desincronizado del repo (3 jobs vs 21 reales); manifiesto raíz `00-FILE_MANIFEST_FINAL.json`
   inconsistente consigo mismo.
8. **Certificación sin flujo**: solo 1 de 7 variantes tiene DOCX editable; columna "Verificación"
   del registro vacía.

---

## 3. Plan de acción

Estructura: cada acción tiene **Qué / Por qué / Cómo / Cuándo / Aceptación**. Las fases son
acumulativas; el workstream comercial (F5) corre en paralelo desde el día 1.

### Timeline maestro

| Fase | Horizonte   | Tema                    | Resultado clave                                                        |
| ---- | ----------- | ----------------------- | ---------------------------------------------------------------------- |
| F0   | Semana 1    | Quick wins de confianza | Versiones sincronizadas, artefactos purgados, integridad del `.exe`    |
| F1   | Semanas 2-4 | CI/CD de verdad         | 1 entrypoint, gates reales, versionado automático, e2e en CI           |
| F2   | Meses 2-3   | Consolidación de código | `@gv/shared`, src/ por dominios, logger único, DI ligera               |
| F3   | Meses 3-6   | Escala H+V              | Plugin architecture, ConfigService, evaluación continua, multi-runtime |
| F4   | Continuo    | Gobernanza viva         | Métricas vivas, normativas nuevas, docs sin deriva                     |
| F5   | Paralelo    | Comercial (MASTER)      | De 5/10 → 7/10: primer piloto pago factible                            |

---

### FASE 0 — Quick wins de confianza (semana 1, costo ~0)

**F0.1 — Sincronizar versiones y sellar el auto-update**

- **Qué**: fijar `3.8.2` como verdad única (VERSION, CHANGELOG con entrada 3.8.2 + retro-entradas
  3.6/3.7); completar el `sha256` de `releases/latest-version.json` y verificarlo en
  `auto-update.yml`; mover `RELEASE-v4.0.0.md` y `ARCHITECTURE-STATUS.md` a `docs/releases/` como
  snapshots fechados.
- **Por qué**: 4 corrientes de versión + un binario distribuido sin hash = la cadena de supply-chain
  más débil del stack y el daño reputacional más fácil de evitar.
- **Cómo**: edición manual única + un script `src/tools/version-sync.ts` que compare VERSION ↔
  package.json ↔ CHANGELOG y falle si divergen (hook pre-commit + job CI).
- **Cuándo**: día 1-2.
- **Aceptación**: `npm run version:check` verde en CI; `sha256` no vacío; ningún doc raíz con
  versión ≠ package.json.

**F0.2 — Purgar artefactos trackeados**

- **Qué**: `git rm -r --cached .pnpm-store .local tests/gga-comprehensive-output.log`; mover
  `test-agent-broken*.json`/`test-opcode-broken.json` a `tests/fixtures/`; sacar `sbom.json` y
  `sbom/` del git (ya se generan en CI como artifact); mover
  `GENTLE-VANGUARD-GOVERNANCE-AUDIT-REPORT.json` a `docs/governance/`.
- **Por qué**: un store de pnpm binario e informes de sesión personales en git contaminan el
  historial y la imagen pública del repo (crítico si el repo es vitrina comercial).
- **Cómo**: comandos git anteriores + `.gitignore` ya cubre; evaluar history-rewrite del
  `.pnpm-store` si contuvo metadatos sensibles.
- **Cuándo**: día 2.
- **Aceptación**: `git ls-files | grep -E "pnpm-store|.local/"` vacío; CI verde.

**F0.3 — Corregir dependencia fantasma y workspace**

- **Qué**: mover `better-sqlite3` + `@types/better-sqlite3` a `dependencies` (raíz) y declararlo en
  `apps/web-dashboard/package.json`; añadir `packages: ['apps/*', 'packages/*']` a
  `pnpm-workspace.yaml` raíz y eliminar el `pnpm-lock.yaml`/`pnpm-workspace.yaml` anidado del
  dashboard.
- **Por qué**: hoy el dashboard solo funciona por ascenso de directorios (frágil a cualquier
  reestructuración) y el "workspace" duplica instalaciones completas.
- **Cómo**: edición de package.json + `pnpm install` para regenerar el lockfile único; verificar
  build del dashboard.
- **Cuándo**: día 3.
- **Aceptación**: `cd apps/web-dashboard && npm run build` exit 0 sin resolver dependencias por
  ascenso; un solo lockfile en el repo.

**F0.4 — Docker non-root**

- **Qué**: en el stage runner del `Dockerfile` añadir
  `RUN addgroup -S app && adduser -S app -G app` + `USER app` y ajustar permisos de los directorios
  de runtime; en compose quitar `version:` y pinear tags de jaeger/prometheus/otel.
- **Por qué**: correr como root es la primera línea de cualquier baseline (Trivy/Grype lo reportan);
  `:latest` rompe reproducibilidad.
- **Cuándo**: día 3-4. **Aceptación**: `docker run` muestra usuario no-root; `docker compose config`
  sin warnings.

**F0.5 — Reparar los docs de entrada rotos**

- **Qué**: `gv verify` → `gv check` en `README.md:56`; reemplazar el paso 3 de
  `docs/getting-started/README.md` (bootstrap .ps1 inexistente) por `npm run setup:complete`;
  eliminar `docs/guides/GETTING-STARTED.md` (pide "TypeScript 7+", cifras de 127 skills) moviéndolo
  a `.archive/`; reparar las 7 referencias a `docs/AGENTS.md`.
- **Por qué**: el onboarding es la primera experiencia de un cliente/alumno que evalúa el stack; hoy
  falla en el paso 3.
- **Cuándo**: día 4-5. **Aceptación**: un clon limpio + README lleva a un `watchtower:health` verde
  sin tocar un doc extra.

**F0.6 — Decidir el destino de graphify**

- **Qué**: o bien regenerar el grafo (`npm run graphify -- update .` y verificar `graph.json`), o
  desactivar la sección de AGENTS.md y los pasos del pipeline hasta que exista. Documentar la
  decisión en un ADR.
- **Por qué**: AGENTS.md ordena "primero consultar el grafo" pero `graph.json` no existe → cada
  sesión paga el costo de descubrir el workflow roto (ya ocurrió en esta revisión).
- **Cuándo**: día 5. **Aceptación**: `npm run graphify -- status` → `exists: true`, o AGENTS.md sin
  referencias activas al grafo.

---

### FASE 1 — CI/CD de verdad (semanas 2-4)

**F1.1 — Un solo entrypoint de CI**

- **Qué**: consolidar `ci.yml`, `pr.yml`, `push-checks.yml` y `security.yml` en un workflow `ci.yml`
  que invoque los reusables existentes (`reusable-lint`, `reusable-test`, `reusable-security-scan`,
  `reusable-docker`); añadir `concurrency: cancel-in-progress`, `timeout-minutes` por job y
  `permissions: contents: read` top-level.
- **Por qué**: hoy un PR a main ejecuta gitleaks/trivy/secretlint/lint/tests/coverage dos veces —
  costo duplicado y gates contradictorias (audit estricto en ci.yml vs audit silenciado en el
  reusable).
- **Cuándo**: semana 2. **Aceptación**: en un PR a main, cada check aparece exactamente una vez;
  minutos de CI reducidos ~40%.

**F1.2 — Gates reales (eliminar la seguridad decorativa)**

- **Qué**: quitar `|| echo "Audit found issues"` del job npm-audit; Trivy `exit-code: 0` → `1` para
  CRITICAL/HIGH; eliminar el pseudo-SAST de `ci.yml:164-166` o configurar `eslint-plugin-security`
  de verdad en `eslint.config.js`; decidir si error-budget/SLO checks son gates (sin `|| true`) o
  informes (etiquetados como tales); reparar el trufflehog de pre-commit
  (`--fail=false ... || exit 0` en `.lefthook.yml:33-37`) o eliminarlo (gitleaks+secretlint ya
  cubren).
- **Por qué**: la confianza falsa es el riesgo #1 del pipeline: el equipo cree que está protegido y
  no lo está. Mejor 5 gates reales que 15 decorativas.
- **Cuándo**: semana 2. **Aceptación**: cada paso de seguridad puede fallar el build y se demuestra
  con un test de inyección (un secret falso en una rama sacrifice).

**F1.3 — Versionado automático de releases**

- **Qué**: adoptar **changesets** (encaja con monorepo pnpm y permite CHANGELOG por paquete) o
  release-please; unificar las 4 fuentes en una (`package.json` como fuente, `VERSION` generado);
  hook pre-commit que verifique sincronía; mover el flujo de `release.yml` a tags automáticos.
- **Por qué**: el versionado manual ya divergió 3 veces; con publicaciones y alumnos, cada
  desincronía es un ticket de soporte.
- **Cuándo**: semana 3. **Aceptación**: un merge a main produce versión+changelog sin edición
  manual; `npm run version:check` en CI.

**F1.4 — Matriz de Node y actions pineadas**

- **Qué**: matriz `node: [22, 24]` (alineada con `.nvmrc` v24.15.0 y `engines >=20`); pinear por SHA
  las ~12 actions tag-pinned restantes; unificar los 3 SHAs de checkout y 2 de pnpm/action-setup;
  actualizar `codecov-action@v4`→`v5`.
- **Por qué**: hoy nadie prueba la versión que usan los devs; las tags mutables son vector de
  supply-chain (conflicto directo con el principio security-first).
- **Cuándo**: semana 3. **Aceptación**: CI verde en 22 y 24;
  `grep -E "uses:.*@v[0-9]" .github/workflows/*.yml` solo devuelve actions sin SHA disponible o
  justificadas.

**F1.5 — E2e y cobertura con dientes**

- **Qué**: job e2e separado en CI (hoy solo corren con `--all`); subir el umbral agregado de
  cobertura 30%→**40%** (hitómetro al roadmap propio de 50% Q3-2026:
  `tests/coverage-config.json:49-61`); consolidar el doble canal de cobertura (artifact + codecov)
  en uno.
- **Cuándo**: semana 4. **Aceptación**: e2e verde en cada PR; coverage gate bloquea por debajo de
  40%.

**F1.6 — Un bot de dependencias**

- **Qué**: mantener Renovate (ya tiene grouping+automerge) y desactivar Dependabot.
- **Por qué**: dos bots = PRs duplicados de las mismas actualizaciones.
- **Cuándo**: semana 2 (5 min). **Aceptación**: cero PRs duplicados de dependencias en 2 semanas.

---

### FASE 2 — Consolidación de código (meses 2-3)

**F2.1 — Paquete interno `@gv/shared` (matar la duplicación)**

- **Qué**: crear `packages/shared/` con: `parse-args.ts` único (reemplaza 29 implementaciones y el
  idiom de 227 archivos), `bm25.ts` + `tokenize.ts` compartidos (fusiona `retrieval-grader.ts:66` y
  `structural-compression.ts:207`, decidiendo explícitamente el bonus `+0.3`), `fs-json.ts`
  (consolida 84 helpers), `result.ts` (tipo `Result<T,E>` para eliminar los `catch {}` vacíos).
- **Por qué**: la duplicación con drift ya produce comportamiento inconsistente (dos BM25 distintos
  = scores distintos para el mismo input). Es la mayor deuda de mantenibilidad.
- **Cómo**: crear el paquete con tests → codemod progresivo por dominio (empezando por los 29
  `parseArgs`) → `npm run codemod:shared` como script re-ejecutable.
- **Cuándo**: mes 2. **Aceptación**: `grep -r "function parseArgs" src/ | wc -l` = 1; cero
  diferencias funcionales en los tests de retrieval-grader y structural-compression.

**F2.2 — Reorganizar `src/` por dominios**

- **Qué**: mover los 286 archivos raíz a módulos: `src/retrieval/`, `src/tokens/`, `src/security/`,
  `src/orchestration/`, `src/ops/`, `src/compression/`, `src/content/`…; eliminar `src/logs/` y
  `src/tools/` muertos; resolver la colisión `auto-code-review.ts`; mantener barriles (`index.ts`)
  para no romper los 303 scripts npm durante la transición.
- **Por qué**: con 452 archivos, el plano impide ownership por dominio y hace imposible razonar
  sobre límites; es prerrequisito para escalar en horizontal (equipos/agentes por dominio).
- **Cómo**: migración asistida por dominio con `git mv` (preserva historial), un PR por dominio, CI
  como red de seguridad.
- **Cuándo**: meses 2-3, incremental. **Aceptación**: 0 archivos .ts en raíz de `src/` (o <10
  documentados); builds y tests verdes en cada PR.

**F2.3 — Logger estructurado único**

- **Qué**: adoptar el logger existente (`src/utils/logger.ts`, tipándolo con `data?: unknown` en
  lugar de `any`) o migrar a `pino`; salida JSON a `.logs/`; auditar los ~46 `catch {}` vacíos
  convirtiéndolos en `logger.warn` con contexto.
- **Por qué**: 5.293 `console.*` sin niveles ni estructura hacen imposible correlacionar con las
  trazas OTLP que ya exporta el stack — observabilidad a medias.
- **Cuándo**: mes 2-3 (codemod). **Aceptación**: `grep -r "console.log" src/ | wc -l` < 50 (solo
  CLIs interactivos); todo error logueado con contexto estructurado.

**F2.4 — Endurecer TypeScript**

- **Qué**: reactivar `@typescript-eslint/no-explicit-any` como warn → error en 2 hits; activar
  `noUnusedLocals/noUnusedParameters`; erradicar los 218 `any` empezando por `utils/logger.ts` y
  `compare-tokens-sessions.ts`.
- **Cuándo**: mes 3. **Aceptación**: `grep -rE ": any|as any" src/ | wc -l` = 0; lint sin warnings
  de any.

**Consolidación modular nativa — mantenimiento actual**

- **Qué**: mantener la separación por dominios ya integrada en `src/` y en el servidor del
  dashboard; documentar nuevos módulos detrás de entradas/barrels estables.
- **Por qué**: la modularidad nativa mantiene ownership, testeo y revisión acotados sin introducir
  una fase o producto separado.
- **Cuándo**: mantenimiento continuo. **Aceptación**: imports estables, documentación alineada y
  validaciones del stack verdes.

**F2.6 — DI ligera + ConfigService**

- **Qué**: introducir un contenedor mínimo (no hace falta framework: un `createContainer()` con
  factories) que reemplace los 12 `getInstance()` dispersos; extraer `ConfigService` tipada que
  centralice los 249 `process.env` con validación zod (ya es dependencia) y defaults documentados.
- **Por qué**: los singletons dispersos obligan a hacks tipo `resetInstance()` en tests y crean
  orden de inicialización implícito entre pipeline steps; la config dispersa impide validar el
  entorno al arranque.
- **Cuándo**: mes 3. **Aceptación**: orquestadores testeables sin I/O real;
  `ConfigService.validate()` falla al arranque si falta un env requerido (fail-fast en vez de
  comportamiento raro a mitad de sesión).

**F2.7 — Dashboard: tests y toolchain**

- **Qué**: subir de 7 a ≥16 componentes con tests (40% — meta del propio coverage-config); alinear
  versiones via `catalog:` de pnpm (typescript, eslint, @typescript-eslint, vitest, @types/node);
  consolidar ESLint flat config en el dashboard.
- **Cuándo**: mes 3. **Aceptación**: `catalog:` en ambos package.json; 16+ componentes testeados.

**F2.8 — CLI unificada**

- **Qué**: consolidar los 303 scripts npm bajo `gv <comando>` (`src/cli/gv.ts` ya tiene 23
  subcomandos y la infraestructura); mantener aliases npm para los 20 más usados; documentar el mapa
  completo.
- **Por qué**: 303 scripts es una API imposible de descubrir; la CLI unificada es la superficie
  profesional para usuarios y alumnos.
- **Cuándo**: mes 3. **Aceptación**: `gv --help` lista dominios; docs de referencia generadas del
  propio CLI.

---

### FASE 3 — Escala horizontal y vertical (meses 3-6)

> Alineado con las prácticas 2026: evaluation-first, OTel como estándar de trazas, guardrails
> defense-in-depth (input → output → decisión), y observabilidad que captura el razonamiento, no
> solo stack traces.

**F3.1 — Vertical (profundidad por instancia): evaluación continua**

- **Qué**: convertir los 5 tests eval existentes en un pipeline de **evaluación continua** que corra
  en cada release sobre trazas reales del propio stack (Nexus ya tiene `traces` + `feedback`):
  dataset dorado de tareas de sesión, scoring automático (éxito/fracaso/tokens/coste), y regresión
  de calidad como gate.
- **Por qué**: el estándar 2026 es evaluation-first — los agentes fallan silenciosamente en su
  razonamiento; el stack ya captura las trazas (diferencial enorme vs la competencia) pero no las
  usa para auto-evaluarse.
- **Cuándo**: meses 3-4. **Aceptación**: un reporte de eval por release con tendencia; gate que
  bloquea regresión >X%.

**F3.2 — Vertical: guardrails defense-in-depth formalizado**

- **Qué**: mapear los guardrails existentes (prompt-injection-guard, secret-scanner,
  result-gatekeeper, correction-rules) a las 3 capas del patrón 2026 — input filters → output
  validators → decision controls (umbrales de autonomía, requisitos de evidencia, escalación
  humana)— y documentar el mapa en un ADR; añadir PII-redaction al output path (hoy solo secrets).
- **Por qué**: los componentes existen y son buenos, pero no hay un modelo explícito de colocación —
  que es donde está el diseño (la colocación importa tanto como el guardrail mismo).
- **Cuándo**: mes 4. **Aceptación**: ADR del mapa de guardrails; test end-to-end que demuestre que
  un input malicioso es bloqueado en la capa correcta.

**F3.3 — Horizontal (más instancias/cargas): runtime ports & adapters**

- **Qué**: formalizar ports para las dependencias de infraestructura: `StoragePort` (SQLite hoy;
  path a Postgres para multi-instancia), `QueuePort` (in-process hoy; path a Redis/BullMQ para colas
  de sesión distribuidas), `TracingPort` (OTLP hoy). El `DatabaseManager` ya tiene repos inyectables
  — extender el patrón hacia fuera.
- **Por qué**: escalar en horizontal (varias sesiones/máquinas/cohortes de alumnos concurrentes)
  requiere que el estado compartido y las colas salgan del proceso; con ports, el swap es
  configuración, no reescritura.
- **Cuándo**: meses 4-5. **Aceptación**: ADR de arquitectura hexagonal aplicada; `StoragePort` con 2
  implementaciones (sqlite en memoria para tests, sqlite disco para prod) demostrando el swap.

**F3.4 — Horizontal: plugin architecture para skills/agentes**

- **Qué**: definir el contrato de plugin (manifest + entrypoint + permisos declarados) que unifique
  `skills/`, `.opencode/skills/` y `public/skills/`; registry con validación de schema (zod) y ciclo
  de vida (install → verify → enable → deprecate).
- **Por qué**: 263 skills internas + 385 públicas sin contrato común ni política de sync es la mayor
  barrera para que terceros (alumnos, comunidad) contribuyan — que es exactamente el motor de
  adopción comercial.
- **Cuándo**: meses 4-6. **Aceptación**: una skill externa se instala con `gv skill install <url>`,
  pasa validación de schema y permisos, y aparece en el índice.

**F3.5 — Sostenibilidad económica del runtime**

- **Qué**: dashboard ejecutivo de coste sobre `token_usage`/`token_transactions` (ya hay 658M tokens
  históricos): coste por sesión/agente/dominio, proyección mensual, y alertas de presupuesto (el
  token-budget-guard ya mide; falta la superficie de decisión).
- **Por qué**: "que brinde ahorro" es un requisito explícito; los datos ya están — falta
  convertirlos en decisiones de routing (model-router perfiles cheap/balanced/premium).
- **Cuándo**: mes 5. **Aceptación**: panel "cost per outcome" visible; al menos 1 decisión de
  routing documentada tomada por datos.

**F3.6 — Observabilidad estándar OTel completa**

- **Qué**: completar la estandarización OpenTelemetry de las trazas propias (`.telemetry/` + OTLP
  export ya existe) sumando métricas y logs al mismo estándar; correlacionar session_id ↔ trace_id ↔
  token_transactions en una sola vista.
- **Por qué**: el consenso 2026 es OTel unificado, no un tracer monolítico; y correlacionar todo
  contra una sesión es lo que permite demostrar ROI a un cliente enterprise.
- **Cuándo**: meses 5-6. **Aceptación**: dashboard muestra la cadena completa
  sesión→traza→tokens→coste.

---

### FASE 4 — Gobernanza viva (continuo)

**F4.1 — Normativa de métricas vivas (nueva, prioritaria)**

- **Qué**: prohibir hardcodear conteos (tablas/checks/skills/agentes) en docs; generarlos desde
  código o centralizarlos en `config/stack-metrics.json` que los docs citen; corregir ya las 6
  ubicaciones de "12 tablas/3 migraciones" y las 5+ de "95 checks/13 componentes" (AGENTS.md,
  NEXUS-NORMATIVA.md, ADR-007, ADR-0013, ANNUAL-AUDIT-PLAN.md, skills validate-stack ×2,
  QUICK-START, ARCHITECTURE.md).
- **Por qué**: cada cifra hardcodeada caduca y contamina en cadena (las skills validate-stack
  enseñan la cifra errónea a los agentes que validan el stack).
- **Cuándo**: semana 2 (corrección) + normativa en mes 2. **Aceptación**:
  `grep -r "12 tables\|95 checks" --include="*.md"` = 0 hits activos.

**F4.2 — Normativa de versionado y releases** (ver F1.3) + **normativa de deprecación de docs**:
etiqueta "last verified" obligatoria en docs de estado, archival a `.archive/` >N meses —
implementando lo que el propio `docs/README.md:57-68` ya pide.

**F4.3 — Completar la migración de skills**

- **Qué**: resolver las 60 skills duplicadas entre `skills/` y `.opencode/skills/` (verificar
  divergencias caso a caso, dejar una canónica con sync automático); documentar la política de
  `public/skills/` (385) — qué se publica, cuándo y cómo se sincroniza; regenerar un índice real de
  skills.
- **Cuándo**: mes 2. **Aceptación**: 0 skills duplicadas divergentes; `skills/INDEX.md` generado
  automáticamente.

**F4.4 — Actualizar el cuerpo normativo**

- **Qué**: reescribir los 144 `REF-OBSOLETA` de `rules/` apuntando a los equivalentes TS; derogar
  formalmente `POWERSHELL-STANDARDS.md` (conflicto con NORM-TS-001) dejándolo como referencia
  legacy; actualizar `openspec/config.yaml` a TS-first o declararlo config-only (ADR-0019, ya
  reservado); actualizar `README-GOVERNANCE.md` o restaurar las secciones exigidas.
- **Cuándo**: meses 2-3. **Aceptación**: `grep -rc "REF-OBSOLETA" rules/` en mínimos históricos y
  cada referencia apunta a un archivo existente.

**F4.5 — Backlog de deuda marcada**

- **Qué**: agendar los 17 TODOs de session-close y 14 de review RDD como items formales en
  `docs/backlog/` (el destino natural ya existe).
- **Cuándo**: mes 2. **Aceptación**: 0 TODOs "huérfanos" — todos en backlog con prioridad.

---

### FASE 5 — Comercial: GENTLE_VANGUARD_MASTER (paralelo, desde ya)

> Objetivo del propio plan comercial (correcto): el único hito que importa es **un piloto pago
> exitoso con resultados medibles**. Todo lo demás acelera eso.

**Sprint A — Consolidación (semanas 1-2, costo ~0)**

1. **Declarar canónico y deduplicar**: `01-MASTER_OPERATIONS` como fuente única; 02/03/04 quedan
   como históricos o se eliminan con nota; conservar solo la generación "10 slides" de decks de
   oferta; meta 487 → ~300 archivos sin pérdida.
2. **Regenerar el manifiesto raíz** desde el estado real, con commit/tag del repo como referencia.
3. **Reparar rutas del manifiesto 15D** (eliminar `/mnt/data/...`) apuntando a
   `08-CERTIFICATES_AND_VISUALS`; mover carpetas crudas (`imagenes publicacion 18-08-26`,
   `_qa_glossary/`) a `99_INBOX/`.
4. **Sincronizar el kit 06 con el repo** (21 jobs + runbooks reales) o marcarlo histórico — el repo
   ya superó al kit.

- **Aceptación**: 0 duplicados por hash fuera de los marcados históricos; manifiesto
  auto-consistente.

**Sprint B — Habilitar venta (semanas 3-6)** 5. **Pricing para 3 ofertas lanzables** (Workshop,
Foundations, Academia Integral): calcular desde horas de entrega + soporte; publicar rango;
completar la sección 13 de la plantilla de propuesta con condiciones de pago/cancelación/límites de
soporte. 6. **Legal mínimo viable**: T&C + privacidad + reembolsos (1 página c/u, coherentes con
Monotributo/ARCA al facturar) + términos de licencia del currículo para instituciones. 7. **Landing
única** con el funnel ya diseñado: demo de 90s (grabarla — es el asset P1 del propio control), CTA
de piloto, formulario, booking. 8. **Payment links** (MercadoPago/Stripe) para las 3 ofertas, aunque
el cobro inicial sea manual.

- **Aceptación**: existe un camino completo click→pago para 1 oferta; legal revisado.

**Sprint C — Academia vendible (meses 2-4)** 9. **Densificar los 12 módulos**: de 180 → 1.500-2.500
palabras con comandos verificables contra un commit congelado del repo (la estructura pedagógica ya
existe; es relleno, no rediseño). Prioridad M01-M04. 10. **Flujo de certificación**: DOCX editable
para las 7 variantes, numeración automática desde el CSV, código de verificación. 11. **Sistema de
entrega mínimo**: repo privado por cohorte + feedback form; el engine de content-operations ya
gestiona avisos de cohorte.

- **Aceptación**: 1 módulo "gold" completo como plantilla de calidad; flujo de certificado
  end-to-end demostrable.

**Sprint D — Evidencia y escala (meses 3-6)** 12. **Ejecutar el sprint 15D real** y poblar
métricas/testimonios (hoy todo en 0 — el mayor lastre de credibilidad); documentar 1 case study del
primer piloto con permiso. 13. Recién entonces activar la oferta Executive/Institutional y evaluar
licenciamiento del currículo.

- **Aceptación**: landing muestra ≥3 pruebas reales (métricas, testimonio, case study).

**Conexión stack ↔ comercial (importante)**

- El repo ES la vitrina: F0.2 (purgar artefactos), F0.5 (onboarding roto) y F1.3 (versiones) son
  también acciones comerciales — un alumno que clona el repo y el paso 3 falla es un reembolso
  futuro.
- La release gate de evidencia del plan comercial (instalación limpia + health + checksum +
  rollback) debe implementarse como checks automáticos de F1: es la misma cosa.

---

## 4. Escalabilidad horizontal y vertical — síntesis arquitectónica

| Eje                        | Hoy                                          | Target                                                     | Mecanismo (acción) |
| -------------------------- | -------------------------------------------- | ---------------------------------------------------------- | ------------------ |
| **Vertical: calidad**      | 120 tests, evals estáticas                   | Evaluación continua sobre trazas reales, gate por release  | F3.1               |
| **Vertical: seguridad**    | Guardrails dispersos y buenos                | Defense-in-depth formalizada (input/output/decisión) + PII | F3.2               |
| **Vertical: costo**        | Medición completa sin superficie de decisión | Cost-per-outcome dashboard + routing por datos             | F3.5               |
| **Horizontal: proceso**    | SQLite + colas in-process                    | StoragePort/QueuePort con swap a Postgres/Redis            | F3.3               |
| **Horizontal: ecosistema** | 263 skills internas sin contrato             | Plugin registry con schema + permisos + install            | F3.4               |
| **Horizontal: personas**   | Onboarding roto, docs divergentes            | Onboarding único + métricas vivas + normativas             | F0.5, F4           |
| **Confianza**              | Gates decorativas, versiones divergentes     | CI único con gates reales + versionado automático          | F1                 |

## 5. KPIs del plan

| KPI                            | Base (hoy)        | Meta 3 meses            | Meta 6 meses                   |
| ------------------------------ | ----------------- | ----------------------- | ------------------------------ |
| Watchtower                     | 93/95             | 95/95                   | 95/95 sostenido                |
| Cobertura agregada             | 30%               | 40%                     | 50% (roadmap propio Q3/Q4)     |
| `any` en src/                  | 218               | <50                     | 0                              |
| Archivos >800 líneas           | 16                | 8                       | 0-2                            |
| `console.*` en src/            | 5.293             | <1.000                  | <50 (solo CLIs)                |
| Duplicados por hash (MASTER)   | 165 (34%)         | 0 activos               | 0 activos                      |
| Versiones divergentes          | 4 corrientes      | 1                       | 1 (automática)                 |
| Docs con cifras caducadas      | 10+               | 0                       | 0 (normativa vigente)          |
| Componentes dashboard con test | 7/40+             | 16                      | 24                             |
| Comercial                      | 5/10, sin pricing | 7/10, 1 oferta vendible | 1er piloto pago con resultados |

## 6. Riesgos y mitigaciones

| Riesgo                                               | Prob. | Mitigación                                                                                                 |
| ---------------------------------------------------- | ----- | ---------------------------------------------------------------------------------------------------------- |
| Refactor masivo de src/ rompe los 303 scripts npm    | Alta  | Migración por dominio con barriles + un PR por dominio; CI como red; aliases npm durante transición (F2.2) |
| Gates reales de CI bloquean el flujo diario          | Media | Escalar severidades gradualmente (warn→error) y en ramas sacrifice antes de main (F1.2)                    |
| History rewrite de .pnpm-store rompe forks           | Media | Solo si se confirma metadata sensible; si no, dejar el borrado simple                                      |
| Densificar 12 módulos consume el tiempo comercial    | Alta  | Priorizar M01-M04 + 1 módulo "gold" como plantilla; el resto por cohorte demanda                           |
| Changesets/release-please choca con release del .exe | Media | Probar el flujo completo en una release menor antes de la primera cohorte                                  |
| Perder principios base en el refactor                | Baja  | Checklist de principios (sección 1) como criterio de aceptación de cada PR de F2/F3                        |

## 7. Referencias (mejores prácticas 2026 consultadas)

- [The 2026 AI Agent Stack, Drawn from Scratch](https://codingwithroby.substack.com/p/the-2026-ai-agent-stack-drawn-from)
  — observabilidad diseñada desde el inicio, no añadida.
- [AI Agents in 2026: Tools, Memory, Evals, and Guardrails](https://andriifurmanets.com/blogs/ai-agents-2026-practical-architecture-tools-memory-evals-guardrails)
  — arquitectura integrada, no componentes aislados.
- [AI Agent Observability 2026: Tracing & Monitoring Stack](https://www.digitalapplied.com/blog/ai-agent-observability-2026-tracing-monitoring-stack-guide)
  — capturar cada llamada a modelo.
- [What Is Agent Observability? (MLflow 2026)](https://mlflow.org/articles/what-is-agent-observability-a-2026-developer-guide/)
  — registrar cada paso: prompts, tool calls, cadenas de razonamiento.
- [Expaso: Agent Observability Best Practices 2026](https://expanso.io/blog/ai-agent-observability-best-practices/)
  — trazar → estandarizar formato → ver la cadena completa → evaluar continuamente.
- [Datadogh: Guardrail Placement as a Design Decision](https://www.datadoghq.com/blog/securing-ai-agents-guardrail-placement/)
  — la colocación de guardrails importa tanto como los guardrails (base de F3.2).
- [Traversaal: Defense-in-Depth Guardrails](https://blog.traversaal.ai/ai-agent-guardrails-defense-in-depth-architecture-guide/)
  — input filters + output validators + escalation controls.
- [Arthur: Pre/Post-LLM Guardrails](https://www.arthur.ai/blog/best-practices-for-building-agents-guardrails)
  — PII redaction, hallucination detection, self-correction.
- [AppSec Engineer: Decision Guardrails](https://www.appsecengineer.com/blog/how-to-design-guardrails-for-secure-and-scalable-ai-agents)
  — umbrales de autonomía, requisitos de evidencia, triggers de escalación.
- [Hugging Face: Observability in Agentic AI](https://huggingface.co/blog/royswastik/evaluating-agentic-ai-systems-part-3-observability)
  — los agentes fallan en su razonamiento, no en sus stack traces.

---

## 8. Primeros 5 movimientos (si solo se hace una cosa esta semana)

1. `sha256` del `.exe` + sincronizar VERSION/package.json/CHANGELOG (F0.1) — 2 horas.
2. `git rm --cached` de `.pnpm-store`, `.local/`, logs de tests, fixtures de raíz (F0.2) — 30 min.
3. `better-sqlite3` a `dependencies` + `packages:` en `pnpm-workspace.yaml` (F0.3) — 1 hora.
4. README: `gv verify` → `gv check` + paso 3 del getting-started (F0.5) — 30 min.
5. Corregir las 6 ubicaciones de "12 tablas/3 migraciones" → 23/7 (F4.1) — 1 hora.

_Fin del plan. Documento vivo — revisar y actualizar al cierre de cada fase._

---

## 9. FASE 6 — Análisis transversal de optimización (añadido 2026-08-22, sesión de cierre)

Evaluación de ~20 áreas (cache, memoria, DB, grafos, delegaciones, autoasignaciones, ahorro
token/contexto, prompts, gestión skills/contenido/subagentes, ciclo sesión, commits,
autoaprendizaje, autorecuperación, docs, publicación, referencias, arquitectura, disponibilidad)
sobre la evidencia real de las sesiones 1-4. Lo ya cubierto por fases existentes no se repite; aquí
van los hallazgos NUEVOS.

### N1 — Schema drift en Nexus (ALTO, pequeño) — base de datos

`token_transactions` y `token_savings` se crean ad-hoc en `src/tokens/token-ingest.ts` (FUERA del
MigrationRunner) mientras migraciones 001-007 viven en
`apps/web-dashboard/server/database/repositories/MigrationRunner.ts`. Dos fuentes de schema = drift
garantizado. **Acción:** migración 008 que adopte esas tablas (CREATE IF NOT EXISTS + verificación
de columnas idénticas) y eliminar los CREATE ad-hoc.

### N2 — Dos grafos de código superpuestos (ALTO, arquitectura)

`.codegraph/` (codegraph.db, freshness por hooks) y `graphify-out/graph.json` (query semántico,
builder nativo nuevo) hacen trabajo solapado con interfaces distintas. **Acción (ADR-0019):**
definir roles explícitos — CodeGraph = índice incremental post-hook para tooling MCP; graphify =
grafo de análisis/query para agentes — o fusionar graphify como consumidor del índice de CodeGraph.
Documentar en AGENTS.md.

### N3 — Compresión aplicada a sí mismo: AGENTS.md (MEDIO, ahorro de token/contexto)

AGENTS.md paga tokens en CADA sesión de CADA agente (~800 líneas). El stack tiene compresión de
prompts — pero no se aplica a sus propias instrucciones. **Acción:** versión comprimida
AGENTS-fast.md (≤150 líneas: comandos críticos + punteros) y que los tool-profiles la usen por
defecto; la completa queda como referencia. Estimar ahorro con `npm run token:trace` antes/después.

### N4 — Auto-heal continuo de daemons (ALTO, disponibilidad/autorecuperación)

Esta sesión los daemons (dashboard-ws, codegraph) murieron 2 veces y NADA los revivió solo — el
autoheal del watchtower corre al inicio de sesión (lazy), no continuo; el watchdog del dashboard
murió con su hijo. **Acción:** `scheduled.yml` ya corre watchtower periódicamente — verificar que
use `-Action autoheal` (no solo health) y que el watchdog del dashboard sea supervisor-resilient
(respawneo del propio watchdog). KPI: 95/95 sostenido sin intervención manual entre sesiones.

### N5 — Profiles multi-tool con fuente única (MEDIO, gestión de subagentes/prompt)

`config/tool-profiles/` (CLAUDE.md, CLAUDE.compressed.md, cursorrules, …) duplican prompts de
agentes con drift ya observado. **Acción:** un YAML canónico de profiles + generador
(`gv profiles:build`) que emita los archivos por herramienta; CI gate de sincronía (diff contra
generados).

### N6 — Cache con telemetría (MEDIO, cache)

`response_cache` existe (SHA256+TTL+hit_count) pero el hit-rate no se reporta en ningún dashboard ni
alerta. **Acción:** métrica hit/miss por hora → Nexus (`metric_snapshots`) + alerta si hit-rate <
umbral; política de evicción LRU además del prune por TTL.

### N7 — Verificar índice de embeddings (MEDIO, autoasignación de skills)

Watchtower reporta "index parseable: **6 skills**" pero el embedder regeneró **419**. Posible
contador incorrecto del check o índice parcialmente parseado. **Acción:** revisar
`checkMlEmbeddings` (¿cuenta solo un sub-arreglo?) y alinear con `.atl/skill-embeddings.json`
metadata.totalSkills.

### N8 — Pre-push compuesto (BAJO, proceso de commit)

10 checks secuenciales en pre-push = fricción. **Acción:** un solo script `prepush-gate.ts` paralelo
(Promise.allSettled) con fail-fast y caché de resultados por hash de árbol (si nada cambió desde el
último push verde, skip). Meta: <60s en cold, <5s warm.

### N9 — Cerrar el loop de aprendizaje (MEDIO, autoaprendizaje/delegaciones)

error-memory + session_scoring + routing-table existen pero no hay verificación de que el
éxito/fracaso de delegaciones actualice la routing-table (success-rate) de forma demostrable.
**Acción:** test E2E del loop: delegación simulada → resultado → routing-table
hit_count/success_rate cambian → siguiente recomendación usa el dato. Documentar el circuito en un
diagrama (skill diagram-design).

### Áreas ya cubiertas por fases existentes (no duplicar)

Cache/DB→N1+N6; grafos→N2; memoria/engram→auto-reindex verificado (0.4h); delegaciones y
autoasignaciones de pasos/modelos→adaptive-steps+profiles M6 OK (lo pendiente es N9); ahorro
token→compresión al 98% verificada + N3; gestión de contenido→engine 21 jobs canónico; inicio de
sesión→pipeline lazy OK; cierre de sesión→F4.5 backlog (17 TODOs); commits→N8; docs→F4.1/F4.2;
publicación→sha256 verificado + F1.3 changesets pendiente; referencias→F4.4 (144 REF-OBSOLETA);
arquitectura/diseño→F2.2 (8/18 dominios) + F3.3 ports; disponibilidad→N4 + StoragePort F3.3.

### Prioridad de ejecución sugerida (enlazado al backlog existente)

1. N1 (schema drift) — pequeño, riesgoso de dejar.
2. N4 (auto-heal continuo) — disponibilidad visible.
3. N7 (embeddings) — verificar antes de tocar el embedder.
4. N2 (ADR grafos) — decisión arquitectónica temprana.
5. N9 (loop de aprendizaje) — demostrable, vende bien.
6. N3, N5, N6, N8 — mejoras incrementales.
