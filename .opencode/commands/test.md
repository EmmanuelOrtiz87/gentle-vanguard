---
description: Run the full test suite across all categories
agent: sdd-verify
---

Execute the complete test suite:

1. TypeScript compilation: `npm run typecheck`
2. Config tests: `npm run test:config` (6 tests)
3. Workflow tests: `npm run test:workflows` (2 tests)
4. Integration tests: `npm run test:integration`
5. Dashboard build: `cd apps/web-dashboard && npm run build`
6. Lint: `npm run lint`
7. Format check: `pnpm prettier --check "**/*.{md,json,yml,yaml,ts,js,html,css}"`

Display a summary:

- Total tests: X passed, Y failed
- Build status: PASS/FAIL
- Lint status: PASS/FAIL
- Format status: PASS/FAIL
- Any actionable failures

$ARGUMENTS
