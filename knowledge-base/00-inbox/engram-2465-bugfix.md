---
created: 2026-08-02 04:29:19
tags: [engram, bugfix]
engram_id: 2465
type: bugfix
---

# Fix definitivo dashboard-ws: 5 causas raíz de falso negativo recurrente

**What**: Resuelto de raíz el problema recurrente del dashboard-ws que reportaba 3 FAILs en cada sesión aunque el WS estuviera vivo. Se corrigieron 4 archivos:
1. `src/dashboard-common.ts` — isProcessAlive() parseaba mal en Windows: tasklist /FI retorna exit code 0 SIEMPRE (incluso para PIDs inexistentes). Ahora parsea la salida CSV buscando `"<pid>"`. Antes alive(999999)=true, ahora false.
2. `src/dashboard-ws-autostart.ts` — el PID file registraba el PID del wrapper cmd.exe, no del node real. Ahora tras health check resuelve el PID real con getProcessIdByPort() y lo escribe. El bucle de health ya no aborta cuando muere el wrapper (el node real es descendiente y sigue vivo), espera hasta 20s.
3. `src/core/maintenance-watchtower.ts` — el check 'WS server process' marcaba FAIL por PID stale aunque HTTP respondiera 200. Ahora HTTP = fuente de verdad: si responde, PASS + auto-cura el PID file con el PID real. Nuevo helper getPidByPort() (netstat/lsof).
4. `src/dashboard-ws-service.ts` — spawn('npx.cmd',...) fallaba con spawn EINVAL en login Windows. Cambiado a cmd.exe /c set WS_PORT=... && tsx.cmd.

**Why**: Cada inicio de sesión la watchtower marcaba 3 FAILs de dashboard-ws, forzando re-trabajo manual y gasto de tokens. El WS real siempre estaba vivo pero los PID files apuntaban a procesos muertos.

**Where**: src/dashboard-common.ts, src/dashboard-ws-autostart.ts, src/core/maintenance-watchtower.ts, src/dashboard-ws-service.ts

**Learned**:
- tasklist /FI en Windows NO es fiable para comprobar existencia de proceso (exit code 0 siempre) — parsear output CSV.
- En Windows, al spawnear .cmd vía child_process, el child.pid es el PID del cmd.exe wrapper, no del proceso node hijo. Resolver el PID real por puerto (netstat) es la única forma fiable.
- La watchtower debe usar HTTP como fuente de verdad para el dashboard, no archivos PID (que pueden estar stale).
- Resultado final: 82/82 PASS, 0 WARN, 0 FAIL. El autostart ahora hace [SKIP] limpio cuando WS ya corre.

---
*Imported from Engram on 2026-09-06*
