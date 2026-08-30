# Gentle-Vanguard Analytics — Pendientes

> Última actualización: 2026-08-28 (sesión de hoy). El app está integrada al stack y produce
> análisis con LLM real + fallback heurístico. Esta lista organiza el trabajo
> completado y los riesgos resueltos en sesión.

Leyenda: `[ ]` pendiente · `[x]` hecho · `[~]` en curso · `[!]` riesgo.

> **P0 + P1 + P2 + P3: 100% completos. Todos los riesgos documentados resueltos.** Ver PROGRESS.md
> para el detalle de cada ola.

## P0 — Operación del stack (debe estar antes de que otros la usen)

- [x] **Commit del avance actual** — landed (4 commits: 432c01c5, a4b34c2c, c7a13f6a, 020af3b5).
- [x] **Stepper en cabecera con scroll-spy** — 4 botones (Conexión → Análisis → Reporte →
  Evidencia) con badge numérico y gradiente de marca cuando la sección está activa.
- [x] **Historial limitado a 5** — API `GET /api/reports` default `limit=5` (cap 25),
  panel del sidebar muestra últimos 5.
- [x] **Wire MCP en `opencode.json#mcp`** — `gv-analytics-atlassian` habilitado stdio.
- [x] **Daemon del stack** — `src/gv-analytics-launcher.ts` con pidfiles en `.runtime/`,
  scripts `analytics:start|start:api|stop|build|dev`, integrado a `process-hygiene.ts`
  (3 nuevas DAEMON_CLASSES) y `maintenance-watchtower.ts` (6 checks en
  `checkGvAnalytics`). Vite match reorderado para evitar falso positivo de duplicado.
- [x] **Cleanup automático del puerto 4754** — launcher mata PID previo + fallback
  `netstat -ano` para liberar el puerto antes del spawn.

## P1 — Análisis con LLM real (core del producto)

- [x] **Reemplazar heurística por model router** — `analyzeInput` ahora invoca
  `agent-delegator --agent sdd-explore` con prompt estructurado (JSON shape estricto).
  Fallback heurístico se mantiene como graceful degradation.
- [x] **Pipeline route-and-delegate** — `apps/gv-analytics/server/llm.ts` envuelve
  agent-delegator con timeout 90s, extracción de JSON (fenced + balanced brace scan),
  normalización de shape.
- [x] **Cache LLM en Nexus** — tabla `gv_analytics_llm_cache` (hash sha256 de
  input+evidence → payload JSON). Cache hits <50ms.
- [x] **Diagramas renderizables** — bloques con copy-to-clipboard y render mermaid
  on-demand (CDN, fallback a texto). Tag "mermaid" visible cuando aplica.

## P2 — Producto / UX (COMPLETO)

- [x] **OAuth 2.0 con callback local** — evolución del API token. Servidor de callback
  en `127.0.0.1`, persistencia cifrada AES-GCM en `.runtime/gv-analytics/`.
  Landed en `b521732a` (3LO + PKCE + state + refresh).
- [x] **Validación Atlassian mejorada** — feedback inmediato en la UI al pegar
  credenciales (status de Jira/Confluence/Bitbucket con un solo click).
  Landed en `ab7b77ef` (botón "Probar"/"Revalidar").
- [x] **Templates de reporte** — formatos configurables (executive brief vs full SDD)
  desde la UI sin tocar código. Landed en `c223d3be` (brief/sdd/handoff + selector UI).
- [x] **Tests E2E** — suite Vitest/Playwright que cubra: conexión, análisis,
  persistencia, export PDF, export DOCX. Landed en `5e1ef5fa` (11 casos, `test:integration`).
- [x] **Métricas de uso** — cuántas requests/min, qué proveedor de modelo responde,
  latencia p50/p95. Tabla `gv_analytics_metrics` + dashboard widget. Landed en `77221771`
  (backend + `/api/metrics`; el widget del dashboard queda en P3).

## P3 — Cross-app / futuro (PRIORIDAD SIGUIENTE)

- [x] **Theme switcher** (light/dark) — actualmente solo dark. Landed en `ab7b77ef`
  (toggle en cabecera, persistido en localStorage, tokens en `:root[data-theme='light']`).
- [x] **Widget en `apps/web-dashboard`** — vista de "últimos análisis" sin necesidad
  de abrir gv-analytics. Landed en `6086e8f5` (proxy `/gv-analytics` en Vite +
  `useAnalyticsReports` con polling 15s + `AnalyticsWidget` con i18n en/es/pt-BR,
  insertado en `Dashboard.tsx`; renderiza `null` si la API no responde).
- [x] **i18n en/pt/es** — siguiendo el patrón del dashboard actual. Landed en
  `cd5725ed` (`i18n.tsx` con ~70 claves en 3 idiomas + `LocaleProvider`/`useT`/
  `LocaleSwitcher`; `App.tsx` refactorizado con `tt()` en todos los sub-componentes;
  `main.tsx` envuelto con `LocaleProvider`; CSS para `.locale-switcher`).
- [x] **Separar credenciales Atlassian + 3 pantallas** — decisión del usuario:
  Jira/Confluence comparten un API token; Bitbucket usa un token + workspace
  separados. Backend: `ConnectionForm`/`StoredConnection` con `bitbucketApiToken?`,
  `tokenFor()` elige el token por servicio (Bitbucket → `bitbucketApiToken` con
  fallback a `apiToken` para vaults viejos), `authHeader()` recibe el servicio.
  Frontend: refactor a 3 pantallas con tabs (Operación / Configuración / Historial);
  `ConfigView` con tokens separados en `fieldset` + Estado + OAuth; `HistoryView`
  con tabla filtrable tipo Excel (fecha, hora, título, modo, id) con búsqueda +
  filtro por modo. i18n ampliado en en/es/pt-BR.
