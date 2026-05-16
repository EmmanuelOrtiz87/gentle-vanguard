# Distributed Tracing Skill - Gua Completa

## Tabla de Contenidos

1. [Descripcin General](#descripcin-general)
2. [Caractersticas Principales](#caractersticas-principales)
3. [Instalacin y configuración](#instalacin-y-configuración)
4. [Uso Bsico](#uso-bsico)
5. [Casos de Uso Avanzados](#casos-de-uso-avanzados)
6. [estructura de directorios](#estructura-de-directorios)
7. [Reportes y Anlisis](#reportes-y-anlisis)
8. [Troubleshooting](#troubleshooting)

## Descripcin General

El **Distributed Tracing Skill** proporciona un sistema completo de observabilidad para el
gentle-vanguard, permitiendo rastrear la ejecucin de dispatches, orchestration y automatización
con:

- **Correlation IDs**: Identificadores nicos para rastrear operaciónes a travs de mltiples
  componentes
- **Span Hierarchy**: estructura jerrquica de spans para visualizar relaciones entre operaciónes
- **Performance Metrics**: Mtricas de rendimiento en tiempo real
- **Centralized Reporting**: Reportes centralizados en un nico directorio
- **OpenTelemetry Compatible**: Compatible con estndares de observabilidad

## Caractersticas Principales

### 1. Correlation IDs

Cada sesin obtiene un identificador nico que se propaga a travs de todas las operaciónes:

```
Formato: session-YYYY-MM-DD-XX-XXXXXXXX-YYYYMMDDHHMMSS-XXXXXXXX
Ejemplo: session-2026-04-23-24-20260423143500-a1b2c3d4
```

### 2. Span Hierarchy

estructura jerrquica que muestra relaciones entre operaciónes:

```
Root Span (Session)
 Dispatch Span
    Task Routing Span
    Agent Execution Span
    Result Processing Span
 Orchestration Span
    Phase Execution Span
    State Management Span
 Automation Span
     Event Processing Span
     Action Execution Span
```

### 3. Performance Metrics

- Latencia de operaciónes (ms)
- Throughput de dispatches (ops/sec)
- Tasa de xito/error (%)
- Utilizacin de recursos

### 4. Reportes Centralizados

Todos los reportes se generan automticamente en `.telemetry/reports/`:

- `daily-summary-YYYY-MM-DD.md` - Resumen diario
- `performance-analysis-YYYY-MM-DD.md` - Anlisis de rendimiento
- `error-analysis-YYYY-MM-DD.md` - Anlisis de errores
- `dispatch-metrics-YYYY-MM-DD.md` - Mtricas de dispatches

## Instalacin y configuración

### Paso 1: Verificar archivos Instalados

```powershell
# Verificar que los archivos existan
Test-Path "skills/distributed-tracing-skill/distributed-tracing-core.ps1"
Test-Path "skills/distributed-tracing-skill/report-generator.ps1"
Test-Path "config/distributed-tracing-config.json"
Test-Path "scripts/utilities/initialize-distributed-tracing.ps1"
Test-Path "scripts/utilities/telemetry-dashboard.ps1"
```

### Paso 2: configuración Automtica

El sistema se inicializa automticamente durante el `session-autostart`:

```powershell
# Ejecutar autostart (incluye inicializacin de tracing)
.\tools\session-autostart.cmd
```

### Paso 3: Verificar Inicializacin

```powershell
# Ver resumen de telemetra
.\tools\telemetry-dashboard.ps1 -Action show-summary
```

## Uso Bsico

### Inicializar Tracing en un Script

```powershell
# Cargar el mdulo de tracing
. .\skills\distributed-tracing-skill\distributed-tracing-core.ps1

# Inicializar tracing para la sesin
$tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"

# Ahora puedes usar las funciones de tracing
```

### Crear Spans

```powershell
# Crear un span raz para una operacin
$span = Start-Span -Name "process-dispatch" -SpanType "dispatch" -Attributes @{
    DispatchType = "auto-delegation"
    Priority = "high"
    TaskId = "task-123"
}

# ... realizar operacin ...

# Finalizar el span
End-Span -Span $span -Status "success"
```

### Registrar Mtricas

```powershell
# Registrar una mtrica de latencia
Record-Metric -Name "dispatch-latency" -Value 1250 -Unit "ms" -Tags @{
    DispatchType = "auto-delegation"
    AgentType = "code-review"
    Status = "success"
}

# Registrar una mtrica de throughput
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
# 1. Cierra el span raz
# 2. Exporta todos los spans
# 3. Exporta todas las mtricas
# 4. Muestra un resumen
```

## Casos de Uso Avanzados

### Rastrear un Dispatch Completo

```powershell
# Inicializar
. .\skills\distributed-tracing-skill\distributed-tracing-core.ps1
$tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"

# Crear span raz para dispatch
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

    # ... realizar extraccin de keywords ...
    $keywords = @("login", "authentication", "security")

    Add-SpanMetric -Span $keywordSpan -MetricName "keywords-found" -Value $keywords.Count
    End-Span -Span $keywordSpan -Status "success"

    # Span para decisión tree
    $decisiónSpan = Start-Span -Name "decisión-tree-evaluation" -SpanType "operation" `
        -ParentSpanId $dispatchSpan.SpanId -Attributes @{
        KeywordCount = $keywords.Count
    }

    # ... evaluar decisión tree ...
    $confidence = 0.95

    Add-SpanMetric -Span $decisiónSpan -MetricName "confidence-score" -Value $confidence
    End-Span -Span $decisiónSpan -Status "success"

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

### Integracin con Auto-Delegation Router

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
        # ... lgica de routing ...
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

## estructura de directorios

```
.telemetry/
 traces/
    dispatch-traces-2026-04-23.jsonl
    orchestration-traces-2026-04-23.jsonl
    automation-traces-2026-04-23.jsonl
    operation-traces-2026-04-23.jsonl
 metrics/
    metrics-2026-04-23.json
    metrics-2026-04-22.json
 reports/
    daily-summary-2026-04-23.md
    performance-analysis-2026-04-23.md
    error-analysis-2026-04-23.md
    dispatch-metrics-2026-04-23.md
 spans/
    spans-2026-04-23.json
    spans-2026-04-22.json
 events/
    events-2026-04-23.jsonl
 index.json
```

### Nomenclatura de archivos

| Patrn                                   | Descripcin              |
| --------------------------------------- | ----------------------- |
| `dispatch-traces-YYYY-MM-DD.jsonl`      | Traces de dispatches    |
| `orchestration-traces-YYYY-MM-DD.jsonl` | Traces de orchestration |
| `automation-traces-YYYY-MM-DD.jsonl`    | Traces de automation    |
| `metrics-YYYY-MM-DD.json`               | Mtricas del da          |
| `daily-summary-YYYY-MM-DD.md`           | Resumen diario          |
| `performance-analysis-YYYY-MM-DD.md`    | Anlisis de rendimiento  |
| `error-analysis-YYYY-MM-DD.md`          | Anlisis de errores      |
| `dispatch-metrics-YYYY-MM-DD.md`        | Mtricas de dispatches   |

## Reportes y Anlisis

### Generar Reportes

```powershell
# Generar todos los reportes para hoy
.\tools\telemetry-dashboard.ps1 -Action generate-reports

# Generar reportes para una fecha especfica
.\tools\telemetry-dashboard.ps1 -Action generate-reports -Date (Get-Date).AddDays(-1)
```

### Ver Reportes

```powershell
# Listar todos los reportes disponibles
.\tools\telemetry-dashboard.ps1 -Action show-reports

# Ver resumen de telemetra
.\tools\telemetry-dashboard.ps1 -Action show-summary
```

### Ver Datos de Tracing

```powershell
# Ver traces recientes
.\tools\telemetry-dashboard.ps1 -Action view-traces

# Ver mtricas recientes
.\tools\telemetry-dashboard.ps1 -Action view-metrics
```

### Exportar Datos

```powershell
# Exportar todos los datos de telemetra
.\tools\telemetry-dashboard.ps1 -Action export-data

# Los datos se exportarn a: telemetry-export/
```

### Limpiar Datos Antiguos

```powershell
# Limpiar datos ms antiguos de 30 das
.\tools\telemetry-dashboard.ps1 -Action cleanup

# Limpiar datos ms antiguos de 7 das
.\tools\telemetry-dashboard.ps1 -Action cleanup -RetentionDays 7
```

## Troubleshooting

### Problema: Los spans no se estn registrando

**Solucin:**

```powershell
# Verificar que tracing est inicializado
$correlationId = Get-CorrelationId
if (-not $correlationId) {
    Write-Host "Tracing no inicializado. Ejecutar:"
    . .\skills\distributed-tracing-skill\distributed-tracing-core.ps1
    $tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"
}
```

### Problema: No se encuentran reportes

**Solucin:**

```powershell
# Verificar que el directorio de telemetra exista
if (-not (Test-Path ".telemetry")) {
    New-Item -ItemType Directory -Path ".telemetry" -Force
}

# Generar reportes manualmente
.\tools\telemetry-dashboard.ps1 -Action generate-reports
```

### Problema: Mtricas no se exportan

**Solucin:**

```powershell
# Asegurarse de finalizar tracing
Finalize-DistributedTracing

# Verificar que los archivos se crearon
Get-ChildItem -Path ".telemetry/metrics" -Filter "*.json"
```

### Problema: Correlation ID no se propaga

**Solucin:**

```powershell
# Obtener el correlation ID actual
$corrId = Get-CorrelationId

# Pasar explcitamente a funciones
$span = Start-Span -Name "operation" -CorrelationId $corrId
```

## configuración Avanzada

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

## archivos Relacionados

- `skills/distributed-tracing-skill/distributed-tracing-core.ps1` - Core implementation
- `skills/distributed-tracing-skill/report-generator.ps1` - Report generation
- `config/distributed-tracing-config.json` - Configuration
- `scripts/utilities/initialize-distributed-tracing.ps1` - Initialization script
- `scripts/utilities/telemetry-dashboard.ps1` - Dashboard and management tool
- `scripts/utilities/session-autostart.cmd` - Autostart integration

## Soporte y Contribuciones

Para reportar problemas o contribuir mejoras, consulta:

- `CONTRIBUTING.md`
- `docs/` - Documentacin adicional

