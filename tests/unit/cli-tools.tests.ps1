# cli-tools.tests.ps1
# Unit tests for CLI tools (gv.ps1, etc.)

Describe 'CLI Tools Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'GV CLI' {
        It 'gv.ps1 exists and is wrapper' {
            $f = Join-Path $script:utilitiesPath "gv.ps1"
            Test-Path $f | Should -Be $true
            $content = Get-Content $f -Raw
            ($content -match 'WORKFLOW-ORCHESTRATION\\gv\.ps1|WORKFLOW-ORCHESTRATION/gv\.ps1') | Should -Be $true
        }

        It 'gv.ps1 passes arguments to canonical gv' {
            $f = Join-Path $script:utilitiesPath "gv.ps1"
            $content = Get-Content $f -Raw
            ($content -match '& \$wfPath @args|& \$wfPath \$args') | Should -Be $true
        }
    }

    Context 'Session Manager CLI' {
        It 'session-manager.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            Test-Path $f | Should -Be $true
        }

        It 'session-manager.ps1 has AutoStart mode' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'AutoStart|auto-start') | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }
    }

    Context 'GV Benchmark (FF-006)' {
        It 'gv-benchmark.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "gv-benchmark.ps1"
            Test-Path $f | Should -Be $true
        }

        It 'gv-benchmark.ps1 has SLO definitions' {
            $f = Join-Path $script:utilitiesPath "gv-benchmark.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'sloDefaults|SLO|slo') | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }

        It 'gv-benchmark.ps1 references gv.ps1' {
            $f = Join-Path $script:utilitiesPath "gv-benchmark.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'gv\.ps1|wfScript') | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }
    }
}




