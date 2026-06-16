# Observability Normatives — Gentle-Vanguard

Canonical standards for logging, tracing, metrics, and observability across Gentle-Vanguard stack.
Last updated: 2026-05-12 | Version: 1.0.0

---

## 1. Observability Pillars (Three Signals)

All observability MUST collect from these three pillars:

| Pillar      | Purpose                        | Tools                           | Example                                                                              |
| ----------- | ------------------------------ | ------------------------------- | ------------------------------------------------------------------------------------ |
| **Logs**    | What happened (events, errors) | Structured JSON, ELK, Splunk    | `{ level: "ERROR", msg: "User auth failed", userId: "123", error: "invalid-token" }` |
| **Traces**  | How it happened (flow, timing) | OpenTelemetry, Jaeger, Datadog  | Agent→Skill→Execution: 3 spans, 47ms total                                           |
| **Metrics** | How much (counters, gauges)    | Prometheus, Datadog, CloudWatch | `agent_dispatch_seconds_bucket{agent="DEV"} = 0.234`                                 |

---

## 2. Structured Logging

### Log Levels (syslog + custom)

| Level        | Usage                          | Severity | Example                                     |
| ------------ | ------------------------------ | -------- | ------------------------------------------- |
| **DEBUG**    | Development, low-level details | 📘       | Token allocation, cache hits                |
| **INFO**     | Normal operations, milestones  | 💙       | Agent dispatch started, task completed      |
| **WARN**     | Potential issues, deprecations | 💛       | Deprecated endpoint called, retry attempted |
| **ERROR**    | Failures, exceptions           | 🔴       | Skill execution failed, auth expired        |
| **CRITICAL** | System failures, data loss     | 🚨       | Database down, security breach detected     |

### Structured Format (JSON)

**REQUIRED**: All logs MUST be valid JSON with these fields:

```json
{
  "timestamp": "2026-05-12T19:55:32.123Z",
  "level": "INFO",
  "service": "gentle-vanguard-agent-router",
  "traceId": "550e8400-e29b-41d4-a716-446655440000",
  "spanId": "span-12345",
  "userId": "user-abc123",
  "sessionId": "session-2026-05-12-11",
  "message": "Agent dispatch initiated",
  "component": "orchestrator",
  "operation": "dispatch_agent",
  "duration_ms": 45,
  "result": "SUCCESS",
  "attributes": {
    "agent_code": "DEV",
    "skill": "sdd-lifecycle",
    "confidence": 0.95,
    "trigger": "implement"
  },
  "error": null,
  "metadata": {
    "environment": "production",
    "region": "us-east-1",
    "version": "2.1.0"
  }
}
```

### Log Emission Rules

```powershell
# PowerShell: Use structured logging function
function Write-StructuredLog {
    param(
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL')]
        [string]$Level,

        [string]$Message,

        [hashtable]$Attributes = @{}
    )

    $logEntry = @{
        timestamp = (Get-Date -AsUTC -Format 'o')
        level = $Level
        service = 'gentle-vanguard-orchestrator'
        traceId = $env:TRACE_ID ?? (New-Guid).Guid
        message = $Message
        attributes = $Attributes
    }

    $logEntry | ConvertTo-Json -Depth 10 | Write-Output
}

# Usage:
Write-StructuredLog -Level INFO -Message "Task started" -Attributes @{
    taskId = "task-123"
    userId = "user-456"
    duration_ms = 42
}
```

---

## 3. Distributed Tracing (OpenTelemetry)

### Trace Components

Every operation MUST emit traces with:

1. **Trace ID** — Unique per user request (e.g., `550e8400-e29b-41d4-a716-446655440000`)
2. **Span ID** — Unique per operation within trace (e.g., `span-12345`)
3. **Parent Span ID** — Links to parent operation (e.g., `parent-span-111`)

### Span Lifecycle

```
Request enters system
  ↓
[ROOT_SPAN: orchestrator-dispatch]
  traceId: 550e8400-e29b-41d4-a716-446655440000
  spanId: span-1
  operation: dispatch_agent
  attributes: { agent: "DEV", skill: "sdd-lifecycle" }
  ├─ [CHILD_SPAN: pre-process-input]
  │  spanId: span-2
  │  parentSpanId: span-1
  │  operation: pre_process_input
  │  duration_ms: 23
  │  status: OK
  ├─ [CHILD_SPAN: skill-execution]
  │  spanId: span-3
  │  parentSpanId: span-1
  │  operation: skill_execute
  │  duration_ms: 156
  │  status: OK
  │  ├─ [CHILD_SPAN: file-read]
  │  │  spanId: span-4
  │  │  duration_ms: 12
  │  └─ [CHILD_SPAN: agent-verify]
  │     spanId: span-5
  │     duration_ms: 31
  └─ [CHILD_SPAN: response-emit]
     spanId: span-6
     operation: response_emit
     duration_ms: 8
     status: OK

Total duration: 187ms
```

