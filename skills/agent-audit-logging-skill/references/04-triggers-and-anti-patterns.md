# Trigger Phrases & Anti-Patterns

## Trigger Phrases

| Phrase                       | Action                                  |
| ---------------------------- | --------------------------------------- |
| "Show me the audit log"      | Display recent audit events             |
| "Trace task [id]"            | Show full trace for a specific task     |
| "Generate compliance report" | Build compliance report for time period |
| "What did the agent do?"     | Show action timeline for a session      |
| "Show error summary"         | Aggregate and display recent errors     |
| "Audit agent [name]"         | Show all activity for a specific agent  |
| "Run forensic analysis"      | Deep dive into an incident trace        |
| "Export audit data"          | Export logs for external compliance     |

## Anti-Patterns

| Anti-Pattern                    | Why It Fails                           | Fix                               |
| ------------------------------- | -------------------------------------- | --------------------------------- |
| Logging everything in one table | Queries are slow, impossible to prune  | Partition by date + tier          |
| No structured schema            | Can't query or analyze logs            | Defined AuditEvent schema         |
| Synchronous logging             | Slows down agent responses             | Async buffered writes             |
| No retention policy             | Storage grows unbounded, costs explode | TTL-based retention tiers         |
| Logging only errors             | No trace of normal operation           | Log all events, not just failures |
| No trace IDs                    | Can't connect related events           | Always propagate trace_id         |
| PII in logs                     | Compliance violations                  | Strip or hash PII before logging  |
