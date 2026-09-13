---
created: 2026-07-28 16:31:31
tags: [engram, architecture]
engram_id: 2176
type: architecture
---

# Arquitectura Dashboard Unificada - Implementación Completa

**What**: Implementada arquitectura unificada para conectar pipeline con dashboard
**Why**: El dashboard mostraba datos vacíos porque el pipeline guardaba en un formato/lugar y el dashboard esperaba en otro
**Where**:
- Nuevo módulo: src/core/session-context-log.ts (fuente de verdad única)
- Pipeline: src/session-cleanup-start.ts (guarda en context-log)
- Dashboard: apps/web-dashboard/server/database/metrics-writer.ts (lee de context-log)
**Arquitectura**:
- Sistema unificado: .session/context-log/<session-id>/.state.json
- Pipeline guarda → Dashboard lee (mismo formato)
- Módulo compartido: SessionContextLog (usado por ambos lados)
**Cambios realizados**:
1. Creado session-context-log.ts con API unificada
2. Actualizado session-cleanup-start.ts para guardar en context-log
3. Actualizado metrics-writer.ts para leer de SessionContextLog
4. Reemplazada lógica de tokens y sessions con sistema unificado
5. Typecheck: ✅ PASA (sin errores)
**Beneficios**:
- Single source of truth
- Formato estandarizado
- Escalable (ambos usan mismo módulo)
- Tipo-safe (TypeScript)
- Backward compatible (mantiene archivos viejos)
**Estado**: COMPLETADO - Listo para reiniciar y probar

---
*Imported from Engram on 2026-09-06*
