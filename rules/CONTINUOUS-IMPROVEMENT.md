# Continuous Improvement Framework (Kaizen)

**Version:** 1.0.0
**Last updated:** 2026-05-14
**Applies to:** All gentle-vanguard processes, rules, skills, and agent behavior

---

## 1. Philosophy

This project uses Kaizen (改善) — continuous improvement through small, incremental changes. Every session should leave the project better than it was found. No improvement is too small.

**Core tenets:**
1. **Leave it better** — Every session adds at least one improvement
2. **Measure before and after** — Improvements must be verifiable
3. **Document the learning** — All improvements are recorded in Engram and adaptive rules
4. **Error as data** — Failures are improvement opportunities, not blame events

---

## 2. Improvement Cycles

### 2.1 Per-Session Cycle
```
1. END of session → capture "what could be better?"
2. Propose 1-3 concrete improvements
3. Implement if ≤ 5 min; defer if larger
4. Log in Engram + adaptive rules
```

### 2.2 Weekly Cycle (Audit-Driven)
Triggered by `gentle-vanguard-audit-skill` / `audit-sweep.ps1`:
1. Run full audit sweep
2. Categorize findings (critical/high/medium/low)
3. Assign improvement items to upcoming sessions
4. Track in `.local/improvement-proposals/`

### 2.3 Monthly Cycle (Judgment Day)
Triggered by `gv judgment-day`:
1. Adversarial review of the entire stack
2. Identify systemic patterns (not one-off bugs)
3. Propose structural improvements
4. Update rules, configs, and/or architecture

---

## 3. Improvement Categories

| Category | Examples | Review Cadence |
|----------|----------|----------------|
| **Contradictions** | Pester version conflict, Write-Host rules | Immediate (blocks work) |
| **Gaps** | Missing code review standards, incident runbook | Weekly |
| **Optimizations** | Faster scripts, smaller context, better routing | Weekly |
| **New capabilities** | New skills, new agents, new integrations | Monthly |
| **Tech debt** | Dead code, duplicated configs, stale docs | Monthly |
| **Security** | Secret detection, prompt injection hardening | Immediate |

### Priority Matrix

| | High Impact | Low Impact |
|--|-----------|-----------|
| **Easy** | 🔴 DO NOW | 🟡 DO THIS WEEK |
| **Hard** | 🟠 PLAN THIS MONTH | ⚪ BACKLOG |

---

## 4. Improvement Proposal Process

### 4.1 Proposal Format
Every improvement proposal is a JSON file in `.local/improvement-proposals/`:

```json
{
  "id": "IMP-YYYY-MM-DD-NNN",
  "title": "Short description",
  "category": "contradiction|gap|optimization|capability|tech-debt|security",
  "source": "session-YYYY-MM-DD-XX|audit|judgment-day|user",
  "severity": "critical|high|medium|low",
  "effort": "minutes|hours|days",
  "impact": "high|medium|low",
  "description": "What needs to improve and why",
  "proposed_action": "What to do",
  "verification": "How to confirm it's fixed",
  "status": "proposed|approved|in-progress|done|cancelled",
  "session": "session-YYYY-MM-DD-XX"
}
```

### 4.2 Proposal Lifecycle
```
Identify → Write proposal → Auto-approve (if ≤5min) / Route → Implement → Verify → Close
```

---

## 5. Metrics & Success Criteria

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Contradictions in rules | 0 | `agent-verify.ps1` consistency check |
| Rules with stale dates (<90d) | 0 | Date audit |
| Improvement proposals implemented/session | ≥ 1 | `.local/improvement-proposals/` count |
| Agent-verify pass rate | 100% | `agent-verify.ps1` |
| Cross-reference validity | 100% | Link checker |
| Rules-to-config duplication | 0 | Manual audit |

---

## 6. What to Improve (Cheat Sheet)

When looking for improvements, check these areas in order:

1. **Are there contradictions?** (same rule, different values in different files)
2. **Are there gaps?** (use cases not covered by any rule)
3. **Are there stale references?** (links to files that were moved or renamed)
4. **Is there duplication?** (same content in multiple files)
5. **Is there dead code?** (scripts, skills, configs no longer used)
6. **Are there optimization opportunities?** (can context be smaller, scripts faster?)
7. **Is there tech debt?** (would a future contributor curse this code?)

---

## 7. References

| Resource | Path |
|----------|------|
| Adaptive Rules | `rules/adaptive/LEARNED-NORMS.md` |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Code Review Standards | `rules/CODE-REVIEW-STANDARDS.md` |
| Audit Skill | `skills/gentle-vanguard-audit-skill/` |
| Improvement Proposals | `.local/improvement-proposals/` |
| Judgment Day | `scripts/utilities/judgment-day-orchestrator.ps1` |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_

