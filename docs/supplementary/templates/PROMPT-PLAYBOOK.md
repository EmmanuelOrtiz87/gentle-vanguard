# Prompt Playbook

Use one of these templates as-is. Keep prompts compact.

## 1. Bug Fix Template

Goal: Fix a specific bug in the listed files.

Target files:

- <path/file1>
- <path/file2>

Constraints:

- Do not edit files outside the list.
- No style-only changes.
- Keep public behavior unchanged except for the bug.

Validation:

- Run: <test/build command>
- Expected: tests pass and bug path verified.

Output:

- Summary of root cause.
- Files changed.
- Validation result.
- Remaining risk.

## 2. Refactor Template

Goal: Refactor for readability/maintainability without behavior changes.

Target files:

- <path/file1>

Constraints:

- Preserve external API.
- Max files changed: <N>.
- No dependency changes unless requested.

Validation:

- Run: <test/lint command>

Output:

- What was simplified.
- Why it is safer/clearer.
- Validation status.

## 3. Code Review Template

Goal: Review changed code for defects, regressions, and missing tests.

Scope:

- Compare branch changes in: <module/path>

Constraints:

- Findings first, ordered by severity.
- Include file+line evidence for each finding.

Output:

- Critical findings.
- Major findings.
- Minor findings.
- Testing gaps.

## 4. Documentation Update Template

Goal: Update documentation to match implemented behavior.

Target files:

- <docs/file>

Constraints:

- Keep terminology consistent with current stack.
- Remove stale references.

Validation:

- Verify links and command accuracy.

Output:

- Sections updated.
- Stale items removed.
- Follow-up docs needed.

## 5. Multi-Repo Orchestration Template

Goal: Apply one cross-repo change with minimal drift.

Repositories:

- <repo1>
- <repo2>

Constraints:

- Keep identical behavior across repos.
- Max files per repo: <N>.
- Shared naming must stay consistent.

Validation:

- Run per repo: <command>

Output:

- Repo-by-repo diff summary.
- Parity check results.
- Known exceptions.
