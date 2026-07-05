# Observability & SLO Standards

**Version:** 1.0.0 | **Date:** 2026-07-04 | **Status:** Active

## Purpose

Define Service Level Objectives (SLOs) for all stack components, establish observability standards,
and ensure reliable operation of the Gentle-Vanguard system.

---

## Three Pillars of Observability

### 1. Structured Logging

**Standard Format:**

```json
{
  "timestamp": "2026-07-04T10:30:00Z",
  "level": "INFO|WARN|ERROR|FATAL",
  "service": "component-name",
  "environment": "dev|staging|prod",
  "requestId": "uuid",
  "userId": "user-id",
  "operation": "operation-name",
  "duration_ms": 150,
  "message": "Human-readable message",
  "metadata": {}
}
```

**Logging Rules:**

1. Use structured JSON logs, not freeform strings
2. Include: timestamp, level, service, requestId, operation
3. Never log secrets, tokens, passwords, or full PII
4. Use stable field names across all services
5. Log at appropriate levels (no INFO for errors, no DEBUG in prod)

### 2. Metrics (RED Method)

**Required Metrics for Every Component:**

| Metric       | Definition              | Target      |
| ------------ | ----------------------- | ----------- |
| **R**ate     | Requests per second     | Measured    |
| **E**rrors   | Error rate (%)          | < 1%        |
| **D**uration | Latency (p50, p95, p99) | p95 < 400ms |

**Additional Metrics:**

| Metric       | Definition             | Target   |
| ------------ | ---------------------- | -------- |
| Saturation   | Resource utilization   | < 80%    |
| Availability | Uptime percentage      | > 99.9%  |
| Throughput   | Operations per minute  | Measured |
| Error Budget | Remaining error budget | > 20%    |

### 3. Distributed Tracing

**Tracing Rules:**

1. Instrument all inbound requests
2. Propagate trace context to downstream services
3. Wrap external I/O spans: DB, HTTP, queues, cache
4. Add domain-relevant span attributes
5. Sample rate: 100% in dev, 10% in prod

**Span Attributes:**

```json
{
  "trace_id": "abc123",
  "span_id": "def456",
  "parent_span_id": "ghi789",
  "operation": "skill.execute",
  "service": "hybrid-executor",
  "duration_ms": 250,
  "status": "OK|ERROR",
  "attributes": {
    "skill.id": "my-skill",
    "skill.version": "1.0.0",
    "user.id": "user-123"
  }
}
```

---

## Service Level Objectives (SLOs)

### Component SLOs

| Component             | Availability | Latency (p95) | Error Rate | Throughput |
| --------------------- | ------------ | ------------- | ---------- | ---------- |
| Dashboard WS          | 99.9%        | < 100ms       | < 0.5%     | 100 req/s  |
| CodeGraph             | 99.95%       | < 50ms        | < 0.1%     | 1000 req/s |
| Engram                | 99.99%       | < 20ms        | < 0.01%    | 500 req/s  |
| Graphify              | 99.9%        | < 200ms       | < 0.5%     | 50 req/s   |
| ML Embeddings         | 99.9%        | < 100ms       | < 0.5%     | 200 req/s  |
| Session Pipeline      | 99.99%       | < 500ms       | < 0.1%     | 10 req/s   |
| Security Orchestrator | 99.99%       | < 50ms        | < 0.01%    | 500 req/s  |
| Audit Pipeline        | 99.99%       | < 100ms       | < 0.01%    | 200 req/s  |
| Tracing               | 99.9%        | < 30ms        | < 0.5%     | 1000 req/s |
| Knowledge Vault       | 99.9%        | < 150ms       | < 0.5%     | 100 req/s  |

### Error Budget Policy

| Budget Remaining | Action                            |
| ---------------- | --------------------------------- |
| > 50%            | Normal operations, ship features  |
| 20-50%           | Caution, increase testing         |
| 5-20%            | Freeze non-critical changes       |
| < 5%             | Full freeze, focus on reliability |
| 0%               | Incident response, no new deploys |

---

## Alerting Rules

### Alert Severity Levels

| Severity | Response Time | Notification      | Escalation          |
| -------- | ------------- | ----------------- | ------------------- |
| CRITICAL | Immediate     | PagerDuty + Slack | Auto-escalate 15min |
| HIGH     | 15 min        | Slack             | Auto-escalate 30min |
| MEDIUM   | 1 hour        | Slack             | Daily review        |
| LOW      | 4 hours       | Email             | Weekly review       |

### Alert Conditions

| Condition                 | Severity | Component         |
| ------------------------- | -------- | ----------------- |
| Component down            | CRITICAL | Any               |
| Error rate > 5%           | HIGH     | Any               |
| Latency p95 > 1s          | HIGH     | Any               |
| Error budget < 20%        | MEDIUM   | Any               |
| Disk usage > 80%          | MEDIUM   | Storage           |
| Memory usage > 80%        | MEDIUM   | Any               |
| CPU usage > 80%           | MEDIUM   | Any               |
| Certificate expiring < 7d | HIGH     | Security          |
| Backup failed             | HIGH     | State Persistence |

---

## Incident Response

### Triage Sequence

1. **Check symptoms:** latency, availability, error rate
2. **Identify scope:** all users, one endpoint, one region
3. **Correlate traces** to failing components
4. **Inspect logs** with requestId/traceId
5. **Validate mitigation**, then root cause

### Incident Severity

| Severity | Description          | Response          | Resolution |
| -------- | -------------------- | ----------------- | ---------- |
| SEV1     | Complete outage      | All hands         | 1 hour     |
| SEV2     | Major feature broken | Team lead         | 4 hours    |
| SEV3     | Minor feature broken | Assigned engineer | 24 hours   |
| SEV4     | Cosmetic issue       | Backlog           | 1 week     |

---

## Dashboard Metrics

### Real-Time Dashboard Shows

1. **Component Health:** Green/Yellow/Red status
2. **Request Rate:** Requests per second per component
3. **Error Rate:** Percentage of failed requests
4. **Latency:** p50, p95, p99 percentiles
5. **Throughput:** Operations per minute
6. **Saturation:** CPU, Memory, Disk usage
7. **SLO Compliance:** Current vs target
8. **Error Budget:** Remaining budget

### Historical Trends

1. **Daily:** 24-hour rolling window
2. **Weekly:** 7-day rolling window
3. **Monthly:** 30-day rolling window
4. **Quarterly:** 90-day rolling window

---

## Enforcement

1. **tracing-instrument.ps1** creates spans for all operations
2. **structured-logger.ps1** formats logs as JSON
3. **slo-monitor.ps1** checks SLO compliance
4. **alert-manager.ps1** routes alerts to owners
5. **dashboard** displays real-time metrics
6. **watchtower** validates observability health

---

## Related Files

- `scripts/utilities/ops/TRACING/tracing-instrument.ps1`
- `scripts/utilities/telemetry/TELEMETRY-METRICS/structured-logger.ps1`
- `scripts/utilities/telemetry/TELEMETRY-METRICS/slo-monitor.ps1`
- `apps/web-dashboard/` (dashboard)
- `rules/NORMATIVAS-PERFORMANCE.md`
- `rules/INCIDENT-RESPONSE.md`
