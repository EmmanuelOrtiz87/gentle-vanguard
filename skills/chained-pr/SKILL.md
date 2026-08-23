---
name: chained-pr
description: >
  Split large changes into chained or stacked pull requests that protect reviewer focus and stay
  within Gentle-Vanguard's 400-line cognitive review budget. Trigger: when a PR would exceed 400
  changed lines, when planning chained PRs, stacked PRs, or reviewable slices.

triggers:
  - chained pr
  - stacked pr
  - split pr
  - large pr
  - review slices
  - 400 line budget
license: Apache-2.0
metadata:
  author: gentle-vanguard (adapted for Gentle-Vanguard)
  version: '1.0'
  source: GV-native
---

# Chained PRs (Gentle-Vanguard Adaptation)

## When to Use #

Use this skill when:

- A planned PR is likely to exceed **400 changed lines** (`additions + deletions`).
- You need chained PRs, stacked PRs, or a feature branch with multiple reviewable slices.
- A reviewer asks to split a PR for cognitive load, review fatigue, or burnout prevention.
- You must protect Gentle-Vanguard's **micro-scoping rule**: Max 10 files/judgment (learned
  2026-05-02).

Do not use this skill for small fixes or single-purpose changes that fit comfortably under the
review budget.

## Critical Rules (Gentle-Vanguard) #

| Rule             | Requirement                                                                                                           |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- |
| Review budget    | **MUST split** when a PR exceeds **400 changed lines**                                                                |
| Review time      | Design each PR for an approximately **≤60-minute** human review                                                       |
| Review health    | Optimize for sustainable maintainer attention, not just CI compliance                                                 |
| Start and finish | Every chained PR MUST state where it starts, where it ends, what came before, and what comes next                     |
| Autonomy         | Every chained PR MUST be understandable and verifiable on its own                                                     |
| Scope            | One deliverable work unit per PR; do not mix unrelated refactors, features, tests, or docs                            |
| Dependencies     | State what each PR depends on and what follows next                                                                   |
| Exceptions       | Use `size:exception` only when a maintainer agrees the large diff is unavoidable                                      |
| SDD handoff      | If SDD forecasts a >400-line workload, honor `delivery_strategy`: ask, auto-chain, or require/record `size:exception` |
| Visual map       | Every chained PR MUST include a dependency diagram that marks the current PR                                          |
| Tracker PR       | Every chain SHOULD have a draft tracker PR that lists every child PR and current status                               |

The goal is not bureaucracy. The goal is preventing reviewer burnout so maintainers can review with
care instead of skimming. Big PRs create fatigue, hide defects, and slow merge velocity.

## Choosing the Split Strategy (Gentle-Vanguard) #

| Scenario                                | Recommended approach  | Why                                            |
| --------------------------------------- | --------------------- | ---------------------------------------------- |
| Fix links + move scripts + rename rules | Feature branch chain  | Keeps unrelated work separate, each ≤400 lines |
| Each slice can land independently       | Stacked PRs to `main` | Reduces long-lived branch drift                |
| Docs refactor + new skills              | Feature branch chain  | Allows integration before final merge          |

## Decision Gates (Gentle-Vanguard) #

| Condition                                            | Action                                 |
| ---------------------------------------------------- | -------------------------------------- |
| PR ≤400 changed lines and focused                    | Keep single PR.                        |
| PR >400, each slice can land independently           | Use Stacked PRs to main.               |
| PR >400, feature must integrate before main          | Use Feature Branch Chain with tracker. |
| Generated/vendor/migration diff cannot split cleanly | Ask maintainer for `size:exception`.   |
| SDD provides `delivery_strategy`                     | Follow it before apply/PR creation.    |

## Execution Steps (Gentle-Vanguard) #

1. Estimate changed lines and identify independent work units.
2. Ask for a chain strategy when none is cached and the budget is exceeded.
3. Create branches/PRs using the chosen strategy only.
4. Add Chain Context to each PR without replacing the repo PR template.
5. Verify each PR independently: CI/tests/docs/manual checks, rollback scope, and clean diff.
6. Keep tracker PR draft/no-merge until all child PRs are reviewed and integrated.

## Output Contract (Gentle-Vanguard) #

Return the chosen strategy, PR order, current PR boundary, dependency diagram, review budget
(`additions + deletions`), verification plan, and any `size:exception` rationale.

## Chain Boundaries #

Every PR in a chain needs explicit boundaries — see
[references/detail.md](references/detail.md).

---

> **Referencias detalladas**:
> [references/detail.md](references/detail.md) — chain boundaries;
> [references/chaining-details.md](references/chaining-details.md) — strategy notes, comparison
> table, and reviewer guidance (merged from `.opencode/skills/chained-pr`).

## Examples

**Input:** a task matching `chained-pr` triggers.
**Action:** apply the workflow described above.
**Expected result:** Split large changes into chained or stacked pull requests that protect reviewer focus and stay within Gentle-Vanguard's 400-line cognitive review budget.
