# Human-in-the-Loop Gates

**Version:** 1.0.0 | **Date:** 2026-07-04 | **Status:** Active

## Purpose

Define when human approval is required before AI agents can proceed with actions. Ensures safety,
security, and quality for high-impact operations.

---

## Gate Classification

### Gate Levels

| Level | Name    | Description                             | Response Time    |
| ----- | ------- | --------------------------------------- | ---------------- |
| G0    | Auto    | No approval needed, agent proceeds      | Immediate        |
| G1    | Notify  | Agent proceeds, human notified          | None (info only) |
| G2    | Confirm | Agent asks, human confirms              | < 5 minutes      |
| G3    | Approve | Agent pauses, human approves            | < 1 hour         |
| G4    | Block   | Agent stops, requires explicit approval | < 24 hours       |

---

## Action Classification

### G0 — Auto (No Approval)

| Action               | Rationale       |
| -------------------- | --------------- |
| Read files           | Non-destructive |
| Run tests            | Non-destructive |
| Generate code        | Reversible      |
| Search codebase      | Non-destructive |
| Create documentation | Non-destructive |
| Run linting          | Non-destructive |

### G1 — Notify (Proceed + Inform)

| Action              | Rationale          |
| ------------------- | ------------------ |
| Git commit          | Logged, reversible |
| Git push            | Logged, reversible |
| Create branch       | Non-destructive    |
| Update dependencies | Logged, testable   |
| Run CI pipeline     | Non-destructive    |

### G2 — Confirm (Ask Before)

| Action                  | Rationale                 |
| ----------------------- | ------------------------- |
| Delete files            | Potentially destructive   |
| Force push              | Destructive, irreversible |
| Modify config files     | May affect system         |
| Run database migrations | May affect data           |
| Install new packages    | May affect security       |

### G3 — Approve (Pause Before)

| Action                   | Rationale               |
| ------------------------ | ----------------------- |
| Modify security policies | High security impact    |
| Modify authentication    | High security impact    |
| Change access controls   | High security impact    |
| Deploy to production     | High business impact    |
| Modify CI/CD pipeline    | High operational impact |

### G4 — Block (Explicit Approval Required)

| Action                       | Rationale                |
| ---------------------------- | ------------------------ |
| Disable security controls    | Critical security impact |
| Modify owner authentication  | Critical security impact |
| Purge audit logs             | Compliance violation     |
| Execute destructive commands | Data loss risk           |
| Modify trusted-users-policy  | Critical security impact |

---

## Confidence-Based Gates

### Confidence Thresholds

| Confidence Score | Gate Level | Action                           |
| ---------------- | ---------- | -------------------------------- |
| > 0.9            | G0         | Auto-proceed                     |
| 0.7 - 0.9        | G1         | Proceed + notify                 |
| 0.5 - 0.7        | G2         | Ask for confirmation             |
| 0.3 - 0.5        | G3         | Pause for approval               |
| < 0.3            | G4         | Block, require explicit approval |

### When Confidence is Low

1. Agent MUST NOT guess or assume
2. Agent MUST ask for clarification
3. Agent MUST present options to human
4. Agent MUST wait for explicit direction

---

## Escalation Paths

### Automatic Escalation

| Condition                   | Escalation        |
| --------------------------- | ----------------- |
| No response in 5 min (G2)   | Escalate to G3    |
| No response in 1 hour (G3)  | Escalate to G4    |
| Security violation detected | Immediate G4      |
| Confidence < 0.3            | Immediate G4      |
| Multiple failures in row    | Escalate severity |

### Escalation Contacts

| Severity | Contact           | Channel           |
| -------- | ----------------- | ----------------- |
| CRITICAL | System Owner      | PagerDuty + Slack |
| HIGH     | Tech Lead         | Slack             |
| MEDIUM   | Assigned Engineer | Slack             |
| LOW      | Team Channel      | Email             |

---

## Agent Behavior Rules

### Mandatory Rules

1. **Never guess** — If unsure, ask
2. **Never assume** — Verify before acting
3. **Never skip gates** — Gates are mandatory, not optional
4. **Always log** — Record all gate decisions
5. **Always explain** — Tell human what you're about to do

### Gate Response Format

```
🔒 GATE LEVEL: G{level}
ACTION: {action_description}
RISK: {risk_assessment}
CONFIDENCE: {confidence_score}
OPTIONS:
  1. {option_1}
  2. {option_2}
  3. {option_3}
AWAITING: Your approval to proceed
```

### Gate Decision Logging

```json
{
  "timestamp": "2026-07-04T10:30:00Z",
  "agent": "DEV-apply",
  "session_id": "session-123",
  "action": "delete-file",
  "target": "src/old-file.ts",
  <!-- REF-OBSOLETA: src/old-file.ts no existe (ruta migrada o eliminada) -->
  "gate_level": 2,
  "confidence": 0.65,
  "human_decision": "approved",
  "human_id": "user-456",
  "reasoning": "File confirmed as unused"
}
```

---

## Integration with Security

### Security Policy Alignment

| Security Rule           | Gate Level |
| ----------------------- | ---------- |
| security.disable        | G4         |
| security.modify         | G3         |
| security.disable.Block  | G4         |
| orchestrator.disable    | G3         |
| config.strategic.modify | G3         |
| api-keys.modify         | G4         |
| session.requireAuth     | G3         |

### OWASP LLM06 Prevention

- Grant agents ONLY minimum necessary tools
- Implement permission scoping per tool
- Require human-in-the-loop for high-impact actions
- Rate limiting per tool

---

## Dashboard Integration

### Real-Time Gate Status

The dashboard shows:

- Pending gate approvals
- Gate decision history
- Average approval time
- Escalation count
- Confidence distribution

### Gate Metrics

| Metric            | Definition            | Target  |
| ----------------- | --------------------- | ------- |
| Approval Rate     | % of gates approved   | > 90%   |
| Avg Response Time | Time to approve       | < 5 min |
| Escalation Rate   | % of gates escalated  | < 10%   |
| Override Rate     | % of gates overridden | < 5%    |

---

## Enforcement

1. **pre-process-input.ps1** evaluates gate level before actions
2. **security-orchestrator.ps1** enforces security gates
3. **privacy-gateway.ps1** enforces privacy gates
4. **audit-pipeline.ps1** logs all gate decisions
5. **dashboard** displays gate status

---

## Related Files

- `scripts/security/security-orchestrator.ps1`
- `scripts/security/privacy-gateway.ps1`
- `src/pre-process-input.ts`
- `config/security-policy.json`
- `rules/NORMATIVAS-SECURITY-COMPLIANCE.md`
- `rules/DELEGATION-RULES.md`
