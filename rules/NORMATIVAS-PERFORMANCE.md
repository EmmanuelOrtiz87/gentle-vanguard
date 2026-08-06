# Normativas de Rendimiento

Versión: 1.0.0 | Actualización: 2026-08-04

## 🎯 Objetivos de Rendimiento

### Latencia
- **Percepción instantánea**: < 100ms para respuestas
- **Feedback rápido**: < 500ms para operaciones de tools
- **Operaciones pesadas**: < 2s con indicador de progreso

### Throughput
- **Procesamiento paralelo**: hasta 5 subagentes concurrentes
- **Batch processing**: grupos de 5 para lazy steps
- **Rate limiting**: respetar cooldowns de proveedores externos

### Eficiencia de Recursos
- **Token budget**: 60,000 diarios / 15,000 por sesión
- **Uso memory**: liberar recursos con `lazy: true` pattern
- **Procesos**: cleanup automático de huérfanos cada 24h

## ⚙️ Políticas de Optimización

### 1. Context Engineering
```typescript
// Prioridad: Explícito > Implícito > Inferido
1. User message (explícito)
2. Session artifacts (.session/context-log/)
3. Engram memory (persistente)
4. CodeGraph index (codebase structure)
```

### 2. Truncamiento Inteligente
- Output limitado a 50 líneas por defecto
- Code blocks: solo líneas relevantes
- Respuestas comprimidas con profile `ultra`

### 3. Lazy Execution
```json
{
  "lazy": true,
  "onStepFailure": "continue",
  "maxConcurrent": 5
}
```

### 4. Checkpoint Management
- Autocheckpoints cada 15 minutos de actividad
- Snapshot manual en puntos de inflexión
- Rollback: restaurar desde checkpoint válido

## 📊 Métricas y Alertas

### Quality Gates
| Gripe | Threshold | Aaction |
|-------|-----------|---------|
| Token usage | > 70% soft, > 90% hard | Switch a `chat-compact` |
| Session time | > 4h | Prompt checkpoint |
| Memory growth | > 500MB | Auto-prune caches |
| Error rate | > 5% | Auto-diagnosis |

### Performance SLOs
- **P95 latency**: < 200ms (tool calls)
- **P99 latency**: < 500ms (subagent dispatch)
- **Availability**: 99.5% uptime esperado
- **MTTR**: < 5 minutos para auto-healing

## 🔧 Herramientas de Optimización

### Scripts Nativos
- `npx tsx src/semantic-search.ts` → Busqueda semántica (vs grep)
- `npx tsx src/session-cleanup-start.ts` → Flush caches
- `npx tsx src/workload-guard.ts` → Pre-validación de carga
- `npx tsx src/token-optimization-orchestrator.ts` → Compresión

### Configuración
- `config/token-budget-guard.json` → Presupuesto y thresholds
- `config/session-autostart.config.json` → Lazy step scheduling
- `.opencode/response-profile.json` → Perfil compresión

## 📜 Reglas Obligatorias

1. **Nunca** ejecutar 3+ pasos idénticos sin verificación de progreso
2. **Siempre** usar `lazy: true` para steps no críticos
3. **Después** de cada tool call, verificar si se necesita `mem_save`
4. **Antes** de cargar archivos grandes, usar `head`/`Select-Object -First`
5. **Siempre** preferir CodeGraph antes que búsqueda de texto plano

## 🎯 Benchmarks Target

```
Session Autostart: < 10s (00 PASS)
Health Check: < 2s
Engram Search: < 500ms
CodeGraph Query: < 1s
Subagent Dispatch: < 200ms
```

## 📢 Escalado

Si performance < 80%:
1. Ejecutar `npx tsx src/self-diagnosis.ts --profile performance`
2. Revisar `.session/metrics-report.json`
3. Considerar `npx tsx src/session-compact.ts` para limpieza
4. Escalar a orchestrator si degradación persiste

---
Última actualización: 2026-08-04 | Owner: GOV
