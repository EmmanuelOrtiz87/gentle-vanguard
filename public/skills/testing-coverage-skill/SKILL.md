---
name: testing-coverage
description: >
  Test coverage requirements for script behavior changes. Trigger: "test", "testing", "coverage",
  "spec", "unit test"
metadata:
  source: GV-native
---

# Testing Coverage Skill

## Purpose

Ensure test coverage for all behavior changes in scripts.

## Test Framework

Gentle-Vanguard uses **Pester** for PowerShell and **ShellSpec** for Bash scripts.

## Running Tests

```powershell
# PowerShell - Pester
Invoke-Pester -Path .\tests\

# Bash - ShellSpec
shellspec spec/

# Via gv.ps1
.\gv.ps1 test
```

## Test Structure

```
scripts/
 tests/
    unit/           # Isolated function tests
    integration/    # End-to-end tests
    helpers/        # Shared fixtures
```

## Critical Rules

1. Every feature or bug fix MUST include tests
2. Use setup/cleanup blocks with temp dirs
3. Mock external commands in unit tests
4. Run tests before every push

## Pester Patterns

```powershell
Describe "Get-Config" {
    BeforeEach {
        $script:configPath = "test-config.json"
    }

    It "returns default values" {
        $result = Get-Config
        $result.provider | Should -Be "openai"
    }

    It "throws when config missing" {
        { Get-Config -Path "missing.json" } | Should -Throw
    }
}
```

## Test Categories

| Type        | Purpose                     | Speed     |
| ----------- | --------------------------- | --------- |
| Unit        | Test functions in isolation | Fast      |
| Integration | Test full workflows         | Slow      |
| Smoke       | Quick sanity check          | Very Fast |

## Coverage Requirements

| Change Type   | Min Coverage    |
| ------------- | --------------- |
| New function  | 80%             |
| Bug fix       | Regression test |
| Config change | Smoke test      |
