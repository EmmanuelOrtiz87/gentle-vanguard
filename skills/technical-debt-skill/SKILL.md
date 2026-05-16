---
name: technical-debt-skill
description: >
  Technical debt assessment, prioritization, remediation planning, and debt documentation. Trigger:
  "technical debt", "debt audit", "refactor", "code smell", "anti-pattern", "cleanup",
  "maintainability", "architecture erosion".
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
---

## When to Use

- Auditing a codebase for maintainability issues
- Prioritizing debt remediation work
- Proposing refactors with business justification
- Documenting architectural erosion, coupling, or duplication

## Debt Categories

- Code debt: duplication, long methods, poor boundaries
- Test debt: missing or brittle tests
- Documentation debt: missing ADRs/specs/runbooks
- Operational debt: missing alerts, manual processes, poor observability
- Architectural debt: leaky abstractions, cyclic dependencies, unsafe shared state

## Prioritization Model

Rank debt by:

1. Delivery drag: how much it slows feature work
2. Incident risk: how likely it causes failures
3. Change frequency: how often the area changes
4. Blast radius: how much breaks if it fails

Address debt where all four are high.

## Debt Record Template

```markdown
# Debt Record: {title}

## Problem

{What is wrong now?}

## Impact

- Delivery drag:
- Risk:
- Scope:

## Evidence

- Files/modules:
- Incidents/bugs:
- Test gaps:

## Remediation Options

1. Minimal containment
2. Local refactor
3. Broader redesign

## Recommendation

{Chosen path and why}
```

## Anti-Patterns

- "We'll clean it up later" without a debt record
- Bundling debt cleanup into unrelated features with no scope control
- Large refactors without specs, tests, or rollback plan
- Treating documentation debt as low priority when onboarding or incident recovery suffers

