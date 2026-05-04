---
name: commit-hygiene
description: >
  Enforce conventional commits and clean commit history.
  Trigger: "commit", "conventional commit", "commit message", "commit hygiene"
---

# Commit Hygiene Skill

## Purpose
Enforce conventional commits format and maintain a clean, readable git history.

## Format
```
type(scope): description
```

Validated by regex:
```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+
```

## Valid Types

| Type | Use For |
|------|---------|
| feat | New feature or behavior |
| fix | Bug fix |
| docs | Documentation only |
| chore | Maintenance, dependencies, tooling |
| refactor | Restructuring without behavior change |
| test | Adding or fixing tests |
| ci | CI/CD pipeline changes |
| style | Formatting, whitespace, no logic change |
| perf | Performance improvement |
| build | Build system, Makefile changes |
| revert | Reverting a previous commit |

## Critical Rules
- One logical change per commit
- Use imperative mood: "add" not "added"
- Keep subject line  72 characters
- Reference issue numbers when relevant: `feat(auth): add JWT support (#123)`
- If commit needs explanation, add body separated by blank line

## Anti-patterns

```
# BAD  vague
update stuff

# BAD  multiple concerns
feat: add login and fix bug and update docs

# BAD  past tense
fix: fixed the cache issue
```

## Pre-commit Validation

Use `invoke-ai-review.ps1` with commit-msg hook:
```powershell
.\invoke-ai-review.ps1 install --commit-msg
```

