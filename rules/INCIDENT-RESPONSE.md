# Incident Response Runbook

**Version:** 1.0.0
**Last updated:** 2026-05-14
**Applies to:** All foundation infrastructure, CI/CD, AI agents, and production systems

---

## 1. Severity Definitions

| Severity | Label | Response Time | Examples |
|----------|-------|---------------|----------|
| **SEV1** | 🔴 Critical | 15 min | Security breach, data loss, production down, secrets leaked |
| **SEV2** | 🟡 High | 1 hour | CI/CD broken, test suite red, quality gate bypassed |
| **SEV3** | 🔵 Medium | 4 hours | Non-critical bug, performance degradation, doc errors |
| **SEV4** | ⚪ Low | 24 hours | Cosmetic issues, enhancement requests, tech debt |

---

## 2. Incident Response Lifecycle

```
Detect → Triage → Contain → Resolve → Verify → Document → Review
```

### 2.1 Detect
Sources:
- Automated alerts (GitHub Actions failures, quality gate failures)
- Agent self-verification failures (`agent-verify.ps1`)
- Watchtower health checks (`foundation watchtower`)
- Token budget exceeded (`token-guard.ps1`)
- User reports
- Secret leak detection (Gitleaks, Trufflehog)

### 2.2 Triage
1. Determine severity (SEV1-4)
2. Assign incident lead
3. Open tracking issue with `incident/` label
4. Notify relevant parties

### 2.3 Contain
| Incident Type | Containment Action |
|--------------|-------------------|
| Secret leak | Revoke credential immediately, rotate |
| Security breach | Isolate affected systems, revoke access |
| CI/CD broken | Revert last commit, fix build |
| Agent misbehavior | Kill agent session, review logs |
| Token budget exceeded | Suspend non-critical agents, request top-up |

### 2.4 Resolve
1. Implement fix following `rules/DEVELOPMENT-STANDARDS.md#modification-protocol`
2. Run `agent-verify.ps1` to confirm fix
3. Run affected tests
4. Get peer review (per `rules/CODE-REVIEW-STANDARDS.md`)

### 2.5 Verify
1. Fix verified in staging/CI
2. All quality gates pass
3. No regressions detected
4. `foundation verify` returns clean

### 2.6 Document
Record in the incident tracking issue:
- Timeline (detection → triage → containment → resolution)
- Root cause
- Impact scope
- Actions taken
- Prevention measures

### 2.7 Review (Post-Mortem)
Schedule within 48h for SEV1, 1 week for SEV2:
- What went wrong?
- What went right?
- What should we change?
- Action items with owners

---

## 3. Specific Incident Playbooks

### 3.1 Secret Leak (SEV1)
```
1. REVOKE — invalidate the secret NOW (don't investigate first)
2. ROTATE — generate new secret, update consumers
3. SCRUB — use `git filter-repo` to remove from history
4. AUDIT — check CI logs, agent logs, and chat history for exposure
5. PREVENT — update `.gitleaks.toml`, add pre-commit rule
6. DOCUMENT — incident report with timeline
```

### 3.2 AI Agent Hallucination (SEV3)
```
1. IDENTIFY — find what the agent invented (API, function, dependency)
2. CORRECT — replace with real implementation or remove
3. VERIFY — run tests to confirm no cascading failures
4. ADAPT — add rule to hallucination guard if pattern repeats
```

### 3.3 Quality Gate Failure (SEV2)
```
1. IDENTIFY — which gate failed and why
2. FIX — address the root cause (code, config, or test)
3. RE-RUN — trigger CI again
4. ESCALATE — if gate itself is broken, bypass per GOV authorization
```

### 3.4 Workspace Corruption (SEV2)
```
1. STASH — `git stash` any uncommitted work
2. RESTORE — `git restore .` to clean state
3. REBASE — if branch is corrupted, recreate from clean target
4. RUN — `agent-verify.ps1` to confirm workspace health
```

---

## 4. Communication

| Severity | Channel | Who |
|----------|---------|-----|
| SEV1 | Immediate notification | All team + lead |
| SEV2 | Within 1 hour | Team channel |
| SEV3 | End of day | Relevant sub-team |
| SEV4 | Next standup | Individual |

### Incident Update Format
```
[INCIDENT] SEV{1-4} — {short title}
Status: Detected / Triaging / Containing / Resolving / Resolved
Impact: {what's affected}
Lead: @person
ETA: {estimated resolution}
```

---

## 5. Post-Mortem Template

```markdown
## Post-Mortem: {Incident Title}
**Date**: YYYY-MM-DD
**Severity**: SEV{1-4}
**Duration**: {detection → resolution}

### Summary
{2-3 sentences}

### Timeline
- HH:MM — Detection
- HH:MM — Triage
- HH:MM — Containment
- HH:MM — Resolution

### Root Cause
{Clear explanation of why this happened}

### Impact
- {What was affected? How many users/systems?}

### Action Items
- [ ] {Item} — Owner, Due date
- [ ] {Item} — Owner, Due date

### Lessons Learned
- {What went well}
- {What could be improved}
- {What surprised us}
```

---

## 6. References

| Resource | Path |
|----------|------|
| Error Handling | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md` |
| Observability | `rules/NORMATIVAS-OBSERVABILITY.md` |
| SRE Practices | `docs/NORMATIVAS-SRE.md` |
| Incident Response Skill | `skills/incident-response-skill/SKILL.md` |
| Watchtower | `scripts/utilities/watchtower.ps1` |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_
