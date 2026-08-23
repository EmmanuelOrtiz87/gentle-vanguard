---
name: agent-audit-logging-skill
description: >
  Imported from mercury-agent-skills. Use when working with "audit logging", "compliance",
  "observability", "agent tracing". Triggers: "audit logging", "compliance", "observability", "agent
  tracing".
metadata:
  source: mercury-agent-skills
  original-name: agent-audit-logging
---

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

## Usage

Use **agent-audit-logging-skill** when a task matches its triggers (agent-audit-logging-skill).

Purpose: Imported from mercury-agent-skills.

## Examples

Concrete usage drawn from this skill's own documentation:

```python
from audit_logger import AuditLogger, AuditEvent, EventType

logger = AuditLogger(storage_backend)
await logger.log_invocation("support-agent", "process refund", session_id)
await logger.log_tool_call("support-agent", "get_order", {"order_id": 123}, trace_id)
await logger.log_decision("support-agent", "escalate", "refund exceeds threshold", 0.85, trace_id)
```
