# Integration phase tests for phases 1.3, 2, 3 (Tracing, State Persistence, Audit).
# Validates that the v4.0 infrastructure components are present and wired.

Describe "Phase 1.3 / 2 / 3 integration" {
    BeforeAll {
        # tests/integration/phase-13-2-3 -> tests/integration -> tests -> repo root (3 levels up)
        $script:repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        if (-not $script:repoRoot) {
            throw "Could not resolve repo root from PSScriptRoot: $PSScriptRoot"
        }
    }

    Context "Distributed tracing" {
        It "tracing-instrument source exists" {
            Test-Path (Join-Path $script:repoRoot "src/tracing-instrument.ts") | Should -BeTrue
        }

        It "tracing step configured in pipeline" {
            $cfg = Get-Content (Join-Path $script:repoRoot "config/session-autostart.config.json") -Raw | ConvertFrom-Json
            $steps = @($cfg.pipeline.steps)
            ($steps | Where-Object { $_.id -eq "tracing-init" -and $_.enabled }).Count | Should -BeGreaterOrEqual 1
        }
    }

    Context "State persistence" {
        It "checkpoint-manager source exists" {
            Test-Path (Join-Path $script:repoRoot "src/checkpoint-manager.ts") | Should -BeTrue
        }

        It "checkpoint step configured in pipeline" {
            $cfg = Get-Content (Join-Path $script:repoRoot "config/session-autostart.config.json") -Raw | ConvertFrom-Json
            $steps = @($cfg.pipeline.steps)
            ($steps | Where-Object { $_.id -eq "checkpoint-auto-create" -and $_.enabled }).Count | Should -BeGreaterOrEqual 1
        }
    }

    Context "Audit pipeline" {
        It "audit-pipeline source exists" {
            Test-Path (Join-Path $script:repoRoot "src/infrastructure/audit-pipeline.ts") | Should -BeTrue
        }

        It "audit step configured in pipeline" {
            $cfg = Get-Content (Join-Path $script:repoRoot "config/session-autostart.config.json") -Raw | ConvertFrom-Json
            $steps = @($cfg.pipeline.steps)
            ($steps | Where-Object { $_.id -eq "audit-pipeline-init" -and $_.enabled }).Count | Should -BeGreaterOrEqual 1
        }
    }
}
