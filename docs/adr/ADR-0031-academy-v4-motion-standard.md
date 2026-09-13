# ADR-0031 — Academy v4 y el motion/UX standard del stack (homologación de apps)

Fecha: 2026-09-06 · Estado: aceptado · Apps: `apps/academy-web` (v4) + roadmap de adopción para
todas las apps

## Status

Accepted — implementado (Academy v4 + homologación 8/8 apps, 2026-09-06).

## Context

Academy (v2, 2026-09-01) tenía la base del canon v2 Premium (tokens, atmósfera, glass cards) pero se
quedó atrás frente a las apps trabajadas recientemente (Prompt Studio v4.6, CMS v3.9.0): sin capa de
motion, sin toasts, sin lightbox, sin navegación por teclado en búsqueda, i18n solo es/en, contenido
desactualizado (v3.8.2, "27 tablas" cuando Nexus tiene 37) y capturas de demo obsoletas. No existía
un vocabulario de efectos **oficial y reutilizable** — cada app inventaba los suyos, y la
homologación UX/CX pedida para command-center, prompt-studio, archify, CMS, dashboard y design-hub
no tenía estándar escrito al cual remitir.

## Decision

1. **Academy v4** (`apps/academy-web`): nueva capa CSS `academy-motion.css` (carga al final: tokens
   → atmosphere → style → components → layout → motion) + `app.js` v4 con: spotlight-card con
   seguimiento de puntero, reveal-stagger (`--reveal-i`), sistema de toasts glass con `aria-live`,
   lightbox de imágenes con navegación ← → / Escape, back-to-top con anillo de progreso de scroll,
   Ctrl+K + ↑↓/Enter en búsqueda con badges y conteo, mini-TOC con scroll-spy por
   IntersectionObserver, copy-code con fallback `execCommand`, continue-learning banner
   (localStorage `gv-academy-last`), glosario con filtro vivo + contador, blur-up de imágenes,
   breadcrumbs, celebración sobria de track completo, i18n **es/en/pt**, keyboard ← → para paginar
   lecciones.
2. **Diagramas SVG vivos**: helper con gradientes por instancia (ids únicos), nodos con hover-glow,
   aristas con `dash-flow` animado, corrección factual (Nexus **37 tablas** verificado en
   `sqlite_master`) y 4 diagramas nuevos: `session-pipeline`, `watchtower-loop`, `apps-map`,
   `memory-sync`.
3. **Demo gallery con capturas reales**: `scripts/capture-v4.mjs` (Playwright) captura dashboard
   autenticado (login por API con `GV_DASHBOARD_TOKEN` de env — la cookie vive solo en el navegador
   de captura), CMS y Prompt Studio en vivo; `build-demoimgs.mjs` re-embed. Capturas viejas
   obsoletas eliminadas (`dashboard-marketplace`, `dashboard-content-operations`).
4. **Contenido**: track nuevo **"Apps del stack"** (8 lecciones, una por app, con datos reales de
   puertos/arquitectura), glosario 120 → **132 términos** (MCP, SSE, prompt injection, WAL,
   hash-chain, token budget, motion standard, etc. reordenados alfabéticamente), diagrama
   `memory-sync` en la lección de knowledge-base, footer del stack a v3.9.0.
5. **Estándar oficial transversal**: `docs/design/07-motion-ux-standard.md` documenta el vocabulario
   de efectos, tokens de motion, reglas de accesibilidad y el checklist de adopción. Las demás apps
   homologan contra ese documento (plan en `docs/apps/HOMOLOGACION-UX-2026-09-06.md`).

## Alternativas descartadas

- **Librerías de animación (framer-motion, GSAP)**: viola local-first/sin-deps de las apps vanilla y
  agrega peso; el vocabulario completo se logra con CSS moderno + ~150 líneas de JS delegado.
- **View Transitions API**: aún sin soporte uniforme en el target (Chrome + file://); `viewIn` +
  reveal cubre el mismo efecto.
- **Capturar el dashboard con `GV_DASHBOARD_DEV_AUTH=1` permanente**: cambia estado del entorno; el
  login por API en el navegador efímero de captura es equivalente y no deja rastro.

## Consecuencias

- Academy queda como **referencia de motion/UX** del stack (junto a analytics en visual). Toda app
  nueva debe arrancar del estándar 07.
- El estándar es **opt-out por respeto** (`prefers-reduced-motion`) y sin dependencias — portable a
  apps React (los patrones son CSS-first, el JS es delegado y aislable).
- Pendiente conocido (preexistente, no de este cambio): el "native aggregator" del dashboard muestra
  cards superiores en skeleton hasta el próximo ciclo de métricas; el bridge offline de Agent
  Activity sigue abierto.

## Verificación

- Playwright: filtro de glosario (8 hits "mcp"), mini-TOC (5 links), copy-code, toasts al marcar
  lección + persistencia localStorage, Ctrl+K → ↑ → Enter navega a `#/lesson/...`, 0 pageerrors
  (solo CORS preexistente del widget CC en file://).
- Capturas validadas: home dark/light, lección con scroll-spy activo, glosario (132 términos), demo
  con capturas reales, track nuevo, mobile 390px.
