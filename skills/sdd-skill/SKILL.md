---
name: sdd-skill
description: >
  Spec-Driven Development (SDD): spec-first workflow, acceptance criteria,
  BDD scenarios, docs/specs/ conventions, and spec validation gates.
  Trigger: "spec", "spec-driven", "SDD", "acceptance criteria", "BDD", "feature spec",
  "write spec first", "docs/specs", "specification", "define requirements first".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Before writing ANY new feature code — write the spec first
- When capturing acceptance criteria before implementation
- When writing BDD scenarios to define behavior
- When reviewing a feature to verify spec coverage
- When creating a template SDD for a module or service

## Enforcement Profile

Mandatory:

1. Net-new feature behavior.
2. API contract changes.
3. Cross-module or architectural behavior changes.

Conditionally optional (with mini-spec):

1. Hotfixes and production incidents where speed is critical.
2. Purely internal refactors with no behavior change.

For exceptions, use a mini-spec before merge with:

1. Problem statement.
2. Scope and non-goals.
3. Acceptance criteria.
4. Validation command/evidence.

Reference policy: `docs/reference/SDD-GOVERNANCE-POLICY.md`

## The SDD Workflow

**Rule: Code NEVER precedes specification. The spec IS the source of truth.**

```
1. SPEC → 2. REVIEW → 3. IMPLEMENT → 4. VALIDATE → 5. CLOSE
```

### Step 1 — Write the Spec
Create `docs/specs/{feature-name}.md` using the template below **before** creating any code files.

### Step 2 — Review the Spec
Spec must answer: What? Why? Who? When? Constraints? Non-goals?
Get approval or self-review before proceeding.

### Step 3 — Implement Against the Spec
Each implementation task must reference the spec section it fulfills.
Never add behavior not described in the spec without updating the spec first.

### Step 4 — Validate
Run acceptance criteria as tests. Verify BDD scenarios pass.
Spec must be marked `status: validated` before merge.

### Step 5 — Close
Move fulfilled spec to archive or mark `status: done`.

## Spec File Template

Create at `docs/specs/{feature-slug}.md`:

```markdown
# Spec: {Feature Name}

**Status**: draft | reviewed | implementing | validated | done
**Author**: {name}
**Date**: YYYY-MM-DD
**Linked PR/Branch**: {link or N/A}

## Problem Statement

{1–3 sentences. Why does this need to exist?}

## Goals

- {Goal 1}
- {Goal 2}

## Non-Goals

- {What this explicitly does NOT do}

## Acceptance Criteria

```gherkin
Feature: {Feature Name}

  Scenario: {Happy path}
    Given {initial context}
    When {action}
    Then {expected outcome}

  Scenario: {Edge case}
    Given {context}
    When {action}
    Then {outcome}
```

## Technical Design

{Architecture decisions, data models, API contracts — brief}

## Validation Plan

| Criteria | Test Type | Status |
|---|---|---|
| {AC 1} | Unit | ⬜ |
| {AC 2} | E2E | ⬜ |

## References

- Related ADRs: {link}
- Related SDD docs: {link}
```

## Spec Location Convention

```
docs/
  specs/           ← active specs (draft, reviewing, implementing)
  sdd/             ← completed/historical SDD documents
    {module}-sdd.md
    FEATURE-TECHNICAL-SUMMARY.template.md
```

## Acceptance Criteria Quality Rules

Write criteria that are:
- **Testable** — can be automated as a test
- **Unambiguous** — only one interpretation possible
- **Behavioral** — "user sees X" not "system calls function Y"
- **Bounded** — one scenario = one behavior

See [bdd-scenarios-skill](../bdd-scenarios-skill/SKILL.md) for BDD writing patterns.

## Anti-Patterns to Avoid

- ❌ Writing code first, spec later ("we'll document it after")
- ❌ Vague AC: "should work correctly"
- ❌ Implementation details in AC: "calls the /api/v2/users endpoint"
- ❌ Skipping edge cases in spec
- ❌ Marking spec `done` before validation

## Commands

```powershell
# Check if a docs/specs/ folder exists in the project
Test-Path "docs/specs"

# List all active specs
Get-ChildItem "docs/specs" -Filter "*.md" | Select-Object Name, LastWriteTime

# Validate spec status in a session review
wf end-session    # runs closure checks and captures session outcomes
wf review         # run review/audit gate before PR or publish
```
