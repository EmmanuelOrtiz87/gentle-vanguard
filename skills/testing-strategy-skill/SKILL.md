---
name: testing-strategy-skill
description: "Trigger: testing strategy, test pyramid, what to test, coverage target, unit test, integration test. Decides what, when, and how to test across Go, Angular, and Python stacks."
---

## Activation Contract

Use when setting up test infrastructure, deciding what to test, choosing test levels, improving coverage, or debugging test failures.

## Hard Rules

- MUST follow test pyramid: 70% unit, 20% integration, 10% E2E
- MUST test business logic, API handlers, critical paths, and edge cases
- MUST NOT test framework internals, trivial getters, configuration, or third-party code
- MUST use Arrange-Act-Assert pattern
- MUST keep tests independent (no order dependency)
- MUST write tests in same package (Go) or alongside source (Angular)

## Decision Gates

| Gate | Condition | Action |
|------|-----------|--------|
| What to test | Business logic, API handlers, critical paths? | Always test |
| What to test | UI components, error paths? | Consider testing |
| What to test | Framework code, config, third-party? | Never test |
| Coverage | Below 60% stmts / 50% branches / 70% funcs? | Block or improve before PR |
| Coverage | Below 80% stmts / 70% branches / 90% funcs? | Recommended improvement |

## Execution Steps

1. Identify scope: business logic, API handlers, critical paths, edge cases
2. Write tests using Arrange-Act-Assert for each scope item
3. Apply test pyramid ratios (70% unit, 20% integration, 10% E2E)
4. Run coverage check against minimum thresholds
5. Verify no anti-patterns (testing internals, brittle selectors, order dependencies)

## Output Contract

Return test plan (what was tested and at what level), coverage report, and any detected anti-patterns.

## References

- `references/code-examples.md` — Go and Angular test examples with mocking
- `references/quick-reference.md` — Naming conventions, file locations, commands
- `references/ci-integration.md` — CI/CD test configuration