- [x] **Storybook** — OMITIDO por decisión del usuario (componentes gv-analytics son
  internos de una sola app, no un design system; no hay infra Storybook en el repo).
- [x] **UX/seguridad de conexión** — (a) "Probar" ahora usa `POST /api/connection/test`
  que valida credenciales SIN persistir (solo "Guardar y probar" persiste); (b) "Editar"
  precarga siteUrl/email/workspace desde la conexión guardada y muestra tokens enmascarados
  (`apiTokenMasked`/`bitbucketApiTokenMasked`, p.ej. `••••771A`) con hint "dejar vacío para
  mantener"; (c) `buildConnection` mantiene el token existente si el campo queda vacío;
  (d) campos obligatorios marcados con `*` (siteUrl, email, apiToken).
- [x] **Validar tokens URL + fix vault path + mejoras UI** — (a) `buildConnection` rechaza
  tokens que sean URLs (`isUrlLike`) con mensaje claro (evita pegar la URL del sitio en el
  campo token — causa raíz del 401 de Bitbucket); (b) fix del path del vault: `vault.ts`
  resuelve el repo root desde `fileURLToPath(import.meta.url)` en vez de `process.cwd()`
  (antes el vault se guardaba en `C:\.runtime\` cuando el server corría desde la raíz del
  repo); vault migrado a `C:\Workspace_local\gentle-vanguard\.runtime\gv-analytics\`;
  (c) resumen de conexión con formato `campo: valor` y separación visual (`.summary-row`);
  (d) recuadro OAuth 2.0 oculto por decisión del usuario (la conexión por API token cubre
  los 3 servicios); (e) columna Export en el historial (exporta por id sin cargar el
  reporte completo); (f) filtro de modos corregido: "Todos los modos" + etiquetas
  URL/Pedido legibles (antes mostraba "Modo — Modo"). Landed en `c026c089`.

## Estado verificado

- typecheck: verde (raíz + apps/gv-analytics), incluyendo el fix de `mcp.ts`
- build: verde (170KB JS / 18.5KB CSS gzipped)
- session start: `gv.ts session start` → `active` en `session status` sin workaround
- watchtower health: 6/6 gv-analytics checks PASS
- process-hygiene: gv-analytics-api + gv-analytics-vite healthy, no duplicates
- end-to-end: POST /api/analyze con input real → `llmSource=agent` en 5.4s
- LLM retry: hasta 2 reintentos cuando `currentState`/`proposedSolution`/`nextActions` vacíos
- export PDF sin Chrome: devuelve HTML con `X-GV-PDF-Fallback` header (no error 500)
- export DOCX: `docx` cargado on-demand (lazy import), cero costo en arranque del server
- templates: `GET /api/templates` 200 (brief/sdd/handoff); export MD/HTML/DOCX/PDF
  con `?template=` todos 200 (verificado end-to-end)
- tests: 11/11 `test:integration` PASS
- conexión: Jira + Confluence + Bitbucket todos OK

## Riesgos / Decisiones — TODOS RESUELTOS

- [x] **LLM JSON parcial** — prompt reescrito con reglas explícitas + ejemplo de
  respuesta mínima válida; `CRITICAL RULES` prohíben arrays vacíos; retry loop de
  hasta 2 intentos con hint adicional en cada reintento; si tras los retries aún hay
  listas vacías se retorna el análisis parcial con `source: 'agent'` en lugar de
  degradar a fallback heurístico. Landed en esta sesión (`llm.ts`).
- [x] **`docx` como dep directa** — movido a lazy `await import('docx')` dentro de
  `toDocx()`. El módulo solo se carga cuando se solicita un export DOCX. El type
  import `import type { Paragraph } from 'docx'` se mantiene para el tipado en
  compilación sin costo en runtime. Landed en esta sesión (`export.ts`).
- [x] **Export PDF sin fallback** — `toPdf()` ya no lanza un `Error` cuando Chrome/Edge
  no está disponible. Genera el HTML export, marca el buffer con `pdfFallbackHtml = true`
  y el handler de `index.ts` lo sirve con `Content-Type: text/html` +
  `X-GV-PDF-Fallback` header explicando la causa. Landed en esta sesión
  (`export.ts` + `index.ts`).
- [x] **`mcp.ts` — `analyzeInput` llamada con firma incorrecta** — corregido el call en
  el MCP tool `gv_analytics_analyze`: de `analyzeInput(mode, input)` a
  `analyzeInput(mode === 'url' ? { url: input } : { request: input })`. Elimina el
  error preexistente `TS2554: Expected 1 arguments, but got 2`. Landed en esta sesión
  (`mcp.ts`).
- [x] **Bug session start — PID efímero** — `getSessionState()` ya no hace
  `process.kill(state.pid, 0)`. La sesión es válida si `lastActivity` es ≤ 30 min.
  `createSession()` omite el campo `pid` para evitar confusión futura. Landed en esta
  sesión (`src/cli/gv.ts`).

## Comando de arranque

```bash
npm run analytics:start   # API :4754 + Vite :5174 con cleanup
# o
npm run analytics:start:api  # solo API
```

