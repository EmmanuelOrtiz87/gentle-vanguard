# Dashboard + CMS — Plan Maestro "Next-Level"

> Versión: 1.0  ·  Fecha: 2026-08-22  ·  Apps: `apps/web-dashboard/` (metrics) + `Marketplace.tsx` (skills CMS) + `src/content-operations/` (content engine)
>
> Stack: React 18 · Vite 5 · Tailwind 3 · Recharts · Lucide · react-router 7 · ws 8 · better-sqlite3 · root stack `gentle-vanguard@3.8.2`
>
> Lectura objetivo: CTO, líder técnico, equipo de marketing y developer relations.

> **Estado de ejecución 2026-08-23:** Dashboard y CMS ya tienen shell visual unificado, datos reales, histórico temporal, Marketplace install/uninstall/versionado/gobernanza/migraciones y Content Operations con filtros, calendario, preview, tabla y Kanban. El autostart de sesión ejecuta pasos TypeScript sin `cmd.exe`. Los puntos marcados como futuros debajo requieren trabajo adicional de producto o infraestructura y no deben interpretarse como funcionalidades ya entregadas.

---

## 0 · Resumen ejecutivo (TL;DR)

El dashboard ya tiene una base sólida y diferenciada (AG-UI + HITL + SQLite + i18n + auto-healing), pero le faltan cinco cosas que lo separan de un "producto de primer nivel":

