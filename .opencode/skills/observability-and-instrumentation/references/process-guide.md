# Observability Process Guide

## 1. Define "working" before instrumenting

Telemetry without a question is noise. Before adding any instrumentation, write down 2–4 questions
an on-call engineer will ask about this feature:

```
FEATURE: checkout payment retry
QUESTIONS ON-CALL WILL ASK:
1. What fraction of payments succeed on first attempt vs after retry?
2. When a payment fails permanently, why? (provider error? timeout? validation?)
3. Is the payment provider slower than usual?
→ Every signal below must help answer one of these.
```

If you can't name the questions, you're not ready to instrument.

## 2. Pick the right signal for each question

| Signal             | Answers                                | Cost profile                     | Example                                   |
| ------------------ | -------------------------------------- | -------------------------------- | ----------------------------------------- |
| **Structured log** | "What happened in this specific case?" | Per-event; grows with traffic    | `payment_failed` with provider error code |
| **Metric**         | "How often / how fast, in aggregate?"  | Fixed per series; cheap to query | p99 latency of provider calls             |
| **Trace**          | "Where did time go across services?"   | Per-request; usually sampled     | One slow checkout, broken down by hop     |

Rule of thumb: metrics tell you **that** something is wrong, traces tell you **where**, logs tell
you **why**.

## 3. Structured logging

Log events, not prose. Every log line is a JSON object with a stable event name and machine-readable
fields:

```typescript
// BAD: string interpolation — unqueryable, inconsistent
logger.info(`Payment ${id} failed for user ${userId} after ${n} retries`);

// GOOD: stable event name + structured fields
logger.warn(
  {
    event: 'payment_failed',
    paymentId: id,
    provider: 'stripe',
    errorCode: err.code,
    attempt: n,
  },
  'payment failed',
);
```

**Log levels — use them consistently:**

| Level   | Meaning                                                 | On-call action               |
| ------- | ------------------------------------------------------- | ---------------------------- |
| `error` | Invariant broken; someone may need to act               | Investigate                  |
| `warn`  | Degraded but handled (retry succeeded, fallback used)   | Watch for trends             |
| `info`  | Significant business event (order placed, job finished) | None                         |
| `debug` | Diagnostic detail                                       | Off in production by default |

**Correlation IDs are mandatory.** Generate (or accept) a request ID at the system boundary and
attach it to every log line, span, and outbound call:

```typescript
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] ?? crypto.randomUUID();
  req.log = logger.child({ requestId: req.id });
  res.setHeader('x-request-id', req.id);
  next();
});
```

**Never log secrets, tokens, passwords, or full PII.**

## 4. Metrics

For request-driven services, instrument **RED** on every endpoint and every external dependency:
**R**ate (requests/sec), **E**rrors (failure rate), **D**uration (latency histogram, not average).
For resources (queues, pools, hosts), use **USE**: **U**tilization, **S**aturation, **E**rrors.

```typescript
import { Histogram } from 'prom-client';

const httpDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'route', 'status_class'],
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});
```

**Cardinality is the failure mode.** Every unique label combination is a separate time series.
Labels must come from small, fixed sets (route template, status class, provider name). Never use
user IDs, raw URLs, error messages, or other unbounded values as labels:

```
OK as label:    route="/api/tasks/:id"   status_class="5xx"   provider="stripe"
NEVER a label:  user_id, email, request_id, full URL, error message text
```

Track averages never, percentiles always. Use histograms and read p50/p95/p99.

## 5. Distributed tracing

Use OpenTelemetry — it's the vendor-neutral standard, and auto-instrumentation covers HTTP, gRPC,
and common DB clients with near-zero code:

```typescript
// tracing.ts — must be imported before anything else
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  serviceName: 'checkout-service',
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

Add manual spans only around meaningful internal units of work (e.g., `applyDiscounts`,
`chargeProvider`) and attach attributes on-call will filter by. Propagate context across every
async boundary — HTTP headers, queue message metadata — or the trace dies at the gap. Sample
head-based at a low rate by default; keep 100% of errors if your backend supports tail sampling.

## 6. Alerting

Alert on **symptoms users feel**, not on causes:

```
SYMPTOM (page-worthy):           CAUSE (dashboard, not a page):
error rate > 1% for 5 min        CPU at 85%
p99 latency > 2s                 one pod restarted
queue age > 10 min               disk at 70%
```

Cause-based alerts fire when nothing is wrong and miss failures you didn't predict. Symptom-based
alerts fire exactly when users are hurt.

Rules for every alert:
1. **It must be actionable.** If the response is "ignore it", delete the alert.
2. **It links to a runbook** — even three lines: what it means, first query, escalation path.
3. **It has a threshold and duration** justified by the SLO or by historical data.
4. Use two severities: **page** (user-facing, act now) and **ticket** (degradation, act this week).

## 7. Verify the telemetry itself

Instrumentation is code; it can be wrong. Before calling the work done:

- Force an error in staging → find it in the logs by `requestId`, confirm fields are structured
- Send test traffic → confirm metric series appear with the expected labels and sane values
- Follow one request across services in the tracing UI → no broken spans
- Fire each new alert once (lower threshold temporarily) → confirm it reaches the right channel
  and the runbook link works
