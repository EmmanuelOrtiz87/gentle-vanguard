---
name: quality
description: Code quality governance skill - enforces linters, formatters and best practices
---

# Quality Skill

REJECT if:
- Linter errors (ESLint, golint, shellcheck, etc.)
- Formatting errors (Prettier, gofmt, shfmt, etc.)
- Unused variables or unreachable code

REQUIRE:
- Code passes all configured linters and formatters

PREFER:
- Consistent naming and style across files
