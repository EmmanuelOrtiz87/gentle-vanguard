# 📊 Real-Data Pipeline Architecture

**Location:** `apps/web-dashboard/server/real-data/`  
**Barrel Entry:** `apps/web-dashboard/server/real-data.ts` (17 lines)  
**Status:** Dashboard Core  
**Structure:** 6 native modules behind a thin barrel entry

---

## Overview

The Real-Data Pipeline processes and streams live metrics, traces, alerts, and feedback to the dashboard UI. It's the compute-heavy core of observability.

**Key Responsibility:** Transform raw telemetry into structured, queryable observability data.

---

## Module Structure

```
real-data/
├── metrics.ts           # 931L - Metrics computation (CPU, mem, latency, throughput)
├── traces.ts            # 281L - Request tracing, span aggregation
├── alerts.ts            # 256L - Alert rule evaluation, escalation
├── feedback.ts          # 154L - User feedback ingestion + tagging
├── response-cache.ts    # 128L - Caching computed results
├── helpers.ts           # 87L  - Common utilities, formatters
└── index.ts             # 17L  - Barrel exports
```

---

## Metrics Module (931L)

**Computes:**
- CPU usage (process, system)
- Memory (heap, RSS, external)
- Latency (p50, p95, p99)
- Throughput (req/s, msg/s)
- Error rates
- Cache hit ratios
- Token usage (in/out)

**Updates:** Every 5 seconds (configurable)  
**Retention:** 7 days (configurable)  

```typescript
import { computeMetrics } from './real-data/metrics';

const metrics = await computeMetrics({
  timeWindow: '5m',
  percentiles: [50, 95, 99]
});
```

---

## Traces Module (281L)

**Captures:**
- Request lifecycle (start → end)
- Span hierarchy (parent/child)
- Timing breakdowns
- Resource usage per request
- Error traces with stack

**Indexing:** Session ID, user, agent, timestamp  
**Query:** `GET /api/traces?sessionId=X&limit=50`

---

## Alerts Module (256L)

**Evaluates:**
- Threshold violations (CPU > 80%)
- Anomalies (deviation from baseline)
- Error rate spikes
- Latency degradation
- Process crashes
- Database issues

**Actions:**
- Log to Nexus
- Push to dashboard (WebSocket)
- Trigger webhooks
- Page on-call (if critical)

---

## Response Cache (128L)

**Caches:**
- Computed metrics (5m TTL)
- Aggregated traces (1h TTL)
- Alert history (7d TTL)

**Invalidation:** On new data arrival  
**Storage:** Nexus DB + in-memory cache  

---

## Usage

### Streaming Metrics

```typescript
import { streamMetrics } from './real-data';

// WebSocket server sends every 5s
const metricsStream = streamMetrics({
  interval: 5000,      // 5 seconds
  onData: (metrics) => {
    ws.send(JSON.stringify({ type: 'metrics', data: metrics }));
  }
});
```

### Query Traces

```bash
curl http://localhost:3000/api/traces?sessionId=abc123&limit=100
```

### Alert Configuration

**File:** `config/dashboard-alerts.json`

```json
{
  "rules": [
    {
      "id": "high-cpu",
      "metric": "cpu",
      "operator": ">",
      "threshold": 80,
      "severity": "warning",
      "ttl": "5m"
    }
  ]
}
```

---

## Performance

- **Metrics compute:** <100ms per cycle
- **Trace aggregation:** <200ms per window
- **Cache hit ratio:** >90%
- **Memory footprint:** ~200MB (7-day retention)

---

## Integration

**Sources:**
- ProcessMetrics (OS stats)
- RequestLogger (HTTP)
- ErrorHandler (exceptions)
- TokenCounter (usage)
- SessionManager (lifecycle)

**Destinations:**
- Dashboard (WebSocket)
- Nexus DB (persistence)
- Alerts system
- Reports (CSV, PDF)

---

## Test Coverage

**Location:** `tests/unit/real-data/`
- `metrics.test.ts` - Computation accuracy
- `traces.test.ts` - Span aggregation
- `alerts.test.ts` - Rule evaluation
- `cache.test.ts` - Cache hit ratios

**Target:** 85%+ coverage

---

**See:** `docs/modules/MODULE-STRUCTURE.md`  
**Dashboard:** `apps/web-dashboard/`  
**Tests:** `tests/unit/real-data/*.test.ts`

