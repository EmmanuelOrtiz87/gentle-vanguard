# Dispatch Memory Manager - Memoria Persistente para Dispatches

## Descripción General

El **Dispatch Memory Manager** es un módulo que resuelve el gap de "No hay memoria persistente entre dispatches" integrando Engram con el sistema de dispatch-agent para mantener contexto entre ejecuciones.

## Problema Identificado

Antes de esta implementación:
- Cada dispatch era aislado sin memoria del contexto anterior
- Los resultados de ejecuciones anteriores se perdían
- No había forma de recuperar información de dispatches previos
- El sistema no podía aprender o mejorar basándose en ejecuciones anteriores

## Solución Implementada

### Componentes

#### 1. **dispatch-memory-manager.ps1**
Módulo central que gestiona la persistencia de memoria de dispatch.

**Ubicación:** `scripts/utilities/WORKFLOW-ORCHESTRATION/dispatch-memory-manager.ps1`

**Funcionalidades:**
- `save`: Guarda el contexto de un dispatch
- `load`: Carga el contexto más reciente o uno específico
- `list`: Lista todos los dispatches de una sesión
- `clear`: Elimina contextos específicos o de toda una sesión
- `sync`: Sincroniza y reporta dispatches de una sesión

**Estructura de Almacenamiento:**
```
.engram-data/
├── dispatch-memory/
│   ├── dispatch-registry.json          # Índice de todos los dispatches
│   └── contexts/
│       ├── dispatch-20260423-120530.json
│       ├── dispatch-20260423-120545.json
│       └── ...
```

#### 2. **dispatch-agent.ps1 (Modificado)**
Integración del dispatch-agent con el memory manager.

**Cambios:**
- Carga contexto anterior antes de ejecutar
- Guarda contexto después de ejecutar
- Pasa contexto anterior a los agentes

**Flujo:**
```
1. Load-PreviousDispatchContext()
   ↓
2. Invoke-ParallelDispatch()
   ↓
3. Save-DispatchContext()
```

### Estructura de Datos

#### Contexto de Dispatch
```json
{
  "execution_id": "dispatch-20260423-120530",
  "session_id": "session-2026-04-23-22",
  "timestamp": "2026-04-23T12:05:30-03:00",
  "context": {
    "agents": ["DEV", "QA"],
    "task": "implement feature",
    "mode": "parallel",
    "risk": "medium",
    "previous_context": { ... },
    "results_summary": {
      "total": 2,
      "ready": 2,
      "failed": 0,
      "blocked": 0
    }
  },
  "status": "saved"
}
```

#### Registro de Dispatch
```json
{
  "dispatches": [
    {
      "execution_id": "dispatch-20260423-120530",
      "session_id": "session-2026-04-23-22",
      "timestamp": "2026-04-23T12:05:30-03:00",
      "status": "saved"
    }
  ],
  "last_updated": "2026-04-23T12:05:30-03:00"
}
```

## Uso

### Guardar Contexto
```powershell
& .\dispatch-memory-manager.ps1 -Action save `
  -ExecutionId "dispatch-20260423-120530" `
  -DispatchContext @{
    agents = @("DEV", "QA")
    task = "implement feature"
    mode = "parallel"
  } `
  -AsJson
```

### Cargar Contexto Anterior
```powershell
& .\dispatch-memory-manager.ps1 -Action load -AsJson
```

### Cargar Contexto Específico
```powershell
& .\dispatch-memory-manager.ps1 -Action load `
  -ExecutionId "dispatch-20260423-120530" `
  -AsJson
```

### Listar Dispatches de Sesión
```powershell
& .\dispatch-memory-manager.ps1 -Action list -AsJson
```

### Sincronizar Memoria
```powershell
& .\dispatch-memory-manager.ps1 -Action sync -AsJson
```

### Limpiar Contexto
```powershell
# Limpiar contexto específico
& .\dispatch-memory-manager.ps1 -Action clear `
  -ExecutionId "dispatch-20260423-120530"

# Limpiar toda la sesión
& .\dispatch-memory-manager.ps1 -Action clear `
  -SessionId "session-2026-04-23-22" `
  -Force
```

