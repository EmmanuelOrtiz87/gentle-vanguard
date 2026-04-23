# Distributed Tracing Skill

## Descripción

Este skill proporciona capacidades de tracing distribuido para el workspace-foundation, permitiendo rastrear la ejecución de dispatches, orchestration y automatización con:

- **OpenTelemetry Integration**: Implementación compatible con estándares de observabilidad
- **Correlation IDs**: Identificadores únicos para rastrear operaciones a través de múltiples componentes
- **Span Hierarchy**: Estructura jerárquica de spans para visualizar relaciones entre operaciones
- **Performance Metrics**: Métricas de rendimiento en tiempo real
- **Centralized Reporting**: Reportes centralizados en un único directorio

## Características

### 1. Correlation IDs
- Generación automática de IDs únicos por sesión
- Propagación a través de todas las operaciones
- Formato: `session-YYYY-MM-DD-XX-XXXXXXXX` (UUID)

### 2. Span Hierarchy
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
- Latencia de operaciones
- Throughput de dispatches
- Tasa de éxito/error
- Utilización de recursos

### 4. Reportes Centralizados
Estructura de directorios:
```
.telemetry/
├── traces/
│   ├── dispatch-traces-YYYY-MM-DD.jsonl
│   ├── orchestration-traces-YYYY-MM-DD.jsonl
│   └── automation-traces-YYYY-MM-DD.jsonl
├── metrics/
│   ├── performance-metrics-YYYY-MM-DD.json
│   ├── dispatch-metrics-YYYY-MM-DD.json
│   └── system-metrics-YYYY-MM-DD.json
├── reports/
│   ├── daily-summary-YYYY-MM-DD.md
│   ├── performance-analysis-YYYY-MM-DD.md
│   └── error-analysis-YYYY-MM-DD.md
└── index.json
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

# ... realizar operación ...

End-Span -Span $span -Status "success"
```

### Registrar Métricas
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

## Integración con Componentes Existentes

### Auto-Delegation Router
- Cada dispatch genera un span raíz
- Sub-spans para keyword extraction, decision tree, confidence scoring
- Métricas de routing accuracy

### Judgment Day Orchestrator
- Span para cada fase de judgment
- Métricas de review time y approval rate
- Trazabilidad de decisiones

### Session Manager
- Correlation ID propagado a toda la sesión
- Métricas de session lifecycle
- Análisis de session performance

## Configuración

Ver: `config/distributed-tracing-config.json`

## Archivos Relacionados

- `skills/distributed-tracing-skill/distributed-tracing-core.ps1` - Core implementation
- `skills/distributed-tracing-skill/otel-exporter.ps1` - OpenTelemetry exporter
- `skills/distributed-tracing-skill/metrics-collector.ps1` - Metrics collection
- `skills/distributed-tracing-skill/report-generator.ps1` - Report generation
- `tools/telemetry-dashboard.ps1` - Dashboard para visualizar traces