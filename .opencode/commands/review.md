---
description: Perform comprehensive code review on staged or recent changes
agent: sdd-verify
---

Run a comprehensive code review on the current changes:

1. Check staged files: `git status`
2. Review diff: `git diff` (or `git diff --cached` for staged)
3. Run auto-code review: `npx tsx src/auto-code-review.ts --action pre-commit`
4. Run Karpathy enforcer: `npx tsx src/hooks/karpathy-enforcer-hook.ts`
5. Run normative audit: `npx tsx src/hooks/normative-audit-hook.ts`
6. Run security scan: `npm run scan:secrets -- --scan .`
7. Check formatting: `pnpm prettier --check {staged_files}`

Review axes:

- Correctness: Does the code do what it claims?
- Readability: Is it clear and maintainable?
- Architecture: Does it follow existing patterns?
- Security: Any vulnerabilities introduced?
- Performance: Any performance regressions?

Display a structured review with findings per axis.

$ARGUMENTS
