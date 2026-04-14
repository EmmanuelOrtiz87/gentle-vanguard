# Review Custom Rules

Add custom code review criteria in this directory.

**Format: `.md` files only.** This file (`README.md`) is excluded from rule loading.

Name files using the rule ID prefix: `REV-NNN-short-description.md`

## Mandatory Template

Every file in this directory must follow this structure:

```markdown
# [Rule Title]

## Metadata

| Field    | Value               |
|----------|---------------------|
| Rule ID  | REV-NNN             |
| Scope    | [PR type or area]   |
| Severity | HIGH / MEDIUM / LOW |

## Requirement

Clear statement of the review criterion.

## Blocking Conditions

What must be fixed before merge approval.

## Non-Blocking Recommendations

Advisory items to flag but not block on.

## Required Evidence

What evidence or output must be present in the PR.
```

## Example

File: `REV-001-security-and-regression.md`

```markdown
# Security and Regression Gate

## Metadata

| Field    | Value                    |
|----------|--------------------------|
| Rule ID  | REV-001                  |
| Scope    | All PRs to main          |
| Severity | HIGH                     |

## Requirement

All PRs must pass security and regression checks before merge.

## Blocking Conditions

- Security vulnerabilities (OWASP Top 10).
- Data-loss regressions in any storage path.

## Non-Blocking Recommendations

- Code style and readability improvements.
- Optional refactoring suggestions.

## Required Evidence

Smoke test output and PowerShell parser validation results in PR description.
```