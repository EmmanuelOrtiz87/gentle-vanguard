# testing-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Testing Skill

## When to Use

- Writing new tests (unit, integration, e2e)
- Setting up test infrastructure or strategy
- Improving test coverage
- Choosing testing frameworks
- Deciding what, when, and how to test
- Debugging failing tests

## Hard Rules

- MUST follow test pyramid: 70% unit, 20% integration, 10% E2E
- MUST test business logic, API handlers, critical paths, and edge cases
- MUST NOT test framework internals, trivial getters, configuration, or third-party code
- MUST use Arrange-Act-Assert pattern
- MUST keep tests independent (no order dependency)
- MUST NOT commit flaky tests — auto-quarantine on detection

## Core Principles

1. **Test behavior, not implementation**
2. **Arrange-Act-Assert (AAA)** — clear test structure
3. **One assertion per test** — when practical
4. **Meaningful names** — describe expected behavior
5. **Fast feedback** — unit tests <100ms
6. **Independence** — no order dependency

## The Modern Test Pyramid

```
      E2E (5%)
    Integration (15%)
  Component/Contract (30%)
      Unit Tests (50%)
```

| Layer       | Scope                 | Speed | Who Owns    |
| ----------- | --------------------- | ----- | ----------- |
| Unit        | Single function/class | ms    | Developers  |
| Component   | UI component/module   | ms-s  | Developers  |
| Contract    | API boundaries        | s     | Dev + QA    |
| Integration | Service interactions  | s-min | QA          |
| E2E         | Full user flows       | min   | QA + DevOps |

## Decision Gates

| Gate         | Condition                                    | Action                     |
| ------------ | -------------------------------------------- | -------------------------- |
| What to test | Business logic, API handlers, critical paths | Always test                |
| What to test | UI components, error paths                   | Consider testing           |
| What to test | Framework code, config, third-party          | Never test                 |
| Coverage     | <60% stmts / <50% branches / <70% funcs      | Block or improve before PR |
| Coverage     | <80% stmts / <70% branches / <90% funcs      | Recommended improvement    |

## Execution Steps

1. Identify scope: business logic, API handlers, critical paths, edge cases
2. Write tests using Arrange-Act-Assert for each scope item
3. Apply test pyramid ratios (70% unit, 20% integration, 10% E2E)
4. Run coverage check against minimum thresholds
5. Verify no anti-patterns (testing internals, brittle selectors, order dependencies)

## Mocking Best Practices

- Mock external dependencies, not internal modules
- Use dependency injection over monkey-patching
- Reset mocks between tests to avoid leaky state

## CI Integration

- Unit/component tests on every PR (fail under 5 min)
- Integration suite on every merge to main
- E2E nightly or on demand
- Flaky test detection → auto-quarantine → alert

> **Detailed reference**: [references/detail.md](references/detail.md)
