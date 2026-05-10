# Dispatch Memory Manager - Memoria Persistente para Dispatches

## Descripcin General

El **Dispatch Memory Manager** es un mdulo que resuelve el gap de "No hay memoria persistente entre
dispatches" integrando Engram con el sistema de dispatch-agent para mantener contexto entre
ejecuciónes.

## Problema Identificado

Antes de esta implementacin:

- Cada dispatch era aislado sin memoria del contexto anterior
- Los resultados de ejecuciónes anteriores se perdan
- No haba forma de recuperar informacin de dispatches previos
- El sistema no poda aprender o mejorar basndose en ejecuciónes anteriores

## Solucin Implementada

### Componentes

#### 1. **dispatch-memory-manager.ps1**

Mdulo central que gestióna la persistencia de memoria de dispatch.

**Ubicacin:** `scripts/utilities/WORKFLOW-ORCHESTRATION/dispatch-memory-manager.ps1`

**Funcionalidades:**

- `save`: Guarda el contexto de un dispatch
- `load`: Carga el contexto ms reciente o uno especfico
- `list`: Lista todos los dispatches de una sesin
- `clear`: Elimina contextos especficos o de toda una sesin
- `sync`: Sincroniza y reporta dispatches de una sesin

**Estructura de Almacenamiento:**

```
.engram-data/
 dispatch-memory/
    dispatch-registry.json          # ndice de todos los dispatches
    contexts/
        dispatch-20260423-120530.json
        dispatch-20260423-120545.json
        ...
```

#### 2. **dispatch-agent.ps1 (Modificado)**

Integracin del dispatch-agent con el memory manager.

**Cambios:**

- Carga contexto anterior antes de ejecutar
- Guarda contexto despus de ejecutar
- Pasa contexto anterior a los agentes

**Flujo:**

```
1. Load-PreviousDispatchContext()

2. Invoke-ParallelDispatch()

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

### Cargar Contexto Especfico

```powershell
& .\dispatch-memory-manager.ps1 -Action load `
  -ExecutionId "dispatch-20260423-120530" `
  -AsJson
```

### Listar Dispatches de Sesin

```powershell
& .\dispatch-memory-manager.ps1 -Action list -AsJson
```

### Sincronizar Memoria

```powershell
& .\dispatch-memory-manager.ps1 -Action sync -AsJson
```

### Limpiar Contexto

```powershell
# Limpiar contexto especfico
& .\dispatch-memory-manager.ps1 -Action clear `
  -ExecutionId "dispatch-20260423-120530"

# Limpiar toda la sesin
& .\dispatch-memory-manager.ps1 -Action clear `
  -SessionId "session-2026-04-23-22" `
  -Force
```

## Integracin con dispatch-agent

El dispatch-agent ahora automticamente:

1. **Carga contexto anterior** antes de ejecutar:

```powershell
$previousContext = Load-PreviousDispatchContext
```

2. **Construye contexto actual** con informacin relevante:

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

3. **Guarda contexto** despus de ejecutar:

```powershell
Save-DispatchContext -ExecutionId $result.execution_id -Context $dispatchContext
```

## Beneficios

**Continuidad**: Mantiene contexto entre dispatches  
 **Recuperabilidad**: Puede recuperar informacin de ejecuciónes anteriores  
 **Trazabilidad**: Registro completo de todas las ejecuciónes  
 **Aprendizaje**: Los agentes pueden acceder a contexto histrico  
 **Debugging**: Facilita diagnstico de problemas en ejecuciónes anteriores  
 **Optimizacin**: Permite mejorar basndose en resultados previos

## Casos de Uso

### 1. Recuperacin de Contexto

Si un dispatch falla, el siguiente puede recuperar el contexto anterior y continuar.

### 2. Anlisis de Tendencias

Analizar patrones de xito/fallo en mltiples ejecuciónes.

### 3. Optimizacin Adaptativa

Ajustar parmetros (modo, riesgo) basndose en resultados histricos.

### 4. Auditora y Compliance

Mantener registro completo de todas las operaciónes de dispatch.

## Integracin Futura con Engram

Esta implementacin est diseada para ser compatible con Engram:

1. Los datos se almacenan en `.engram-data/` (mismo directorio que Engram)
2. Estructura JSON compatible con Engram
3. Puede sincronizarse con Engram para anlisis ms profundo
4. Preparado para integracin con bsqueda y anlisis de Engram

## configuración

### Variables de Entorno

- `WFS_SESSION_ID`: ID de sesin actual (se usa automticamente)

### Rutas Configurables

Todas las rutas se derivan de `.engram-data/`:

- Directorio de memoria: `.engram-data/dispatch-memory/`
- Registro: `.engram-data/dispatch-memory/dispatch-registry.json`
- Contextos: `.engram-data/dispatch-memory/contexts/`

## Mantenimiento

### Limpiar Memoria Antigua

```powershell
# Limpiar dispatches de sesin anterior
& .\dispatch-memory-manager.ps1 -Action clear `
  -SessionId "session-2026-04-22-XX" `
  -Force
```

### Monitorear Uso de Espacio

```powershell
# Ver tamao de directorio de memoria
Get-ChildItem -Path ".engram-data/dispatch-memory" -Recurse |
  Measure-Object -Property Length -Sum
```

## Troubleshooting

### Contexto no se guarda

- Verificar que `.engram-data/dispatch-memory/` existe
- Verificar permisos de escritura
- Revisar logs en `-Verbose`

### Contexto anterior no se carga

- Verificar que hay dispatches previos en la sesin
- Usar `-Action list` para ver dispatches disponibles
- Verificar que `dispatch-registry.json` existe

### Errores de JSON

- Verificar que los archivos de contexto no estn corruptos
- Usar `-Verbose` para ms detalles
- Limpiar y reintentar si es necesario

## Prximos Pasos

1. **Integracin con Engram**: Sincronizacin automtica con Engram
2. **Analytics**: Dashboard de mtricas de dispatch
3. **Machine Learning**: Prediccin de xito basada en contexto histrico
4. **Auto-tuning**: Ajuste automtico de parmetros
5. **Distributed Memory**: Compartir contexto entre sesiónes/mquinas

## Referencias

- [dispatch-agent.ps1](./dispatch-agent.ps1)
- [dispatch-memory-manager.ps1](./dispatch-memory-manager.ps1)
