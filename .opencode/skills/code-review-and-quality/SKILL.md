---
name: code-review-and-quality
description:
  Multi-axis code review. Assess correctness, readability, architecture, security, and performance
  before merging.
triggers:
  - code review
  - quality
  - review code
  - assess
  - pre-merge review
---

# Code Review and Quality

## Overview

Five-axis review with quality gates. **Approve when it improves overall code health** — perfect code
isn't the goal. Don't block because it isn't how you'd write it.

## Five-Axis Review

See [references/review-criteria.md](references/review-criteria.md) for criteria per axis:

- **Correctness** — spec match, edge cases, error paths, test coverage, race conditions
- **Readability** — naming, control flow, complexity, dead code, abstractions
- **Architecture** — patterns, module boundaries, dependency direction
- **Security** — input validation, secrets, auth, injection, untrusted data
- **Performance** — N+1, unbounded ops, sync/async, pagination

## Review Workflow

See [references/review-process.md](references/review-process.md) for details:

1. Understand context before code
2. Review tests first (they reveal intent)
3. Walk implementation with the five axes
4. Categorize findings by severity
5. Verify the verification story

### Finding Severity

| Prefix                        | Meaning       | Action                      |
| ----------------------------- | ------------- | --------------------------- |
| _(none)_                      | Required      | Fix before merge            |
| **Critical:**                 | Blocks merge  | Security, data loss, broken |
| **Nit:**                      | Minor         | May ignore                  |
| **Optional:** / **Consider:** | Suggestion    | Worth considering           |
| **FYI**                       | Informational | No action needed            |

Lead with correctness and security, then structural issues.

## Change Descriptions

First line: short, imperative, standalone. Body: what and why — context not visible in the code.
**Anti-patterns:** "Fix bug," "Fix build," "Add patch."

## Change Sizing

~100 lines ideal, ~300 acceptable for single logical changes, ~1000+ split it. ~1000 lines per file
signals decomposition. Separate refactoring from feature work. See
[references/quality-gates.md](references/quality-gates.md) for splitting strategies.

## Dead Code Hygiene

After refactoring, check for orphans. List them. Ask before deleting.

## Review Speed

Respond within one business day. Ask authors to split large changes.

## Handling Disagreements

1. **Facts and data** override opinions
2. **Style guides** are absolute on style
3. **Engineering principles**, not preference
4. **Consistency** acceptable if it doesn't degrade health

Don't accept "I'll clean it up later." Require cleanup or file a bug with self-assignment.

## Honesty in Review

Don't rubber-stamp. Don't soften real issues. Quantify when possible. Push back on clear problems.
Accept override gracefully when the author has full context. Comment on code, not people.

## Common Rationalizations

| Rationalization                 | Reality                                               |
| ------------------------------- | ----------------------------------------------------- |
| "It works, that's good enough"  | Unreadable/insecure code creates compounding debt.    |
| "We'll clean it up later"       | Later never comes.                                    |
| "AI code is probably fine"      | Needs more scrutiny, not less.                        |
| "Tests pass, so it's good"      | Tests miss architecture, security, readability.       |
| "The refactor makes it cleaner" | Relocating complexity isn't reducing it.              |
| "It's only a small addition"    | Small diffs push files past healthy boundaries.       |
| "Just a version bump"           | Behavior change you didn't write. Read the changelog. |
| Bulk dependency bumps           | Hides which package broke the build. One per change.  |

## Verification

All Critical and Required issues resolved or deferred, tests pass, build succeeds. See
[references/quality-gates.md](references/quality-gates.md) for full checklist and red flags.

## Verification Contract (gentle-ai v2.2.x alignment)

Every reviewed work unit MUST carry implementation evidence before it is accepted. This contract is
absorbed from the gentle-ai review transaction model and applied natively to our stack:

| Requirement             | Rule                                                                                                                                          |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Focused test command    | Exact command + exact result recorded (e.g. `npm run test:config` → 6 passed).                                                                |
| Runtime harness         | Command/scenario + exact result, or explicit `N/A` with reason why no runtime boundary exists.                                                |
| Rollback boundary       | Names the exact files/behavior removable without unrelated work; stated independently of commit creation.                                     |
| Review budget           | Keep each PR within 400 changed lines (`additions + deletions`) unless a maintainer accepts `size:exception`.                                 |
| Evidence in same unit   | Tests, docs, and verification travel with the behavior they verify — never in a separate follow-up.                                           |
| Five lifecycle gates    | `post-apply` (implemented candidate), `pre-commit` (staged), `pre-push` (committed), `pre-pr` (candidate + base), `release` (immutable tree). |
| Immutable review target | Review the frozen candidate tree, not the live worktree; never accept "it passed locally" without replayable evidence.                        |

### Review findings format

Severe findings MUST include an `evidence_class` and `causal_disposition`. Claims of `introduced`,
`behavior-activated`, or `worsened` are admitted only when repository-derived changed-line evidence
supports the claimed location. Review results echo the exact subject identity (lineage/target/lens)
and report structured inspection: completed paths, not prose.

### Chained PR protection

When a planned PR exceeds 400 changed lines: split into chained PRs (see `chained-pr` skill), each
reviewable in about 60 minutes, with a dependency diagram marking the current PR with `📍`, and
tests/docs kept with the unit they verify.

## Change Sizing (aligned)

See [references/quality-gates.md](references/quality-gates.md). Budget:

- ~100 lines ideal, ~300 acceptable for single logical changes, ~1000+ split it.
- The 400-line PR budget from gentle-ai is the hard cap for a single reviewable unit.

## See Also

- [references/review-criteria.md](references/review-criteria.md)
- [references/review-process.md](references/review-process.md)
- [references/quality-gates.md](references/quality-gates.md)
- `security-and-hardening` skill
- `performance-optimization` skill
