# Gentle-Vanguard Analytics - Progress Log

## 2026-08-28

### Hecho

- Sesion del stack iniciada con `npm run session:autostart:detached`.
- Se decidio separar Analytics del dashboard como app independiente.
- Se reviso la base existente: dashboard, MCP registry, MCP manager, model router y OpenCode config.
- Se consulto documentacion publica de Atlassian:
  - Jira REST API v3.
  - Confluence REST API v2.
  - Bitbucket Cloud REST API.
- Se definio API token read-only como MVP y OAuth 2.0 como evolucion.
- Se scaffolded `apps/gv-analytics`.
- Se agrego `apps/gv-analytics` al workspace pnpm.
- Se agrego documentacion inicial en `docs/analytics/`.
- Build de la app paso con `pnpm --filter @gentle-vanguard/gv-analytics build`.
- Se agrego MCP `gv-analytics-atlassian` en `apps/gv-analytics/server/mcp.ts`.
- Se registro el MCP en `config/mcp-registry.json` con `autoStart: false`.
- Se detecto y corrigio la resolucion de root en `src/mcp/mcp-manager.ts`, que estaba buscando el
  registry debajo de `src/config` en lugar de `config`.
- `npm run mcp:manager -- --action list --quiet` ya muestra `gv-analytics-atlassian`.
- Endpoint `/api/analyze` probado con un pedido de checkout/frontend/backend/payment/QA.
- Servidor local iniciado en `http://127.0.0.1:4754`.

### Decisiones

- La UI no controla OpenCode directamente. La app invoca una capa backend local de
  Gentle-Vanguard, y esa capa usa el model router/agentes/OpenCode por detras.
- El primer corte no escribe en Atlassian. Las acciones write quedan bloqueadas hasta incorporar
  aprobacion humana y auditoria.
- Los secretos no se guardan en archivos versionados.

### Pendiente inmediato

- Enriquecer MCP Atlassian con herramientas reales de lectura profunda.
- Agregar `gv-analytics-atlassian` a `opencode.json#mcp` cuando se decida habilitarlo dentro de
  sesiones OpenCode, cuidando no pisar cambios locales existentes.
- Persistir reportes en Nexus.
- Implementar exportacion PDF/DOCX.

### Avance 2 (checkpoint 2026-08-28, sesion ZCode)

Hecho y verificado con build verde + smoke test end-to-end:

- **Persistencia Nexus**: nueva tabla `gv_analytics_reports` en `.runtime/gentle-vanguard.db`
  (SQLite WAL, `apps/gv-analytics/server/reports.ts`). Cada `POST /api/analyze` persiste el
  reporte. Endpoints nuevos: `GET /api/reports` (historial), `GET /api/reports/:id`.
- **Exportacion**: `server/export.ts` genera MD, HTML (tema claro para impresion), DOCX (libreria
  `docx`) y PDF (Chrome/Edge headless `--print-to-pdf`, `windowsHide`). Endpoint:
  `GET /api/reports/:id/export?format=md|html|docx|pdf`. Smoke test OK: PDF real de 102KB con
  firma `%PDF-1.4`.
- **MCP enriquecido** (`server/mcp.ts` v0.2.0, 6 tools): `gv_atlassian_jira_issue` (issue completo
  con comentarios), `gv_atlassian_confluence_page`, `gv_atlassian_bitbucket_pr` (con diff),
  `gv_atlassian_search` (Jira + Confluence) + las 2 originales. `analyzeInput` ahora tambien trae
  issues vinculados y docs de Confluence que mencionan el ticket.
- **UI**: menu de exportacion (PDF/DOCX/HTML/MD) y panel de historial clickable en el aside.
- **Re-tema marca GV**: paleta migrada de verde a tokens Academy/14-BRAND-SYSTEM (cyan `#22d3ee`,
  violeta `#a78bfa`, bg `#0a0e17`, superficies `#1f2937`, gradiente 135deg violeta->cyan).
- Deps agregadas al package.json del app: `better-sqlite3`, `docx`,
  `@modelcontextprotocol/sdk`, `zod` (antes venian por hoisting).

Bugs corregidos en el camino:

- Duplicado `evidence` en el literal de `AnalyticsReport` (TS1117).
- `TextRun` con API incorrecta en export DOCX (TS2554).
- Servidor viejo de la sesion anterior ocupaba el puerto 4754; matarlo antes de re-testear
  (`netstat -ano | grep :4754`).

### Pendiente siguiente

