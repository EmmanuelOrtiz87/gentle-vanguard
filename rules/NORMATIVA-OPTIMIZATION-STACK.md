# NORMATIVA: STACK DE OPTIMIZACIÓN DE TOKENS Y COSTOS

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Garantizar que todas las optimizaciones de tokens y costos de API se mantengan activas,
verificables y nunca se degraden por cambios no controlados.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **Compresión de system prompt activa** — CLAUDE.md no debe exceder 65 líneas. Se verifica en health-check. | CI/CD reject si supera 70 líneas |
| 2 | **Response cache operativo** — `pre-process-input.ps1` debe tener SHA256 cache activo con TTL ≤ 30min. Cache no puede ser deshabilitado permanentemente. | Health check failure si cache ausente |
| 3 | **Modelo en producción siempre óptimo** — `opencode.json` debe usar modelos económicos para agentes rutinarios y modelos premium solo para fases críticas (SDD-design, SDD-verify). | Audit trimestral de costos |
| 4 | **Pre-task compression activa** — `pre-task-compress.ps1` debe ejecutarse antes de delegar a subagentes. Ratio de compresión mínimo 25%. | CI check falla si ratio < 20% |
| 5 | **Token tracking funcional** — `token-usage.json` debe actualizarse cada turno. Reporte disponible vía `token-usage-notifier.ps1`. | Session-end audit detecta ausencia |
| 6 | **Pre-compact hook configurado** — `pre-compact-hook.ps1` debe leer métricas reales de `token-usage.json`, no usar valores hardcoded. | Review obligatorio en PRs |
| 7 | **Notificaciones de tokens activas** — `token-display-config.json` debe tener notificaciones habilitadas para el agente. | Health check failure |
| 8 | **Cache no persistente se limpia** — `.session/preprocess-response-cache.json` no debe exceder 5MB. Limpieza automática semanal. | Cleanup hook |

## Verificación Automatizada

Ejecutar `scripts/validation/verify-optimization-stack.ps1` para validar las 8 reglas.
Este script forma parte del health-check general y del CI pipeline.

## Excepciones

Solo se permite deshabilitar temporalmente una optimización con aprobación documentada y
re-activación programada (máximo 24h). Toda excepción debe registrarse en `.exceptions/`.

## Referencias

- `CLAUDE.md` — system prompt principal
- `scripts/utilities/pre-process-input.ps1` — response cache SHA256
- `scripts/hooks/pre-task-compress.ps1` — compresión de subagentes
- `scripts/utilities/PERFORMANCE-OPTIMIZATION/pre-compact-hook.ps1` — compactación automática
- `opencode.json` — configuración de modelos y cache
- `.session/token-usage.json` — tracking de tokens
- `.session/preprocess-response-cache.json` — cache de respuestas
- `scripts/validation/verify-optimization-stack.ps1` — verificador automatizado
