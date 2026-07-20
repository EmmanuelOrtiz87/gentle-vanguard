---
name: observability-and-instrumentation
description:
  Instruments code so production behavior is visible and diagnosable. Use when adding logging,
  metrics, tracing, or alerting. Use when shipping any feature that runs in production and you need
  evidence it works. Use when production issues are reported but you can't tell what happened from
  the available data.
---

# Observability and Instrumentation

Code you can't observe is code you can't operate. Instrumentation is not a post-launch add-on.

## When to Use

- Building any feature that will run in production
- Adding a new service, endpoint, background job, or external integration
- A production incident took too long to diagnose
- Reviewing a PR that adds I/O, retries, queues, or cross-service calls

Not for: active debugging (`debugging-and-error-recovery`), performance profiling
(`performance-optimization`), launch checklists (`shipping-and-launch`).

## Process

### 1. Define "working" before instrumenting
Write 2–4 questions an on-call engineer will ask. Telemetry without a question is noise.

### 2. Pick the right signal
Metrics tell you **that** something is wrong, traces tell you **where**, logs tell you **why**.

### 3. Structured logging
Log events as JSON with stable names, correlation IDs, and structured fields. Never log secrets.
See `references/process-guide.md`.

### 4. Metrics
RED for endpoints (Rate, Errors, Duration). USE for resources. Cardinality is the failure mode.
See `references/process-guide.md`.

### 5. Distributed tracing
OpenTelemetry auto-instrumentation. Propagate context across async boundaries.
See `references/process-guide.md`.

### 6. Alerting
Alert on symptoms users feel, not causes. Must be actionable, link a runbook, and have justified
thresholds. See `references/process-guide.md`.

### 7. Verify the telemetry
Trigger the paths; confirm output in staging. See `references/process-guide.md`.

## Red Flags

See `references/common-pitfalls.md`.

## Verification

See `references/observability-checklist.md`.
