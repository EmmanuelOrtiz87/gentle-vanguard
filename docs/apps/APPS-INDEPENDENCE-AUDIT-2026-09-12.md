# Auditoría de Independencia de Apps — 2026-09-12

> Objetivo: verificar que las 9 apps del stack + Command Center funcionan, cumplen la normativa
> (ADR-0017 loopback-only, NORM-TS-001, regla procesos-ocultos), tienen ciclo de vida nativo
> (`start.sh`/`stop.sh` en su directorio **y** gestión desde Command Center), base de datos propia
> y documentación completa — es decir, **comercializables por separado**.

## Matriz consolidada (estado final tras las correcciones)

| App | UI | API | BD propia | start/stop nativos | En CC | Autónoma | Tests |
| --- | --- | --- | --- | --- | --- | --- | --- |
| web-dashboard | 5173 | WS 8080 (dinámico) | ✅ vendida (Nexus interno, path configurable) | ✅ (reescritos, no bloquean) | ✅ | ✅ código; datos = fuente del stack por diseño | ✅ vitest |
| gv-analytics | 5174 | 4754 | ✅ `apps/gv-analytics/.runtime/gv-analytics.db` | ✅ | ✅ | ✅ (delegador LLM opcional) | ✅ (nueva suite) |
| content-cms | 5175 | 3787 | ✅ `apps/content-cms/.runtime/content-cms.db` (migrada desde Nexus) | ✅ | ✅ | ✅ (deps vendidas) | ✅ vitest |
| academy-web | 4173 | — (estática) | ✅ `data/` (JSON/JS) | ✅ | ✅ (como `academy`) | ✅ (sync best-effort) | ✅ validadores |
| prompt-studio | 5176 | 5177 | ✅ `apps/prompt-studio/.runtime/` (migrada desde root) | ✅ | ✅ | ✅ (import gemas vendido) | ✅ (7 tests HTTP) |
| archify | 5179 | 4790 | ✅ `apps/archify/.runtime/archify.db` | ✅ | ✅ | ✅ (deps declaradas) | ✅ vitest + engine |
| design-hub | 8095 | — (estática) | ➖ stateless | ✅ (pidfile anclado) | ✅ | ✅ | ✅ status.js |
| academy-crm | 4791 | 4792 | ✅ `apps/academy-crm/data/crm.db` | ✅ (nuevos) | ✅ | ✅ (deps declaradas) | ✅ (15 tests) |
| academy-landing | 4174 | — (estática) | ➖ stateless (leads→localStorage) | ✅ (nuevos) | ✅ (nueva) | ✅ total | ➖ estática |
| command-center | 8090 | — | ➖ stateless (pidfiles) | ✅ | — (es el panel) | ✅ código (sin imports de `src/`) | ✅ vitest 6 + smoke |

Leyenda: ✅ conforme · ➖ no aplica/backlog.

## Ciclo de vida — convención única

- Cada app tiene `apps/<app>/start.sh` y `stop.sh` **idempotentes**: chequeo de puerto con
  `netstat`, pidfiles compartidos con CC en `.runtime/app-<id>-<proceso>.pid`, bind `127.0.0.1`
  (ADR-0017), spawn oculto (`nohup` desde Git Bash no abre ventanas; servers TS siempre con
  `node --import tsx` — nunca `npx tsx`, regla procesos-ocultos).
- Command Center usa los **mismos pidfiles y puertos**: arrancar con un método y parar con el
  otro funciona igual. Fallback de CC en stop: dueño del puerto vía `netstat -ano` (~50 ms;
  antes PowerShell `Get-NetTCPConnection` ~3 s).
- Los `start.sh` nativos **no bloquean** (dashboard: ~5,5 s y retorna con URLs; antes delegaba
  en el launcher del stack y quedaba en foreground).
- Verificación final 2026-09-12 (con el código corregido): **9/9 apps `running` desde CC con
  PID real de cada proceso**, 9/9 UIs HTTP 200, 6/6 APIs de salud OK (`/api/health`,
  `/api/crm/health`, `/api/items` sirviendo datos migrados de la BD propia del CMS), binds
  `127.0.0.1` verificados por `netstat` (ya no existe ningún 0.0.0.0), ciclo nativo
  completo del dashboard (stop → start → health) y smoke de CC
  (`tests/smoke/command-center-smoke.mjs`) PASS.

> **Lección operativa del día**: un zombie del WS del dashboard (de pruebas previas) retenía el
> :8080 sin atender conexiones — `netstat` lo mostraba LISTENING y CC lo daba por vivo mientras
> el spawn real moría por `EADDRINUSE`. Ante un puerto "vivo pero sordo", identificar el PID
> (`Get-CimInstance Win32_Process`), verificar su fecha de creación y matar el árbol
> (`taskkill //F //T`). El reaper del stack clasifica estos huérfanos: `npm run process:hygiene`.

