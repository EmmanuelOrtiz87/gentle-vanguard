# Auditoría funcional de apps — 2026-09-02

> Fase de **funcionalidad** (la visual/brand quedó cerrada el 2026-09-02 con v2 Premium).
> Método: audit estático por app (CRUD, endpoints, persistencia, stubs, botones muertos) +
> simulación de uso real en browser (flujos completos, consola, red) + benchmark contra apps
> líderes por categoría. Todo lo marcado "arreglado" fue re-verificado en vivo.

## Resumen ejecutivo

- **8 apps auditadas y probadas en vivo**. Todas cargan sin errores de consola (solo hints de
  a11y menores). Ninguna usa mock data: todo deriva de Nexus/SQLite, archivos o localStorage.
- **5 bugs de funcionalidad arreglados y verificados** (ver §Fixes).
- **3 features estructurales nuevos** (ver §Features nuevos): logs por app en Command Center,
  acknowledge de alertas en Dashboard, progreso de lecciones en Academy.
- **Veredicto por app**: 6 de 8 son plenamente operativas (CRUD real + persistencia +
  acciones). Academy pasa de "100% lectura" a interactiva con progreso. Design Hub es la más
  limitada (estática por diseño; su CRUD real es el token editor con persistencia localStorage).

## Matriz funcional por app

