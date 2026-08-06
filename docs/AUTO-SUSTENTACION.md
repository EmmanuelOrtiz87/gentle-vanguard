# Sistema de Auto-Sustentación - Gentle-Vanguard

## Visión General

El stack Gentle-Vanguard implementa un sistema completo de **auto-sustentación** que permite al
ecosistema:

1. **Auto-detectar** problemas mediante health checks continuos
2. **Auto-corrigir** fallos mediante mecanismos de auto-healing
3. **Auto-verificar** la efectividad de correcciones mediante mutation testing
4. **Auto-documentar** el estado y aprender de patrones

## Componentes de Auto-Sustentación

### 1. 🔍 Health Check System (Watchtower)

**Ubicación**: `src/core/maintenance-watchtower.ts`

**Funcionamiento**:

- Verifica 86+ puntos de control en 17 componentes
- Ejecuta en modo `health`, `autoheal`, `rebuild`, `continuous`
- Reporta PASS/WARN/FAIL/SKIP con acciones recomendadas

**Modos de operación**:

```bash
# Verificación única
npm run watchtower:health
# o
npx tsx src/core/maintenance-watchtower.ts --action health

# Auto-healing de fallos detectados
npx tsx src/core/maintenance-watchtower.ts --action autoheal

# Reconstrucción completa de índices
npx tsx src/core/maintenance-watchtower.ts --action rebuild

# Monitoreo continuo (cada 60s)
npx tsx src/core/maintenance-watchtower.ts --action continuous --interval 60
```

**Componentes monitoreados**:

- Dashboard WS (puerto 8080)
- CodeGraph MCP Server (puerto 3000)
- ML Embeddings
- Engram MCP
- MCP Bridge
- Session Management
- Git Hooks
- Configs JSON
- Security Policies
- Cloud Connectors
- Tracing
- State Persistence
- Audit Pipeline
- Governance Rules
- Nexus DB
- Model Provider Health

### 2. 🏥 Auto-Heal System

**Mecanismo**:

Cuando watchtower detecta un FAIL, ejecuta la fase `autoHeal()` que:

1. **Filtra componentes que necesitan restart** (acción 'restart' o 'rebuild')
2. **Aplica correcciones específicas**:
   - Dashboard WS: Reinicia vía `dashboard-ws-autostart.ts`
   - CodeGraph MCP: Ejecuta `npx codegraph serve --mcp`
   - ML Embeddings: Reconstruye índices
   - Engram: Reindexa RAG
3. **Verifica resultado** (espera 4-10 segundos y re-chequea)
4. **Reporta resultado** (PASS con PID nuevo o FAIL marcado como crítico)

**Correcciones implementadas**:

| Componente      | Fallo Detectado      | Acción Auto-Heal                                 |
| --------------- | -------------------- | ------------------------------------------------ |
| `dashboard-ws`  | HTTP API no responde | Reinicia `npx tsx src/dashboard-ws-autostart.ts` |
| `dashboard-ws`  | Watchdog caído       | Reinicia vía wrapper con `shell: true`           |
| `codegraph`     | Server process FAIL  | Ejecuta `npx codegraph serve --mcp`              |
| `ml-embeddings` | Index stale (>48h)   | Reconstruye embeddings                           |
| `engram`        | Reindex stale (>72h) | Reindexa RAG                                     |

### 3. 🧪 Mutation Testing System

**Ubicación**: `src/engram-judgment-mutation-test.ts`

**Propósito**:

- Validar robustez de juicios de memoria
- Detectar juicios "frágiles" que cambian ante pequeñas mutaciones
- Garantizar consistencia de veredictos en Engram

**Mutaciones aplicadas**:

- `content_truncate`: Remueve último 10% del contenido
- `content_noise`: Sinonimiza términos técnicos comunes
- `timestamp_shift`: Desplaza timestamps +1 día
- `scope_reduction`: Elimina secciones secundarias
- `path_generalization`: Generaliza paths a wildcards

**Criterios de estabilidad**:

- **Stable**: ≥80% de mutaciones mantienen el mismo veredicto
- **Unstable**: 50-79% mantienen el veredicto
- **Fragile**: <50% mantienen el veredicto (requiere re-validación)

**Uso**:

```bash
# Validar un juicio específico
npx tsx src/engram-judgment-mutation-test.ts --judgment-id=<id>

# Validar todos los juicios recientes
npx tsx src/engram-judgment-mutation-test.ts --validate-all
```

### 4. ♻️ Auto-Correction Rules Engine