1. **Selector de rango temporal e histórico** (el gap #1 vs Datadog/Grafana/PostHog).
2. **Tests reales** (hoy 6/31 componentes, 1/13 hooks — CI no puede refactorizar con confianza).
3. **Limpieza de placeholders y mocks en producción** (`byModel` sintético, "Install Skill" no-op, README desincronizado, versiones reportadas en 3 lugares distintos).
4. **Auth, RBAC, notificaciones externas, share links, audit log** (hoy el dashboard es read-only-friendly pero no enterprise-ready).
5. **Storytelling de demo**: landing, tour guiado, mock-data seeder, video script, comparativa pública.

El "CMS" más maduro es el **Marketplace de skills** (532 LOC, browse + publish + reviews). El `apps/doc-gentle/` está archivado (solo README) y `src/content-operations/` es CLI-only — la oportunidad está en **elevar el Marketplace a CMS de primer nivel y construir una `ContentOpsPanel` web** sobre el engine existente.

Estas dos superficies combinadas (dashboard + marketplace + content ops) son el mejor caballo de batalla del stack: muestran observabilidad profunda, IA trabajando en vivo, y un supply-chain de contenido que **ningún competidor tiene**.

---

## 1 · Auditoría del estado actual (resumen)

Inventario verificado en `apps/web-dashboard/`:

| Dimensión | Hoy | Estado |
|---|---|---|
| Rutas | 10 (`/`, `/tracing`, `/marketplace`, `/agents`, `/tasks`, `/timeline`, `/docs`, `/mcp`, `/knowledge`, `/multi-repo`) | ✅ Lazy + Suspense |
| Componentes | 31 | ⚠️ 6/31 con tests |
| Hooks | 13 | ⚠️ 1/13 con tests |
| Panel crítico "money-shot" | `StackCapabilitiesPanel` (anomalías + circuit breakers + DB healing) | ✅ Diferenciador único |
| WebSocket | 1 server, 5s metrics + 200ms file-watcher debounce, 3s reconnect | ✅ Real-time sólido |
| Persistencia | SQLite (`manager.ts`, 12 repos) + JSON files | ✅ Unificado |
| i18n | en/es/pt-BR para 17 labels de métricas; chrome en inglés | ⚠️ Parcial |
| Auth | Ninguna | ❌ Bloquea enterprise |
| Time-range | No existe (siempre "último 5s" o "all-time") | ❌ Gap #1 |
| Tests E2E | 0 | ❌ Riesgo alto |
| Bundle | Recharts (150KB) usado en 1 componente; lucide 0.294 (2+ años); eslint 8.57 EOL | ⚠️ Modernizable |
| Documentación | README desincronizado (v3.3.0 / v3.3.1 / v3.8.2) | ❌ Daña confianza |

Métricas y gaps detallados en `apps/web-dashboard/IMPROVEMENT-AUDIT.md` (este archivo es la versión pública-privada del plan ejecutivo).

---

## 2 · Plan Dashboard — 5 tracks paralelos

### Track A · Visual & UX profesional (P0/P1)

**P0 — Lo que hace que "se vea como producto de primer nivel"**
- **A1. Selector de rango temporal** global (header), con presets `5m · 1h · 24h · 7d · 30d · custom`. Afecta a todas las charts, KPIs, heatmaps, stack tables. Estado persistido en URL (`?range=24h&from=...&to=...`). — *cierra el gap #1*.
- **A2. Empty/loading/error states unificados**: skeleton loaders consistentes (no `animate-pulse` ad-hoc), error boundaries por panel, retry explícito, "última actualización" + "auto-refresh on/off" por panel.
- **A3. Comando palette (⌘K / Ctrl-K)** estilo Linear/Vercel: navegar a cualquier ruta, paneles, settings, docs, ejecutar skills, abrir agent chat.
- **A4. Layouts guardados y compartibles**: drag-and-drop de paneles, layouts por usuario (`localStorage`), export/import JSON, share-link con estado (signed URL).
- **A5. Sidebar persistente** con secciones colapsables + icon-only mode (estilo Datadog). Hoy todo es top-nav; con 10 rutas se vuelve ruidoso.
- **A6. Dark mode con `prefers-color-scheme`** (hoy solo toggle manual), persistencia, transición suave.
- **A7. i18n completo**: traducir chrome (botones, modales, navegación, toasts, validaciones), no solo los 17 labels de métricas. Agregar `fr` y `de` opcional.
- **A8. Accessibility**: focus rings visibles, `aria-label` en icon-only buttons, `aria-live` en alerts/notifications, focus trap en modales, Esc handler, skip-link, contraste AA validado.
- **A9. Responsive serio**: tests en 360/768/1024/1440/1920; charts adaptativos; tablas con virtualization (`@tanstack/react-virtual`).
- **A10. Microinteracciones**: número animado al cambiar (count-up), pulse en alerts nuevos, smooth-chart transitions, confetti en deploy exitoso (cero coste cognitivo).

### Track B · Datos en vivo y mecanismo de refresh (P0/P1)

- **B1. Time-series store real**: hoy `useMetrics` guarda un ring-buffer de 20 puntos en memoria. Migrar a **TimeSeries buffer en SQLite** (1 fila/minuto por métrica, 30 días retención) y servir `/api/metrics/history?metric=tokens&range=24h` con agregación server-side. Base para el time-range selector (A1).
- **B2. Backpressure y rate-limit visual**: si el WS desconecta > 10s, mostrar banner full-width + countdown; reconnect exponencial visible.
- **B3. Suscripciones WS granulares**: hoy `useSharedWs` reenvía TODO a todos los listeners. Agregar `subscribe(metric|alerts|tasks|traces|...)` para reducir CPU cliente.
- **B4. SSE como alternativa a WS**: para consumidores pasivos (dashboards embebidos, screenshots), exponer `/api/sse/metrics` server-sent-events; menor overhead y proxieable.
- **B5. Schema versioning + payload diffing**: enviar solo diffs en el WS (`{added, removed, changed}`) en lugar del JSON completo cada 5s. Reduce ancho de banda 60-80% en datasets grandes.
- **B6. Lazy load de paneles pesados**: stack tables y heatmaps solo se hidratan cuando entran al viewport (`IntersectionObserver`).
- **B7. WebWorker para parsing**: el `LiveTraceFeed` parsea JSONL en main thread; mover a worker.
- **B8. Cache offline más inteligente**: hoy `offlineCache.ts` cachea un snapshot. Subir a **service worker** con stale-while-revalidate; primero paint con cache, después revalidar.

### Track C · Calidad técnica y confiabilidad (P0)

- **C1. Tests, tests, tests**: meta 80% coverage. Priorizar:
  - `useMetrics`, `useStackTables`, `useAgentStream`, `useSharedWs`, `useAlerts`, `useLocale` (hooks)
  - `Dashboard`, `Marketplace`, `TracingDashboard`, `AgentChat`, `MCPServers`, `KnowledgePanel`, `MultiRepoView` (componentes grandes)
  - `real-data.ts`, `marketplace-api.ts`, `shared-state-bridge.ts`, `validations.ts`, `metrics-writer.ts` (server)
  - **E2E con Playwright**: flujos críticos (crear agent session → enviar mensaje → ver respuesta en chart; publicar skill → instalar → ejecutar).
- **C2. Eliminar placeholders**:
  - `real-data.ts:273-289` `byModel` sintético → retornar `[]` o marcar explícitamente como `unavailable` y mostrar CTA "ejecuta `npm run perf:slo` para popular".
  - `Marketplace.tsx:380-382` "Install Skill" → wire a `/api/marketplace/:id/install` (ver Track E2).
  - `useMetrics.ts:23` `_useWebSocketMode` → renombrar a `useWebSocketMode` y usarlo para alternar entre WS-push y HTTP-poll.
  - `InteractiveDocs.tsx:365-374` "Try it" → ejecutar el skill de verdad vía `executeSkill` MCP.
- **C3. Sincronizar versiones**: hoy v3.8.2 / v3.3.1 / v3.3.0 en distintos archivos. Single source of truth: leer de `package.json` en build.
- **C4. Sincronizar protocolo WS en README**: agregar `trace_update`, `state_delta`, `task_delta`, `agent_stream_chunk`, `agent_ui_hints`, `notification` a la tabla.
- **C5. Modernizar dependencias**: `lucide-react@0.460+`, `eslint@9` (flat config), `typescript@5.6+` (validar v6 primero), `react@19` (con plan de migración).
- **C6. Drop Recharts**: solo se usa en `LiveChart.tsx`. Reemplazar por componente SVG custom (~3KB) y liberar 150KB de bundle.
- **C7. Replace `better-sqlite3` por `@gentle-vanguard/core` (la abstracción de BD del stack)** para que el dashboard herede la misma capa que el resto del stack. Reduce surface de build nativo.
- **C8. Pre-commit + CI quality gate**: typecheck, lint, test, build, bundle-size budget, lighthouse-ci con score mínimo 90 en Performance/A11y/Best-Practices/SEO.
- **C9. Error tracking**: integrar Sentry o auto-hosted (GlitchTip) para cliente + servidor. Reportar errores con contexto (tenant, route, payload size).
- **C10. Feature flags** (`@gentle-vanguard/core` ya tiene `auto-delegation.json`): laminar releases, A/B de UI.

### Track D · Observabilidad del propio dashboard (P0/P1)

- **D1. Self-telemetry**: el dashboard mide todo el stack, pero no se mide a sí mismo. Agregar:
  - Métricas Prometheus en `/metrics` (request rate, latency p50/p95/p99, error rate, WS connections, broadcast size, snapshot write duration).
  - Dashboard "interno" en `/admin` (protegido por feature flag): cuántas conexiones, cuánto tarda cada panel en hidratar, tamaño de payloads.
- **D2. Log search con full-text**: hoy `/api/knowledge` está subexpuesto. Construir un panel `/logs` con búsqueda, filtros (level/source/session_id), tail en vivo, link a traces.
- **D3. Trace→log→metric correlation**: cada trace ID debe permitir saltar al log exacto y al chart de la métrica asociada.
- **D4. Audit log viewer**: el directorio `.session/audit/logs/*.jsonl` ya se escribe; construir un panel que lo muestre filtrable por actor, recurso, timestamp, con export CSV/JSON.
- **D5. Notificaciones nativas en alertas**: mantener transiciones `fired/resolved` dentro del WebSocket, historial de auditoría y toasts in-app; no depender de servicios externos.
- **D6. SLOs reales y burn-rate alerts**: hoy el `SloPanel` lee de un JSON estático. Conectar a OpenSLO o un mini-motor interno; calcular burn rate (1h, 6h, 24h, 72h) estilo Google SRE workbook.
- **D7. Anomaly detection en el cliente**: complementar las anomalías del stack con un modelo simple (z-score, MAD) sobre el ring buffer; marcar puntos anómalos en las charts.
- **D8. Forecasting**: regresión lineal simple sobre series de tokens/cost para "fin de mes" / "fin de cuota" — el insight de $ valor.

### Track E · CMS / Marketplace (P0/P1)

**El "CMS" más maduro es el Marketplace (skills). El doc-gentle está archivado; el content-operations es CLI. Plan en 3 carriles:**

**E1. Marketplace — Browse & Discover (P0)**
- Sort: `trending · newest · top-rated · most-downloaded · recently-active`.
- Facetas: `agentType`, `tags`, `language`, `category`, `author`.
- Búsqueda full-text con highlighting (sqlite FTS5 o MiniSearch).
- Paginación + infinite scroll.
- Vista de detalle enriquecida: README renderizado (markdown con syntax highlight), changelog, version history, dependencies, "used by", screenshots, comments, Q&A.
- "Used in stack" badge: si el skill ya está instalado en este stack, mostrar ✓ y enlazar al agent que lo usa.

**E2. Marketplace — Authoring & Publishing (P0)**
- Editor markdown con preview live (split-pane), syntax highlight, validación continua (no solo on-submit).
- Plantillas: `data-analyzer`, `api-client`, `doc-summarizer`, `test-runner`, `compliance-checker`.
- Versioning semántico guiado, diff entre versiones, deprecation policy.
- Install/uninstall real: wire a `/api/marketplace/:id/install` (post a `scripts/mcp/skill-server.ts` o filesystem).
- Author profile page: sus skills, ratings, downloads, follow.
- "Fork this skill" para改良.
- CI del publisher: ejecutar el skill en sandbox al publicar, mostrar resultados antes de submit.

**E3. Marketplace — Moderation & Trust (P1)**
- Cola de moderación con reviewer role.
- Signed manifests (ya hay base en `federation-config.json`) — verificar autor y versión.
- Vulnerability scanning (SBOM, secret scan) en el publish pipeline.
- License display (MIT/Apache/proprietary) y rate-limit per-author.

**E4. Marketplace — API pública (P1)**
- REST + GraphQL para terceros: `GET /v1/skills`, `POST /v1/skills/{id}/install`, webhooks (`skill.published`, `skill.updated`, `skill.installed`).
- OAuth2 / API keys; rate-limit por key.

**E5. Content-Operations Panel (P0 — diferenciador único)**
- Construir `apps/web-dashboard/src/components/ContentOpsPanel.tsx` que envuelve `src/content-operations/engine.ts` (CLI hoy).
- Vista Kanban del state machine `DRAFT → VALIDATED → PACKAGED → REVIEW → APPROVED → PUBLISHED → MEASURED` (+ `FAILED`).
- Calendar view de publicaciones planificadas.
- Approval queue con preview del paquete.
- "Publish" con un click + rollback.
- Métricas por plataforma (LinkedIn / X / blog / newsletter) — clicks, reach, conversions.
- **Ningún competidor tiene esto. Es nuestro "we invented content supply chain for LLM agents".**

**E6. Doc-Gentle revival (P2 — opcional)**
- Solo si se valida demanda: tomar el `document-processor` skill del root stack y envolverlo en una UI web.
- Demo: drag-and-drop PDF/DOCX/PNG → OCR → resumen → Q&A interactivo.
- No competir con ChatPDF/Claude.ai; ser el caso de uso que muestra el stack en acción.

---

## 3 · Plan de Promoción / GTM (P0/P1)

> *"Las herramientas del stack deben ser la mejor publicidad del stack."*

### 3.1 Posicionamiento

- **Dashboard**: *"AI-aware observability for teams that ship with agents."*
  - Vs Datadog (no tiene AI-native UI hints ni HITL).
  - Vs Grafana (no tiene agentes ni cost optimization insights).
  - Vs Vercel Observability (no tiene marketplace ni multi-repo mesh).
- **Marketplace / Content Ops**: *"The first content supply chain built for AI agents."*
  - Cero competidores. Esto es original.

### 3.2 Money-shots (5 demos de 90 segundos)

1. **Live Agent Chat** con ui_hints, HITL y @mentions → *"Mira la IA trabajando, estructurada, sin alucinaciones de UI."*
2. **Trace waterfall + feedback loop** → *"Cada span tiene un 👍/👎 que entrena tu routing."*
3. **Stack Capabilities** (anomalías + CB + DB healing) → *"Tu infraestructura se cura sola."*
4. **Cost by model + suggestedAction** → *"Esta semana te ahorraste $1,247 cambiando `big-pickle → haiku` automáticamente."*
5. **ContentOps Kanban** → *"De un draft en Notion a un post en LinkedIn, medido, con rollback."*

### 3.3 Demo-tour UI

- **Landing en `/`** (hoy es el dashboard live): redirigir a un tour curado con 5 cards "Money-shot #N" y un CTA "Live dashboard" abajo.
- **Mock data seeder**: `npm run seed:demo` puebla SQLite con 30 días de datos sintéticos realistas (spike de tokens el lunes, incidente el viernes, 3 alerts disparadas, etc.).
- **Read-only public mode**: `?public=1` desactiva writes (publish skill, agent send, emit event). URL compartible.
- **"Reset" button** en el header para limpiar WS subscriptions y datos locales entre demos.
- **Pre-baked screenshots** en `docs/img/` (5 paneles, 1920×1080) + GIFs cortos.
- **Video script** en `docs/marketing/video-script.md` con timing por shot y B-roll.

### 3.4 Materiales a producir (P0)

- [ ] `docs/landing/index.html` — landing estática (sin React), deploy en GitHub Pages.
- [ ] `docs/landing/pricing.html` — tiers Free / Pro / Team / Enterprise.
- [ ] `docs/landing/vs-datadog.html`, `vs-grafana.html`, `vs-posthog.html` — comparativas.
- [ ] `docs/landing/case-study-1.html` — caso de uso real.
- [ ] `docs/marketing/loom-scripts.md` — 5 guiones de 90s.
- [ ] `apps/web-dashboard/public/screenshots/` — 10 capturas + 3 GIFs.
- [ ] `apps/web-dashboard/public/og-image.svg` — OpenGraph para compartir.
- [ ] `README-PUBLIC.md` actualizar con: hero GIF, "5 money-shots", 3 links a docs.

### 3.5 Canales y cadencia (P1)

- **Dev.to / Hashnode**: 1 post técnico quincenal.
- **X / LinkedIn**: 1 money-shot GIF por semana, hook: "$X saved this week" o "self-healed in 1.2s".
- **YouTube shorts**: 30s por money-shot.
- **Hacker News**: 1 "Show HN" con landing + demo en vivo.
- **Product Hunt**: lanzamiento cuando v4.0 con time-range + ContentOpsPanel.
- **Conferencias**: KCD, AI Engineer Summit, DevTools podcast pitches.

### 3.6 Métricas de éxito (12 semanas post-lanzamiento v4.0)

| Métrica | Target |
|---|---|
| GitHub stars | 1.000+ |
| Descargas del binario | 5.000 |
| Skills publicadas en marketplace | 50 |
| Lighthouse Performance | ≥ 90 |
| Dashboard TTFB | < 200ms p95 |
| NPS del demo-tour | ≥ 40 |

---

## 4 · Roadmap priorizado (12 semanas)

### Fase 0 — Quick wins (Semana 1, ~3 días)
- [x] Sincronizar versiones (C3) — `package.json` es la fuente.
- [x] Actualizar README con protocolo WS completo (C4).
- [x] Renombrar `_useWebSocketMode` → `useWebSocketMode` (C2).
- [x] Reemplazar `byModel` sintético por `[]` con CTA (C2).
- [x] Conectar "Install Skill" del Marketplace (E2).
- [x] Agregar `aria-label` y focus rings a 5 botones principales (A8 quick).
- [ ] Tag: `v3.8.3` (patch).

### Fase 1 — Time-range + tests base (Semanas 2-3, ~10 días)
- [x] Time-series buffer en SQLite (B1).
- [x] Selector de rango global con presets (A1).
- [ ] Tests de `useMetrics`, `useStackTables`, `useAgentStream`, `useSharedWs` (C1 — hooks).
- [ ] Tests de `Dashboard`, `Marketplace`, `TracingDashboard` (C1 — componentes grandes).
- [ ] CI quality gate con coverage report (C8).
- [ ] Tag: `v3.9.0` (minor).

### Fase 2 — Marketplace first-class (Semanas 4-5, ~10 días)
- [ ] Editor markdown con preview + validación continua (E2).
- [x] Sort + facetas + búsqueda de catálogo local (E1; full-text federado queda futuro).
- [ ] Vista de detalle enriquecida (E1).
- [ ] Author profile (E2).
- [ ] Versioning + diff (E2).
- [ ] Tag: `v3.10.0`.

### Fase 3 — Self-telemetry + auth (Semanas 6-7, ~10 días)
- [x] Auth opt-in por `GV_DASHBOARD_TOKEN` para APIs + estado en health (RBAC y signed tokens quedan futuros).
- [x] `/metrics` Prometheus + audit log viewer integrado en `/audit` (D1/D4 base; admin avanzado queda futuro).
- [x] Notificaciones internas de transiciones de alertas por WebSocket, sin dependencias externas.
- [x] Audit log viewer (D4).
- [x] SLO burn rate real sobre snapshots SQLite (D6 base; alert routing queda futuro).
- [ ] Tag: `v4.0.0` (major — primer release "enterprise-ready").

### Fase 4 — ContentOpsPanel + GTM (Semanas 8-10, ~15 días)
- [x] `ContentOpsPanel.tsx` con Kanban + calendar.
- [ ] Landing `/`, pricing, comparativas (3.4).
- [ ] Mock data seeder (3.3).
- [ ] Public read-only mode (3.3).
- [ ] Video scripts + screenshots + GIFs (3.4).
- [ ] 5 posts quincenales en blog (3.5).
- [ ] Tag: `v4.1.0`.

### Fase 5 — Polish + scale (Semanas 11-12, ~10 días)
- [ ] ⌘K command palette (A3).
- [ ] Layouts guardados (A4).
- [x] SSE alternativo en `/api/sse/metrics` (B4; autenticación opt-in cuando se configura token).
- [ ] Drop Recharts → SVG custom (C6).
- [ ] Modernizar lucide, eslint, typescript (C5).
- [ ] E2E Playwright (C1).
- [ ] Lighthouse score ≥ 90.
- [ ] Tag: `v4.2.0`.

### Backlog (post v4.2)
- Doc-Gentle revival (E6).
- Forecasting (D8).
- Anomaly detection cliente (D7).
- Federation dashboard dedicado.
- Marketplace API pública v1 (E4).
- i18n fr/de (A7).

---

## 5 · Estimaciones y dependencias

| Fase | Esfuerzo | Riesgo | Personas |
|---|---|---|---|
| F0 | 0.5 dev-week | Bajo | 1 |
| F1 | 2 dev-weeks | Medio (SQLite schema + UI) | 1-2 |
| F2 | 2 dev-weeks | Medio (FTS5 + editor) | 1-2 |
| F3 | 2 dev-weeks | Medio-alto (auth) | 2 |
| F4 | 3 dev-weeks | Medio (ContentOpsPanel + marketing) | 2-3 |
| F5 | 2 dev-weeks | Bajo-medio | 1-2 |
| **Total** | **~12 dev-weeks** | | **2 promedio** |

Dependencias críticas: el `metrics-aggregator` y `metrics-writer` del root stack deben exponer una API de time-series antes de F1.

---

## 6 · Riesgos y anti-patterns a evitar

1. **No competir en lo horizontal** (Datadog tiene 700 integraciones; no las vas a tener). Competir en lo vertical: **AI-native, content-ops, auto-healing**.
2. **No prometer "como Datadog pero gratis"** — el mercado lo ve como "versión barata de Datadog". Posicionar como **categoría nueva**: *AI-aware observability + content supply chain*.
3. **No romper la promesa "local-first"**. El binario debe correr offline; las notificaciones externas son opt-in.
4. **No acumular deuda de i18n** — agregar `fr/de` ahora es barato, después es caro. F0 ya tiene el patrón.
5. **No hacer marketing antes de que F1 esté en producción** — un dashboard sin time-range no es presentable a un manager.
6. **No olvidar el README público** — `README-PUBLIC.md` se replica en `gentle-vanguard-public`; debe ser la mejor página de aterrizaje. Hoy está desactualizado (v3.3.0 vs v3.8.2 real).

---

## 7 · Cómo ejecutar este plan

### Modo recommended (1 semana de descubrimiento)
1. **Hoy**: validar este plan con stakeholders (CTO + Marketing).
2. **Semana 1**: SDD completo para F1 (time-range + tests base) con BA/DEV/QA/QA.
3. **Semana 2+**: ejecutar F1-F5 con reviews por fase.

### Modo fast-track (sin SDD)
1. Asignar owners por track (A, B, C, D, E).
2. Daily standup de 15min.
3. Review semanal con demo en vivo del dashboard actualizado.

### Métricas de seguimiento
- Coverage % (subir de 20% a 80% en 12 semanas).
- Lighthouse score (subir a 90+).
- Bundle size (bajar 30%).
- TTFB p95 (< 200ms).
- Stars en repo (crecer orgánicamente con buen material).
- Skills publicadas en marketplace (target: 50 en 12 semanas).

---

## 8 · Referencias citadas (file:line)

- `apps/web-dashboard/src/App.tsx:20-29` — lazy routes
- `apps/web-dashboard/src/components/Dashboard.tsx:79-96` — OfflineBanner
- `apps/web-dashboard/src/components/Dashboard.tsx:411-444` — Cost insights con suggestedAction
- `apps/web-dashboard/src/components/Marketplace.tsx:380-382` — "Install Skill" no-op
- `apps/web-dashboard/src/components/StackCapabilitiesPanel.tsx` — money-shot #3
- `apps/web-dashboard/src/components/TracingDashboard.tsx:185-215` — feedback loop
- `apps/web-dashboard/src/hooks/useMetrics.ts:23` — `_useWebSocketMode` ignorado
- `apps/web-dashboard/src/hooks/useStackTables.ts:20-56` — polling 15s
- `apps/web-dashboard/src/hooks/useSharedWs.ts:5-96` — singleton WS
- `apps/web-dashboard/server/websocket-server.ts:1487-1587` — broadcast 5s
- `apps/web-dashboard/server/websocket-server.ts:1601-1619` — file-watcher 200ms
- `apps/web-dashboard/server/real-data.ts:273-289` — byModel sintético
- `apps/web-dashboard/server/real-data.ts:477-481` — model switch suggestion
- `apps/web-dashboard/server/database/manager.ts:122-369` — 12 repos SQLite
- `src/content-operations/engine.ts` — state machine único
- `src/content-operations/cli.ts` — `list|validate|prepare|status|report|transition|export`

---

**Próximo paso**: validar este plan, decidir fase 0 (quick wins) sin SDD para esta semana, y agendar SDD formal para fase 1.
