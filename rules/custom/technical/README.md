# Technical Custom Rules

Add repository-specific technical rules in this directory.

**Format: `.md` files only.** This file (`README.md`) is excluded from rule loading.

Name files using the rule ID prefix: `TECH-NNN-short-description.md`

## Mandatory Template

Every file in this directory must follow this structure:

```markdown
# [Rule Title]

## Metadata

| Field    | Value                 |
|----------|-----------------------|
| Rule ID  | TECH-NNN              |
| Scope    | [target files/paths]  |
| Severity | HIGH / MEDIUM / LOW   |

## Requirement

Clear, actionable statement of what is required.

## Why It Matters

Rationale — explain the risk or consequence.

## Validation

How to verify: command, parser check, or acceptance criteria.
```

## Example

File: `TECH-001-parser-validation.md`

```markdown
# PowerShell Parser Validation

## Metadata

| Field    | Value                    |
|----------|--------------------------|
| Rule ID  | TECH-001                 |
| Scope    | scripts/**/*.ps1         |
| Severity | HIGH                     |

## Requirement

All runtime PowerShell scripts must parse cleanly before commit.

## Why It Matters

Prevents parser and runtime regressions in hook and CI automation.

## Validation

```powershell
[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)
$errors.Count -eq 0
```
```