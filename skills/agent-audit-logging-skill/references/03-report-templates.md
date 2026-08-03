# Audit Report Templates

## Daily Audit Summary

```markdown
# Agent Audit Summary — {date}

## Overview
- **Total Invocations**: 1,247
- **Successful**: 1,198 (96.1%)
- **Failed**: 49 (3.9%)
- **Handoffs**: 87
- **Human Escalations**: 12

## Top Agents by Activity
| Agent          | Invocations | Errors | Avg Duration |
| -------------- | ----------- | ------ | ------------ |
| Support Agent  | 534         | 12     | 2.3s         |
| Research Agent | 312         | 8      | 8.1s         |
| Code Agent     | 401         | 29     | 4.7s         |

## Error Summary
- **TimeoutError**: 23 (46.9%)
- **RateLimitError**: 14 (28.6%)
- **ValidationError**: 12 (24.5%)

## Compliance Checks
- ✅ Human escalation rate within threshold
- ✅ Tool approval rate 100%
- ✅ Data access logged for all operations
- ⚠️ Token budget at 87% — review recommended
```

## Incident Forensics Report

```markdown
# Incident Forensics — Trace {trace_id}

## Timeline
| Time     | Agent   | Action                    | Duration | Status     |
| -------- | ------- | ------------------------- | -------- | ---------- |
| 14:23:01 | Router  | Task received             | 0ms      | ✅         |
| 14:23:02 | Support | Reasoning about refund    | 1.2s     | ✅         |
| 14:23:03 | Support | Tool call: get_order      | 0.3s     | ✅         |
| 14:23:04 | Support | Decision: escalate        | 0.5s     | ✅         |
| 14:23:05 | Support | Handoff to Billing        | 0.1s     | ✅         |
| 14:23:06 | Billing | Tool call: process_refund | 12.3s    | ❌ Timeout |
| 14:23:19 | Billing | Retry: process_refund     | 12.1s    | ❌ Timeout |
| 14:23:33 | Billing | Circuit breaker OPEN      | 0ms      | ⚠️         |
| 14:23:34 | Billing | Degraded to fallback      | 0.2s     | ✅         |
| 14:23:35 | Billing | Human escalation          | 0.1s     | ✅         |

## Root Cause
The `process_refund` API was down (503 errors). The circuit breaker correctly opened after 2
failures, and the agent degraded to a fallback path before escalating to a human operator.

## Recommendations
1. Increase `process_refund` timeout from 10s to 30s
2. Add a cached fallback for refund status checks
3. Set up PagerDuty alert for `process_refund` failures
```
