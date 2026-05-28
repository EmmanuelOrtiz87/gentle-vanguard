# sre-scripts.tests.ps1
# Unit tests for SRE (Site Reliability Engineering) scripts

Describe 'SRE Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:enforceBudget = Join-Path $script:root "scripts/sre/enforce-error-budget.ps1"
        $script:budgetConfig = Join-Path $script:root "config/sre-error-budgets.json"
    }

    Context 'Enforce Error Budget Script' {
        It 'enforce-error-budget.ps1 exists' {
            Test-Path $script:enforceBudget | Should -Be $true
        }

        It 'enforce-error-budget.ps1 has parameter block' {
            $content = Get-Content $script:enforceBudget -Raw
            ($content -match 'param\(') | Should -Be $true
        }

        It 'enforce-error-budget.ps1 has error handling' {
            $content = Get-Content $script:enforceBudget -Raw
            ($content -match 'try\s*\{|catch\s*\{') | Should -Be $true
        }

        It 'enforce-error-budget.ps1 returns JSON with -Json flag' {
            $content = Get-Content $script:enforceBudget -Raw
            ($content -match 'ConvertTo-Json') | Should -Be $true
        }
    }

    Context 'SRE Error Budget Config' {
        It 'sre-error-budgets.json exists' {
            Test-Path $script:budgetConfig | Should -Be $true
        }

        It 'sre-error-budgets.json is valid JSON' {
            { Get-Content $script:budgetConfig -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'sre-error-budgets.json has error_budgets' {
            $config = Get-Content $script:budgetConfig -Raw | ConvertFrom-Json
            $config.error_budgets | Should -Not -BeNullOrEmpty
        }

        It 'sre-error-budgets.json has consumption_actions' {
            $config = Get-Content $script:budgetConfig -Raw | ConvertFrom-Json
            $config.consumption_actions | Should -Not -BeNullOrEmpty
        }

        It 'sre-error-budgets.json has enforcement section' {
            $config = Get-Content $script:budgetConfig -Raw | ConvertFrom-Json
            $config.enforcement | Should -Not -BeNullOrEmpty
        }
    }
}