## Integración con dispatch-agent

El dispatch-agent ahora automáticamente:

1. **Carga contexto anterior** antes de ejecutar:
```powershell
$previousContext = Load-PreviousDispatchContext
```

2. **Construye contexto actual** con información relevante:
```powershell
$dispatchContext = @{
    agents = $agentList
    task = $Task
    mode = $Mode
    risk = $Risk
    previous_context = $previousContext
    results_summary = $result.summary
}
```

3. **Guarda contexto** después de ejecutar:
```powershell
Save-DispatchContext -ExecutionId $result.execution_id -Context $dispatchContext
```

## Beneficios

✅ **Continuidad**: Mantiene contexto entre dispatches  
✅ **Recuperabilidad**: Puede recuperar información de ejecuciones anteriores  
✅ **Trazabilidad**: Registro completo de todas las ejecuciones  
✅ **Aprendizaje**: Los agentes pueden acceder a contexto histórico  
✅ **Debugging**: Facilita diagnóstico de problemas en ejecuciones anteriores  
✅ **Optimización**: Permite mejorar basándose en resultados previos  

## Casos de Uso

### 1. Recuperación de Contexto
Si un dispatch falla, el siguiente puede recuperar el contexto anterior y continuar.

### 2. Análisis de Tendencias
Analizar patrones de éxito/fallo en múltiples ejecuciones.

### 3. Optimización Adaptativa
Ajustar parámetros (modo, riesgo) basándose en resultados históricos.

### 4. Auditoría y Compliance
Mantener registro completo de todas las operaciones de dispatch.

## Integración Futura con Engram

Esta implementación está diseñada para ser compatible con Engram:

1. Los datos se almacenan en `.engram-data/` (mismo directorio que Engram)
2. Estructura JSON compatible con Engram
3. Puede sincronizarse con Engram para análisis más profundo
4. Preparado para integración con búsqueda y análisis de Engram

## Configuración

### Variables de Entorno
- `WFS_SESSION_ID`: ID de sesión actual (se usa automáticamente)

### Rutas Configurables
Todas las rutas se derivan de `.engram-data/`:
- Directorio de memoria: `.engram-data/dispatch-memory/`
- Registro: `.engram-data/dispatch-memory/dispatch-registry.json`
- Contextos: `.engram-data/dispatch-memory/contexts/`

## Mantenimiento

### Limpiar Memoria Antigua
```powershell
# Limpiar dispatches de sesión anterior
& .\dispatch-memory-manager.ps1 -Action clear `
  -SessionId "session-2026-04-22-XX" `
  -Force
```

### Monitorear Uso de Espacio
```powershell
# Ver tamaño de directorio de memoria
Get-ChildItem -Path ".engram-data/dispatch-memory" -Recurse | 
  Measure-Object -Property Length -Sum
```

## Troubleshooting

### Contexto no se guarda
- Verificar que `.engram-data/dispatch-memory/` existe
- Verificar permisos de escritura
- Revisar logs en `-Verbose`

### Contexto anterior no se carga
- Verificar que hay dispatches previos en la sesión
- Usar `-Action list` para ver dispatches disponibles
- Verificar que `dispatch-registry.json` existe

### Errores de JSON
- Verificar que los archivos de contexto no están corruptos
- Usar `-Verbose` para más detalles
- Limpiar y reintentar si es necesario

## Próximos Pasos

1. **Integración con Engram**: Sincronización automática con Engram
2. **Analytics**: Dashboard de métricas de dispatch
3. **Machine Learning**: Predicción de éxito basada en contexto histórico
4. **Auto-tuning**: Ajuste automático de parámetros
5. **Distributed Memory**: Compartir contexto entre sesiones/máquinas

## Referencias

- [dispatch-agent.ps1](./dispatch-agent.ps1)
- [dispatch-memory-manager.ps1](./dispatch-memory-manager.ps1)
- [Engram Documentation](../../docs/)