## Hallazgos y correcciones

### Críticos (resueltos)

1. **web-dashboard bindeaba 0.0.0.0** (WS y Vite) — violación ADR-0017. Ahora
   `listen(PORT, '127.0.0.1')` (`server/ws-hub/context.ts`) y `--host 127.0.0.1` en Vite.
2. **web-dashboard no era arrancable desde su directorio** (delegaba en `src/ops/dashboard-start.ts`
   de la raíz y bloqueaba en foreground). `start.sh`/`stop.sh` reescritos: self-contained, en
   background, pidfiles propios.
3. **content-cms usaba la BD del stack y código de otras apps** (importaba `DatabaseManager` y
   `ContentOSRepo` de web-dashboard, y `engine`/`provider-hub` de `src/` raíz). Desacoplado: BD
   propia + código vendido a la app (ver abajo).
4. **prompt-studio guardaba su BD fuera de la app** (`.runtime/prompt-studio/` de la raíz).
   Migrada a `apps/prompt-studio/.runtime/` con resolución desde `import.meta.url`.
5. **academy-crm y academy-landing sin ciclo de vida nativo** — creados `start.sh`/`stop.sh` y
   registradas en CC (landing es alta nueva; crm ya estaba pero solo via CC).
6. **CTAs de academy-web perdían eventos**: `app.js` posteaba a :4790 (API vieja del CRM); el CRM
   escucha en :4792. Reapuntado.

### Menores (resueltos)

- `start-dashboard.bat` eliminado (roto: apuntaba a scripts movidos; violaba NORM-TS-001).
- `command-center`: `AppId` no incluía `academy-crm` (error de tipos latente) → añadidos
  `academy-crm` y `academy-landing`; import de `getFreePort` desde `src/` raíz → inlineado
  (CC sin dependencias de código del stack); serving de CSS de marca con fallback 404;
  test del registry actualizado (6→9 apps); README reescrito (tabla de 9 apps/puertos, tests
  correctos).
- `package.json` raíz: `cc:server` apuntaba a ruta inexistente → corregido;
  `dashboard:server` usaba `npx tsx` → `node --import tsx`.
- `portOwner` de CC migrado de PowerShell a `netstat -ano` (stop ~3 s → ~50 ms).
- gv-analytics: script `intelligence:analyze` roto (archivo inexistente) corregido; `llm.ts`
  ahora degrada gracefully si el delegador del stack no existe; README actualizado (BD
  app-local); suite de tests mínima nueva.
- archify y academy-crm: `better-sqlite3` y `tsx` declarados en su `package.json` (antes
  resueltos por hoisting del monorepo — rompía standalone).
- academy-web: basura eliminada (`5000`, `scripts/_tmp-pro3-manifests.mjs`); ruta hardcodeada
  en `capture-v4.mjs` parametrizada; README con ciclo de vida y tests.
- design-hub: pidfile anclado al directorio de la app (antes dependía del cwd);
  `scripts/start.js` portable; README actualizado.
- prompt-studio: `package-lock.json` (artefacto npm en workspace pnpm) eliminado;
  `vite.config.ts` con `host 127.0.0.1` + `strictPort`.
- content-cms: `vite.config.ts` fijado a `5175/strictPort/127.0.0.1` (antes caía al 5173 por
  defecto y colisionaba con el dashboard).

## Decisiones de arquitectura

1. **BD del web-dashboard**: la app vendors la capa Nexus (manager + 16 repositorios +
   metrics-writer) dentro de `apps/web-dashboard/server/database/`. Por defecto apunta a la BD
   del stack si existe (su función es observarla) con fallback a BD propia en
   `apps/web-dashboard/.runtime/`; overridable por env (`GENTLE_VANGUARD_DB_DIR/FILE`). Código
   100% autónomo; la fuente de datos es un adaptador configurable.
2. **academy-landing en CC**: es una app más del ciclo de vida local (estática :4174). Su deploy
   real es GitHub Pages (`.github/workflows/deploy-landing.yml`); el generador vive en
   `apps/academy-web/scripts/build-landing.mjs` (acople de build documentado).
3. **Sync cross-app con degradación**: academy-landing (leads→localStorage), academy-web
   (trackCrmEvent fire-and-forget), academy-crm (lectura JSONL de leads con `existsSync`)
   degradan silenciosamente sin el stack — el requisito de autonomía no rompe las integraciones.
4. **workspace deps (`@gentle-vanguard/*`)**: gv-analytics usa `@gentle-vanguard/design-system`
   (`workspace:*`). Para comercializar: bundle con el paquete (publicable) o snapshot de CSS ya
   compilado — documentado en su README.

## Backlog de mejoras

Cerrado en la misma sesión (ronda 2):

