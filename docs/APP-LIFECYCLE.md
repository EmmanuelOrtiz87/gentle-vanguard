# App Lifecycle — scripts nativos start/stop

Cada app activa del monorepo tiene sus propios scripts bash (`start.sh` / `stop.sh`) en su carpeta,
utilizables directamente desde Git Bash sin depender del command-center:

```bash
bash apps/<app>/start.sh   # idempotente
bash apps/<app>/stop.sh    # idempotente (pidfile + fallback por puerto)
```

Los scripts detectan el project root (`../../` desde la app), escriben/leen pidfiles en
`.runtime/` (mismos nombres que usa command-center) y nunca abren ventanas cmd. Logs en
`.runtime/app-*.log`.

## Tabla de referencia

| App               | Puerto(s)            | start.sh                  | stop.sh                  | Alternativa npm (desde root)                                    | Pidfile(s) (.runtime/)                          |
| ----------------- | -------------------- | ------------------------- | ------------------------ | --------------------------------------------------------------- | ----------------------------------------------- |
| web-dashboard     | 5173 (Vite) + 8080 (WS, dinámico) | `apps/web-dashboard/start.sh` | `apps/web-dashboard/stop.sh` | `npx tsx src/ops/dashboard-start.ts` / `dashboard-stop.ts` | `dashboard-ws.pid`, `dashboard-vite.pid` (propios) |
| gv-analytics      | 4754 (API) + 5174 (Vite) | `apps/gv-analytics/start.sh` | `apps/gv-analytics/stop.sh` | `npm run` en la app: `dev` (bloqueante)                        | `app-analytics-api.pid`, `app-analytics-vite.pid` |
| content-cms       | 3787 (API) + 5175 (Vite) | `apps/content-cms/start.sh` | `apps/content-cms/stop.sh` | `npm run` en la app: `dev` (bloqueante)                        | `app-cms-api.pid`, `app-cms-vite.pid`             |
| academy-web       | 4173                 | `apps/academy-web/start.sh` | `apps/academy-web/stop.sh` | `python -m http.server 4173 -d apps/academy-web`               | `app-academy-http.pid`                            |
| prompt-studio     | 5177 (API) + 5176 (Vite) | `apps/prompt-studio/start.sh` | `apps/prompt-studio/stop.sh` | `npm run` en la app: `dev` (bloqueante)                        | `app-prompts-api.pid`, `app-prompts-vite.pid`     |
| archify           | 4790 (API) + 5179 (Vite) | `apps/archify/start.sh` | `apps/archify/stop.sh`     | `npm run` en la app: `dev` (bloqueante)                        | `app-archify-api.pid`, `app-archify-vite.pid`     |
| design-hub        | 8095                 | `apps/design-hub/start.sh` | `apps/design-hub/stop.sh`  | `node apps/design-hub/scripts/start.js` / `stop.js` (delega)   | `app-design-hub-http.pid` (propio)                |
| command-center    | 8090                 | `apps/command-center/start.sh` | `apps/command-center/stop.sh` | `npm run cc:start` / `npx tsx src/cli/gv.ts cc stop`       | `command-center.pid` (propio)                     |

## Notas

- **Delegación**: design-hub (scripts node propios), web-dashboard (`src/ops/dashboard-start.ts`
  / `dashboard-stop.ts`, que gestionan watchdogs) y command-center (`apps/command-center/start.ts`
  / `src/cli/gv.ts cc stop`) reutilizan los mecanismos existentes del monorepo en vez de
  duplicarlos.
- **Apps eliminadas** (gv-design-studio, gv-design-system-catalog): borradas del repo en la etapa 4
  del plan `docs/design/06-migration-plan-v2-premium.md` (reemplazadas por Design Hub).
- **Puerto dinámico del WS del dashboard**: ver `.runtime/dashboard-ports.json` (default 8080).
- **Fallback de stop**: si el pidfile no existe o el PID ya murió, `stop.sh` localiza el dueño del
  puerto vía `netstat -ano` y lo termina con `taskkill //F //T` (incluye hijos).
- Fix (2026-09-01): `GET /` directo contra el puerto 4754 del API de gv-analytics ya no crashea con
  `ERR_HTTP_HEADERS_SENT` (`serveStatic` escribía headers dos veces al faltar `dist/`).
  `apps/gv-analytics/server/index.ts` ahora lee el body antes de escribir headers y guarda el
  fallback con `res.headersSent`: sirve `dist/index.html` (200) o un 404 JSON limpio si falta el
  build, sin tumbar el proceso. La UI vía Vite :5174 sigue igual.