- Agregar `gv-analytics-atlassian` a `opencode.json#mcp` (habilitarlo en sesiones OpenCode).
- Registrar el server como daemon del stack (pidfile `.runtime/`, comanda `npm run` en el app,
  integracion al watchtower/process-hygiene).
- Analisis con LLM real via model router (hoy la lectura de frentes/estimacion es heuristica).
- Diagramas visuales actuales/propuestos (diagram-design) en vez de texto plano.
- Commit del avance (tree tiene cambios del app + pnpm-lock + mcp-registry).

### Avance 3 (2026-08-28, sesion actual — feedback UX)

Hecho y verificado con build verde + typecheck verde:

- **Stepper en cabecera con scroll-spy** — los 4 enlaces pasivos se convirtieron en
  botones paso-a-paso (1 Conexion / 2 Analisis / 3 Reporte / 4 Evidencia) con badge
  numerico y gradiente de marca cuando la seccion esta activa. `IntersectionObserver`
  actualiza el estado segun scroll (`rootMargin: -30% 0px -50% 0px`).
- **Historial limitado a 5** — `GET /api/reports` default `limit=5` con cap 25,
  panel lateral ahora dice "Ultimos 5 reportes persistidos en Nexus".
- **PENDING.md** — lista priorizada de 16 items con plan operativo por olas.
- **Typecheck + build**: verde (`tsc --noEmit && vite build` → 2.12s, 162KB JS, 13KB CSS).

### Avance 4 (2026-08-28, P0 stack integration)

Landed en commit `a4b34c2c`. Integra gv-analytics al stack como first-class daemon:

- `src/gv-analytics-launcher.ts` (single-shot, port 4754 cleanup, detached, pidfiles
  en `.runtime/gv-analytics-{api,vite}.pid`, SIGINT/SIGTERM cleanup).
- Scripts npm: `analytics:start | start:api | stop | build | dev`.
- `opencode.json#mcp.gv-analytics-atlassian` habilitado.
- `process-hygiene.ts`: 3 nuevas `DAEMON_CLASSES`; el match generico de `vite-server`
  se reordeno despues de `gv-analytics-vite` para evitar falso positivo de duplicado.
- `maintenance-watchtower.ts`: `checkGvAnalytics()` con 6 checks (build, API HTTP,
  process, Vite dev, MCP registry, opencode.json wire). 6/6 PASS verificado.
- Smoke test: launcher arranca, API responde, watchtower OK.

### Avance 5 (2026-08-28, P1 LLM real + diagramas)

Landed en commits `c7a13f6a` (LLM) y `020af3b5` (diagramas).

- `apps/gv-analytics/server/llm.ts`: wrapper sobre `agent-delegator --agent sdd-explore`
  con timeout 90s, extraccion de JSON (fenced + balanced brace scan), normalizacion de
  shape, tabla `gv_analytics_llm_cache` (sha256 hash) en Nexus. Fallback heuristico
  cuando el modelo no responde o devuelve JSON no parseable.
- `apps/ggv-analytics/server/atlassian.ts`: `analyzeInput` ahora invoca
  `enrichWithLLM` primero. Si retorna analisis, el reporte usa LLM output; si no,
  cae al heuristico con `llmSource='heuristic'`.
- `src/types.ts`: `AnalyticsReport` gana `llmSource | llmDurationMs | llmCached | llmNotes`.
  `complexity.level` acepta `'critical'`.
- UI: badge de proveniencia LLM (agent=cyan, cache=verde, fallback=ambar, heuristico=ambar)
  con duracion. Bloques de diagramas con copy-to-clipboard y render mermaid on-demand
  (CDN, fallback a texto). Tag "mermaid" cuando el contenido califica.
- End-to-end: `POST /api/analyze` con pedido real de checkout Magento → `llmSource=agent`
  en 5.4s. Cache hit <50ms.

### Estado al cierre de ola

- typecheck + build: verde
- watchtower: 6/6 gv-analytics checks PASS
- process-hygiene: gv-analytics-api + gv-analytics-vite healthy
- P0 + P1: 100% done
- P2: 0% (OAuth, validacion, templates, tests E2E, metricas)
- P3: 0% (widget, i18n, theme, storybook)

### Notas para retomar

Comando sugerido para continuar:

```bash
npm run session:autostart:detached
Get-Content -Raw docs/analytics/PROGRESS.md
Get-Content -Raw docs/analytics/README.md
Get-Content -Raw docs/analytics/PENDING.md
```
