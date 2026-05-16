# Inter-Agent Communication Protocol

**Version:** 1.0.0
**Last updated:** 2026-05-14
**Applies to:** All agent-to-agent calls via `auto-delegation-router`, `sdd-orchestrator`, and `gv.ps1 agent`

---

## 1. Purpose

Define a formal protocol for communication between AI agents in the gentle-vanguard stack. This ensures:
- Deterministic handoffs (agent A → agent B produces same result for same input)
- Error isolation (agent B failure does not cascade to agent A)
- Observability (every call is logged with source, target, duration, result)
- Circuit breaking (repeated failures suspend agent access)

---

## 2. Agent Roles

| Role | Code | Responsibility |
|------|------|---------------|
| Orchestrator | ORCH | Routes tasks, manages lifecycle, enforces policies |
| Business Analyst | BA | Requirements gathering, exploration, SDD lifecycle |
| Software Architect | SAD | System design, API contracts, architecture decisions |
| Developer | DEV | Code generation, implementation, refactoring |
| QA / Verifier | QA | Testing, validation, quality gates |
| Operations | OPS | CI/CD, deployment, infrastructure |
| Governance | GOV | Policy enforcement, audit, compliance |
| Documentation | DOC | Technical writing, changelogs, guides |

---

## 3. Communication Contract

Every inter-agent call MUST follow this contract:

### Request Format
```json
{
  "source": "BA",
  "target": "DEV",
  "correlationId": "uuid",
  "task": {
    "type": "implement|review|design|analyze",
    "description": "Clear description of what to do",
    "context": "Relevant context for the task",
    "constraints": ["Security first", "No external dependencies"],
    "outputFormat": "code|json|markdown|diff",
    "deadline": "ISO8601 timestamp or null"
  },
  "metadata": {
    "sessionId": "session-xxx",
    "modelTier": "T1|T2|T3",
    "tokenBudget": 750
  }
}
```

### Response Format
```json
{
  "source": "DEV",
  "target": "BA",
  "correlationId": "uuid",
  "status": "success|failure|partial",
  "result": {
    "output": "The actual result content",
    "filesChanged": ["path/to/file.ps1"],
    "testResults": "passed|failed|not_run"
  },
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description",
    "recoverable": true|false
  },
  "metrics": {
    "durationMs": 1234,
    "tokensUsed": 500,
    "toolCalls": 12
  }
}
```

---

## 4. Circuit Breaker Pattern

Each agent-target pair has a circuit breaker that tracks failures.

### States
| State | Meaning | Behavior |
|-------|---------|----------|
| **CLOSED** | Normal operation | Calls pass through |
| **OPEN** | Too many failures | Calls blocked immediately |
| **HALF_OPEN** | Testing recovery | One call allowed; if OK → CLOSED, if fail → OPEN |

### Configuration (in orchestrator.json)
```json
{
  "circuitBreaker": {
    "failureThreshold": 3,
    "resetTimeoutSeconds": 300,
    "halfOpenMaxCalls": 1,
    "exceptions": ["timeout", "hallucination", "evidence_missing"]
  }
}
```

### Behavior
1. Each agent call tracks success/failure
2. After `failureThreshold` consecutive failures → circuit OPENS
3. While OPEN → calls return error immediately (no agent invocation)
4. After `resetTimeoutSeconds` → circuit moves to HALF_OPEN
5. In HALF_OPEN, one call is allowed:
   - Success → CLOSED (normal operation resumes)
   - Failure → OPEN again with doubled timeout

### Circuit Breaker States by Agent Pair (Current)

| Source → Target | State | Failures | Last Failure |
|----------------|-------|----------|-------------|
| ORCH → BA | CLOSED | 0 | - |
| ORCH → DEV | CLOSED | 0 | - |
| ORCH → QA | CLOSED | 0 | - |
| BA → SAD | CLOSED | 0 | - |
| SAD → DEV | CLOSED | 0 | - |
| DEV → QA | CLOSED | 0 | - |

---

## 5. Error Handling & Escalation

### Error Types
| Code | Meaning | Action |
|------|---------|--------|
| `TIMEOUT` | Agent did not respond in time | Retry (1x), then escalate |
| `HALLUCINATION` | Agent output contained hallucinations | Retry with stricter constraints |
| `EVIDENCE_MISSING` | Agent could not verify its output | Escalate to human |
| `TOOL_FAILURE` | Tool call failed | Retry (3x with backoff) |
| `BUDGET_EXCEEDED` | Token budget exhausted | Escalate to orchestrator |

### Escalation Chain
```
Agent failure → self-retry (1-3x) → escalateOnFailure → orchestrator → human
```

---

## 6. Observability

Every inter-agent call MUST be logged:
- **What**: correlationId, source, target, task type, duration, tokens, result
- **Where**: `.session/inter-agent-calls.jsonl` (append-only JSONL)
- **When**: At call completion (success or failure)
- **Alerting**: If error rate > 5% in any 1-hour window

### Log Format
```json
{
  "timestamp": "2026-05-14T21:30:00Z",
  "correlationId": "uuid",
  "source": "BA",
  "target": "DEV",
  "taskType": "implement",
  "durationMs": 4500,
  "tokensUsed": 750,
  "toolCalls": 15,
  "status": "success",
  "circuitState": "CLOSED"
}
```

---

## 7. Agent-to-Agent Validation Rules

| Rule | Enforced By | Action on Violation |
|------|------------|-------------------|
| Every call has correlationId | Pre-call validation | Block call |
| Source and target are valid agent roles | Pre-call validation | Block call |
| Token budget is specified | Pre-call validation | Default to 750 |
| Response matches output format | Post-call validation | Log warning, attempt repair |
| Duration < timeout | Runtime | Kill agent, escalate |
| Error is classified | Post-call validation | Log as `UNKNOWN_ERROR` |
| Circuit breaker respected | Pre-call validation | Block if OPEN |

---

## 8. References

| Resource | Path |
|----------|------|
| Auto-Delegation Router | `scripts/utilities/AI-AGENT-MANAGEMENT/auto-delegation-router.ps1` |
| Orchestrator Config | `config/orchestrator.json` |
| Error Handling | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Performance | `rules/NORMATIVAS-PERFORMANCE.md` |
| AI Normatives | `rules/AI-NORMATIVES.md` |
| Session Metrics Tracker | `scripts/utilities/session-metrics-tracker.ps1` |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_