### Span Attributes (Standard)

Every span MUST include:

```json
{
  "traceId": "550e8400-e29b-41d4-a716-446655440000",
  "spanId": "span-3",
  "parentSpanId": "span-1",
  "operationName": "skill-execution",
  "startTime": "2026-05-12T19:55:32.123Z",
  "endTime": "2026-05-12T19:55:32.279Z",
  "duration_ms": 156,
  "status": "OK",
  "attributes": {
    "skill.name": "sdd-lifecycle",
    "skill.version": "2.1.0",
    "agent.code": "DEV",
    "user.id": "user-abc123",
    "session.id": "session-2026-05-12-11",
    "environment": "production"
  },
  "events": [
    {
      "name": "skill_start",
      "timestamp": "2026-05-12T19:55:32.123Z"
    },
    {
      "name": "skill_complete",
      "timestamp": "2026-05-12T19:55:32.279Z"
    }
  ],
  "errors": []
}
```

---

## 4. Metrics (Prometheus Format)

### Required Metrics

```
# Agent dispatch latency (histogram)
agent_dispatch_seconds_bucket{agent="DEV",le="0.1"} 42
agent_dispatch_seconds_bucket{agent="DEV",le="0.5"} 156
agent_dispatch_seconds_bucket{agent="DEV",le="1.0"} 203
agent_dispatch_seconds_sum{agent="DEV"} 234.5
agent_dispatch_seconds_count{agent="DEV"} 203

# Skill execution success rate (counter)
skill_executions_total{skill="sdd-lifecycle",status="SUCCESS"} 1024
skill_executions_total{skill="sdd-lifecycle",status="FAILURE"} 8

# Token usage (gauge)
token_usage_total{service="agent-router",period="day"} 28500
token_budget_limit{service="agent-router",period="day"} 30000

# Cache hit rate (counter)
cache_hits_total{cache="session",operation="read"} 512
cache_misses_total{cache="session",operation="read"} 24

# Error rate by category (counter)
errors_total{severity="CRITICAL"} 0
errors_total{severity="HIGH"} 3
errors_total{severity="MEDIUM"} 12
```

### Metric Collection

```powershell
# PowerShell: Emit metrics to Prometheus-compatible endpoint
function Emit-Metric {
    param(
        [string]$Name,
        [double]$Value,
        [hashtable]$Labels = @{}
    )

    $labelStr = ($Labels.GetEnumerator() | ForEach-Object { "$($_.Key)=`"$($_.Value)`"" }) -join ','
    $metric = "$Name{$labelStr} $Value"

    # Send to metrics collector (e.g., Prometheus pushgateway)
    Invoke-RestMethod -Uri "http://metrics-collector:9091/metrics/job/gentle-vanguard" `
        -Method POST -Body $metric
}

# Usage:
Emit-Metric -Name "agent_dispatch_seconds" -Value 0.234 `
    -Labels @{ agent = "DEV"; skill = "sdd-lifecycle" }
```

---

## 5. Observability Configuration

### `config/observability-config.json`

```json
{
  "observability": {
    "enabled": true,
    "environment": "production",
    "version": "1.0.0",

    "logging": {
      "level": "INFO",
      "format": "json",
      "output": [
        "stdout",
        "file:///logs/gentle-vanguard.log",
        "elk:elasticsearch.example.com:9200"
      ],
      "retention_days": 30,
      "sampling": {
        "enabled": false,
        "rate": 1.0
      }
    },

    "tracing": {
      "enabled": true,
      "exporters": [
        {
          "type": "jaeger",
          "endpoint": "http://jaeger.example.com:14268/api/traces",
          "sample_rate": 1.0
        },
        {
          "type": "datadog",
          "api_key": "${DATADOG_API_KEY}",
          "site": "datadoghq.com"
        }
      ],
      "max_trace_size_bytes": 65536,
      "attributes": {
        "service.name": "gentle-vanguard-orchestrator",
        "service.version": "2.1.0",
        "deployment.environment": "production"
      }
    },

    "metrics": {
      "enabled": true,
      "exporters": [
        {
          "type": "prometheus",
          "endpoint": "http://prometheus.example.com:9090",
          "interval_seconds": 60
        }
      ],
      "collectors": [
        "agent_dispatch",
        "skill_execution",
        "token_usage",
        "cache_performance",
        "error_rates"
      ]
    },

    "alerts": {
      "enabled": true,
      "rules": [
        {
          "name": "agent_dispatch_slow",
          "threshold_ms": 1000,
          "severity": "WARN",
          "action": "log_and_notify"
        },
        {
          "name": "skill_failure_rate",
          "threshold_percent": 5,
          "window_minutes": 5,
          "severity": "CRITICAL",
          "action": "page_oncall"
        }
      ]
    }
  }
}
```

---

## 6. Integration Points

### Per Agent (Auto-Instrumented)

Each agent MUST emit traces:

```powershell
# Pre-dispatch
Write-StructuredLog -Level INFO -Message "Agent dispatch initiated" `
    -Attributes @{ agent = "DEV"; confidence = 0.95 }

# Post-dispatch
Emit-Metric -Name "agent_dispatch_seconds" -Value $elapsedMs/1000

# On error
Write-StructuredLog -Level ERROR -Message "Agent execution failed" `
    -Attributes @{ error = $error.Message; severity = "HIGH" }
