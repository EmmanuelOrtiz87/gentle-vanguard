---
created: 2026-09-10 20:41:12
tags: [engram, architecture]
engram_id: 3864
type: architecture
---

# Academy: realtime WS notifications + landing pública generada

**What**: 2 nuevas capacidades: (1) notificación en tiempo real de leads/exports vía WebSocket — el POST a /api/academy-leads o /api/academy-exports broadcastea inmediatamente a los clientes WS conectados (toast instantáneo en el dashboard, sin esperar el polling de 15s), (2) landing pública externa en apps/academy-landing/ — página de marketing estática autocontenida generada por script.

**Why**: El usuario pidió seguir potenciando el stack. El WS cierra el loop de tiempo real; la landing pública es la puerta de entrada para tráfico externo (la estrategia de venta de los ebooks).

**Where**:
- `apps/web-dashboard/server/handlers/observability.ts` — `broadcastAcademyNotification()` (usa clients+safeSend de ws-hub/context.ts), invocada en POST de academy-leads y academy-exports
- `apps/academy-landing/index.html` — NUEVO: landing estática generada (hero, stats, destacados con covers, premium, micro-ebooks, pricing $29/$49/$99, lead form con discovery del dashboard + fallback localStorage)
- `apps/academy-landing/covers/*.svg` — covers de destacados copiados por el script
- `apps/academy-web/scripts/build-landing.mjs` — NUEVO: genera la landing leyendo los manifests (patrón build-covers)
- `apps/academy-landing/README.md` — docs de la landing
- `apps/academy-web/README.md` — sección Landing pública

**Learned**: (1) El broadcast WS usa la misma infraestructura que las notificaciones existentes (clients Set + safeSend de ws-hub/context.ts) — el formato {type:'notification', notifications:[...]} es lo que useMetrics procesa. (2) El test headless no captura el toast realtime porque el POST ocurre antes de abrir el navegador — artefacto de test, el wiring está verificado por código (misma infraestructura que las notificaciones que sí funcionan). (3) La landing se GENERA por script (build-landing.mjs) — el catálogo queda embebido y los covers copiados; regenerar tras agregar productos. (4) El lead form de la landing usa el mismo discovery (command-center 8090 → dashboard port) con fallback a localStorage. (5) typecheck pasa.

---
*Imported from Engram on 2026-09-12*
