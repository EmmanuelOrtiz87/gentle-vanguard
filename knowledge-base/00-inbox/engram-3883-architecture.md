---
created: 2026-09-11 18:47:02
tags: [engram, architecture]
engram_id: 3883
type: architecture
---

# Dashboard deshabilitado del session autostart — apps on-demand

**What**: Dashboard deshabilitado del session autostart — ya no se inicia automáticamente al iniciar una sesión. Las 3 steps lazy (dashboard-ws-start, dashboard-ui-start, dashboard-operational-metrics) cambiadas a enabled:false. Todas las apps ahora son on-demand: solo corren cuando se inician explícitamente desde command-center.

**Why**: El usuario reportó que el dashboard estaba corriendo sin que nadie lo activara (estado "partial" en command-center). La causa era que el session-autostart.config.json tenía 3 steps lazy con enabled:true que iniciaban el dashboard automáticamente en cada sesión.

**Where**:
- `config/session-autostart.config.json` — dashboard-ws-start, dashboard-ui-start, dashboard-operational-metrics cambiados a enabled:false con descripción "DISABLED: Dashboard is on-demand only. Start manually from command-center."

**Learned**: (1) El session-autostart.config.json tiene 117 steps, de los cuales ~80 son lazy (se ejecutan en background). Los steps que inician apps (daemons) deben estar disabled para que las apps sean on-demand. (2) Los steps que inician apps son: dashboard-ws-start (8080), dashboard-ui-start (5173), dashboard-operational-metrics, command-center, codegraph-mcp-server-start, token-ingest-init. (3) El patrón correcto para apps comercializables: cada app solo corre cuando se inicia explícitamente desde command-center. El session autostart solo debe iniciar servicios internos del stack (DB, engram, codegraph), NO apps comercializables. (4) El proceso fantasma del dashboard (PID 27888 en puerto 8080) fue iniciado por el session autostart y matado manualmente.

---
*Imported from Engram on 2026-09-12*
