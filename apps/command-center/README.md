# Command Center — Gentle-Vanguard

Panel de control **standalone** para el ciclo de vida de las apps construidas del stack:
**Dashboard, Analytics, Content CMS y Academy**. Completamente aparte del dashboard —
desde aquí se inicia, detiene y abre cada aplicación a demanda, en pantallas individuales.

## Acceso

```
http://127.0.0.1:8090/
```

| Modo | Comando |
| --- | --- |
| Interactivo (abre browser) | `npm run cc:start` |
| Solo server (foreground) | `npm run cc:server` |
| CLI | `npx tsx src/cli/gv.ts cc start\|stop\|status` |
| Automático | Lazy step `command-center` del session autostart (`--no-browser`) |

## Qué hace

- **Estado real por app**: badge `running` / `stopped` / `partial`, con PID y puerto de cada
  proceso (server + cliente). Polling cada 5 segundos.
- **⏻ Iniciar / Detener** por app — idempotente: si ya está corriendo no re-ejecuta nada;
  si está por partes (`partial`), solo arranca lo que falta.
- **↗ Abrir** — abre la app en una pestaña individual del navegador.
- **Gestiona también el Dashboard** (no hay self-managed: este panel es un proceso aparte).
  Al detener el dashboard mata primero sus **watchdogs** (ws/vite) para que no lo resuciten.

## Arquitectura

- `server.ts` — servidor HTTP puro de Node (**cero dependencias, cero build**).
  - `GET /api/health` → `{ok, app:'command-center'}`
  - `GET /api/apps` → estado real (pidfile + port probe)
  - `POST /api/apps/:id/start` / `POST /api/apps/:id/stop` → idempotentes
- `start.ts` — launcher: si ya hay un CC vivo solo abre el browser; si no, spawn oculto
  (`windowsHide` + `detached` + `stdio ignore`, regla procesos-ocultos) y espera health.
- `public/index.html` — UI autocontenida (vanilla JS + tokens de diseño GV inline).

### Detección de estado (fuente de verdad)

1. Pidfile propio `.runtime/app-<id>-<proceso>.pid` (escrito por este panel al arrancar).
2. Fallback a pidfiles legacy (`dashboard-ws.pid`, `dashboard-vite.pid`) escritos por los
   launchers del stack.
3. **Port probe** TCP — el puerto respondiendo es la prueba definitiva de vida.
4. En `stop()`, si no hay pidfile vivo, **fallback por dueño del puerto**
   (`Get-NetTCPConnection`) — mata procesos arrancados por cualquier launcher.

### Seguridad

- Bind exclusivo a `127.0.0.1` (loopback-only, ADR-0017 local-first).
- Sin auth en loopback (mismo perfil local-default que el dashboard); rechaza `Host`
  headers ajenos a `127.0.0.1` / `localhost` / `::1` (anti DNS-rebinding).
- La UI se sirve con `Cache-Control: no-store` y surfacea cualquier error JS en la grilla
  (nunca falla en silencio).

## Puertos

| App | Procesos | Puertos |
| --- | --- | --- |
| Dashboard | websocket-server + vite | 8080 (dinámico, `.runtime/dashboard-ports.json`) + 5173 |
| Analytics | API + vite | 4754 + 5174 |
| Content CMS | vite | 5175 |
| Academy | http.server estático | 4173 |
| **Command Center** | este server | **8090** (env `CC_PORT`, persistido en `.runtime/command-center-ports.json`) |

## Registro operativo

- Pidfile: `.runtime/command-center.pid` (limpiado en SIGTERM/SIGINT).
- Clase daemon registrada en `DAEMON_CLASSES` (`src/core/process-hygiene.ts`) — el reaper
  lo reconoce como healthy y no lo mata en los sweeps.
- No es tocado por el cierre de sesión (igual que el dashboard): persiste entre sesiones.

## Tests

```
node --import tsx --test tests/unit/command-center.test.ts   # unit
node tests/smoke/command-center-smoke.mjs                    # smoke end-to-end
```
