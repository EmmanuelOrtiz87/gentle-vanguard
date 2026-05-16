---
name: chained-pr
description: >
  Split large changes into chained or stacked pull requests that protect reviewer focus and stay
  within Gentle-Vanguard's 400-line cognitive review budget. Trigger: when a PR would exceed 400 changed
  lines, when planning chained PRs, stacked PRs, or reviewable slices.
license: Apache-2.0
metadata:
  author: gentle-vanguard (adapted for Gentle-Vanguard)
  version: '1.0'
---

# Chained PRs (Gentle-Vanguard Adaptation)

## When to Use#

Use this skill when:

- A planned PR is likely to exceed **400 changed lines** (`additions + deletions`).
- You need chained PRs, stacked PRs, or a feature branch with multiple reviewable slices.
- A reviewer asks to split a PR for cognitive load, review fatigue, or burnout prevention.
- You must protect Gentle-Vanguard's **micro-scoping rule**: Max 10 files/judgment (learned 2026-05-02).

Do not use this skill for small fixes or single-purpose changes that fit comfortably under the
review budget.

## Critical Rules (Gentle-Vanguard)#

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

## Choosing the Split Strategy (Gentle-Vanguard)#

| Scenario                                | Recommended approach  | Why                                            |
| --------------------------------------- | --------------------- | ---------------------------------------------- |
| Fix links + move scripts + rename rules | Feature branch chain  | Keeps unrelated work separate, each ≤400 lines |
| Each slice can land independently       | Stacked PRs to `main` | Reduces long-lived branch drift                |
| Docs refactor + new skills              | Feature branch chain  | Allows integration before final merge          |

## Chain Boundaries#

Every PR in a chain needs explicit boundaries:

| Boundary     | What to document                                     |
| ------------ | ---------------------------------------------------- |
| Start        | The branch, PR, or state this PR builds on           |
| End          | The finished unit this PR leaves behind              |
| Before       | Prior PRs reviewers can assume already exist         |
| After        | Follow-up PRs reviewers should ignore for now        |
| Out of scope | Related work intentionally excluded from this review |

## Tracker PR Requirement#

For any chain with more than two PRs, create a draft tracker PR before review starts. The tracker PR
is not the review surface. It is the map.

It must include:

- every child PR in merge/review order,
- current status for each PR,
- one dependency diagram,
- explicit instruction not to review the aggregate diff,
- `size:exception` if the aggregate diff exceeds 400 changed lines,
- `no-merge` while the chain is incomplete.

## Diagram Requirement#

Every child PR must show where it sits in the chain. Mark the current PR with `📍`.

```text
main
└── #101 Gentle-Vanguard
     └── #102 Fix links
          └── 📍 #103 Move scripts
               └── #104 Rename rules
                    └── #105 Tracker
```

Pair the diagram with a status table:

| PR   | Scope            | Status         |
| ---- | ---------------- | -------------- |
| #101 | Gentle-Vanguard audit | ✅ Passing     |
| #102 | Fix links        | ✅ Passing     |
| #103 | Move scripts     | 📍 Review here |
| #104 | Rename rules     | ⚪ Pending     |
| #105 | Tracker          | 🟡 Draft       |

## Gentle-Vanguard Integration#

When planning produces tasks that may exceed 400 changed lines:

1. Treat the `Review Workload Forecast` as a hard planning signal.
2. Follow the cached `delivery_strategy` before `sdd-apply` writes code.
3. Convert suggested work units into PR slices.
4. Keep each slice autonomous: tests/docs included, CI green, clear rollback.
5. Do not let one `sdd-apply` batch silently grow into a burnout-sized PR.

## Feature Branch Chain (Gentle-Vanguard)#

Use this when multiple PRs should integrate together before landing in `main`.

```text
main
 └── feat/gentle-vanguard-audit          # integration branch
      ├── #102 Fix links           # PR targets feat/gentle-vanguard-audit
      ├── #103 Move scripts        # PR targets feat/gentle-vanguard-audit
      └── #104 Rename rules       # PR targets feat/gentle-vanguard-audit
```

### Steps#

