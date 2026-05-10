# Output Format Examples

## APPROVED Format

```markdown
## Judgment Day — {target}

### Round {N} — Verdict

| Finding | Judge A | Judge B | Severity | CONFIDENCE | Status |
|---------|---------|---------|----------|------------|--------|
| Missing null check in auth.go:42 | ✓ HIGH | ✓ HIGH | CRITICAL | HIGH/HIGH | Confirmed |
| Race condition in worker.go:88 | ✓ MED |  | WARNING (real) | MED/- | Suspect (A only) |
| Windows volume root edge case |  | ✓ LOW | WARNING (theoretical) | -/LOW | INFO — reported |
| Naming mismatch in handler.go:15 |  | ✓ HIGH | SUGGESTION | -/HIGH | Suspect (B only) |
| Error swallowed in db.go:201 | ✓ HIGH | ✓ MED | WARNING (real) | HIGH/MED | Confirmed |

**Confirmed issues**: 2 CRITICAL (both judges, HIGH confidence)
**Suspect issues**: 1 WARNING (A only, MED), 1 SUGGESTION (B only, HIGH)
**Contradictions**: none
**Minority positions**: See below

### MINORITY POSITIONS (Gemini Principle)
- **Judge A lone finding**: Race condition in worker.go:88 (WARNING, MED confidence) — Judge B did not flag this
- **Judge B lone finding**: Naming mismatch in handler.go:15 (SUGGESTION, HIGH confidence) — Judge A did not flag this
→ These are preserved for manual review. They are NOT auto-fixed.

### Fixes Applied (Round {N})
- `auth.go:42` — Added nil check before dereferencing user pointer
- `db.go:201` — Propagated error instead of silently returning nil

### Round {N+1} — Re-judgment
- Judge A: PASS — No issues found (changed from Round 1: cited fix applied)
- Judge B: PASS — No issues found

**Anti-Sycophancy Check**:
- Judge A changed verdict on auth.go:42 (CRITICAL → PASS) ✅ Cites fix applied (legitimate)
- Judge B changed verdict on db.go:201 (WARNING → PASS) ✅ Cites fix applied (legitimate)
→ No sycophancy detected.

---
### JUDGMENT: APPROVED
Both judges pass clean. The target is cleared for merge.

**Minority positions preserved**:
- Race condition in worker.go:88 (Judge A only) — consider follow-up review
- Naming mismatch in handler.go:15 (Judge B only) — consider follow-up review
```

## ESCALATED Format

```markdown
## Judgment Day — {target}

### JUDGMENT: ESCALATED

User chose to stop after {N} fix iterations. Issues remain.
Manual review required before proceeding.

### Remaining Issues
| Finding | Judge A | Judge B | Severity | CONFIDENCE |
|---------|---------|---------|----------|------------|
| {description} | ✓ HIGH |  | CRITICAL | HIGH/- |

### MINORITY POSITIONS (preserved)
- {lone finding by one judge} — included for transparency

### Anti-Sycophancy Report
- {any judges that changed verdict without evidence? List here}

### History
- Round 1: {N} confirmed issues found
- Fix 1: applied {list}
- Round 2: {N} issues remain
- Fix 2: applied {list}
- Round 3: {N} issues remain — escalated

Recommend: human review of the remaining issues above before re-running judgment day.
```