- ✅ Tests para prompt-studio (7/7, HTTP-level con BD tmp) y academy-crm (15/15: repo-level
  cascade/transitions + HTTP-level; override `CRM_DB_PATH` añadido a `server/db.ts`).
- ✅ Lint gv-analytics: 28 errores → 0 (imports/vars muertos, stubs `_param`; sin cambios de
  comportamiento; lint+typecheck+test+build en verde).

Vigente (no bloqueante):

- Extraer `content-operations` a `packages/*` si vuelve a compartirse entre apps.
- Unificar `server.log`/logs sueltos en `.runtime/` por app.
- i18n/branding audit final antes de empaquetado comercial (ver docs/brand/BRAND-KIT.md).

## Integración nueva: watchtower ↔ Command Center

- Nuevo componente **`apps-registry`** en el watchtower
  (`src/core/watchtower/checks-apps.ts`): vigila las 9 apps vía `GET /api/apps` de CC —
  presencia en el registro, contratos `start.sh`/`stop.sh` por app, y coherencia de estado
  (puerto vivo sin pid conocido → WARN, el patrón del zombie de esta sesión). Totales del
  watchtower: **154 checks / 29 componentes**; apps-registry 28/28 PASS.
- Nuevo comando ZCode **`/apps`** (`.zcode/commands/apps.md`): estado y ciclo de vida de las
  9 apps desde el chat (start/stop/logs vía CC).

## Ronda 3 — seguridad de dependencias cerrada

- **vitest 3 → 4.1.11** (absorción de la rama dependabot
  `security/dependency-updates-vite-vitest-sharp`, cherry-pick 258f3608): **222 tests en verde**
  en las 8 suites (root 6, dashboard 104, cms 62, archify 19, crm 15, prompts 7, CC 6,
  analytics 3).
- `pnpm audit`: **0 vulnerabilidades** — allowlist de GHSA-82fw-gwwq-j7x9 eliminada del
  prepush gate. hono ya estaba en 4.13.5.
- Los `package.json` de content-cms/web-dashboard ya declaraban `vitest ^4.1.11`; el resto de
  apps resuelve hoisted desde el root.
- Recuperación operativa: 4 archivos de apps que solo vivían en disco (package.json de
  cms/analytics/dashboard + vite.config del dashboard) fueron re-trackeados en el repo anidado
  con sus versiones reales — ya no pueden perderse en un `git rm` del root.

## Decisión academy-landing (2026-09-13)

El usuario cuestionó su origen: **se creó el 2026-09-10** como pieza pública del funnel
comercial de Academy pedido en esa sesión (landing → leads → dashboard → CRM; engram
#3850/#3862/#3864). Decisión: **MANTENER**. Hallazgos y acciones:

- El deploy a GitHub Pages **nunca se activó** (Pages sin configurar en el repo, API 404) y el
  workflow `deploy-landing.yml` estaba sin commitear → **commiteado** en esta ronda.
- Para activarla de verdad: **Settings → Pages → Source: GitHub Actions** (1 click) y push a
  main con cambios en `apps/academy-landing/**`. URL resultante:
  `https://<owner>.github.io/<repo>/academy-landing/`.
- La landing es estática, stateless y auto-generada (`apps/academy-web/scripts/build-landing.mjs`
  desde el catálogo); costo de mantenimiento cero.
- **Conversión self-contained (2026-09-13)**: la landing ya no depende del stack para convertir —
  botones "Me interesa"/"Solicitar" marcan el producto, el form registra el lead (localStorage +
  sync best-effort) y abre WhatsApp (`wa.me/message/YHVWXB5AZR4EJ1`) con el mensaje compuesto
  copiado al portapapeles (los links `wa.me/message/` no aceptan prefill; si se configura
  `whatsappPhone` el prefill es directo). Botón de email (mailto) listo, se activa configurando
  un email real en `CONTACT` (hoy: placeholder `.local` sin usar). Verificado end-to-end en
  browser: interés → form → registro → WhatsApp con mensaje completo.
- **Landing trackeada en el ROOT repo** (`.gitignore`: `/apps/*` + `!/apps/academy-landing/`) —
  el workflow de Pages la deploya desde aquí. GOTCHA: con `core.untrackedCache=true`, un
  directorio con cero entradas en el index puede quedar invisible para `git add`/`git status`
  hasta sembrar una entrada (p. ej. `git update-index --cacheinfo`).

## Fuentes

- Auditoría paralela de 3 agentes (grupos A/B/C) sobre apps/, `rules/` y CC — 2026-09-12.
- Tests en vivo: ciclo de vida CC + nativo por app; `npx vitest run` (CC 6/6, cms 7 suites,
  archify 4 suites + engine, dashboard); smoke CC; watchtower `npm run watchtower:health`.
