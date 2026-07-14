---
description: Perform comprehensive code review on staged or recent changes
agent: sdd-verify
---

Run a comprehensive code review on the current changes:

1. Check staged files: `git status`
2. Review diff: `git diff` (or `git diff --cached` for staged)
3. Run auto-code review: `pwsh scripts/utilities/EVOLVE/auto-code-review.ps1 -Action pre-commit`
4. Run Karpathy enforcer: `pwsh hooks/karpathy-enforcer-hook.ps1`
5. Run normative audit: `pwsh hooks/normative-audit-hook.ps1`
6. Run security scan: `pwsh scripts/security/scan-skill-hook.ps1`
7. Check formatting: `pnpm prettier --check {staged_files}`

Review axes:

- Correctness: Does the code do what it claims?
- Readability: Is it clear and maintainable?
- Architecture: Does it follow existing patterns?
- Security: Any vulnerabilities introduced?
- Performance: Any performance regressions?

Display a structured review with findings per axis.

$ARGUMENTS
