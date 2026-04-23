# Distributed Tracing Skill - Guía Completa

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Características Principales](#características-principales)
3. [Instalación y Configuración](#instalación-y-configuración)
4. [Uso Básico](#uso-básico)
5. [Casos de Uso Avanzados](#casos-de-uso-avanzados)
6. [Estructura de Directorios](#estructura-de-directorios)
7. [Reportes y Análisis](#reportes-y-análisis)
8. [Troubleshooting](#troubleshooting)

## Descripción General

El **Distributed Tracing Skill** proporciona un sistema completo de observabilidad para el workspace-foundation, permitiendo rastrear la ejecución de dispatches, orchestration y automatización con:

- **Correlation IDs**: Identificadores únicos para rastrear operaciones a través de múltiples componentes
- **Span Hierarchy**: Estructura jerárquica de spans para visualizar relaciones entre operaciones
- **Performance Metrics**: Métricas de rendimiento en tiempo real
- **Centralized Reporting**: Reportes centralizados en un único directorio
- **OpenTelemetry Compatible**: Compatible con estándares de observabilidad

## Características Principales

### 1. Correlation IDs
Cada sesión obtiene un identificador único que se propaga a través de todas las operaciones:

```
Formato: session-YYYY-MM-DD-XX-XXXXXXXX-YYYYMMDDHHMMSS-XXXXXXXX
Ejemplo: session-2026-04-23-24-20260423143500-a1b2c3d4
```

### 2. Span Hierarchy
Estructura jerárquica que muestra relaciones entre operaciones:

```
Root Span (Session)
├── Dispatch Span
│   ├── Task Routing Span
│   ├── Agent Execution Span
│   └── Result Processing Span
├── Orchestration Span
│   ├── Phase Execution Span
│   └── State Management Span
└── Automation Span
    ├── Event Processing Span
    └── Action Execution Span
```

### 3. Performance Metrics
- Latencia de operaciones (ms)
- Throughput de dispatches (ops/sec)
- Tasa de éxito/error (%)
- Utilización de recursos

### 4. Reportes Centralizados
Todos los reportes se generan automáticamente en `.telemetry/reports/`:

- `daily-summary-YYYY-MM-DD.md` - Resumen diario
- `performance-analysis-YYYY-MM-DD.md` - Análisis de rendimiento
- `error-analysis-YYYY-MM-DD.md` - Análisis de errores
- `dispatch-metrics-YYYY-MM-DD.md` - Métricas de dispatches

## Instalación y Configuración

### Paso 1: Verificar Archivos Instalados

```powershell
# Verificar que los archivos existan
Test-Path "skills/distributed-tracing-skill/distributed-tracing-core.ps1"
Test-Path "skills/distributed-tracing-skill/report-generator.ps1"
Test-Path "config/distributed-tracing-config.json"
Test-Path "tools/initialize-distributed-tracing.ps1"
Test-Path "tools/telemetry-dashboard.ps1"
```

### Paso 2: Configuración Automática

El sistema se inicializa automáticamente durante el `session-autostart`:

```powershell
# Ejecutar autostart (incluye inicialización de tracing)
.\tools\session-autostart.cmd
```

### Paso 3: Verificar Inicialización

```powershell
# Ver resumen de telemetría
.\tools\telemetry-dashboard.ps1 -Action show-summary
```

## Uso Básico

### Inicializar Tracing en un Script

```powershell
# Cargar el módulo de tracing
. .\skills\distributed-tracing-skill\distributed-tracing-core.ps1

# Inicializar tracing para la sesión
$tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"

# Ahora puedes usar las funciones de tracing
```

### Crear Spans

```powershell
# Crear un span raíz para una operación
$span = Start-Span -Name "process-dispatch" -SpanType "dispatch" -Attributes @{
    DispatchType = "auto-delegation"
    Priority = "high"
    TaskId = "task-123"
}

# ... realizar operación ...

# Finalizar el span
End-Span -Span $span -Status "success"
```

### Registrar Métricas

```powershell
# Registrar una métrica de latencia
Record-Metric -Name "dispatch-latency" -Value 1250 -Unit "ms" -Tags @{
    DispatchType = "auto-delegation"
    AgentType = "code-review"
    Status = "success"
}

# Registrar una métrica de throughput
Record-Metric -Name "dispatch-throughput" -Value 42 -Unit "ops/sec" -Tags @{
    Period = "1min"
}
```

### Agregar Eventos a Spans

```powershell
# Agregar un evento a un span
Add-SpanEvent -Span $span -EventName "agent-selected" -Attributes @{
    AgentName = "code-review-agent"
    Confidence = 0.95
}

Add-SpanEvent -Span $span -EventName "task-completed" -Attributes @{
    Result = "approved"
    ReviewTime = 1250
}
```

### Finalizar Tracing

```powershell
# Finalizar tracing y exportar todos los datos
Finalize-DistributedTracing

# Esto:
# 1. Cierra el span raíz
# 2. Exporta todos los spans
# 3. Exporta todas las métricas
# 4. Muestra un resumen
```

## Casos de Uso Avanzados

### Rastrear un Dispatch Completo

```powershell
# Inicializar
. .\skills\distributed-tracing-skill\distributed-tracing-core.ps1
$tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"

# Crear span raíz para dispatch
$dispatchSpan = Start-Span -Name "auto-delegation-dispatch" -SpanType "dispatch" -Attributes @{
    TaskDescription = "Implement login feature"
    Timestamp = Get-Date -Format "o"
}

try {
    # Span para keyword extraction
    $keywordSpan = Start-Span -Name "keyword-extraction" -SpanType "operation" `
        -ParentSpanId $dispatchSpan.SpanId -Attributes @{
        TaskLength = 100
    }
    
    # ... realizar extracción de keywords ...
    $keywords = @("login", "authentication", "security")
    
    Add-SpanMetric -Span $keywordSpan -MetricName "keywords-found" -Value $keywords.Count
    End-Span -Span $keywordSpan -Status "success"
    
    # Span para decision tree
    $decisionSpan = Start-Span -Name "decision-tree-evaluation" -SpanType "operation" `
        -ParentSpanId $dispatchSpan.SpanId -Attributes @{
        KeywordCount = $keywords.Count
    }
    
    # ... evaluar decision tree ...
    $confidence = 0.95
    
    Add-SpanMetric -Span $decisionSpan -MetricName "confidence-score" -Value $confidence
    End-Span -Span $decisionSpan -Status "success"
    
    # Span para agent execution
    $agentSpan = Start-Span -Name "agent-execution" -SpanType "operation" `
        -ParentSpanId $dispatchSpan.SpanId -Attributes @{
        AgentType = "code-review"
        Confidence = $confidence
    }
    
    # ... ejecutar agente ...
    
    End-Span -Span $agentSpan -Status "success"
    
    # Finalizar dispatch
    End-Span -Span $dispatchSpan -Status "success"
}
catch {
    End-Span -Span $dispatchSpan -Status "error" -ErrorMessage $_.Exception.Message
    throw
}

# Finalizar tracing
Finalize-DistributedTracing
```

### Integración con Auto-Delegation Router

```powershell
# En auto-delegation-router.ps1, agregar tracing:

function Route-TaskToAgent {
    param([string]$TaskDescription)
    
    # Obtener correlation ID
    $correlationId = Get-CorrelationId
    
    # Crear span para routing
    $routingSpan = Start-Span -Name "task-routing" -SpanType "dispatch" -Attributes @{
        TaskDescription = $TaskDescription
        CorrelationId = $correlationId
    }
    
    try {
        # ... lógica de routing ...
        $agent = Select-BestAgent -Task $TaskDescription
        
        Record-Metric -Name "routing-confidence" -Value $agent.Confidence -Unit "%" -Tags @{
            TaskType = $TaskDescription
            SelectedAgent = $agent.Name
        }
        
        End-Span -Span $routingSpan -Status "success"
        return $agent
    }
    catch {
        End-Span -Span $routingSpan -Status "error" -ErrorMessage $_.Exception.Message
        throw
    }
}
```

## Estructura de Directorios

```
.telemetry/
├── traces/
│   ├── dispatch-traces-2026-04-23.jsonl
│   ├── orchestration-traces-2026-04-23.jsonl
│   ├── automation-traces-2026-04-23.jsonl
│   └── operation-traces-2026-04-23.jsonl
├── metrics/
│   ├── metrics-2026-04-23.json
│   └── metrics-2026-04-22.json
├── reports/
│   ├── daily-summary-2026-04-23.md
│   ├── performance-analysis-2026-04-23.md
│   ├── error-analysis-2026-04-23.md
│   └── dispatch-metrics-2026-04-23.md
├── spans/
│   ├── spans-2026-04-23.json
│   └── spans-2026-04-22.json
├── events/
│   └── events-2026-04-23.jsonl
└── index.json
```

### Nomenclatura de Archivos

| Patrón | Descripción |
|--------|-------------|
| `dispatch-traces-YYYY-MM-DD.jsonl` | Traces de dispatches |
| `orchestration-traces-YYYY-MM-DD.jsonl` | Traces de orchestration |
| `automation-traces-YYYY-MM-DD.jsonl` | Traces de automation |
| `metrics-YYYY-MM-DD.json` | Métricas del día |
| `daily-summary-YYYY-MM-DD.md` | Resumen diario |
| `performance-analysis-YYYY-MM-DD.md` | Análisis de rendimiento |
| `error-analysis-YYYY-MM-DD.md` | Análisis de errores |
| `dispatch-metrics-YYYY-MM-DD.md` | Métricas de dispatches |

## Reportes y Análisis

### Generar Reportes

```powershell
# Generar todos los reportes para hoy
.\tools\telemetry-dashboard.ps1 -Action generate-reports

# Generar reportes para una fecha específica
.\tools\telemetry-dashboard.ps1 -Action generate-reports -Date (Get-Date).AddDays(-1)
```

### Ver Reportes

```powershell
# Listar todos los reportes disponibles
.\tools\telemetry-dashboard.ps1 -Action show-reports

# Ver resumen de telemetría
.\tools\telemetry-dashboard.ps1 -Action show-summary
```

### Ver Datos de Tracing

```powershell
# Ver traces recientes
.\tools\telemetry-dashboard.ps1 -Action view-traces

# Ver métricas recientes
.\tools\telemetry-dashboard.ps1 -Action view-metrics
```

### Exportar Datos

```powershell
# Exportar todos los datos de telemetría
.\tools\telemetry-dashboard.ps1 -Action export-data

# Los datos se exportarán a: telemetry-export/
```

### Limpiar Datos Antiguos

```powershell
# Limpiar datos más antiguos de 30 días
.\tools\telemetry-dashboard.ps1 -Action cleanup

# Limpiar datos más antiguos de 7 días
.\tools\telemetry-dashboard.ps1 -Action cleanup -RetentionDays 7
```

## Troubleshooting

### Problema: Los spans no se están registrando

**Solución:**
```powershell
# Verificar que tracing esté inicializado
$correlationId = Get-CorrelationId
if (-not $correlationId) {
    Write-Host "Tracing no inicializado. Ejecutar:"
    . .\skills\distributed-tracing-skill\distributed-tracing-core.ps1
    $tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"
}
```

### Problema: No se encuentran reportes

**Solución:**
```powershell
# Verificar que el directorio de telemetría exista
if (-not (Test-Path ".telemetry")) {
    New-Item -ItemType Directory -Path ".telemetry" -Force
}

# Generar reportes manualmente
.\tools\telemetry-dashboard.ps1 -Action generate-reports
```

### Problema: Métricas no se exportan

**Solución:**
```powershell
# Asegurarse de finalizar tracing
Finalize-DistributedTracing

# Verificar que los archivos se crearon
Get-ChildItem -Path ".telemetry/metrics" -Filter "*.json"
```

### Problema: Correlation ID no se propaga

**Solución:**
```powershell
# Obtener el correlation ID actual
$corrId = Get-CorrelationId

# Pasar explícitamente a funciones
$span = Start-Span -Name "operation" -CorrelationId $corrId
```

## Configuración Avanzada

Ver: `config/distributed-tracing-config.json`

```json
{
  "distributedTracing": {
    "enabled": true,
    "metrics": {
      "collectInterval": 5000,
      "exportInterval": 60000,
      "retentionDays": 30
    },
    "reporting": {
      "generateDaily": true,
      "generateOnSessionEnd": true
    },
    "performance": {
      "trackLatency": true,
      "trackThroughput": true,
      "trackErrorRate": true,
      "samplingRate": 1.0
    }
  }
}
```

## Archivos Relacionados

- `skills/distributed-tracing-skill/distributed-tracing-core.ps1` - Core implementation
- `skills/distributed-tracing-skill/report-generator.ps1` - Report generation
- `config/distributed-tracing-config.json` - Configuration
- `tools/initialize-distributed-tracing.ps1` - Initialization script
- `tools/telemetry-dashboard.ps1` - Dashboard and management tool
- `tools/session-autostart.cmd` - Autostart integration

## Soporte y Contribuciones

Para reportar problemas o contribuir mejoras, consulta:
- `CONTRIBUTING.md`
- `docs/` - Documentación adicional