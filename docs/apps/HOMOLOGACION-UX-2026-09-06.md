# Homologación UX/CX de apps GV — hacia el motion standard v1

Fecha: 2026-09-06 · Base: ADR-0031 + `docs/design/07-motion-ux-standard.md` Referencia viva:
**Academy v4** (`apps/academy-web`). Objetivo: que las 8 apps presenten la misma experiencia —
efectos, transiciones, fondos, movimiento, colores, formatos, bordes — sin perder su carácter por
superficie.

## Estado final (sesión 3, 2026-09-06): 8/8 apps homologadas ✅

| App            | Identidad v2 | View-fade | Motion layer    | Toasts               | Teclado     | i18n es/en/pt | Estado                                |
| -------------- | ------------ | --------- | --------------- | -------------------- | ----------- | ------------- | ------------------------------------- |
| Academy v4     | ✅           | ✅        | ✅ (referencia) | ✅                   | ✅          | ✅            | **✅ HOMOLOGADA** (referencia)        |
| Dashboard      | ✅           | ✅        | ✅              | ✅                   | ✅          | ✅            | **✅ HOMOLOGADA** (+ vista Histórico) |
| Command Center | ✅           | ✅        | ✅              | ✅                   | ✅          | ✅ (es/en)    | **✅ HOMOLOGADA**                     |
| Archify        | ✅           | ✅        | ✅              | ✅                   | parcial     | ✅            | **✅ HOMOLOGADA**                     |
| Prompt Studio  | ✅           | ✅        | ✅              | ✅ (toast unificado) | ✅ (Ctrl+K) | ✅            | **✅ HOMOLOGADA** (sesión 3)          |
| Content CMS    | ✅           | ✅        | ✅              | ✅                   | parcial     | ✅            | **✅ HOMOLOGADA** (sesión 3)          |
| gv-analytics   | ✅           | ✅        | ✅              | parcial              | parcial     | ✅            | **✅ HOMOLOGADA** (sesión 3)          |
| Design Hub     | ✅           | ✅        | ✅              | parcial              | parcial     | ✅            | **✅ HOMOLOGADA** (sesión 3)          |

### Ejecutado en sesión 3 (2026-09-06, cierre del plan)

- **Prompt Studio**: toast unificado con auto-dismiss (los 5 mensajes transitorios del generador
  ahora salen como `.ps-toast` glass con barra de acento gradiente, en lugar de texto inline),
  spotlight radial en las cards de gemas y de la biblioteca (`.ps-spotlight`, verificado 16 cards en
  la tab Gemas), guard reduced-motion. tsc + build verdes.
- **Content CMS**: spotlight en `.gv-glass-card` (historial, medios, settings — listener delegado
  único en `contentos.tsx`), reveal escalonado puro-CSS en `.item-list` (nth-child, sin JS),
  hover-zoom en imágenes de medios con cursor zoom-in. tsc + build verdes (toasts semánticos y
  reduced-motion ya existían de v3.9.0).
- **gv-analytics**: back-to-top con anillo de progreso (`BackToTop` component, aparece >640px de
  scroll), spotlight delegado en todos los `.panel`. tsc + build verdes (viewIn y reduced-motion ya
  existían).
- **Design Hub**: capa compartida `src/styles/motion-hub.css` + `src/scripts/motion-hub.js`
  (spotlight en `dh-panel`/`dh-preview-card`/`dh-comp-card`, tolerante a doble carga, idempotente)
  enlazada en las 3 páginas (shell, tokens-editor, components).

### Nota de portabilidad

El patrón aplicado en las 4 apps es el mismo que define el estándar §3: spotlight con variables
`--mx/--my` alimentadas por UN listener delegado con rAF; toasts glass con barra de acento de
gradiente de marca y spring-in; reveal escalonado con delays ≤45ms; todo apagable bajo
`prefers-reduced-motion`. En apps React el listener vive en un `useEffect` con cleanup; en vanilla,
en un IIFE guardado por flag de ventana.

### Ejecutado en sesión 2 (2026-09-06)

- **Dashboard — vista Histórico nueva** (`/history`): API `GET /api/history/sessions` y
  `/api/history/sessions/:id` (handler `server/handlers/history.ts`) sobre token_usage + traces +
  token_transactions + token_savings. Lista consolidada de TODAS las sesiones (706 reales: zcode,
  minimax, opencode, codex y stack), filtros por rango (7d/30d/90d/todo), fuente, modelo, búsqueda y
  orden; resumen del conjunto filtrado (sesiones, tokens, promedio, tokens ahorrados por cache);
  distribución por fuente; drill-down por sesión con breakdown de modelos, mensajes
  (token_transactions), trazas y ahorro. Heurística de fuente con desambiguación (mini­max vs
  opencode comparten `ses_*` — se resuelve con agent orchestrator/subagent y message_id
  `minimax:*`/`codex:*`; `session-<fecha>` = sesiones del stack). 9 tests (vitest) + tsc + lint +
  build verdes. Footer v3.8.2 → v3.9.0.
