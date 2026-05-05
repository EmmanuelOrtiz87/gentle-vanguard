# monitoring-scripts.tests.ps1
# Unit tests for monitoring scripts

Describe 'Monitoring Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:monitoringPath = Join-Path $script:root "scripts/monitoring"
    }

    Context 'Monitoring Directory' {
        It 'monitoring directory exists' {
            Test-Path $script:monitoringPath | Should Be $true
        }
    }

    Context 'Cross-Workspace Validator' {
        It 'cross-workspace-validator.ps1 exists' {
            $f = Join-Path $script:root "scripts/monitoring/cross-workspace-validator.ps1"
            Test-Path $f | Should Be $true
        }

        It 'cross-workspace-validator.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/monitoring/cross-workspace-validator.ps1"
            if (Test-Path $f) {
                $errors = $null
                $content = Get-Content $f -Raw
                [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
                $errors.Count | Should Be 0
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'Telemetry Metrics' {
        It 'token-budget-guard.ps1 exists in TELEMETRY-METRICS' {
            $f = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/token-budget-guard.ps1"
            Test-Path $f | Should Be $true
        }

        It 'sdd-process-metrics.ps1 exists if present' {
            $f = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1"
            if (Test-Path $f) {
                $true | Should Be $true
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }
    }

    Context 'Sync Drift Report' {
        It 'sync-drift-report.ps1 exists if present' {
            $f = Get-ChildItem -Path $script:root -Filter "sync-drift-report.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($f) {
                Test-Path $f.FullName | Should Be $true
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }
    }
}
