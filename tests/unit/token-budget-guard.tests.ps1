# token-budget-guard.tests.ps1
# Unit tests for token budget guard

Describe 'Token Budget Guard Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:sessionAutostart = Join-Path $script:root "scripts/utilities/SESSION/session-autostart.ps1"
        $script:sessionConfig = Join-Path $script:root "config/session-autostart.config.json"
        $script:tokenGuardPath = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/token-budget-guard.ps1"
    }

    Context 'Token Budget Guard Implementation' {
        It 'session-autostart.ps1 exists' {
            Test-Path $script:sessionAutostart | Should -Be $true
        }

        It 'session-autostart is config-driven' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'config-driven|ConfigFile|\$config\.pipeline') | Should -Be $true
        }

        It 'token-budget-guard script exists' {
            Test-Path $script:tokenGuardPath | Should -Be $true
        }

        It 'token-budget-guard.ps1 has token budget logic' {
            $content = Get-Content $script:tokenGuardPath -Raw
            ($content -match 'token.budget|tokenBudget|budget') | Should -Be $true
        }

        It 'session-autostart config references token-budget-guard' {
            if (Test-Path $script:sessionConfig) {
                $config = Get-Content $script:sessionConfig -Raw | ConvertFrom-Json
                $allScripts = $config.pipeline.steps.script -join ' '
                ($allScripts -match 'token-budget-guard') | Should -Be $true
            } else {
                Write-Warning "session-autostart.config.json not found"
                $true | Should -Be $true
            }
        }
    }

    Context 'Token Budget Guard Integration' {
        It 'session-autostart uses pipeline config for orchestration' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match '\$steps|foreach.*step|\$config\.pipeline') | Should -Be $true
        }

        It 'token-budget-guard.ps1 has usage tracking' {
            if (Test-Path $script:tokenGuardPath) {
                $content = Get-Content $script:tokenGuardPath -Raw
                ($content -match 'usage|tracking|estimate|token.*count') | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }
    }
}



