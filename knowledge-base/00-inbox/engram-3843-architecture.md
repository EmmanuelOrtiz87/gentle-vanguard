---
created: 2026-09-10 03:20:38
tags: [engram, architecture]
engram_id: 3843
type: architecture
---

# Academy→Stack sync VERIFICADO end-to-end

**What**: Integración Academy → Stack COMPLETA y VERIFICADA end-to-end. Las exportaciones de PDF se sincronizan desde el navegador al stack: Academy descubre el puerto del dashboard vía command-center (8090), POSTea a `/api/academy-exports`, y el dashboard server persiste en `.runtime/academy-exports.jsonl` con stats agregadas vía GET.

**Why**: El usuario pidió conectar Academy con el stack para métricas agregadas de qué productos se exportan (estrategia de venta).

**Where**:
- `apps/web-dashboard/server/handlers/observability.ts` — endpoint POST (ingesta `{events:[{kind,id,title,ts}]}` → append JSONL) + GET (stats `{type:'academy-exports', total, top:[{kind,title,count}]}`)
- `apps/web-dashboard/server/websocket-server.ts` — CORS ampliado con `http://127.0.0.1:4173,http://localhost:4173`; `/api/academy-exports` marcado público (sin auth, listener loopback-only)
- `apps/academy-web/app.js` — `syncExportsToStack()` (fetch command-center → descubrir port → POST → marcar synced), `recordExport()` lo llama fire-and-forget, `window.gvSyncExports` expuesto

**Learned**: (1) GOTCHA CRÍTICO: Chrome headless con `--virtual-time-budget` pequeño NO completa fetch reales — el sync fallaba con budget de 30s pero funcionó con 60000ms. El `--timeout` de Chrome tampoco espera timers async. Para verificar syncs de red en headless usar `--virtual-time-budget=60000`. (2) El dashboard server requiere CORS explícito (default solo 5173) y auth para endpoints no públicos — ambos se corrigieron para Academy. (3) El command-center en 8090 ya soporta CORS loopback (127.0.0.1, localhost, ::1) — no requirió cambios. (4) Verificación final: POST directo OK, sync desde navegador OK (evento con ts real en JSONL), GET stats OK. (5) typecheck + lint del dashboard pasan.

---
*Imported from Engram on 2026-09-10*
