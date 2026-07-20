# Example: Production Outage

```markdown
# Five Whys Plus: Payment Service Outage

## Problem Statement

- What: Payment service returned 500 errors
- When: 2024-01-15 14:00-14:45 UTC
- Where: Production, US-East region
- Impact: 2,400 failed transactions, ~$180K revenue impact

## Why Chain

### Why #1: Why did payment service return 500 errors?

**Answer:** Database connection pool exhausted **Evidence:** Connection pool metrics showed 100/100
in use, logs show "connection wait timeout" **Confidence:** High **What else considered:**

- Application bugs (no recent deploys)
- Memory issues (heap normal)
- Network problems (latency normal)

### Why #2: Why was connection pool exhausted?

**Answer:** Queries taking 10x longer than normal **Evidence:** P99 query time went from 50ms to
500ms at 14:00 **Confidence:** High **What else considered:**

- Connection leak (connection count stable before incident)
- Sudden traffic spike (traffic was normal)

### Why #3: Why were queries taking 10x longer?

**Answer:** Missing index on payment_status table **Evidence:** EXPLAIN shows sequential scan on 10M
row table **Confidence:** High **What else considered:**

- Lock contention (no blocking locks)
- DB resource exhaustion (CPU/memory normal)

### Why #4: Why was the index missing?

**Answer:** Migration to add index was rolled back 2 weeks ago **Evidence:** Deployment logs show
rollback on 2024-01-01 **Confidence:** High

### Why #5: Why was the migration rolled back?

**Answer:** Migration timed out during deploy window **Evidence:** Deploy log shows "migration
timeout after 30 minutes"

### Why #6: Why did migration timeout?

**Answer:** Table too large for online migration in current window **Evidence:** Table has 10M rows,
online migration takes ~2 hours **Confidence:** High

### Why #7 (System-level): Why wasn't this caught before impact?

**Answer:** No alerting on query performance degradation **Evidence:** No alerts fired until
connection pool exhausted

## Stopping Criteria Check

- [x] Actionable: Can add index, fix alerting
- [x] Controllable: Within our control
- [x] Fundamental: Index prevents query issue, alerting prevents impact
- [x] Evidenced: All steps have supporting data
- [x] System-focused: Process and tooling issues, not blame

## Root Causes Identified

1. **Primary:** Index migration process doesn't handle large tables
2. **Contributing:** No alerting on query latency before connection exhaustion

## Recommended Actions

| Action                                 | Addresses     | Owner    | Timeline |
| -------------------------------------- | ------------- | -------- | -------- |
| Implement online index creation tool   | Root cause 1  | Platform | 2 weeks  |
| Add query latency alerting             | Root cause 2  | SRE      | 1 week   |
| Create index during maintenance window | Immediate fix | DBA      | Tonight  |
```
