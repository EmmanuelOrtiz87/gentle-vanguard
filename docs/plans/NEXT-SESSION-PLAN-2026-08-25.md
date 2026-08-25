# Próxima Sesión — Plan Consolidado (2026-08-25)

> Sesión actual cerrada limpia. Todo lo pendiente + mejoras/optimizaciones/centralización/escala queda registrado para reanudar sin perder contexto.

## Estado al cierre
- Watchtower: 95-96/96 PASS (transient WARN del health HTTP resuelto; WS y Vite vivos)
- Nexus/SQLite: 27 tablas, 15 migraciones (009-013 tenant, 014 RBAC, 015 routing outcomes), integrity ok, ~54k filas
- Tests: 5/5 root, 52/52 dashboard, typecheck/lint/build/content 21/21 OK
- Dashboard: WS en 8080 vivo (PID detached, windowsHide, unref). Auth por sesión opaca persistida en SQLite (`dashboard_auth_sessions`). Login verificado 200 + cookie `gv_dashboard_session`.
- Token: `GV_DASHBOARD_TOKEN` en User env Windows (no en repo). `GENTLE_TENANT_ID=gentle-vanguard` también en User env. Launcher corregido `src/dashboard-cmd-launcher.ts` (detached:true, stdio:ignore).
- Engram/Nexus: auditoría acumulada en `reports/audits/STACK-END-TO-END-AUDIT-2026-08-24.md` + `docs/security/DASHBOARD-ADMIN-STATUS.md`.

## Cómo retomar (comando de entrada)
```powershell
$env:GV_DASHBOARD_TOKEN=[Environment]::GetEnvironmentVariable('GV_DASHBOARD_TOKEN','User')
$env:GENTLE_TENANT_ID=[Environment]::GetEnvironmentVariable('GENTLE_TENANT_ID','User')
npm run session:autostart:detached
npm run watchtower:health; npm run db:health
# Dashboard si no está vivo:
npm run dashboard:start -- --no-browser
# Verificar login:
# POST http://127.0.0.1:8080/api/auth/login { "token": "<valor de $env:GV_DASHBOARD_TOKEN>" }
```

## Pendiente Real (no inventar valores externos)

### P0 — Administración / RBAC
- ~~RBAC v1 completo~~ ✅ HECHO (2026-08-25): binding sesión→principal/membership, policy versionada, API admin autenticada, UI `/admin`, auditoría, CSRF double-submit, login rate-limit, lockout guards y tests negativos E2E/unit. Evidencia: `docs/security/DASHBOARD-ADMIN-STATUS.md`. Pendiente únicamente opcional: policy v2 con matrices por recurso e integración OIDC/LDAP externa.

### P1 — Tenancy profundo restante
- ~~Feedback JSON legacy~~ ✅ VERIFICADO FANTASMA (2026-08-25): `.session/feedback/` no existe, cero writers TS/PS1; único lector defensivo en `digest-generator.ts:49`. Path DB ya tenant-aware (migración rebuild + TraceRepo + getFeedbackStats(tenantId)). Nada que migrar.
- Backlog CLI ya hecho pero validar child tables, `skill_usage`/`routing_rules` ya migrados, revisar `backlog_items` hijos si aplica, y filesystem provenance (ya etiquetado `system-wide/unprovenanced` en `apps/web-dashboard/server/dashboard-source-provenance.ts`).
  - ✅ Child tables VERIFICADAS (2026-08-25): writes (`addComment`, `recordStatusChange`, `relateItems`, `removeTag`) validan `itemBelongsToTenant` antes de insertar; reads filtran vía JOIN `bi.tenant_id`; `pruneResolved` filtra por tenant. Sin cambios necesarios.
