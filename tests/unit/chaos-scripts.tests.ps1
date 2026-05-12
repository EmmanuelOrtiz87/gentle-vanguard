# chaos-scripts.tests.ps1
# Unit tests for Chaos Engineering scripts

Describe 'Chaos Engineering Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:injectDelay = Join-Path $script:root "scripts/chaos/inject-network-delay.ps1"
    }

    Context 'Chaos Experiment Script' {
        It 'inject-network-delay.ps1 exists' {
            Test-Path $script:injectDelay | Should Be $true
        }

        It 'inject-network-delay.ps1 has parameter block' {
            $content = Get-Content $script:injectDelay -Raw
            ($content -match 'param\(') | Should Be $true
        }

        It 'inject-network-delay.ps1 has LatencyMs parameter' {
            $content = Get-Content $script:injectDelay -Raw
            ($content -match 'LatencyMs') | Should Be $true
        }

        It 'inject-network-delay.ps1 has DryRun switch' {
            $content = Get-Content $script:injectDelay -Raw
            ($content -match 'DryRun') | Should Be $true
        }

        It 'inject-network-delay.ps1 has experiment types' {
            $content = Get-Content $script:injectDelay -Raw
            ($content -match '"network"') | Should Be $true
            ($content -match '"process"') | Should Be $true
            ($content -match '"resource"') | Should Be $true
        }

        It 'inject-network-delay.ps1 has steady state capture' {
            $content = Get-Content $script:injectDelay -Raw
            ($content -match 'Get-SteadyState') | Should Be $true
        }

        It 'inject-network-delay.ps1 has try/catch error handling' {
            $content = Get-Content $script:injectDelay -Raw
            ($content -match 'try\s*\{') | Should Be $true
            ($content -match 'catch\s*\{') | Should Be $true
        }
    }
}
