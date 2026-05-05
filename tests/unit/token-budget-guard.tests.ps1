# token-budget-guard.tests.ps1
# Unit tests for token budget guard

Describe 'Token Budget Guard Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:sessionAutostart = Join-Path $script:root "scripts/utilities/session-autostart.ps1"
    }

    Context 'Token Budget Guard Implementation' {
        It 'session-autostart.ps1 exists' {
            Test-Path $script:sessionAutostart | Should Be $true
        }

        It 'session-autostart.ps1 contains token budget logic' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'token.budget|tokenBudget|TOKEN.*BUDGET') | Should Be $true
        }

        It 'session-autostart.ps1 references token-budget-guard' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'token-budget-guard') | Should Be $true
        }

        It 'session-autostart.ps1 calls token guard with Record' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'TokenBudget.*Record|tokenGuard.*Record') | Should Be $true
        }

        It 'session-autostart.ps1 has warn/critical thresholds' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'warnThreshold|criticalThreshold|WARN|CRITICAL') | Should Be $true
        }
    }

    Context 'Token Budget Guard Integration' {
        It 'session-autostart calls token budget check' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'token.*check|Check.*Token|guard.*token') | Should Be $true
        }

        It 'session-autostart has token usage tracking' {
            $content = Get-Content $script:sessionAutostart -Raw
            ($content -match 'usage|tracking|estimate') | Should Be $true
        }
    }
}
