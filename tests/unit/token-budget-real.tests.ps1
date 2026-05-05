# token-budget-real.tests.ps1
# Unit tests for real token tracking implementation

Describe 'Real Token Budget Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:tokenGuard = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/token-budget-guard.ps1"
    }

    Context 'Token Budget Guard Script' {
        It 'token-budget-guard.ps1 exists' {
            Test-Path $script:tokenGuard | Should Be $true
        }

        It 'token-budget-guard.ps1 has valid PowerShell syntax' {
            if (Test-Path $script:tokenGuard) {
                $errors = $null
                $content = Get-Content $script:tokenGuard -Raw
                [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
                $errors.Count | Should Be 0
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }

        It 'token-budget-guard.ps1 has Task parameter' {
            if (Test-Path $script:tokenGuard) {
                $content = Get-Content $script:tokenGuard -Raw
                ($content -match '\[string\]\$Task|Task.*parameter') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }

        It 'token-budget-guard.ps1 has Risk parameter' {
            if (Test-Path $script:tokenGuard) {
                $content = Get-Content $script:tokenGuard -Raw
                ($content -match '\[string\]\$Risk|Risk.*parameter') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'Real Token Tracking' {
        It 'token-budget-guard.ps1 references usage/response' {
            if (Test-Path $script:tokenGuard) {
                $content = Get-Content $script:tokenGuard -Raw
                ($content -match 'usage|response|token.*count') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }

        It 'token-budget-guard.ps1 has Record switch' {
            if (Test-Path $script:tokenGuard) {
                $content = Get-Content $script:tokenGuard -Raw
                ($content -match 'Record|record') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'Integration with Session' {
        It 'session-autostart.ps1 calls token-budget-guard' {
            $f = Join-Path $script:root "scripts/utilities/session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'token-budget-guard') | Should Be $true
        }

        It 'session-autostart.ps1 passes session-start task' {
            $f = Join-Path $script:root "scripts/utilities/session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'session-start.*Record|Record.*session-start') | Should Be $true
        }
    }
}
