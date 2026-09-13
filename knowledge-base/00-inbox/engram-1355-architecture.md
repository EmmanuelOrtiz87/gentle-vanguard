---
created: 2026-06-08 00:35:14
tags: [engram, architecture]
engram_id: 1355
type: architecture
---

# consolidateMetrics escribe consolidated.json cada 30s

**What**: consolidateMetrics() reemplazó refreshTokenMetrics() en websocket-server.ts. Cada 30s LEE token.json, skill-stats.json, live.json, sessions.json + calcula OS metrics frescos (CPU, RAM, uptime), MERGE todo en un objeto, y ESCRIBE consolidated.json con writeFileSync.

**Why**: El dashboard leía consolidated.json cada 5s pero nadie lo escribía — los números nunca cambiaban. Ahora el propio servidor del dashboard genera el archivo consolidado con datos frescos cada 30s.

**Where**: apps/web-dashboard/server/websocket-server.ts — consolidateMetrics() (reemplazó refreshTokenMetrics()), intervalo 30000ms

**Learned**: El contador _consolidationCount (+1 cada ciclo) y el timestamp_consolidatedAt dan visibilidad inmediata de que la consolidación está activa. OS metrics (CPU, RAM, uptime) cambian en cada ciclo porque process.cpuUsage() y process.memoryUsage() son valores vivos del proceso Node.js.

---
*Imported from Engram on 2026-09-06*
