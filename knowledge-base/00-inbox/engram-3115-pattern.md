---
created: 2026-08-25 09:47:54
tags: [engram, pattern]
engram_id: 3115
type: pattern
---

# Tenant-scoped LRU cache for dashboard hot paths

**What**: Creado cache LRU por tenant nativo en apps/web-dashboard/server/cache/tenant-lru-cache.ts y conectado a las 4 funciones hot de real-data.ts. Estrategia: TTL corto (3s default < intervalo push WS de 5s) — cada push calcula datos frescos mientras ráfagas REST concurrentes comparten una sola computación síncrona de SQLite.

**Why**: El plan P1 pedía perfilar lecturas síncronas de real-data.ts/websocket-server.ts y añadir cache LRU por tenant con invalidación por evento.

**Where**: apps/web-dashboard/server/cache/tenant-lru-cache.ts (nuevo), apps/web-dashboard/server/real-data.ts (4 wrappers), docs/plans/NEXT-SESSION-PLAN-2026-08-25.md

**Learned**: API: getOrLoad(name, tenantId, loader, {ttlMs, maxEntries, params}), invalidate(name?, tenantId?), getLruStats(). Clave compuesta tenantId:params-hash; LRU touch re-inserta al final del Map. Funciones cableadas: getTenantScopedMetrics (tenant-metrics, 3s), getSkillUsageFromDb (skill-usage, 4s), getTokenUsageFromDb (token-usage, 4s), getRoutingRulesFromDb (routing-rules, 5s). Patrón wrapper: función exportada (cache) separada de función interna compute*(lógica pura). GOTCHA TS strict: propagar tenantId explícitamente a los compute* internos; declarar params?: unknown[] en la interfaz de opciones (acceso con corchetes no pasa strict). Verificación: dashboard build verde (23.3s), root typecheck+lint verdes.

---
*Imported from Engram on 2026-09-06*
