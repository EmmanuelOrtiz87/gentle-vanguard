# Gentle-Vanguard Analytics — Pendientes

> Estado al 2026-08-28 (sesión actual). El app está funcional pero no integrado de forma
> nativa al stack. Esta lista organiza el trabajo restante para dejar la app "lista" —
> operacional, conectada al stack, con análisis LLM real y pulido de producto.

Leyenda: `[ ]` pendiente · `[x]` hecho · `[~]` en curso.

## P0 — Operación del stack (debe estar antes de que otros la usen)

- [x] **Commit del avance actual** — staged en PR con apps/gv-analytics + docs/analytics.
- [x] **Stepper en cabecera con scroll-spy** — 4 botones (Conexión → Análisis → Reporte →
  Evidencia) muestran progreso y permiten salto suave. Botón activo se ilumina con el
  gradiente de marca y badge numérico.
- [x] **Historial limitado a 5** — API `GET /api/reports` default `limit=5` (cap 25),
  panel del sidebar dice "Últimos 5 reportes" y slicea en cliente.
- [ ] **Wire MCP en `opencode.json#mcp`** — `gv-analytics-atlassian` ya está en
  `config/mcp-registry.json` con `autoStart:false`. Falta decidir entrypoint y agregarlo a
  `opencode.json` sin pisar overrides locales.
- [ ] **Daemon del stack** — pidfile en `.runtime/gv-analytics.pid`, script `npm run`
  en el package, integración a `process-hygiene.ts` y `maintenance-watchtower.ts` (96 checks).
- [ ] **Cleanup automático del puerto 4754** — `dev` mata el puerto a mano con
  `netstat`. Necesario: cleanup al cierre de sesión para no dejar zombies.

## P1 — Análisis con LLM real (core del producto)

- [ ] **Reemplazar heurística por model router** — `analyzeInput` hoy detecta frentes y
  estima con reglas (regex catalog). Debe invocar el model router
  (`config/model-router.json`) con perfiles cheap/balanced/premium y agentes BA/SAD/DEV/QA/DOC.
- [ ] **Pipeline route-and-delegate** — invocar `npx tsx src/delegate/route-and-delegate.ts`
  o equivalente con el contexto del ticket. El reporte debe componerse de outputs reales
  de los subagentes, no strings hardcodeados.
- [ ] **Cache de evidencia en Nexus** — mismo Jira/Confluence/Bitbucket no debería
  re-fetchar en cada análisis. Tabla `gv_analytics_evidence_cache` con TTL.
- [ ] **Diagramas diagram-design en el reporte** — el slice "diagramas" del reporte devuelve
  strings. Usar `skills/diagram-design` (27 tipos) o equivalente para renderizar
  visualmente el estado actual vs propuesto (HTML/SVG self-contained).

## P2 — Producto / UX

- [ ] **OAuth 2.0 con callback local** — evolución del API token. Servidor de callback
  en `127.0.0.1`, persistencia cifrada AES-GCM en `.runtime/gv-analytics/`.
- [ ] **Validación Atlassian mejorada** — feedback inmediato en la UI al pegar
  credenciales (status de Jira/Confluence/Bitbucket con un solo click).
- [ ] **Templates de reporte** — formatos configurables (executive brief vs full SDD)
  desde la UI sin tocar código.
- [ ] **Tests E2E** — suite Playwright/Vitest que cubra: conexión, análisis,
  persistencia, export PDF, export DOCX. Hoy solo hay smoke test manual documentado.
- [ ] **Métricas de uso** — cuántas requests/min, qué proveedor de modelo responde,
  latencia p50/p95. Tabla `gv_analytics_metrics` + dashboard widget.

## P3 — Cross-app / futuro

- [ ] **Widget en `apps/web-dashboard`** — vista de "últimos análisis" sin necesidad
  de abrir gv-analytics.
- [ ] **i18n en/pt/es** — siguiendo el patrón del dashboard actual.
- [ ] **Theme switcher** (light/dark) — actualmente solo dark.
- [ ] **Storybook** para componentes UI del reporte.

## Riesgos identificados

- El reporte actual se ve completo en UI pero internamente es heurístico. Si el usuario
  espera profundidad SDD real, hay que reemplazarlo antes de declararlo "MVP".
- `mcp-registry.json` ya tiene el server con `autoStart:false`. Si lo prendemos sin
  tener pidfile/daemon registrado, deja zombies cuando se cierre la sesión.
- `docx` está como dep directa. Si se quiere aligerar el bundle del server, mover a
  dependencia opcional.
- Scroll-spy con `IntersectionObserver`: si el reporte es muy corto y todos los panels
  caben en pantalla, la "sección activa" puede oscilar. Probado con rootMargin que
  favorece la sección superior.

## Comando de arranque

```bash
cd apps/gv-analytics
pnpm install
pnpm dev   # vite :5174 + api :4754
```

## Plan operativo (sugerido)

Por la magnitud del pendiente, propongo ejecutar en olas secuenciales para no diluir
calidad:

1. **Ola 1 (en curso)**: commit + stepper + history=5 — UX feedback directo, verde.
2. **Ola 2 (P0)**: wire opencode.json + daemon + cleanup 4754 — integración stack.
3. **Ola 3 (P1)**: model router + diagramas + cache — profundidad real.
4. **Ola 4 (P2)**: OAuth + tests E2E + métricas — producto.
5. **Ola 5 (P3)**: widget + i18n + theme + storybook — cross-app polish.

Si en cualquier ola el stack no tiene la capacidad, se crea nativa o se busca en
internet (Atlassian docs, diagram-design specs, OAuth 2.0 RFC 6749) y se absorbe
en `apps/gv-analytics/server/` + `skills/` para que sea reutilizable.
