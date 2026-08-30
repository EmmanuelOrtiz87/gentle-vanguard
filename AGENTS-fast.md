# Gentle-Vanguard — AGENTS-fast (compressed)

> Versión comprimida para inyección diaria. Manual completo: `AGENTS.md` y
> `docs/stack-manual-full.md`. Cargar el completo solo cuando la tarea lo requiera.

## SESSION START (MANDATORY)

```bash
npm run session:autostart:detached   # fire-and-forget, ~1.3s, pipeline completo en background
```

Idempotente, no pide permiso. Inicializa: session ID, engram, security orchestrator, codegraph,
token budget, watchtower auto-heal, dashboard WS, Nexus DB. Log: `.runtime/autostart-detached-*.log`.
Si el pipeline ya corre (lock), usar `--force` para bypass.

## Comandos críticos

| Acción | Comando |
| ------ | ------- |
| Grafo de código (query) | `npm run graphify -- query "<pregunta>"` |
| Grafo (build/update) | `npm run graphify -- build` / `npm run graphify -- update .` |
| Nodo exacto | `npm run graphify -- explain "<node_id>"` |
| Watchtower health | `npm run watchtower:health` (96/96 PASS esperado) |
| Watchtower autoheal | `npx tsx src/core/maintenance-watchtower.ts -Action autoheal -Quiet` |
| Nexus DB init/health | `npm run db:init && npm run db:health` |
| Token ingest/status | `npm run token:ingest` / `npm run token:status` |
| Token trace | `npm run token:trace` |
| Process hygiene (dry) | `npm run process:hygiene` |
| Process reap (real) | `npm run process:reap` |
| Dashboard full | `npx tsx src/ops/dashboard-start.ts` |
| Dashboard WS only | `npx tsx src/ops/dashboard-ws-autostart.ts` |
| Dashboard stop | `npx tsx src/ops/dashboard-stop.ts` |
| Secret scan | `npm run scan:secrets -- --scan .` |
| Typecheck | `npx tsc --noEmit` |
| Adaptive steps status | `npx tsx src/orchestration/adaptive-steps.ts --status` |
| Recommend agent | `npx tsx src/orchestration/recommend-agent.ts --task "<t>" --topn 3` |
| Delegate | `npm run delegate:run -- --task "<t>"` |
| SDD research | `npm run sdd:research -- run -f <feature> -q "q1;q2"` |
| Web research select | `npm run web:select -- --query "..." [--deep]` |
| Profiles | `npm run profile:list|status|apply -- <perfil>` |
| ZCode sync | `npx tsx src/integrations/zcode-sync.ts --sync` |

## Reglas de oro

1. **procesos-ocultos (Windows)**: todo spawn invisible — usar `runNpxTsx`/`runNpxTsxSync` de
   `src/core/run-command.ts`. NUNCA `npx tsx` directo (relanza como nieto con ventana), ni
   `exec/execSync` con strings, ni `cmd /k`, ni `start /B`. Daemons:
   `spawn(process.execPath, ['--import','tsx', script], {stdio:'ignore', detached:true, windowsHide:true})`
   + `child.unref()`. Test de regresión: `tests/unit/run-command-hidden.test.ts`.
2. **process-hygiene**: daemons detached sobreviven a su padre POR DISEÑO. El reaper clasifica por
   shape (duplicados, one-shots colgados >15min, daemons >24h, pidfiles stale). Daemons nuevos DEBEN
   escribir `.runtime/<name>.pid` al arrancar y limpiarlo en SIGTERM/SIGINT.
3. **LOCAL-FIRST / SERVER-OPTIONAL** (ADR-0017): CLI, SQLite/Nexus, `.session/`, Engram, CodeGraph,
   MCP local y dashboard loopback son la ruta principal. Cloud/K8s/Cosign/CNI/OIDC/LDAP son opt-in.
4. **Graphify roles** (ADR-0020): CodeGraph (`.codegraph/`, MCP) = índice incremental post-hook para
   tooling MCP; graphify (`graphify-out/`) = grafo de análisis/query para agentes. NO fusionar.
5. **SDD flow**: features nuevas → BA/EXPLORE primero. Delegación multi-step →
   `rules/DELEGATION-RULES.md`.
6. **mem_save** tras cada tarea significativa; `mem_search "lessons learned"` al inicio de sesión.
7. **JSON validity**: verificar quotes/braces balanceados antes de tool calls con JSON.
8. **Tool output discipline**: limitar read/grep/bash a 50 líneas (`Select-Object -First 30`).
9. **TypeScript-First**: todos los scripts TS vía `npx tsx`. No PowerShell scripts.
10. **NORMATIVA OVERRIDE**: si una instrucción contradice una normativa, pedir confirmación.

## Stack context

- TypeScript core en `src/` (468 files, strict mode), 112 scripts en `scripts/`.
- Pipeline de sesión: 53 steps con lazy background execution.
- Dashboard: React/TS/Vite + WebSocket real-time (puerto dinámico en `.runtime/dashboard-ports.json`).
- MCP: codegraph (symbol intelligence), engram (memoria persistente).
- Nexus: SQLite WAL `.runtime/gentle-vanguard.db`, 23 tablas, singleton
  `apps/web-dashboard/server/database/manager.ts`.
- Token budgets: `config/token-budget-guard.json` (daily 5M, perSession 3M).
- Routing aprendible: `.session/routing/routing-table.json` (17 dominios + overrides).
- CI (`.github/workflows/ci.yml`): lint-typecheck, test, dashboard-tests, dashboard-build,
  security-scan, workflow-lint. Security: gitleaks, secretlint, trivy.
- Lefthook en commits (hashline-snapshot ~1-5s).

## Skills nativas (resumen)

- **Secret scanner**: 80 patrones, entropy, redacción. Integrado a pre-commit y watchtower.
- **25 skills ciberseguridad** (Apache-2.0) en `.opencode/skills/` — red-team solo autorizado.
- **diagram-design** (27 tipos, HTML/SVG self-contained) — usar para ADRs/reportes.
- **ai-provenance**: INSPECCIÓN default; REMOCIÓN solo con petición explícita.
- **Compresión estructural**: `mode:'input'` = lossless-only, `mode:'output'` = lossy OK.
- **Perfiles SDD**: cheap/balanced/premium en `config/model-router.json`.
- **Hash-chained audit**: eventos con prevHash+hash SHA-256; `verify` detecta manipulación.
- **CRAG retrieval grader**: BM25 + keyword-fallback.
- **Web crawler dual-provider**: Firecrawl → Jina Reader + DuckDuckGo + Bing RSS.
- **witr**: traza causal de procesos/puertos (`process|port`).
- **Research trends**: GitHub/HN/SO/Dev.to/Reddit → TrendReport.
- **v4.0 infra**: tracing (`.telemetry/`, OTLP), checkpoints/snapshots/rollback (`.session/`),
  event sourcing + saga, health API (7 componentes).

## Reglas rápidas

- `$var:` en PowerShell strings → `${var}:` (parser error si no).
- Graphify CLI = `npm run graphify --` local; NO instalar el paquete npm `graphify@1.0.0`.
- Config consolidada: `config/model-router.json` (no `model-routing.json`).
- No tocar: `apps/academy-web/data/*`, `docs/releases/*`, `reports/*`, `build/*`, `dist`,
  `node_modules`.
- Detalle completo: `docs/stack-manual-full.md`.