**Ubicación**: `src/correction-rules-engine.ts`

**Funcionamiento**:

- Escucha eventos de sesión (calidad baja, errores, timeouts)
- Aplica reglas de corrección automática
- Registra acciones tomadas para aprendizaje

**Reglas activas**:

- Token budget excedido → Comprimir contexto activamente
- Timeout en subagente → Incrementar límites adaptativos
- Quality score < 70% → Activar modo depuración extendido
- Errores consecutivos → Escalar a modo manual

### 5. 🧠 Self-Reflection Loop

**Ubicación**: `src/self-reflection-loop.ts`

**Ciclo**:

1. Analiza patrones de sesiones previas
2. Identifica tendencias (mejora/degradación)
3. Genera insights automáticos
4. Propone mejoras al stack

**Activación**:

- Después de cada cierre de sesión (`--reason autostart-close`)
- Mediante `npx tsx src/self-reflection-loop.ts --generate`

### 6. 🔧 Auto-Apply Safe

**Ubicación**: `src/auto-apply-safe.ts`

**Alcance**:

- Aplica optimizaciones seguras identificadas por self-reflection
- Requiere aprobación para cambios de configuración sensibles
- Rollback automático si se detectan regresiones

## Pipeline de Auto-Sustentación

```
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION START                                │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              Watchtower Health Check                            │
│         (detection de FAILs tempranos)                          │
└──────────────────┬──────────────────────────────────────────────┘
                   │
           Sí hay FAILs
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              Auto-Heal Phase                                    │
│    (reinicio de servicios caídos)                              │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              Session Operations                                 │
│           (trabajo del usuario)                                 │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              Session Close                                      │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│         Validation Report (67-100 score)                        │
└──────────────────┬──────────────────────────────────────────────┘
                   │
           Score < 100
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│         Correction Rules Engine                                 │
│    (auto-corrección de gaps)                                    │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│         Self-Reflection Loop                                    │
│    (análisis y aprendizaje)                                     │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│         Auto-Apply Safe                                         │
│    (implementar mejoras seguras)                                │
└─────────────────────────────────────────────────────────────────┘
```

## Capacidades por Componente

| Componente      | Auto-Detect | Auto-Heal     | Mutation Test | Auto-Learn |
| --------------- | ----------- | ------------- | ------------- | ---------- |
| Dashboard WS    | ✅          | ✅            | N/A           | ✅         |
| CodeGraph MCP   | ✅          | ✅            | N/A           | ✅         |
| Engram          | ✅          | ✅ (reindex)  | ✅            | ✅         |
| Token Budget    | ✅          | ✅ (compress) | N/A           | ✅         |
| Session Scoring | ✅          | ✅            | N/A           | ✅         |
| ML Embeddings   | ✅          | ✅            | N/A           | ✅         |
| Nexus DB        | ✅          | ✅ (backup)   | N/A           | ✅         |

## Limitaciones Conocidas

1. **Auto-Heal no cubre**:
   - Fallos de red externa (fuera del control del stack)
   - Errores de permisos del sistema operativo
   - Conflictos de integridad de base de datos (requiere intervención manual)

2. **Mutation Testing requiere**:
   - Juicios existentes en Engram
   - Acceso a MCP server de Engram
   - Recursos de LLM para simular veredictos

3. **Auto-Learning**:
   - Requiere múltiples sesiones para detectar patrones
   - No aplica patrones sin validación humana (stage #8 trust layer)

## Normativas Relacionadas

- `rules/SELF-HEALING-CI.md` - Políticas de auto-corrección
- `rules/NORMATIVAS-AUTONOMOUS-EVOLUTION.md` - Evolución autónoma del stack
- `rules/NORMATIVAS-ENFORCEMENT.md` - Aplicación automática de normas

## Métricas de Efectividad

Las siguientes métricas rastrean la efectividad del sistema:

- **Auto-heal success rate**: % de FAILs sanados automáticamente
- **Mean time to recovery (MTTR)**: Tiempo promedio de detección a corrección
- **Mutation stability**: % de juicios estables ante mutaciones
- **False positive rate**: % de auto-correcciones innecesarias

Estas métricas se reportan en:

- `.session/auto-heal-state.json`
- Panel del Dashboard (sección "System Health")
- Logs de auditoría (`audit-pipeline`)

---

**Documento generado automáticamente por el sistema de auto-sustentación.** **Última
actualización**: 2026-08-06 **Versión**: 1.0.0
