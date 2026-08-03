# Review Authority Threat Model

## Overview

This document defines the trust boundaries, threat vectors, and security assumptions for Gentle-Vanguard's code review system. Based on the [Gentle AI Review Authority Threat Model](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/review-authority-threat-model.md).

## Assumptions

1. **Local Actor Trust** — The system is not designed to defend against a malicious local actor with full git/environment control
2. **Accidental Drift** — Review protects against accidental scope or identity drift, not intentional circumvention
3. **Git Source of Truth** — The Git candidate (SHA, staged index) is the authoritative source for review scope
4. **Bounded Review** — Reviews are scoped to specific candidates and cannot retroactively change

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│                        AUTHOR                                    │
│  Creates change, runs self-review, submits for review          │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                       REVIEWER                                   │
│  Validates against spec, issues content-bound receipt          │
│  - Verifies candidate matches expectation                       │
│  - Checks all findings addressed                                │
│  - Signs receipt with candidate hash                           │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SYSTEM                                    │
│  Binds receipt to Git candidate, enforces delivery gates       │
│  - Stores receipt with candidate SHA                           │
│  - Validates delivery matches receipt                          │
│  - Prevents receipt reuse on different candidates              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DELIVERY                                    │
│  Commit, push, PR — validates receipt against live Git state   │
│  - Fails if candidate SHA changed                               │
│  - Fails if staged index differs                                │
│  - Requires fresh receipt for new candidate                    │
└─────────────────────────────────────────────────────────────────┘
```

## Threat Vectors

### 1. Scope Drift

**Description:** Change grows beyond original review scope

**Example:** Reviewer approves receipt for feature X, but commits also include unrelated changes Y and Z

**Mitigation:**
- Receipt binds to specific file list
- Delivery validates staged index matches receipt
- Staged-only review excludes worktree changes

**Severity:** MEDIUM — Can be detected at delivery time

### 2. Identity Drift

**Description:** Receipt references wrong candidate

**Example:** Review happens on commit A, but delivery uses commit B (different SHA)

**Mitigation:**
- Receipt includes candidate SHA
- Delivery validates SHA match
- Git re-checks remote HEAD before push

**Severity:** HIGH — Requires system-level validation

### 3. Timing (TOCTOU)

**Description:** Time-of-check to time-of-use vulnerability

**Example:** Review approves, but between approval and commit, someone force-pushes and changes history

**Mitigation:**
- Re-validate receipt against current HEAD before push
- Require exact SHA match, not just ancestry
- Protected branches prevent force-push

**Severity:** HIGH — Requires atomic delivery validation

### 4. Staged Index Manipulation

**Description:** Staged files differ from reviewed content

**Example:** Review approves staged changes, but user adds more files to staging before commit

**Mitigation:**
- Staged review freezes complete index at review time
- Delivery validates exact staged content hash
- Warn on unstaged changes during review

**Severity:** MEDIUM — Detectable via content hash

### 5. Receipt Replay

**Description:** Old receipt reused on new candidate

**Example:** Review approves feature branch, but receipt used on main after cherry-pick

**Mitigation:**
- Receipt includes candidate SHA
- Each delivery requires fresh receipt
- Audit trail of receipt usage

**Severity:** HIGH — Prevented by SHA binding

## Security Properties

| Property | Mechanism | Enforcement |
|----------|-----------|-------------|
| **Non-repudiation** | Receipt signed with candidate hash | System validates on delivery |
| **Integrity** | Content hash in receipt | SHA match required |
| **Freshness** | Timestamp + SHA | No stale receipt reuse |
| **Auditability** | Receipt log with all validations | Immutable audit trail |

## Delivery Gates

### Commit Gate

```bash
# Validate receipt before commit
gentle-ai review validate --receipt <receipt-id>
# Must pass: SHA match, content hash match, approval status
```

### Push Gate

```bash
# Validate before push
gentle-ai review validate --receipt <receipt-id> --check-remote
# Must pass: remote HEAD matches expected, no force-push detected
```

### PR Gate

```bash
# Validate PR state
gentle-ai review validate --receipt <receipt-id> --pr
# Must pass: branch matches, no new commits since approval
```

## Protected Main Fast Path

For releases to protected branches, use the fast path only when ALL conditions met:

1. Exact tag exists
2. Tag SHA matches current `origin/main` SHA
3. CI passed with exact SHA
4. Remote HEAD recheck passes
5. No fresh risk detected (no recent force-pushes)

Otherwise, require full receipt validation.

## References

- [Gentle AI Review Authority Threat Model](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/review-authority-threat-model.md)
- [Chapter 21: Verifiable Trust](https://the-amazing-gentleman-programming-book.vercel.app/en/book/Chapter21_Verifiable-Trust)
- [Review Integration Contract](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/review-integration.md)