- ~~Consolidar writers duplicados~~ ✅ HECHO (2026-08-25) tokens (Engram #3107) y `session-current.json` (autostart ahora escribe SOLO `.session/session-current.json` con merge; `.runtime/` ya no se escribe). Plugin `.opencode/plugins/token-tracker.ts` validado: es cache vivo de sesión, la autoridad sigue siendo `token-ingest` → Nexus (lee opencode.db directo). `.event-bus/sessions-history.json`: no existe y 0 refs — muerto confirmado.
- ~~Añadir provenance explícito a nuevos artefactos filesystem~~ ✅ HECHO (2026-08-25): clasificación explícita `system-wide`/`deployment-tenant` y rechazo de datos filesystem sin `tenantId` cuando se presentan como tenant-owned. Evidencia: `apps/web-dashboard/server/dashboard-source-provenance.ts` y `tests/unit/dashboard-source-provenance.test.ts`.

### P1 — Escalabilidad / Centralización / Optimización
- ~~Centralizar config~~ ✅ HECHO (2026-08-25): `src/core/config-loader.ts` nativo — cache mtime-based, deep merge defaults, validador JSON Schema subset propio, CLI `--validate-all` (8/8 configs con schema validan). Primer consumidor migrado: `token-budget-guard.ts`. Adopción incremental para los ~16 loadConfig() restantes. Engram #3114.
- ~~Unificar ingesta de tokens~~ ✅ HECHO (2026-08-25): `token-tracker.ts` SQLite-only (JSONL retirado), `token-metrics-store.ts` readers/writers en Nexus con fallback read-only del close; ver Engram #3107.
- ~~Performance: cache LRU por tenant~~ ✅ HECHO (2026-08-25): `apps/web-dashboard/server/cache/tenant-lru-cache.ts` nativo (TTL 3s < push WS 5s, LRU 64 entradas, invalidación por evento, stats). Conectado a getTenantScopedMetrics/getSkillUsageFromDb/getTokenUsageFromDb/getRoutingRulesFromDb en `real-data.ts` con patrón wrapper compute*. Build dashboard + typecheck + lint verdes. Engram #3115.
- ~~Resiliencia: circuit-breaker v2 en delegators~~ ✅ HECHO (2026-08-25): `agent-delegator.ts` envuelve ejecución nativa en `executeWithCircuit('agent_delegation:<agente>')` con fail-fast fallback; `aws-delegator.ts` y `azure-delegator.ts` migrados del patrón manual duplicado al v2 compartido (`aws_lambda`, `azure_function`) — outcome final del retry loop es lo que graba el circuito. Nuevo config `agent_delegation` + resolución por prefix-match (`resolveCircuitConfig`). Clases duplicadas eliminadas. `--status` verificado.
- ~~SLO alerts por tenant~~ ✅ HECHO (2026-08-25): `config/tenant-registry.json` v1.1 con `sloDefaults` + overrides `slo` por tenant; `getTenantSloObjectives()` + `calculateBurnRate(tenantId)` parametrizados; `/api/slo/burn-rate?tenant=` retorna objetivos y ventanas. Smoke test runtime verificado (Prometheus 200 con métricas OTel, burn-rate 200, RBAC protegiendo endpoints). Engram #3118. **P1 CERRADO AL 100%.**
- ~~Observabilidad: pipeline OTel~~ ✅ HECHO (2026-08-25): `apps/web-dashboard/server/otel-pipeline.ts` unifica telemetry-ingest (spans → Nexus, 60s) + MetricsWriter (snapshots, 30s) detrás de start/stop único con stats. Export Prometheus enriquecido (`/api/metrics/prometheus` ya existía): 4 gauges nuevos de auto-observabilidad del pipeline. Engram #3117.
- ~~Health probe `/api/health`~~ ✅ VERIFICADO (2026-08-25): endpoint GET público devuelve HTTP 200 con `status: "ok"`; cubierto por `tests/integration/api-health.test.js` y probado contra el dashboard activo.
- ~~Loop de aprendizaje de routing~~ ✅ HECHO (2026-08-25): `recordRoutingOutcome` persiste éxitos/fallos por tenant en `routing_rules`; `recommend` consulta Nexus como autoridad y la migración `015_routing_outcome_metrics` añade `success_rate` e índice de selección. Tests: `tests/unit/routing-learning-loop.test.ts` (6 tests dirigidos, todos PASS).

### P2 — Promoción externa / Seguridad (no bloquea local-first; requiere inputs operador)
- La operación local-first está soportada sin completar este bloque. P2 es backlog de promoción
  futura para un servidor/Kubernetes/SaaS opt-in, no una condición para usar el stack local.
- No fabricar: registry digests, firma cosign, CNI/NetworkPolicy, sandbox MCP OS/container.
- Contrato ya existe: `src/ci/deployment-prerequisites.ts --report` + `src/ci/static-gates.ts --strict-images` + `config/k8s/README.md`.
- Cuando el operador provea: `GV_K8S_CNI_PROVIDER`, `GV_K8S_NETWORKPOLICY_ENFORCED`, `NetworkPolicy` manifest, `GV_MCP_SANDBOX_*`, registry + identidad cosign → correr gates en `--promotion` y promover imágenes `image@sha256:<digest>`.
- Validar SBOM/provenance con Syft/Grype/Trivy ya disponibles (Docker/Podman/kubectl/cosign no están en este host Windows).

## Optimizaciones propuestas para "llevar a otro nivel"
- ~~Design tokens pipeline a build-time~~ ✅ HECHO (2026-08-25): se mantiene el pipeline nativo sin añadir `style-dictionary`; `design:tokens --format css --output ...` genera `apps/web-dashboard/src/styles/generated-tokens.css` durante `prebuild`, importado por `src/styles/index.css`. Dashboard build verificado.
- ~~Graphify incremental en CI~~ ✅ HECHO (2026-08-25): nuevo job `graphify-affected` en `.github/workflows/ci.yml` construye el grafo y ejecuta `graphify affected` sobre archivos TS/TSX/JS/JSX modificados en PRs.
- ~~Unificar session lifecycle~~ ✅ HECHO (2026-08-25): `src/core/session-orchestrator.ts` — FSM explícita (idle→bootstrapping→active→cleaning→closing→closed) con transiciones validadas, estado persistido en `.runtime/session-orchestrator-state.json`, delega a los entry points existentes sin reescribirlos. CLI --status/--bootstrap/--startup/--close/--reset. Engram #3122.
- ~~Cache de pnpm para tsx/dlx~~ ✅ CUBIERTO (2026-08-25): todos los jobs CI usan `actions/setup-node` con `cache: pnpm`; el store pnpm compartido cubre resoluciones `pnpm dlx`/tsx sin introducir una ruta de cache artificial.
- ~~Añadir `lefthook` pre-push con `content:validate` + `ci:static-gates`~~ ✅ HECHO (2026-08-25): ambos gates agregados al pre-push existente; hooks re-sincronizados. Engram #3122.

## Criterio de "listo para promoción externa"
- RBAC + binding principal + tests E2E negativos pasan.
- Todos los repos con `tenant_id = ?` y sin lecturas globales filtradas en memoria.
- Gates `--promotion --strict-images --network-policy` en verde con digests reales y evidencia CNI/sandbox.
- Watchtower 97 checks estable en 2 runs consecutivos + `pnpm --dir apps/web-dashboard build` verde.

## Archivos clave para la próxima sesión
- `apps/web-dashboard/server/auth.ts`, `apps/web-dashboard/server/websocket-server.ts`, `src/deployment-tenant-context.ts`
- `apps/web-dashboard/server/database/repositories/MigrationRunner.ts` (009-013), `TokenRepo.ts`, `BacklogRepo.ts`, `TraceRepo.ts`
- `src/dashboard-cmd-launcher.ts` (fix detached), `src/ci/deployment-prerequisites.ts`, `src/ci/static-gates.ts`
- `reports/audits/STACK-END-TO-END-AUDIT-2026-08-24.md`, `docs/security/DASHBOARD-ADMIN-STATUS.md`, `docs/status/CANONICAL-STATUS.md`
