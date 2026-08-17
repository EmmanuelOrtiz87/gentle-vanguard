# Architecture Decision Records (ADRs)

**Purpose**: Document significant architectural decisions and their rationales  
**Format**: [Lightweight ADR Format](https://github.com/joelparkerhenderson/architecture_decision_record)  
**Review
Cycle**: Annually or when circumstances change

---

## Overview

ADRs provide:

- **Rationale**: Why we chose this approach (not just what we did)
- **Alternatives**: What we considered and rejected
- **Consequences**: Tradeoffs and mitigation strategies
- **Context**: Historical record for future maintainers

Each ADR is immutable once accepted. Updates create new ADRs (ADR-0011, etc).

---

## Current Decisions

| ID                                                       | Title                                 | Status           | Date       | Summary                                                                                |
| -------------------------------------------------------- | ------------------------------------- | ---------------- | ---------- | -------------------------------------------------------------------------------------- |
| **[ADR-0001](ADR-0001-foundation-architecture-decisions.md)** | Foundation Architecture Decisions | ✅ Accepted      | May 2026   | Meta-ADR: foundational stack decisions (TypeScript, lefthook, node:test, 5-layer)       |
| **[ADR-0002](ADR-002-typescript-first-architecture.md)** | Primary Language: TypeScript          | ✅ Accepted      | May 2026   | Why TypeScript over PowerShell for automation (supersedes ADR-0012)                     |
| **[ADR-0003](ADR-0003-mcp-workspace-external.md)**       | MCP Workspace: External Local         | ✅ Accepted      | May 2026   | Why MCP workspace is external (not git-tracked)                                         |
| **[ADR-0004](ADR-0004-npx-offline-hardening.md)**        | NPX Hardening: Offline + Workspace    | ✅ Accepted      | May 2026   | Why npx uses offline mode with pre-vetted workspace                                    |
| **[ADR-0005](ADR-0005-homologation-gate.md)**            | Homologation Gate: Mandatory          | ✅ Accepted      | May 2026   | Why release workflow has mandatory repo alignment check                                |
| **[ADR-0006](ADR-0006-code-coverage-requirements.md)**   | Code Coverage: Tiered Thresholds      | ✅ Accepted      | May 2026   | Coverage thresholds (70%/75%/65%) with quarterly targets, native TS runner              |
| **[ADR-0007](ADR-007-nexus-operational-database.md)**    | Nexus Operational Database            | ✅ Accepted      | Jul 2026    | SQLite operational DB (WAL, FK ON) — central nervous system of the stack                |
| **[ADR-0008](ADR-008-session-scoring-metrics.md)**       | Session Scoring Metrics               | ✅ Accepted      | Jul 2026    | Quality scoring per session (delegations, corrections, proactive hits)                  |
| **[ADR-0009](ADR-009-watchtower-autoheal-false-positive.md)** | Watchtower Autoheal (False Positive) | ✅ Accepted  | Aug 2026    | Maintenance watchtower with auto-healing, 95 checks, 13 components                      |
| **[ADR-0010](ADR-010-knowledge-absorption-external-repos.md)** | Knowledge Absorption (External Repos) | ✅ Accepted | Aug 2026    | Absorb external knowledge as native TS (secret-scanner, skills, ai-provenance)          |
| **[ADR-0011](ADR-0011-automated-dependency-updates.md)** | Dependency Updates: Audit + Quarterly | ✅ Accepted      | May 2026   | npm audit in pre-push + quarterly review + Renovate Q3 2026                            |
| **[ADR-0012](ADR-0012-powershell-language-choice.md)**   | Primary Language: PowerShell          | ⚠️ Superseded    | May 2026   | Original PowerShell choice — superseded by ADR-0002 (TypeScript-First)                 |

---

## How to Read ADRs

**Quick Overview** (5 min):

1. Read "Status" line
2. Read "Decision" section
3. Scan "Consequences" for pros/cons

**Full Understanding** (15 min):

1. Understand "Context" and problem
2. Review "Alternatives Considered" table
3. Study "Implementation Details"
4. Note "Related Decisions"

**Challenging a Decision** (30 min):

1. Read the full ADR including "Rationale"
2. Review "Consequences" and "Mitigation"
3. Check "References" for supporting material
4. Open GitHub discussion if you disagree

---

## Creating New ADRs

**When to create an ADR:**

- Major architectural choice (not minor implementation details)
- Decision affects multiple teams or long-term
- Choice has tradeoffs worth documenting
- Team might revisit this decision in future

**When NOT to create an ADR:**

- Bug fixes or patches
- Refactoring internal implementation
- Minor configuration changes
- One-off experimental features

**Process:**

1. **Draft** in [DRAFT template](#template) below
2. **Discuss** with team (PR or Slack)
3. **Update** based on feedback
4. **Commit** to git when team aligns
5. **Reference** in relevant code and docs

---

## Template

```markdown
# ADR-NNN: [Brief Title]

**Status**: Proposed | Accepted | Deprecated  
**Date**: [Month Year]  
**Author**: [Name]  
**Context**: [Why this decision came up]

---

## Context

[Describe the problem, context, constraints, and decision drivers]

### Alternatives Considered

| Option | Pros | Cons | Chosen? |
| ------ | ---- | ---- | ------- |
| A      |      |      |         |
| B      |      |      |         |
| **C**  |      |      | ✅      |

---

## Decision

[What we decided and why]

### Rationale

1. [Reason 1]
2. [Reason 2]

---

## Consequences

### Positive

- [+]

### Negative

- [-]

### Mitigation

- [How to address downsides]

---

## Related Decisions

- `ADR-XXX-example.md` (template placeholder — create when needed)

---

## References

- [Link 1]

---

**Review Date**: [Q/Year]  
**Reviewers**: [Team]  
**Status**: [Stable|Monitor]
```

---

## Decision Tree

```
Should we document this decision?
    ↓
Is it a major architectural choice?
    ├─ YES → Create ADR-NNN.md
    └─ NO  → Document in code comments

Will this affect multiple teams long-term?
    ├─ YES → Create ADR-NNN.md
    └─ NO  → Document in relevant guide

Is there uncertainty or tradeoffs?
    ├─ YES → Create ADR-NNN.md (even if not major)
    └─ NO  → Just implement and reference in comments
```

---

## Cross-References

**Related Guides**:

- [SECURITY-HARDENING.md](../../guides/SECURITY-HARDENING.md) — References ADR-0004
- [FIRST-TIME-SETUP-CHECKLIST.md](../../guides/FIRST-TIME-SETUP-CHECKLIST.md) — MCP workspace setup
  (Step 3)
- [RELEASE-PROCESS.md](../../guides/RELEASE-PROCESS.md) — References ADR-0005
- [FIRST-TIME-SETUP-CHECKLIST.md](../../guides/FIRST-TIME-SETUP-CHECKLIST.md) — References ADR-0002

**Related Code**:

- `src/coverage-runner.ts` — Implements ADR-0006
- `scripts/hooks/*.ps1` — Implements ADR-0001/ADR-0012 (original PowerShell hooks)
- `$HOME\mcp-workspace/` — Implements ADR-0003

---

## FAQs

**Q: Can we change an ADR after accepting it?**

A: No. If circumstances change significantly, create a new ADR (ADR-0011) that supersedes or enhances
the previous decision. Update the old ADR status to "Deprecated" or "Evolved To ADR-0011".

---

**Q: What if I disagree with an ADR?**

A: Respectfully discuss in:

1. Team meeting or Slack
2. Open a GitHub Discussion with your alternative
3. If consensus shifts, create a new ADR

Decisions are made by team consensus, not individuals.

---

**Q: How long should an ADR be?**

A: Typically 1-3 pages. If it's getting longer, consider breaking into multiple ADRs.

---

**Q: Who reviews ADRs?**

A: Team consensus. Typically:

- Security team (for security-related ADRs)
- DevOps team (for infrastructure ADRs)
- All developers (for architectural ADRs)

---

## Glossary

- **Status**: Proposed (draft), Accepted (approved), Deprecated (old, superseded)
- **Context**: The problem or decision driver
- **Rationale**: Why we chose this (supporting logic)
- **Consequences**: What happens because of this decision (good and bad)
- **Alternative**: Another viable approach we rejected

---

## Roadmap

**Planned ADRs (Q3-Q4 2026)**:

- [ ] **ADR-0013**: Annual Security Audit Requirements
- [ ] **ADR-0014**: SLSA Compliance Level (L2 vs L3)

---

## Resources

- [adr.github.io](https://adr.github.io/) — ADR home
- [Lightweight ADR Format](https://github.com/joelparkerhenderson/architecture_decision_record/blob/main/adr_template_by_michael_nygard.md)
- [Michael Nygard's ADR](http://thinkrelevant.com/blog/2011/11/15/documenting-architecture-decisions/)
  — Original concept

---

**Last Updated**: May 13, 2026  
**Maintainer**: Security Team  
**Review Cycle**: Quarterly
