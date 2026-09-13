---
created: 2026-09-10 03:09:59
tags: [engram, architecture]
engram_id: 3842
type: architecture
---

# Academy→Stack: endpoint academy-exports + sync best-effort

**What**: Integración Academy → Stack: endpoint `/api/academy-exports` en el dashboard server + sync best-effort desde Academy. Las exportaciones de PDF de eBooks/Toolkits/Paquetes ahora se registran en `.runtime/academy-exports.jsonl` (JSONL append-only) con stats agregadas vía GET.

**Why**: El usuario pidió conectar Academy con el stack (Nexus/dashboard) para métricas agregadas multi-navegador de qué productos se exportan.

**Where**:
- `apps/web-dashboard/server/handlers/observability.ts` — endpoint POST (ingesta `{events:[{kind,id,title,ts}]}` → append a `.runtime/academy-exports.jsonl`) + GET (stats `{type:'academy-exports', total, top:[{kind,title,count}]}`). Imports: appendFileSync, mkdirSync, join, ROOT de shared.ts
- `apps/academy-web/app.js` — `syncExportsToStack()`: lee eventos pendientes (flag `synced:false`) de localStorage, descubre puerto del dashboard vía command-center (`http://127.0.0.1:8090/api/apps` → app dashboard → proceso server → port), POSTea, marca synced. `recordExport()` lo llama fire-and-forget

**Learned**: (1) El puerto del dashboard es dinámico — el command-center en 8090 (puerto estable) expone los puertos vía GET /api/apps (app dashboard → processes[].port). (2) El endpoint /api/feedback existente NO sirve (requiere traceId/spanId/type up/down) — se creó uno dedicado. (3) JSONL en .runtime es más seguro que tocar Nexus DB (sin cambios de schema). (4) GOTCHA: Chrome headless con --virtual-time-budget NO completa fetch reales (el sync no se pudo verificar headless; el endpoint se verificó con POST/GET directos). (5) typecheck + lint del dashboard pasan con el cambio.

---
*Imported from Engram on 2026-09-10*
