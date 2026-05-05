#Requires -Modules Pester
# v2.6.4 Scripts — Minimal Existence + Parse Tests
# Covers: FF-001 check-sdd-gate, FF-002 sdd-process-metrics,
#         FF-004 sync-drift-report, FF-006 wf-benchmark

Describe 'v2.6.4 Script Suite' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    }

    Context 'FF-001: check-sdd-gate.ps1' {
        BeforeAll {
            $script:sddGate = Join-Path $script:root 'scripts\hooks\check-sdd-gate.ps1'
        }

        It 'exists at expected path' {
            Test-Path $script:sddGate | Should -Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:sddGate -Raw), [ref]$e
            )
            $e.Count | Should -Be 0
        }

        It 'references hook-advisory-classifier.ps1' {
            $content = Get-Content $script:sddGate -Raw
            $content | Should -Match 'hook-advisory-classifier'
        }
    }

    Context 'FF-002: sdd-process-metrics.ps1' {
        BeforeAll {
            $script:sddMetrics = Join-Path $script:root 'scripts\utilities\TELEMETRY-METRICS\sdd-process-metrics.ps1'
        }

        It 'exists at expected path' {
            Test-Path $script:sddMetrics | Should -Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:sddMetrics -Raw), [ref]$e
            )
            $e.Count | Should -Be 0
        }

        It 'accepts -AsJson switch parameter' {
            $content = Get-Content $script:sddMetrics -Raw
            $content | Should -Match '\[switch\]\$AsJson'
        }

        It 'runs and exits 0 in current workspace' {
            $result = pwsh -NoProfile -ExecutionPolicy Bypass -File $script:sddMetrics -Quiet 2>&1
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context 'FF-004: sync-drift-report.ps1' {
        BeforeAll {
            $script:syncDrift = Join-Path $script:root 'scripts\utilities\sync-drift-report.ps1'
        }

        It 'exists at expected path' {
            Test-Path $script:syncDrift | Should -Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:syncDrift -Raw), [ref]$e
            )
            $e.Count | Should -Be 0
        }

        It 'produces valid JSON output with -AsJson' {
            $output = pwsh -NoProfile -ExecutionPolicy Bypass -File $script:syncDrift -AsJson 2>&1
            # Exit code 1 is acceptable (drift found), but output must be valid JSON
            $json = $null
            { $json = $output | Where-Object { $_ -match '^\s*\{' } | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'JSON output contains required fields' {
            $output = pwsh -NoProfile -ExecutionPolicy Bypass -File $script:syncDrift -AsJson 2>&1
            $jsonText = ($output | Where-Object { $_ -match '^\s*[\{\[]' }) -join "`n"
            if ($jsonText) {
                $parsed = $jsonText | ConvertFrom-Json
                $parsed.PSObject.Properties.Name | Should -Contain 'status'
                $parsed.PSObject.Properties.Name | Should -Contain 'drift_score'
            }
        }
    }

    Context 'FF-006: wf-benchmark.ps1' {
        BeforeAll {
            $script:bench = Join-Path $script:root 'scripts\utilities\wf-benchmark.ps1'
        }

        It 'exists at expected path' {
            Test-Path $script:bench | Should -Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:bench -Raw), [ref]$e
            )
            $e.Count | Should -Be 0
        }

        It 'has SLO defaults for status and health' {
            $content = Get-Content $script:bench -Raw
            $content | Should -Match 'status\s*=\s*5'
            $content | Should -Match 'health\s*=\s*15'
        }
    }

    Context 'SDD Gate CI Workflow' {
        BeforeAll {
            $script:sddGateWf = Join-Path $script:root '.github\workflows\sdd-gate.yml'
        }

        It 'workflow file exists' {
            Test-Path $script:sddGateWf | Should -Be $true
        }

        It 'has permissions block' {
            $content = Get-Content $script:sddGateWf -Raw
            $content | Should -Match 'permissions:'
        }

        It 'has timeout-minutes' {
            $content = Get-Content $script:sddGateWf -Raw
            $content | Should -Match 'timeout-minutes:'
        }
    }
}
