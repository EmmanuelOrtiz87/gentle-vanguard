# Pre-Write Planning Templates

Plan before you write. These templates structure the pre-write planning phase and feed the task
breakdown in `SKILL.md`. Use `src/planning-templates.ts` to scaffold and store a plan.

## Shared Decision Gates

Apply these gates before starting implementation. Reject or re-plan at the first failed gate.

| Gate            | Check                                                                          |
| --------------- | ------------------------------------------------------------------------------ |
| **G1 Scope**    | Problem, in/out-of-scope, and constraints are written down and unambiguous     |
| **G2 Approach** | At least 2 approaches considered; chosen approach has documented rationale     |
| **G3 Risk**     | Top risks identified with mitigations; rollback strategy defined               |
| **G4 Tasks**    | Every task has acceptance criteria and verification steps; dependencies mapped |
| **G5 Approval** | Plan is approved by a human or the requesting agent before implementation      |

---

## Feature Planning Template

```markdown
# Plan: [Feature Name]

## Scope Definition

**Problem:** [What problem does this solve? What is the user-visible outcome?]

**In scope:**

- [Capability 1]
- [Capability 2]

**Out of scope:**

- [Explicitly excluded 1]
- [Explicitly excluded 2]

**Constraints:**

- [Tech stack / time / budget / compatibility]

## Approach Analysis

| #   | Approach     | Tradeoffs (complexity / maintainability / performance) | Rationale |
| --- | ------------ | ------------------------------------------------------ | --------- |
| 1   | [Approach A] | ...                                                    | ...       |
| 2   | [Approach B] | ...                                                    | ...       |

**Chosen approach:** [Approach #] — [why it won]

## Risk Assessment

| Risk     | Impact  | Likelihood | Mitigation   |
| -------- | ------- | ---------- | ------------ |
| [Risk 1] | [H/M/L] | [H/M/L]    | [Mitigation] |

**Dependencies / blockers:** [External systems, other tasks, missing knowledge]

**Rollback strategy:** [How to undo this if it fails]

## Task Breakdown

| #   | Task   | Acceptance criteria | Depends on | Estimate |
| --- | ------ | ------------------- | ---------- | -------- |
| 1   | [Task] | [AC bullet]         | —          | [S/M/L]  |

## Decision Gates

- [ ] G1 Scope defined
- [ ] G2 Approach chosen
- [ ] G3 Risks assessed
- [ ] G4 Tasks sized and ordered
- [ ] G5 Approved
```

---

## Refactoring Planning Template

```markdown
# Plan: [Refactor Name]

## Scope Definition

**Problem:** [What is wrong with the current design? What behavior must be preserved?]

**In scope:**

- [Module/subsystem to refactor]
- [Behavior preserved]

**Out of scope:**

- [Explicitly excluded behavior changes]

**Constraints:**

- [Compatibility, public API, performance budget]

## Approach Analysis

| #   | Approach                 | Tradeoffs (complexity / risk / blast radius) | Rationale |
| --- | ------------------------ | -------------------------------------------- | --------- |
| 1   | [Incremental, small PRs] | ...                                          | ...       |
| 2   | [Big-bang rewrite]       | ...                                          | ...       |

**Chosen approach:** [Approach #] — [why it won]

## Risk Assessment

| Risk                      | Impact  | Likelihood | Mitigation                     |
| ------------------------- | ------- | ---------- | ------------------------------ |
| [Regression in edge case] | [H/M/L] | [H/M/L]    | [Test coverage / feature flag] |

**Dependencies / blockers:** [Callers, shared modules, deprecated code]

**Rollback strategy:** [Revert individual commits; keep old path behind flag]

## Task Breakdown

| #   | Task             | Acceptance criteria | Depends on | Estimate |
| --- | ---------------- | ------------------- | ---------- | -------- |
| 1   | [Extract module] | [AC bullet]         | —          | [S/M/L]  |

## Decision Gates

- [ ] G1 Scope defined (behavior preserved)
- [ ] G2 Approach chosen
- [ ] G3 Risks assessed with rollback
- [ ] G4 Tasks sized and ordered
- [ ] G5 Approved
```

---

## Bug Fix Planning Template

```markdown
# Plan: [Bug Fix]

## Scope Definition

**Problem:** [What is the bug? What is the observed vs expected behavior?]

**Reproduction:** [Exact steps, input, environment, or failing test]

**In scope:**

- [Root cause + fix]
- [Regression test]

**Out of scope:**

- [Adjacent issues, related features]

**Constraints:**

- [Must not break existing behavior]

## Approach Analysis

| #   | Approach                    | Tradeoffs (risk / blast radius) | Rationale |
| --- | --------------------------- | ------------------------------- | --------- |
| 1   | [Minimal targeted fix]      | ...                             | ...       |
| 2   | [Refactor surrounding code] | ...                             | ...       |

**Chosen approach:** [Approach #] — [why it won]

## Risk Assessment

| Risk                  | Impact  | Likelihood | Mitigation                 |
| --------------------- | ------- | ---------- | -------------------------- |
| [Fix breaks a caller] | [H/M/L] | [H/M/L]    | [Cover callers with tests] |

**Dependencies / blockers:** [Related open bugs, needed data]

**Rollback strategy:** [Revert the fix commit; feature flag]

## Task Breakdown

| #   | Task                            | Acceptance criteria | Depends on | Estimate |
| --- | ------------------------------- | ------------------- | ---------- | -------- |
| 1   | [Write failing regression test] | [AC bullet]         | —          | [S]      |
| 2   | [Apply minimal fix]             | [AC bullet]         | 1          | [S]      |
| 3   | [Verify full suite]             | [AC bullet]         | 2          | [S]      |

## Decision Gates

- [ ] G1 Scope defined with reproduction
- [ ] G2 Approach chosen
- [ ] G3 Risks assessed with rollback
- [ ] G4 Tasks sized and ordered (test first)
- [ ] G5 Approved
```

---

## CLI Usage

Scaffold and store a plan in `.session/sdd-pipeline/plans/`:

```bash
# Create a plan from a template
npx tsx src/planning-templates.ts --plan --type feature --name user-auth \
  --title "User Authentication" --problem "..." --out-of-scope "admin UI" \
  --constraints "Node 20, must not break OAuth"

# Refactoring / bug-fix variants
npx tsx src/planning-templates.ts --plan --type refactor --name api-v2 ...
npx tsx src/planning-templates.ts --plan --type bugfix --name auth-timeout ...

# Manage stored plans
npx tsx src/planning-templates.ts --list
npx tsx src/planning-templates.ts --show user-auth

# Link a plan to a todo task
npx tsx src/planning-templates.ts --link user-auth T3
```