- **Misterio del "aggregator skeleton" resuelto**: era el proceso WS server stale; tras reinicio vía
  Command Center el home queda 100% vivo (WS Connected, Source SQLite, process hygiene, tokens).
  "Bridge Offline" es estado operacional del daemon de bridge (arranca con sesión de bridge), no
  bug.
- **Command Center**: spotlight-card en las 7 cards, reveal-stagger en primer render, toasts glass
  con barra de acento en start/stop/preset (es/en), reduced-motion guard. Verificado con Playwright.
- **Archify**: reparados los keyframes `gv-view-fade` que se usaban SIN estar definidos (bug real),
  spotlight + reveal en cards de biblioteca, toast premium con barra de acento gradiente, guard
  reduced-motion global. tsc + build verdes.
- **Academy**: captura del dashboard en la demo gallery actualizada a la captura viva (WS
  Connected).

Claves compartidas ya homologadas transversalmente: tokens v2 Premium, logo oficial 32px, topbar
glass, footer mono, `gv-cc-theme` / `gv-cc-lang`, bind loopback, sin dependencias de animación.

## Plan de adopción (orden sugerido)

1. **Command Center** (puerta de entrada visual del stack): reveal-stagger en cards, toasts en
   start/stop/error, spotlight en cards de apps. Es Node puro: los patrones van como CSS + ~60
   líneas JS.
2. **Archify** (mayor brecha): portar `academy-motion.css` como `archify-motion.css` (mismo
   vocabulario, prefijo de app), toasts en generación, lightbox en previews.
3. **Prompt Studio**: unificar toasts (hoy dispersos), spotlight en cards de gemas, blur-up en
   previews, celebración sobria al exportar backup.
4. **Content CMS**: spotlight en cards de historial/medios, blur-up en medios, stagger en
   calendario.
5. **Dashboard**: toasts en admin/RBAC, copy-code en exports JSON, stagger en metric cards,
   back-to-top.
6. **gv-analytics**: spotlight en panels, back-to-top en reportes, copy-code en queries MCP.
7. **Design Hub**: spotlight en tokens/componentes, copy-code en snippets, blur-up en assets.

## Reglas de la homologación

- **Portar patrones, no el archivo literal** cuando la app es React: los efectos son CSS-first; el
  JS delegado se adapta al framework (un `useEffect` con pointermove delegado, un componente Toast).
- Los prefijos `--gv-*` siguen reservados al canónico (`rules/NORMATIVA-DESIGN-SYSTEM.md`); los
  efectos usan esos tokens, no valores nuevos.
- Cada app completa el checklist de la sección 7 del estándar y valida con screenshots
  dark/light/mobile antes de dar la app por homologada.
- **Sin regresiones funcionales**: la homologación es capa de experiencia; no toca rutas, APIs ni
  estado.

## Notas de esta sesión (contexto para la siguiente)

- **Cierre de minors (sesión 4, 2026-09-06)**: analytics YA tenía copy en reportes (botón con i18n
  `report.copy` — la matriz estaba desactualizada); Design Hub copy-code es N/A (no hay bloques de
  código `<pre>`, solo `<code>` inline en mensajes); CMS suma Ctrl+K que enfoca la búsqueda del
  historial (`os-item-search`). Watchtower 124/124 PASS (reparada integridad de Engram: checksums
  regenerados + reindex RAG). Todo pusheado a origin (develop + main en `757b54ff`).
- Dashboard: el "native aggregator" dejó cards superiores en skeleton y Agent Activity en "Bridge
  Offline" — estado preexistente a investigar en la próxima sesión de dashboard (no bloquea la
  homologación). RESUELTO sesión 2: era el proceso WS stale; el bridge es estado operacional.
- Las capturas de demo de Academy quedaron regeneradas desde apps vivas: dashboard (home, tracing
  200 trazas, timeline, admin RBAC), CMS (Content OS) y Prompt Studio, vía
  `apps/academy-web/scripts/capture-v4.mjs` con login por API (`GV_DASHBOARD_TOKEN` de env, cookie
  efímera en el navegador de captura).
