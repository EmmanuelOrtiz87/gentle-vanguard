---
name: apps
description: Estado y ciclo de vida de las 9 apps del stack vía Command Center
---

Gestiona las apps del stack (dashboard, analytics, cms, academy, prompts, archify, design-hub,
academy-crm, academy-landing) a través del Command Center (:8090):

- Estado: `curl -s http://127.0.0.1:8090/api/apps` — lista id, status (running/stopped/partial)
  y PID+puerto por proceso.
- Arrancar/parar: `curl -s -X POST http://127.0.0.1:8090/api/apps/:id/start` (o `/stop`) —
  idempotentes. Ids válidos: los del registro.
- Logs de un proceso: `curl -s "http://127.0.0.1:8090/api/apps/:id/logs?process=<name>&lines=50"`.
- Alternativa nativa por app: `bash apps/<app>/start.sh|stop.sh` (mismos pidfiles).
- Si CC no responde: `bash apps/command-center/start.sh`.

Al reportar al usuario: tabla app → status → URL, y señala cualquier `partial` (mirar sus logs
con el endpoint de logs antes de reiniciar).
