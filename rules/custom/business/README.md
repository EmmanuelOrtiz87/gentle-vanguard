# Business Custom Rules

Add domain and business constraints in this directory.

**Format: `.md` files only.** This file (`README.md`) is excluded from rule loading.

Name files using the rule ID prefix: `BIZ-NNN-short-description.md`

## Mandatory Template

Every file in this directory must follow this structure:

```markdown
# [Rule Title]

## Metadata

| Field         | Value                 |
|---------------|-----------------------|
| Rule ID       | BIZ-NNN               |
| Business Area | [domain or product]   |
| Severity      | HIGH / MEDIUM / LOW   |

## Requirement

Clear, actionable statement of the business constraint.

## Why It Matters

Risk or business reason if this rule is not followed.

## Validation

Acceptance criteria or review checklist item.
```

## Example

File: `BIZ-001-release-governance.md`

```markdown
# Release Governance — Notes Format

## Metadata

| Field         | Value              |
|---------------|--------------------|
| Rule ID       | BIZ-001            |
| Business Area | Release governance |
| Severity      | HIGH               |

## Requirement

Production release notes must include a risk section and a rollback section.

## Why It Matters

Incomplete release notes leave incident responders without context.

## Validation

Release checklist must include both "Risk" and "Rollback" entries before merge approval.
```