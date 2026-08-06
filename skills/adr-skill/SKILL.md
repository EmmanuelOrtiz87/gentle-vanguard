---
name: adr-skill
description: >
  Imported from mercury-agent-skills. Use when working with "ADR", "architecture decision",
  "decision record", "architecture governance". Triggers: "ADR", "architecture decision", "decision
  record", "architecture governance".
metadata:
  source: mercury-agent-skills
  original-name: architecture-decision-records
---

# Architecture Decision Records

Capture architectural decisions systematically so your team understands not just _what_ was decided,
but _why_ — and what alternatives were considered.

## Core Principles

### 1. Decisions Are More Important Than Diagrams

A diagram shows the current architecture. An ADR explains _why_ it is that way.

### 2. Capture Context, Not Just Conclusions

If you only record the conclusion, future engineers will wonder if you considered the obvious
alternative.

### 3. Lightweight Is Sustainable

A structured 1-page record is infinitely better than nothing. If the process is heavy, people won't
follow it.

### 4. Accept and Track Superseded Decisions

Architecture evolves. Old ADRs remain valuable as historical records of the team's thinking.

## ADR Maturity Model

| Level             | Capture                           | Storage                               | Review                                  | Enforcement                           |
| ----------------- | --------------------------------- | ------------------------------------- | --------------------------------------- | ------------------------------------- |
| **1: Tribal**     | Decisions in Slack/meetings       | Nobody remembers                      | None                                    | None                                  |
| **2: Documented** | Some decisions written down       | Shared drive or wiki                  | Sporadic                                | None                                  |
| **3: Systematic** | All significant decisions as ADRs | In repository alongside code          | PR review requires ADR for arch changes | Basic: "needs ADR" check              |
| **4: Integrated** | ADRs linked to implementation     | Searchable, indexed, cross-referenced | Mandatory ADR review for arch changes   | Automated: lint checks for ADR format |
| **5: Governance** | ADRs drive architecture reviews   | Catalog with status dashboard         | Regular architecture review board       | Automated compliance checks           |

Target: **Level 3** for most teams. **Level 4+** for regulated or long-lived systems.

## Usage

When asked to create or review an ADR, use the standard template below. For detailed guidance on
workflows, alternative templates, governance, and tooling, see the reference files in `references/`.

### Standard ADR Template

```markdown
# ADR-{NNN}: {Title}

## Status

[Proposed | Accepted | Deprecated | Superseded]

_If Superseded, list the replacing ADR: Superseded by ADR-{NNN}_

## Context

{Describe the problem, constraints, and forces at play.}

## Decision

{State the decision clearly. What are we doing? What are we NOT doing?}

## Consequences

{List the positive and negative consequences. What tradeoffs are we accepting?}

## Alternatives Considered

{List alternatives and why they were rejected.}

### Option A: {Name}

- **Pros**: ...
- **Cons**: ...
- **Why rejected**: ...

### Option B: {Name}

- **Pros**: ...
- **Cons**: ...
- **Why rejected**: ...

## Compliance

{How will we verify this decision is followed?}
```

## Common Mistakes

1. **Writing ADRs after implementation** — capture before or during, not months later.
2. **No alternatives section** — this is the most valuable part for future readers.
3. **Status never updated** — keep status current (Superseded/Deprecated are valid).
4. **ADRs stored outside the repository** — keep ADRs with the code they describe.
5. **Too many ADRs for trivial decisions** — reserve for meaningful architectural choices.
6. **No review process** — ADRs nobody reads might as well not exist.

---

_See `references/adr-workflow.md` for the full workflow, `references/adr-templates.md` for
lightweight/Y-statement/rejected templates, and `references/adr-advanced.md` for governance,
linting, tools, and change tracking._
