# Testing Standards

**Version:** 1.0.0  
**Last reviewed:** 2026-05-05  
**Framework:** Pester 5.x (PowerShell unit/integration tests)  
**Enforced by:** `agent-verify.ps1` (`tests` domain check) + CI `gentle-vanguard-quality-gate.yml`

---

## 1. Test Pyramid

```
       /‾‾‾‾‾‾‾‾‾\
      /   E2E / CI  \    ← `.github/workflows/` — automated pipeline validation
     /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
    /   Integration    \  ← `tests/integration/` — cross-component flows
   /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
  /      Unit Tests      \ ← `tests/unit/` — individual function/script tests
 /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
```

Target distribution: **70% unit · 20% integration · 10% E2E**.

---

## 2. Coverage Targets

| Layer                                         | Minimum Coverage | Target |
| --------------------------------------------- | ---------------- | ------ |
| Critical scripts (hooks, gv.ps1, token-guard) | 80%              | 90%    |
| Utility scripts (telemetry, metrics, reports) | 60%              | 75%    |
| Config validation functions                   | 100%             | 100%   |
| Integration flows (agent routing, SDD gate)   | 50%              | 70%    |

`agent-verify.ps1` gates on: **0 test failures** + **minimum 12 passing unit tests**.

---

## 3. File Naming and Location

```
tests/
├── unit/
│   ├── gentle-vanguard-core.tests.ps1          # Core infrastructure tests
│   ├── engram-memory-manager.tests.ps1    # Engram integration tests
│   ├── new-scripts.tests.ps1              # Tests for new scripts (see §6)
│   └── ...
├── integration/
│   ├── auto-delegation-router.integration.tests.ps1
│   └── ...
├── security/
│   └── ...
└── performance/
    └── ...
```

Rules:

- Unit test files: `<name>.tests.ps1`
- Integration test files: `<name>.integration.tests.ps1`
- Security test files: `<name>.security.tests.ps1`

---

## 4. Pester Test Structure

```powershell
#Requires -Modules Pester

Describe '<ComponentName> Tests' {
    BeforeAll {
        # Resolve repo root from test file location
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    }

    Context '<Scenario>' {
        It '<expectation in plain English>' {
            # Arrange
            $script = Join-Path $script:root 'scripts/path/to/script.ps1'
            # Assert
            Test-Path $script | Should -Be $true
        }

        It 'parses without errors' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script -Raw), [ref]$errors
            )
            $errors.Count | Should -Be 0
        }
    }
}
```

Rules:

- **Every `It` block must have a single, clear assertion**.
- **Use `Should -Be` not `Should Be`** (Pester 5 syntax — no space).
- **No `$global:` in tests** — use `$script:` for shared state.
- **`BeforeAll` / `AfterAll`** for setup/teardown, not `BeforeEach` for expensive operations.

---

## 5. What to Test

### Always test:

- ✅ Script file **exists** (`Test-Path`)
- ✅ Script **parses without errors** (PSParser)
- ✅ Critical config files **are valid JSON** and have **required keys**
- ✅ Exit codes for success and failure paths
- ✅ Output format for `-AsJson` flags (valid JSON)

### Also test where feasible:

- ✅ Function return values with known inputs
- ✅ Advisory vs blocking classification (hook-advisory-classifier)
- ✅ SLO thresholds in benchmark script
- ✅ Drift detection with known fixture data

### Do NOT test:

- ❌ External services (git, engram, GitHub API) — mock or skip
- ❌ File system mutations without cleanup
- ❌ Time-dependent logic without mocking `Get-Date`

---

## 6. New Script → New Test Rule

**Every new `.ps1` script MUST be accompanied by at least a minimal test** that:

1. Asserts the file exists at the expected path
2. Asserts the file parses without errors
3. (If the script has `-AsJson`) asserts the output is valid JSON

This is the **Mandatory Minimum**. Additional behavior tests are strongly encouraged.

```powershell
# Minimal test template for a new script
Describe 'my-new-script.ps1' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:path = Join-Path $script:root 'scripts/utilities/my-new-script.ps1'
    }

    It 'exists' { Test-Path $script:path | Should -Be $true }

    It 'has zero parse errors' {
        $e = $null
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $script:path -Raw), [ref]$e
        )
        $e.Count | Should -Be 0
    }
}
```

---

## 7. Running Tests

```powershell
# Run all unit tests (used by agent-verify + CI)
pwsh -File scripts/utilities/agent-verify.ps1

# Run specific test file
Invoke-Pester tests/unit/gentle-vanguard-core.tests.ps1 -Output Detailed

# Run with coverage (requires Pester 5.3+)
Invoke-Pester -CodeCoverage scripts/**/*.ps1 -CodeCoverageOutputFile coverage.xml
```

---

## 8. Test Quality Gates

| Gate | Value | Enforcement |
| ---- | ----- | ---------- |
| Zero failing tests | 0 failures | `agent-verify.ps1` + CI |
| Minimum unit tests | ≥ 18 passing | `agent-verify.ps1` |
| Parse errors in test files | 0 | `ps-lint.yml` |
| No `$global:` in tests | Enforced | PSScriptAnalyzer |
| WCAG violations (critical) | 0 | `check-accessibility.ps1` |
| I18n missing keys | 0 | `check-i18n.ps1` |
| SRE error budgets | HEALTHY | `enforce-error-budget.ps1` |

