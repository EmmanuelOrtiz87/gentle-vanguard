# SDD Strict TDD Enforcement

Version: 1.0.0 | Framework: TDD discipline for SDD phases

## Purpose

Ensure every SDD implementation phase follows strict Test-Driven Development: RED (test fails) →
GREEN (test passes) → TRIANGULATE (refine) → REFACTOR (improve).

## When It Applies

Applies to ALL SDD apply/verify phases. Does NOT apply to:

- BA/explore phases (research, requirements)
- SAD/design phases (architecture, API contracts)
- Documentation-only tasks

## Rules

### 1. RED Phase (MUST)

Before writing ANY implementation code:

- Write a failing test that defines the expected behavior
- The test MUST fail for the right reason (not a setup/compile error)
- Record the failing test output in the task notes

### 2. GREEN Phase (MUST)

Write the MINIMUM implementation code to pass the test:

- Do NOT add extra features not covered by tests
- Do NOT refactor during this phase
- All tests MUST pass before moving to TRIANGULATE

### 3. TRIANGULATE Phase (SHOULD)

Add additional test cases to:

- Test boundary conditions
- Test error paths
- Test edge cases
- Verify all new tests fail initially (RED), then pass with existing code (GREEN)

### 4. REFACTOR Phase (MUST)

Improve the implementation while keeping all tests GREEN:

- Apply coding standards from `rules/DEVELOPMENT-STANDARDS.md`
- Follow PowerShell best practices from `rules/POWERSHELL-STANDARDS.md`
- Verify `lefthook validate` still passes
- Verify no regressions

## Enforcement

### Automated Checks (MUST run before commit)

```powershell
# Run test suite
Invoke-Pester -Path tests/ -Output Detailed

# Verify lefthook
lefthook validate
```

### Evidence Recording (MUST)

Each SDD task MUST record:

```
TDD Evidence: [task-id]
  RED:   [failing test output]
  GREEN: [passing test output]
  TRIANGULATE: [additional test cases]
  REFACTOR: [improvements applied]
```

## Testing Layers

| Layer       | When                       | Tool       | Path                 |
| ----------- | -------------------------- | ---------- | -------------------- |
| Unit        | Every SDD apply phase      | Pester 5.x | `tests/unit/`        |
| Integration | Cross-script changes       | Pester 5.x | `tests/integration/` |
| Security    | Auth/key/injection changes | Pester 5.x | `tests/security/`    |

## Exceptions

Exceptions require written justification and approval:

- Legacy code with no tests: document manual verification instead
- Regeneration tasks: verify output structure matches expected format
- Urgent security fixes: document post-fix test creation in follow-up task
