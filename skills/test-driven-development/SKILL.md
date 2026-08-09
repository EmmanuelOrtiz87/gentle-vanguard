---
name: test-driven-development
aliases: ["test-driven-development"]
description: >
  
triggers:
  - tdd
  - test driven
  - write test first
  - failing test
  - test before code
metadata:
  source: opencode-migrated
  migrated: true
  migratedAt: "2026-08-09T01:46:58.313Z"
  originalPath: C:\Workspace_local\gentle-vanguard\.opencode\skills\test-driven-development\SKILL.md
  version: "1.0.0"
---

# Test-Driven Development

## Overview

Write a failing test before the code. For bugs, reproduce with a test first. Tests are proof —
"seems right" is not done.

**When to Use:** New logic, bug fixes, modifying functionality, edge cases. **Skip:** Config
changes, docs, static content.

## TDD Cycle

```
RED → write failing test → GREEN → minimal code to pass → REFACTOR → improve → repeat
```

1. **RED** — Write a failing test first. A passing test on first run proves nothing.
2. **GREEN** — Minimum code to pass. Don't over-engineer.
3. **REFACTOR** — Improve naming, remove duplication, optimize. Tests stay green.

## Prove-It Pattern (Bug Fixes)

Bug report → reproduction test (FAILS) → fix → test PASSES → full suite.

## Test Pyramid

Unit (80%) → Integration (15%) → E2E (5%).

**The Beyonce Rule:** If you liked it, you should have put a test on it.

## Principles

| Principle                        | Description                                        |
| -------------------------------- | -------------------------------------------------- |
| **Test State, Not Interactions** | Assert on outcomes, not internal calls             |
| **DAMP Over DRY**                | Duplication for clarity is OK                      |
| **Prefer Real Over Mocks**       | Real > Fake > Stub > Mock. Mock only at boundaries |
| **Arrange-Act-Assert**           | 3 clear phases per test                            |
| **One Assertion Per Concept**    | Each test verifies one behavior                    |
| **Descriptive Names**            | `it('sets status to completed')`                   |

## Anti-Patterns

| Anti-Pattern                   | Problem                                     |
| ------------------------------ | ------------------------------------------- |
| Testing implementation details | Tests break on refactor, behavior unchanged |
| Flaky tests                    | Erode trust in the suite                    |
| Mocking everything             | Tests pass but production breaks            |
| Snapshot abuse                 | Nobody reviews large snapshots              |
| No test isolation              | Fail together despite passing individually  |

## Rationalizations

| Rationalization          | Reality                                                            |
| ------------------------ | ------------------------------------------------------------------ |
| "I'll write tests after" | You won't. Tests after the fact test implementation, not behavior. |
| "Too simple to test"     | Simple code gets complicated. Tests document expectations.         |
| "Tests slow me down"     | Tests slow you now, speed you up on every future change.           |
| "I tested it manually"   | Manual testing doesn't persist.                                    |

## Red Flags

- Code without tests
- Tests passing on first run
- Bug fixes without reproduction tests
- Vague test names
- Skipped tests to make suite pass

## Verification

- [ ] Every new behavior has a test
- [ ] All tests pass
- [ ] Bug fixes include a reproduction test
- [ ] Test names describe expected behavior
- [ ] No skipped/disabled tests
- [ ] Coverage hasn't decreased

## Browser Testing

Unit tests aren't enough for browser code. Use Chrome DevTools MCP for DOM inspection, console logs,
network requests, performance traces, screenshots.

## Subagents for Testing

For complex bug fixes, spawn a subagent to write the reproduction test — ensures the test is written
without knowledge of the fix.

## See Also

- [`references/tdd-cycle.md`](references/tdd-cycle.md) — RED-GREEN-REFACTOR walkthrough, Prove-It
  Pattern
- [`references/testing-patterns.md`](references/testing-patterns.md) — Pyramid, principles,
  anti-patterns, rationalizations, red flags, verification
- [`references/framework-guide.md`](references/framework-guide.md) — Browser testing with DevTools,
  subagents
- `browser-testing-with-devtools` skill — DevTools setup