| App | Puerto | Qué hace (problema que resuelve) | Cómo lo hace | CRUD real | Persistencia | Utilidad / por qué existe |
|---|---|---|---|---|---|---|
| **web-dashboard** | 5173/8080 | Observabilidad LLM del stack: métricas, trazas, alertas, costos, marketplace, agentes | React+Vite + WS push 5s + REST sobre Nexus SQLite | Feedback en trazas, instalar/desinstalar skills, moderar, chat agentes, admin RBAC, MCP start/stop | Nexus `.runtime/gentle-vanguard.db` + marketplace en archivos | El centro de control operativo: "¿qué hizo mi IA, cuánto costó, está sano?" |
| **gv-analytics** | 5174/4754 | Informes de entrega desde contexto Atlassian (Jira/Confluence/Bitbucket) | React + server TS + Atlassian API real + LLM con cache + vault AES-256-GCM | Reportes: crear/abrir/borrar/bulk/4 export; conexión: crear/test/editar | Nexus (reportes, métricas, cache) + vault encriptado | Convierte tickets/pages en informes ejecutivos exportables sin copy-paste |
| **content-cms** | 5175/3787 | CMS social local-first: brief → variantes multi-red → calendario → export asistido | React + server TS sobre Nexus + generador LLM/template | Items (crear, **eliminar en cascada** ✓), variantes (editar/aprobar/rechazar/copiar), slots (CRUD+transiciones), media (upload/edit/delete) | Nexus + `.runtime/content-os/` | Flujo editorial completo con gate humano, sin publicar directo (ADR-0021) |
| **academy-web** | 4173 | Curso del stack: 11 rutas, 65 lecciones, glosario 115 | SPA vanilla sin build, contenido en JS | **Progreso de lecciones** ✓ (marcar/desmarcar, % por track) | localStorage `gv-academy-progress` + preferencias | Onboarding autocontenido de cualquier persona nueva (incluido uno mismo en 6 meses) |
| **prompt-studio** | 5176/5177 | Biblioteca de prompts profesionales con búsqueda NL | React + better-sqlite3 + FTS5 | Prompts: crear/editar/**eliminar con confirmación** ✓/favorito/copiar/buscar | `.runtime/prompt-studio/prompts.db` (WAL) | El conocimiento de prompting deja de vivir en chats dispersos |
| **archify** | 5179/4790 | Diagramas de sistemas desde JSON IR tipado + delta PR-proof | React + server TS + engine renderers | Diagramas: crear/**actualizar sin duplicar** ✓/eliminar con confirmación/duplicar/abrir; export HTML/SVG/PNG | localStorage `gv-archify-library` (200 máx) | Documentación de arquitectura versionable y revisable en PRs |
| **design-hub** | 8095 | Gestión del design system: tokens, componentes, assets | Estática (python http.server), sin backend | Token editor: editar/save/cancel/history con rollback real; assets: download/favicon/OG | localStorage overrides + history | Fuente visual del canon v2 Premium; los archivos del repo solo via CLI (por diseño) |
| **command-center** | 8090 | Ciclo de vida de las apps del stack | Node puro, cero deps | Start/stop/open por app y global; **visor de logs por app** ✓ | pidfiles + `.runtime/cc-logs/` | Operación sin terminal: arranca/para/diagnostica todo desde el browser |

## Fixes aplicados (verificados en vivo)

1. **archify — guardar duplicaba en vez de actualizar** (`apps/archify/src/App.tsx`): el estudio
   no trackeaba el id del diagrama abierto. Ahora "Abrir → editar → Guardar" actualiza (botón
   cambia a "Actualizar", indicador "editando:" en la barra meta). + Confirmación en delete de
   biblioteca. + `mkdirSync` defensivo por operación en el server (sobrevive limpieza de
   `.runtime` en caliente) + 15 archivos scratch residuales purgados.
2. **prompt-studio — delete sin confirmación** (`apps/prompt-studio/src/App.tsx`): ahora pide
   confirmación con el título. + `better-sqlite3` declarado en package.json (antes vivía del
   hoisting del root) + puerto Vite fijado a 5176 strictPort (alineado con start.sh).
3. **content-cms — no se podían eliminar items** (`server/server.ts`, `contentos.tsx`,
   `src/database/nexus/repositories/ContentOSRepo.ts`): ruta `DELETE /api/items/:id` nueva +
   cascade transaccional (variants y slots mueren con su item; publish_log se conserva como
   audit trail) + botón ✕ en historial con confirmación + i18n es/en. Verificado: 5→4 items,
   8→6 slots.
4. **academy — datos inconsistentes y código muerto** (`app.js`, `index.html`): contador "7
   rutas" → dinámico (`TRACKS.length` = 11); 3 tracks faltantes en nav (automatizaciones,
   casos-reales, knowledge-base); GEN_TEMPLATES muerto eliminado; `data/i18n.js` muerto (340
   líneas sin referenciar) eliminado; comentario de cabecera actualizado.
5. **design-hub — botones muertos en visual-comparison** (`src/labs/visual-comparison/`):
   "Generar Reporte" era `alert()` → ahora modal con botón Copiar; los 11 tooltips "Copiar: X"
   ahora copian de verdad (delegation + feedback visual). + README corregido (export
   Figma/Tailwind vive en el paquete, no en la UI; referencia a script inexistente eliminada).

## Features nuevos (verificados en vivo)

1. **Command Center — logs por app** (`apps/command-center/server.ts`, `public/index.html`):
   stdout+stderr de cada proceso van a `.runtime/cc-logs/<app>-<proceso>.log` vía fd directo
   (sin pipes → sin riesgo EPIPE si CC muere; rotación simple a 512KB). Endpoint
   `GET /api/apps/:id/logs?process=&lines=` + botón "▤ Logs" por card con modal por proceso.
   Responde "¿por qué no arrancó?" sin abrir terminal.
2. **Dashboard — acknowledge de alertas** (`server/ws-hub/context.ts`, `handlers/validations.ts`,
   `handlers/observability.ts`, `src/components/AlertPanel.tsx`): registry en memoria
   server-side; el ack se libera automáticamente cuando la alerta se resuelve (nunca mutea
   permanente). `POST /api/alerts/ack|unack` + botones en AlertPanel con estado acked visible
   (dimmed + hora). WS y REST anotan `acknowledged`/`ackedAt`.
3. **Academy — progreso de lecciones** (`app.js`, `academy-components-v2.css`): botón
   "Marcar como completada" (toggle) por lección, ✓ en nav lateral e índice, contador "X/Y
   (Z%)" + barra de progreso en la vista de track, badge % + mini-barra en cards del Home.
   Persiste en localStorage — la app deja de ser 100% lectura.

## Benchmark competitivo (síntesis)

Referencias por categoría: Langfuse/LangSmith (observabilidad), PromptLayer/Agenta (prompts),
Planable/Buffer (calendario social), Excalidraw/draw.io/Mermaid (diagramas), Tokens
Studio/Style Dictionary (design tokens), Docusaurus/MkDocs (docs), eazyBI/Office Timeline
(reporting Jira).

**Table stakes transversales que toda app seria necesita** — estado del stack:

| Table stake | Estado |
|---|---|
| Confirmación en delete | ✓ cerrado hoy (3 apps) |
| Persistencia local robusta | ✓ todas (SQLite/localStorage) |
| Búsqueda/filtrado de la entidad principal | ✓ (FTS5 en prompts, filtros en tracing/CMS) |
| Export/import interoperable | ✓ (4 formatos analytics, HTML/SVG/PNG archify, JSON/CSV tracing) — ⚠ round-trip import parcial |
| Versionado/historial con rollback | ✓ tokens (hub) y studio legacy CMS — ⚠ falta en prompts y diagramas |
| Workflow states explícitos | ✓ CMS (draft/approved/skipped), variants (edited/approved) |
| Datos reales, nunca mock | ✓ auditado en las 8 |
| Feedback loop del usuario | ✓ trazas (👍/👎) — ⚠ academy/docs sin feedback por página |
| Atajos de teclado | ✓ academy (/), viewer archify (T/S/F/E/R/M/L) — ⚠ inconsistente |
| Undo/redo | ✗ la deuda transversal más grande |

**Diferenciadoras que definen a los líderes** (aún no): A/B testing de prompts con métricas
por variante, datasets+evals sobre trazas, sync bidireccional de tokens a Git, drag-and-drop
del calendario, colaboración real-time.

## Roadmap priorizado (antes de crear apps nuevas)

1. **Prompt Studio: versionado con diff y rollback** (impacto alto, esfuerzo medio) — es LA
   feature que separa una biblioteca de un sistema de prompt management. Cada save crea
   versión inmutable; la UI muestra diff y permite restaurar.
2. **Command Center: causa de fallo accionable** (alto/bajo) — el log ya existe; sumar
   detección de patrones comunes (puerto ocupado, dependencia faltante) en el modal de logs.
3. **Dashboard: métricas y OAuth con UI** (medio/medio) — `/api/metrics` y `/api/oauth/*`
   existen sin superficie visual; las claves i18n oauth.* ya están.
4. **CMS: drag-and-drop de calendario + preview por plataforma** (medio/alto) — table stakes
   de Planable/Buffer.
5. **Analytics: refresh de reportes existentes** (medio/medio) — re-importar y actualizar sin
   regenerar (flujo eazyBI/Office Timeline).
6. **Undo/redo transversal** (alto/esfuerzo alto) — empezar por CMS variants y archify.
7. **Academy: quizzes por lección** (medio/medio) — cierra el loop de aprendizaje; el
   progreso ya existe como base.

## Verificación ejecutada

- Typecheck: archify ✓, prompt-studio ✓, content-cms ✓ (incl. server), command-center ✓,
  web-dashboard ✓ (src+server).
- Tests: content-cms 40/40 ✓ (incl. suite del server), smoke command-center ✓.
- Builds: web-dashboard production ✓.
- Watchtower: todos los componentes OK (tras reap de 1 one-shot colgado).
- En vivo: delete-cascade CMS ✓, update archify ✓, ack/unack alertas ✓ (alerta real
  `high_token_usage`), logs CC ✓ (archify reiniciado vía CC escribe log), progreso academy ✓
  (toggle/track/home), modal design-hub ✓, i18n EN academy ✓ (14/14 nav).
