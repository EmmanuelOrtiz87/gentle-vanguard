# Inter-Agent Communication Protocol

**Version:** 1.1.0 **Last updated:** 2026-05-23

---

## 1. Purpose

Formal protocol for agent-to-agent calls: deterministic handoffs, error isolation, observability,
circuit breaking.

---

## 2. Agent Roles

| Code | Role               | Responsibility                    |
| ---- | ------------------ | --------------------------------- |
| ORCH | Orchestrator       | Routes tasks, lifecycle, policies |
| BA   | Business Analyst   | Requirements, exploration, SDD    |
| SAD  | Software Architect | System design, API contracts      |
| DEV  | Developer          | Code, implementation, refactoring |
| QA   | Verifier           | Testing, validation, gates        |
| OPS  | Operations         | CI/CD, deployment, infra          |
| GOV  | Governance         | Policy, audit, compliance         |
| DOC  | Documentation      | Writing, guides                   |

---

## 3. Communication Contract

Every call: source, target, correlationId, task (type, description, context, constraints), metadata
(sessionId, modelTier, tokenBudget).

Response: source, target, status (success|failure|partial), result (output, filesChanged,
testResults), error (code, message, recoverable), metrics (durationMs, tokensUsed, toolCalls).

See `config/orchestrator.json` for full schema.

---

## 4. Circuit Breaker

States: CLOSED (normal) → OPEN (3 failures) → HALF_OPEN (after 300s) → CLOSED if ok, OPEN if fail.

Config: `config/circuit-breaker.json`. State tracked in `.session/inter-agent-state.json`.

---

## 5. Error Handling

| Code             | Action                          |
| ---------------- | ------------------------------- |
| TIMEOUT          | Retry 1x → escalate             |
| HALLUCINATION    | Retry with stricter constraints |
| EVIDENCE_MISSING | Escalate to human               |
| TOOL_FAILURE     | Retry 3x with backoff           |
| BUDGET_EXCEEDED  | Escalate to orchestrator        |

Escalation chain: Agent → self-retry (1-3x) → escalateOnFailure → orchestrator → human

---

## 6. Observability

Log every call to `.session/inter-agent-calls.jsonl` (append-only JSONL). Fields: timestamp,
correlationId, source, target, taskType, durationMs, tokensUsed, toolCalls, status, circuitState.
Alert if error rate > 5% in 1h window.

---

## 7. Validation

- Every call has correlationId, valid source/target, token budget
- Response format validated post-call
- Circuit breaker respected (block if OPEN)

---

## 8. References

| Resource            | Path                                 |
| ------------------- | ------------------------------------ |
| Orchestrator Config | `config/orchestrator.json`           |
| Circuit Breaker     | `config/circuit-breaker.json`        |
| Error Handling      | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Performance         | `rules/NORMATIVAS-PERFORMANCE.md`    |

---

_Version: 1.1.0 — 2026-05-23 — Status: ACTIVE_
