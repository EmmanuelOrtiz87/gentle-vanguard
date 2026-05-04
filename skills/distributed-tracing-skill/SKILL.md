---
name: distributed-tracing-skill
description: Distributed tracing with OpenTelemetry for workspace sessions
trigger: tracing, telemetry, distributed, correlation, span
---

# Distributed Tracing Skill

## Descripcin

Este skill proporciona capacidades de tracing distribuido para el workspace-foundation, permitiendo rastrear la ejecucin de dispatches, orchestration y automatización con:

- **OpenTelemetry Integration**: Implementacin compatible con estndares de observabilidad
- **Correlation IDs**: Identificadores nicos para rastrear operaciónes a travs de mltiples componentes
- **Span Hierarchy**: estructura jerrquica de spans para visualizar relaciones entre operaciónes
- **Performance Metrics**: Mtricas de rendimiento en tiempo real
- **Centralized Reporting**: Reportes centralizados en un nico directorio

## Caractersticas

### 1. Correlation IDs
- Generacin automtica de IDs nicos por sesin
- Propagacin a travs de todas las operaciónes
- Formato: `session-YYYY-MM-DD-XX-XXXXXXXX` (UUID)

### 2. Span Hierarchy
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
- Latencia de operaciónes
- Throughput de dispatches
- Tasa de xito/error
- Utilizacin de recursos

### 4. Reportes Centralizados
estructura de directorios:
```
.telemetry/
 traces/
    dispatch-traces-YYYY-MM-DD.jsonl
    orchestration-traces-YYYY-MM-DD.jsonl
    automation-traces-YYYY-MM-DD.jsonl
 metrics/
    performance-metrics-YYYY-MM-DD.json
    dispatch-metrics-YYYY-MM-DD.json
    system-metrics-YYYY-MM-DD.json
 reports/
    daily-summary-YYYY-MM-DD.md
    performance-analysis-YYYY-MM-DD.md
    error-analysis-YYYY-MM-DD.md
 index.json
```

## Uso

### Inicializar Tracing
```powershell
. ./skills/distributed-tracing-skill/distributed-tracing-core.ps1

$tracing = Initialize-DistributedTracing -SessionId "session-2026-04-23-24"
```

### Crear Spans
```powershell
$span = Start-Span -Name "dispatch-task" -ParentSpanId $parentSpan.SpanId -Attributes @{
    TaskType = "feature-implementation"
    Priority = "high"
}

# ... realizar operacin ...

End-Span -Span $span -Status "success"
```

### Registrar Mtricas
```powershell
Record-Metric -Name "dispatch-latency" -Value 1250 -Unit "ms" -Tags @{
    DispatchType = "auto-delegation"
    AgentType = "code-review"
}
```

### Generar Reportes
```powershell
Generate-DailyReport -Date (Get-Date) -OutputPath ".telemetry/reports"
```

## Integracin con Componentes Existentes

### Auto-Delegation Router
- Cada dispatch genera un span raz
- Sub-spans para keyword extraction, decisión tree, confidence scoring
- Mtricas de routing accuracy

### Judgment Day Orchestrator
- Span para cada fase de judgment
- Mtricas de review time y approval rate
- Trazabilidad de decisiónes

### Session Manager
- Correlation ID propagado a toda la sesin
- Mtricas de session lifecycle
- Anlisis de session performance

## configuración

Ver: `config/distributed-tracing-config.json`

## archivos Relacionados

- `skills/distributed-tracing-skill/distributed-tracing-core.ps1` - Core implementation
- `skills/distributed-tracing-skill/otel-exporter.ps1` - OpenTelemetry exporter
- `skills/distributed-tracing-skill/metrics-collector.ps1` - Metrics collection
- `skills/distributed-tracing-skill/report-generator.ps1` - Report generation
- `scripts/utilities/telemetry-dashboard.ps1` - Dashboard para visualizar traces