1. Create the feature branch from `main`.
2. Open a main/tracker PR from the feature branch to `main` early and mark it as draft/no-merge.
3. Create each implementation branch from the feature branch.
4. Target each chained PR back to the feature branch.
5. Merge the final feature branch to `main` only after all chained PRs are merged and tested
   together.

### Tracker PR Expectations#

The tracker PR is a **chain map**, not the review surface. Keep it draft/no-merge until the child
PRs are reviewed and integrated.

- Reviewers should review the child PRs, where each slice stays within the 400-line budget.
- The tracker PR may exceed 400 changed lines because it aggregates the full feature branch by
  design.
- If the tracker PR exceeds the budget, request/obtain maintainer-applied `size:exception` and
  document why the aggregate diff is unavoidable.

## Stacked PRs to Main (Gentle-Vanguard)#

Use this when each PR can land in `main` in order.

```text
main <- PR 1: fix-links (50 lines)
          └── PR 2: move-scripts (80 lines)    # targets main after PR 1 merges
                     └── PR 3: rename-rules (30 lines)  # targets main after PR 2 merges
```

### Steps#

1. Create PR 1 from `main`.
2. Create PR 2 from PR 1's branch and target it to PR 1's branch.
3. After PR 1 merges, rebase PR 2 on `main` and retarget it to `main`.
4. Repeat until the stack is merged.

## Chain Context Section#

Insert this extra section into the existing `.github/PULL_REQUEST_TEMPLATE.md` body. Do **not**
replace the repository PR template; the linked issue, PR type, summary, changes, test plan,
automated checks, and contributor checklist sections are still required.

````markdown
## Chain Context#

| Field         | Value                                    |
| ------------- | ---------------------------------------- |
| Chain         | <feature or stack name>                  |
| Tracker PR    | <#NNN or "Not needed">                   |
| Position      | <N of total>                             |
| Base          | `<target branch>`                        |
| Depends on    | <PR/issue/link or "None">                |
| Follow-up     | <next PR or "None">                      |
| Review budget | <changed lines> / 400                    |
| Starts at     | <branch, PR, or state this builds on>    |
| Ends with     | <standalone result delivered by this PR> |

### Chain Overview#

```text
main
 └── #NNN Previous PR
      └── 📍 #NNN This PR
           └── #NNN Next PR
                └── #NNN Tracker
```
````

### Chain Status#

| PR   | Scope   | Status     |
| ---- | ------- | ---------- |
| #NNN | <scope> | <status>   |
| #NNN | <scope> | 📍 This PR |

## Scope#

- <What this PR includes>
- <What this PR intentionally excludes>

## Autonomy#

- [ ] CI is expected to pass for this PR branch
- [ ] This PR has one deliverable scope
- [ ] This PR can be rolled back without unrelated changes
- [ ] Tests, docs, or manual verification cover this unit

## Review Notes#

- Review this PR in isolation.
- Do not review dependent PR changes here.
- If this exceeds 400 changed lines, request/obtain maintainer-applied `size:exception` and document
  the rationale.

## Test Plan#

- <command or manual verification>

````

## Commands (Gentle-Vanguard)#

```bash
# Check PR size before asking for review
gh pr view <PR_NUMBER> --json additions,deletions,changedFiles,title

# Create a chained PR targeting a feature branch
gh pr create --base feat/gentle-vanguard-audit --title "fix: repair broken links" --body-file pr-body.md

# Create a stacked PR targeting the previous branch
gh pr create --base fix-links --title "refactor: move scripts to utilities" --body-file pr-body.md
````

## Reviewer Guidance#

- If a PR exceeds 400 changed lines without `size:exception`, ask for a split.
- Recommend chained PRs when the work must integrate before `main`.
- Recommend stacked PRs when each slice can merge independently.
- Prefer clear dependency notes over clever branch gymnastics.
- Push for autonomy: green CI, clear rollback, and tests or docs for the unit under review.
- Protect reviewer energy. If the chain forces reviewers to reconstruct hidden context, ask for
  clearer boundaries.

## Gentle-Vanguard Lessons Applied (2026-05-02)#

- **Max 10 files/judgment-day** (cognitive budget)
- **Max 400 lines/PR** (cognitive load)
- **Micro-scoping** → 2-5 minute reviews instead of "many minutes"
- **Chained PRs** → No more massive audits that timeout

