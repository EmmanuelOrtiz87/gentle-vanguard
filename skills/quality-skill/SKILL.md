---
name: quality
description: "Trigger: code review, linting, formatting enforcement, PR preparation. Code quality governance skill enforcing linters, formatters and best practices across all project files."
---

# Quality Skill

## Activation Contract
Load during any code review, PR preparation, or when enforcing consistent code quality. Activates on lint/format commands or quality gate checks.

## Hard Rules
- REJECT any code with linter errors (ESLint, golint, shellcheck, etc.)
- REJECT any code with formatting errors (Prettier, gofmt, shfmt, etc.)
- REJECT unused variables or unreachable code

## Decision Gates

| Check | Tool | Action |
|-------|------|--------|
| JS/TS lint | ESLint | Fix or reject |
| General format | Prettier | Run formatter |
| Go format | gofmt | Run formatter |
| Shell check | shellcheck | Fix issues |

## Execution Steps
1. Detect project languages and their configured linters/formatters
2. Run all applicable linters
3. If errors found: report and reject (do NOT auto-fix unless requested)
4. Run all applicable formatters
5. Verify no issues remain

## Output Contract
- Report each linter/formatter result per file
- Exit with rejection message if any hard rule violation exists
- List violations with file path, line number, and rule name

## References
(No local reference files yet)
