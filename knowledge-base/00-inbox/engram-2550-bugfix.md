---
created: 2026-08-05 18:58:39
tags: [engram, bugfix]
engram_id: 2550
type: bugfix
---

# Solución Definitiva Dashboard Health Check

**What**: Creado `src/dashboard-health-checker.ts` - Sistema de health check robusto de 3 niveles para el dashboard.

**Why**: El health check anterior fallaba porque:
- Solo hacía tcp socket check (socket crudo)
- WebSocket server necesita HTTP upgrade handshake
- Socket TCP simple ≠ conexión WebSocket válida
- Resultado: false positives (puerto "abierto" pero server no funcional)

**Where**:
- Nuevo: `src/dashboard-health-checker.ts` - Core de health checking
- Modificado: `src/core/health-check.ts` - Usa nuevo checker

**Solución de 3 Niveles**:
1. **Level 1**: HTTP GET /api/health → JSON expected
2. **Level 2**: HTTP GET /api/metrics → JSON expected
3. **Level 3**: TCP socket (fallback legacy)

**Estados**:
- HEALTHY: Level 1 o Level 2 pasan (API HTTP responde)
- DEGRADED: Solo Level 3 pasa (TCP abierto pero HTTP no responde)
- DOWN: Ninguno pasa

**API**:
- `checkDashboardHealth(wsPort, vitePort)` → Full result
- `isDashboardHealthy()` → boolean
- `checkDashboardHealthWithRetry(retries, delay)` → Con retry

**CLI**:

```bash
npx tsx src/dashboard-health-checker.ts
```

**Resultado**: El health check ahora distingue entre "puerto abierto" y "servidor realmente funcionando".

---
*Imported from Engram on 2026-09-06*
