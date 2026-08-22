# ADR-0006: Code Coverage Requirements and Enforcement Strategy

**Date**: May 13, 2026  
**Author**: Gentle-Vanguard DevOps Team

## Status

Accepted (Implemented)

**Context**: Establishing measurable quality gates after test suite maturation

---

## Context

gentle-vanguard has a strong test suite (33+ tests across unit, integration, security, and
performance categories) but **no code coverage measurement** was in place. Without coverage
thresholds, it is impossible to:

- Know which code paths are exercised by tests
- Detect coverage regressions when refactoring
- Make data-driven decisions about where to add new tests
- Satisfy external audit requirements for test coverage

### Current Test Landscape (May 2026)

| Category    | Files | Tests        |
| ----------- | ----- | ------------ |
| Unit        | 8+    | ~20          |
| Integration | 3+    | ~8           |
| Security    | 2     | 3            |
| Performance | 1     | 2            |
| **E2E**     | 1     | **23** (new) |

### Options Considered

1. **No formal coverage** — keep current state
2. **Coverage report only, no threshold** — measure but don't enforce
3. **Enforce thresholds in CI with progressive targets** ← chosen
4. **100% coverage target** — unrealistic for infrastructure scripts

---

## Decision

**Adopt tiered code coverage thresholds with progressive quarterly targets, enforced as a
non-blocking warning in CI (Q2 2026) and blocking gate (Q3 2026).**

### Initial Thresholds (Q2 2026)

| Metric    | Threshold | Rationale                                                               |
| --------- | --------- | ----------------------------------------------------------------------- |
| Lines     | 70%       | Conservative baseline; infrastructure scripts have unreachable branches |
| Functions | 75%       | Higher than lines — key entry points must be tested                     |
| Branches  | 65%       | Lowest — TypeScript branching is harder to cover                        |

### Target Trajectory

| Period  | Lines | Functions | Branches | Enforcement           |
| ------- | ----- | --------- | -------- | --------------------- |
| Q2 2026 | 70%   | 75%       | 65%      | Warning only          |
| Q3 2026 | 75%   | 80%       | 70%      | CI blocking           |
| Q4 2026 | 80%   | 85%       | 75%      | Blocking + PR comment |

### Excluded Files

Files excluded from coverage measurement (see `tests/coverage-config.json`):

- `src/setup-complete.ts` — one-time machine bootstrap
- `scripts/run-tests-simple.ps1` — test orchestrator (not subject to self-test)

<!-- REF-OBSOLETA: scripts/run-tests-simple.ps1 no tiene equivalente TS (migración PS1→TS) -->

- `scripts/testing/run-tests.ps1` — legacy test runner

<!-- REF-OBSOLETA: scripts/testing/run-tests.ps1 no tiene equivalente TS (migración PS1→TS) -->

- `build/**` — build tooling, not runtime code
- `bin/**` — launcher shims

### Implementation

Coverage is measured with the **native TypeScript coverage runner** (`src/coverage-runner.ts`),
which executes the full test suite under c8 and enforces per-target thresholds:

```bash
npm run coverage        # full run + threshold enforcement (CI gate)
npm run coverage:quick  # quick informational run (pre-push, never blocks)
npm run coverage:report # generate reports only
```

The runner executes each target module independently, parses the V8 coverage JSON (`coverage/`), and
validates aggregate + per-target percentages against `tests/coverage-config.json`. Targets that are
not exercised by any test are reported as WARN (not FAIL) so the gate degrades gracefully.

Configuration in `tests/coverage-config.json` controls thresholds, inclusions, and exclusions. The
CI workflow uploads coverage reports as artifacts.

---

## Consequences

### Positive

- ✅ Objective quality gate — replaces "feels tested enough" subjective assessment
- ✅ Progressive targets avoid big-bang disruption to existing workflow
- ✅ c8 integration stays within the existing TypeScript toolchain (no Istanbul/NYC)
- ✅ Exclusions list prevents false negatives from infrastructure code
- ✅ Audit-ready: coverage history via CI artifact retention

### Negative

- ⚠️ V8 coverage lacks branch-level analysis in some constructs
- ⚠️ Initial 70% threshold may be generous — review after first full measurement
- ⚠️ Full suite run requires the whole test suite to complete within CI timeout

---

## Alternatives Considered

1. **No formal coverage** — Rejected: blind spots compound over time; external audits expect
   measurement
2. **Report-only, no threshold** — Rejected: reports without enforcement degrade over time
3. **100% target** — Rejected: infrastructure/deployment scripts have error-handling branches that
   are intentionally difficult to trigger in tests
4. **Istanbul/NYC for JS, separate for PS** — Rejected: gentle-vanguard is primarily TypeScript;
   adding a second tool doubles complexity

---

## References

- `tests/coverage-config.json` — threshold configuration
- `src/coverage-runner.ts` — native coverage runner implementation
- `tests/unit/coverage-runner.test.ts` — runner unit tests
- `.github/workflows/ci.yml` — CI integration (coverage-report job)
- ADR-0002 (TypeScript-First) — explains why the stack is TypeScript-native
