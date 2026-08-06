# Review Authority Threat Model

## Overview

This document analyzes the security model of Receipt-Driven Development (RDD) in Gentle-Vanguard.

**Scope**: RDD review authorization system  
**Assumptions**: Local development environment with trusted developers  
**Threat Model**: STRIDE with focus on review integrity

---

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        TRUST BOUNDARIES                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [1] AUTHOR ── Creates change, runs self-review                         │
│          │                                                               │
│          ▼                                                               │
│  [2] LOCAL SYSTEM ── Git working directory                              │
│          │                                                               │
│          ▼                                                               │
│  [3] RDD ORCHESTRATOR ── Risk classify, freeze candidate               │
│          │                                                               │
│          ▼                                                               │
│  [4] REVIEWER ── Validates against spec, issues receipt                 │
│          │                                                               │
│          ▼                                                               │
│  [5] COMPACT AUTHORITY ── Immutable receipt bound to Git SHA            │
│          │                                                               │
│          ▼                                                               │
│  [6] DELIVERY GATES ── Validate receipt against live Git state         │
│          │                                                               │
│          ▼                                                               │
│  [7] REMOTE REPO ── GitHub/GitLab (untrusted boundary)                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Threat Vectors

### S - Spoofing

| Threat            | Description                      | Mitigation                                      |
| ----------------- | -------------------------------- | ----------------------------------------------- |
| Identity spoofing | Attacker impersonates reviewer   | Receipts signed with author + reviewer identity |
| Git spoofing      | Commit author field spoofed      | Verify GPG signatures if required               |
| Tool spoofing     | Malicious receipt-manager script | Hash verification of scripts                    |

**Mitigation**: Author + reviewer in receipt; optional GPG verification.

---

### T - Tampering

| Threat                | Description                         | Mitigation                             |
| --------------------- | ----------------------------------- | -------------------------------------- |
| Scope drift           | Change grows beyond original intent | Receipt bound to specific Git tree SHA |
| Identity drift        | Receipt references wrong candidate  | Content-hash verification at gates     |
| Post-review tampering | Code changed after review           | SHA mismatch detected at gates         |
| Receipt tampering     | Malicious modification of receipt   | Content-hash + signature               |

**Mitigation**: Content-bound receipts with SHA-256 of file contents.

---

### R - Repudiation

| Threat                   | Description                    | Mitigation                       |
| ------------------------ | ------------------------------ | -------------------------------- |
| Reviewer denies approval | Claim receipt is forged        | Immutable receipt with timestamp |
| Author claims unreviewed | Bypass review process          | Gate validation requires receipt |
| Break-glass abuse        | Emergency bypass without audit | Audit log of all bypasses        |

**Mitigation**: Receipts stored permanently; audit log in `.session/rdd-gates/`.

---

### I - Information Disclosure

| Threat              | Description               | Mitigation                           |
| ------------------- | ------------------------- | ------------------------------------ |
| Receipt exposure    | Sensitive findings leaked | Receipts stored locally, not in git  |
| Review notes leaked | Security issues exposed   | Classification of findings           |
| Gate logs exposed   | TOCTOU attack info        | Permissions on `.session/` directory |

**Mitigation**: Receipts in `.session/` (gitignored); minimal logging.

---

### D - Denial of Service

| Threat             | Description                  | Mitigation                   |
| ------------------ | ---------------------------- | ---------------------------- |
| Review blocking    | Preventing review completion | Timeouts; manual override    |
| Gate blocking      | Blocking delivery            | Emergency bypass with reason |
| Receipt corruption | Corrupting receipt store     | Backups in Nexus DB          |

**Mitigation**: Emergency bypass; redundant storage.

---

### E - Elevation of Privilege

| Threat            | Description                  | Mitigation                      |
| ----------------- | ---------------------------- | ------------------------------- |
| Bypass gates      | Circumventing RDD validation | Git hooks + mandatory gates     |
| Forge receipt     | Creating fake approval       | Content-hash verification       |
| Kill switch abuse | Disabling RDD arbitrarily    | Requires explicit file creation |

**Mitigation**: Content-bound receipts cannot be forged.

---

## TOCTOU (Time of Check to Time of Use)

### The Problem

```
T0: Review checks code at SHA A
T1: Code modified to SHA B
T2: Receipt for SHA A used to approve SHA B
```

### Mitigation

Every gate validates:

1. **Receipt exists** → post-apply
2. **SHA matches** → pre-commit
3. **SHA in history** → pre-push
4. **Tree hash matches** → pre-pr
5. **Exact match** → release

```
gate validation:
  post-apply:    receipt exists
  pre-commit:    HEAD == candidateHash
  pre-push:      candidateHash ∈ git history
  pre-pr:        tree(HEAD) == tree(candidateHash)
  release:       HEAD == candidateHash AND tree exact
```

---

## Receipt Binding

### Content-Bound Receipt

```typescript
receipt = {
  id: "rcpt-{timestamp}",
  candidateHash: git rev-parse HEAD,           // Git SHA
  contentHash: SHA256(file contents),          // Content hash
  author: git log -1 --format="%an",
  timestamp: ISO8601,
  approved: boolean,
  findings: [...],
}
```

### Validation at Gates

```typescript
validate(gate, receipt):
  if gate == "pre-commit":
    assert receipt.candidateHash == git rev-parse HEAD
    assert receipt.contentHash == SHA256(current files)

  if gate == "release":
    assert receipt.approved == true
    assert no critical findings
    assert receipt.candidateHash == git rev-parse HEAD
```

---

## Kill Switch Safety

### Emergency Disable

```bash
# Create disable flag
> .session/rdd/DISABLED

# Content: reason for disable
echo "Emergency hotfix" > .session/rdd/DISABLED
```

### Safety Measures

1. **Audit**: Disable logged to `.session/rdd/disable-log.jsonl`
2. **Expiry**: Max 24 hours before requiring re-enable
3. **Alert**: Dashboard notification when disabled
4. **Visibility**: `rdd:status` shows DISABLED prominently

---

## Break-Glass Override

### Emergency Bypass

```bash
# Bypass with reason
GIT_COMMIT_MESSAGE="RDD-BYPASS: Emergency security fix"
git commit -m "$GIT_COMMIT_MESSAGE"
```

### Audit Requirements

- Reason must be in commit message
- Logged to `.session/rdd/bypass-log.jsonl`
- Requires 2nd reviewer within 24 hours
- Alert to dashboard

---

## Residual Risks

| Risk                    | Likelihood | Impact | Mitigation           |
| ----------------------- | ---------- | ------ | -------------------- |
| Malicious author        | Low        | High   | Peer review required |
| Compromised workstation | Low        | High   | GPG signatures       |
| Review fatigue          | Medium     | Medium | Automated detection  |
| Gate bypass via CI      | Medium     | High   | CI gates validation  |

---

## Recommendations

1. **Enable GPG signing** for commits in high-risk environments
2. **Multiple reviewers** for Tier 2 (4R) changes
3. **Regular audit** of bypass logs
4. **Backup receipts** to Nexus DB for recovery
5. **Training** on break-glass procedures

---

## References

- Gentle-AI Review Authority Threat Model (github.com/Gentleman-Programming/gentle-ai)
- STRIDE: Spoofing, Tampering, Repudiation, Info disclosure, DoS, Elevation
- `.opencode/skills/review-driven-development/SKILL.md`
- `src/rdd/rdd-gates.ts` — Gate validation implementation
