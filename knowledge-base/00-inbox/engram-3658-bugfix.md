---
created: 2026-09-04 00:12:29
tags: [engram, bugfix]
engram_id: 3658
type: bugfix
---

# GV Analytics LLM - CORS es el bloqueador principal

**What**: El problema de "No se pudo detectar configuración del stack" en el panel LLM de GV Analytics es causado por CORS, no por el código del frontend ni del backend.

**Why**: El frontend Vite corre en puerto 5173 y hace fetch a `127.0.0.1:4754` (backend). El navegador bloquea la request cross-origin porque el backend NO tiene headers `Access-Control-Allow-Origin` configurados.

**Where**: `apps/gv-analytics/server/index.ts` - en la función `routeApi` (línea ~355) o en el `createServer` handler. Se debe agregar:
- `Access-Control-Allow-Origin: *` (o el origen del frontend)
- `Access-Control-Allow-Methods: GET, POST, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`
- Manejar preflight OPTIONS requests

**Learned**:
- El endpoint `/api/llm/detect` funciona perfectamente via curl desde consola (devuelve `{"configured":true,"provider":"custom","model":"claude-sonnet-4"}`)
- El build del frontend SÍ contiene el código LLM (verificado en `dist/assets/index-CWas-HXW.js`)
- El problema NO es el código, es la política de mismo origen del navegador
- El servidor backend está corriendo en PID 17232 en puerto 4754

---
*Imported from Engram on 2026-09-06*