```

### Per Skill (Auto-Instrumented)

Each skill MUST emit traces:

```powershell
# Skill entry
$traceId = New-TraceId
$spanId = New-SpanId
Write-StructuredLog -Level INFO -Message "Skill execution started" `
    -Attributes @{ traceId = $traceId; spanId = $spanId; skill = "sdd-lifecycle" }

# Skill exit
Write-StructuredLog -Level INFO -Message "Skill execution completed" `
    -Attributes @{ traceId = $traceId; spanId = $spanId; duration_ms = 156; status = "SUCCESS" }
```

---

## 7. Dashboards & Alerts

### Recommended Dashboards

1. **Agent Performance** — Dispatch latency, success rates by agent
2. **Skill Health** — Execution time, failure rate, token usage by skill
3. **System Health** — Error rates, uptime, SLO compliance
4. **Token Budget** — Daily/hourly consumption vs. limit
5. **User Journey** — Trace visualization, bottleneck detection

### Alert Rules (Example)

```yaml
# Prometheus alerts
groups:
  - name: gentle-vanguard-alerts
    rules:
      - alert: AgentDispatchSlow
        expr: agent_dispatch_seconds > 0.5
        for: 5m
        annotations:
          summary: 'Agent dispatch slow ({{ $value }}s)'

      - alert: SkillFailureRate
        expr: rate(skill_executions_total{status="FAILURE"}[5m]) > 0.05
        for: 10m
        annotations:
          summary: 'Skill failure rate > 5%'
```

---

## 8. Privacy & Security

### PII Masking

Logs MUST NOT contain:

- User passwords, tokens, API keys
- Credit card numbers, SSNs
- Personally identifiable information (names, emails, IPs)

**REQUIRED**: Implement masking function:

```powershell
function Mask-PII {
    param([string]$Input)

    $masked = $Input `
        -replace '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '[EMAIL_MASKED]' `
        -replace '\b\d{3}-\d{2}-\d{4}\b', '[SSN_MASKED]' `
        -replace '(password|token|apiKey)["\s]*[=:]\s*["\']?[^"\s]*', '$1=[REDACTED]'

    return $masked
}
```

### Data Retention

- **Logs**: 30 days (production), 7 days (staging)
- **Traces**: 14 days
- **Metrics**: 30 days
- **Audit logs**: 1 year (immutable)

---

## 9. Testing & Validation

### Observability Test Suite

```powershell
Describe "Observability" {
  It "logs are valid JSON" {
    $log = Invoke-SkillOperation | Get-Log
    { $log | ConvertFrom-Json } | Should Not Throw
  }

  It "traces include traceId and spanId" {
    $trace = Invoke-SkillOperation | Get-Trace
    $trace.traceId | Should Not BeNullOrEmpty
    $trace.spanId | Should Not BeNullOrEmpty
  }

  It "metrics are Prometheus-formatted" {
    $metric = Get-Metrics
    $metric | Should Match '^[a-z_]+\{.*\}\s+\d+(\.\d+)?$'
  }

  It "PII is masked in logs" {
    $log = Write-StructuredLog -Message "User email@example.com logged in"
    $log | Should Contain "[EMAIL_MASKED]"
  }
}
```

---

## 10. Implementation Checklist

- [ ] `config/observability-config.json` created with default exporters
- [ ] Logging function `Write-StructuredLog` implemented in utilities
- [ ] Tracing instrumentation added to orchestrator
- [ ] Metrics collection enabled for all agents/skills
- [ ] Alerts configured in Prometheus/Datadog
- [ ] Dashboards created in visualization tool
- [ ] PII masking tested
- [ ] 30-day retention configured
- [ ] Observability tests in `tests/observability/`
- [ ] Documentation synchronized with
      [config/observability-config.json](../config/observability-config.json)

---

## References

- [OpenTelemetry](https://opentelemetry.io/)
- [Prometheus Metrics](https://prometheus.io/)
- [ELK Stack](https://www.elastic.co/what-is/elk-stack)
- [Jaeger Tracing](https://www.jaegertracing.io/)
- Project: [config/observability-config.json](../config/observability-config.json)
