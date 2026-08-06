# agent-audit-logging-skill

> Gentle-Vanguard Skill

## Description

>

## Triggers

## Instructions

# Agent Audit Log Reporting

When agents make decisions, take actions, and spend money, every step must be traceable. Audit logs
answer questions like: "What did the agent do?", "Why did it do that?", "Who asked for it?", and
"Can we prove it followed the rules?" This skill covers event sourcing, structured logging,
traceability chains, compliance reporting, and forensic analysis for production multi-agent systems.

## References

Detailed content is split into focused reference files under `references/`:

| File                                          | Contents                                                                       |
| --------------------------------------------- | ------------------------------------------------------------------------------ |
| `references/01-core-concepts.md`              | Why audit logging matters, what to log (priority tables)                       |
| `references/02-implementation.md`             | Full Python code: schema, logger, traceability, compliance, dashboard, storage |
| `references/03-report-templates.md`           | Daily audit summary, incident forensics report templates                       |
| `references/04-triggers-and-anti-patterns.md` | Trigger phrases table, anti-patterns table                                     |

## Quick Start

```python
from audit_logger import AuditLogger, AuditEvent, EventType

logger = AuditLogger(storage_backend)
await logger.log_invocation("support-agent", "process refund", session_id)
await logger.log_tool_call("support-agent", "get_order", {"order_id": 123}, trace_id)
await logger.log_decision("support-agent", "escalate", "refund exceeds threshold", 0.85, trace_id)
```
