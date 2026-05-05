# cli-tools.tests.ps1
# Unit tests for CLI tools (wf.ps1, etc.)

Describe 'CLI Tools Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'WF CLI' {
        It 'wf.ps1 exists and is wrapper' {
            $f = Join-Path $script:utilitiesPath "wf.ps1"
            Test-Path $f | Should Be $true
            $content = Get-Content $f -Raw
            ($content -match 'WORKFLOW-ORCHESTRATION\\wf\.ps1|WORKFLOW-ORCHESTRATION/wf\.ps1') | Should Be $true
        }

        It 'wf.ps1 passes arguments to canonical wf' {
            $f = Join-Path $script:utilitiesPath "wf.ps1"
            $content = Get-Content $f -Raw
            ($content -match '& \$wfPath @args|& \$wfPath \$args') | Should Be $true
        }
    }

    Context 'Session Manager CLI' {
        It 'session-manager.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            Test-Path $f | Should Be $true
        }

        It 'session-manager.ps1 has AutoStart mode' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'AutoStart|auto-start') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'WF Benchmark (FF-006)' {
        It 'wf-benchmark.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "wf-benchmark.ps1"
            Test-Path $f | Should Be $true
        }

        It 'wf-benchmark.ps1 has SLO definitions' {
            $f = Join-Path $script:utilitiesPath "wf-benchmark.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'sloDefaults|SLO|slo') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }

        It 'wf-benchmark.ps1 references wf.ps1' {
            $f = Join-Path $script:utilitiesPath "wf-benchmark.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'wf\.ps1|wfScript') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }
}
