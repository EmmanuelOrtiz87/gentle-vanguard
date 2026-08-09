---
name: SKILL.md
aliases: []
description: >
  
triggers:
  - 
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T21:55:57.083Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\review-driven-development\SKILL.md
  version: "1.0.0"
---

## Workflow

```
1. START WORKFLOW ───────────────┐
                                  │
2. CLASSIFY RISK (evidence-based) │
   └─ Tier 0: Low     → Skip review
   └─ Tier 1: Standard → 1 lens
   └─ Tier 2: High    → 4R review
                                  │
3. REVIEW (0/1/4 lenses)           │
   └─ 4R = Risk, Readability,
          Reliability, Resilience
                                  │
4. ISSUE RECEIPT ─────────────────┘
                                  │
5. VALIDATE GATES
   └─ post-apply
   └─ pre-commit
   └─ pre-push
   └─ pre-pr
   └─ release
```

---

## Commands

```bash
# Start RDD workflow
npm run rdd:start

# Classify risk
npm run rdd:risk

# Run 4R review
npm run rdd:4r -- --receipt=<id>

# Validate gate
npm run rdd:gate -- pre-commit [--receipt=<id>]

# Check status
npm run rdd:status

# Install git hooks
npm run rdd:install-hooks
```

---

## 4R Review Lenses

### RISK

Security, safety, and dangerous behavior.

- Input validation
- No injection vulnerabilities
- No hardcoded secrets
- Auth/authorization checks
- Encryption compliance

### READABILITY

Clarity and maintainability.

- Clear naming
- Comments
- No magic numbers
- Consistent style
- Dead code removal

### RELIABILITY

Correctness and edge cases.

- Unit tests cover paths
- Type safety
- No race conditions
- Null handling
- Build passes

### RESILIENCE

Failure modes and recovery.

- Error handling
- Graceful degradation
- Timeouts on external calls
- Circuit breakers
- Rollback plan

---

## Integration with SDD

RDD complements SDD:

- **SDD**: Plan and design (explore → propose → spec)
- **RDD**: Authorize review (classify → review → receipt)

```
SDD Explore ──────┐
SDD Propose ──────┤
SDD Design ───────┼─ Freeze Candidate ───┐
                  │                      │
                  │              RDD Classify
                  │                      │
SDD Apply ────────┴─ Implement ────────┤
                                       │
                              RDD Review (0/1/4R)
                                       │
                              RDD Receipt Issued
                                       │
                              RDD Gates Validation
                                       │
                                   APPROVED ✅
```

---

## Files

| File                         | Purpose                            |
| ---------------------------- | ---------------------------------- |
| `src/rdd/rdd-core.ts`        | Main coordinator                   |
| `src/rdd/risk-classifier.ts` | Evidence-based risk classification |
| `src/rdd/rdd-4r-review.ts`   | 4 lenses auto-review               |
| `src/rdd/rdd-gates.ts`       | 5 delivery gates                   |
| `.session/receipts/*.json`   | Stored receipts                    |
| `.session/rdd/*.json`        | Workflow state                     |
| `.session/rdd-gates/*.json`  | Gate validations                   |

---

## Safety

### Kill Switch

Disable RDD for emergencies:

```bash
# Create disable flag
> .session/rdd/DISABLED

# Re-enable
rm .session/rdd/DISABLED
```

### Bypassing Gates

Emergency bypass with reason:

```bash
# Requires GIT commit message with:
# RDD-BYPASS: <reason>
```

---

## References

- `rules/DELEGATION-RULES.md`
- `rules/REVIEW-AUTHORITY-THREAT-MODEL.md`
- `config/orchestrator.json`

---

## Philosophy

> Every code change gets a receipt. Every receipt validates at gates. Risk is evidence, not lines of
> code. The code is the source of truth.
