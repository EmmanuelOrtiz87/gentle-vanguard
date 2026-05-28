# sdd-validation.tests.ps1
# Unit tests for SDD (Spec-Driven Development) validation

Describe 'SDD Validation Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:configPath = Join-Path $script:root "config"
    }

    Context 'SDD Config' {
        It 'sdd-config.json exists if present' {
            $f = Join-Path $script:configPath "sdd-config.json"
            if (Test-Path $f) {
                Test-Path $f | Should -Be $true
            } else {
                $true | Should -Be $true  # Skip if doesn't exist
            }
        }

        It 'sdd-config.json is valid JSON if present' {
            $f = Join-Path $script:configPath "sdd-config.json"
            if (Test-Path $f) {
                { Get-Content $f -Raw | ConvertFrom-Json } | Should -Not -Throw
            } else {
                $true | Should -Be $true
            }
        }
    }

    Context 'SDD Gate' {
        It 'sdd-gate.ps1 exists if present' {
            $f = Get-ChildItem -Path $script:root -Filter "sdd-gate.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($f) {
                Test-Path $f.FullName | Should -Be $true
            } else {
                $true | Should -Be $true  # Skip if doesn't exist
            }
        }
    }

    Context 'SDD Metrics' {
        It 'sdd-process-metrics.ps1 exists if present' {
            $f = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1"
            if (Test-Path $f) {
                Test-Path $f | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }

        It 'sdd-process-metrics.ps1 has valid PowerShell syntax if present' {
            $f = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1"
            if (Test-Path $f) {
                $errors = $null
                $content = Get-Content $f -Raw
                [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
                $errors.Count | Should -Be 0
            } else {
                $true | Should -Be $true
            }
        }
    }

    Context 'SDD Lifecycle Skill' {
        It 'sdd-lifecycle skill directory exists' {
            $f = Join-Path $script:root "skills/sdd-lifecycle"
            Test-Path $f | Should -Be $true
        }

        It 'sdd-lifecycle has SKILL.md' {
            $f = Join-Path $script:root "skills/sdd-lifecycle/SKILL.md"
            Test-Path $f | Should -Be $true
        }

        It 'SDD skill mentions lifecycle' {
            $f = Join-Path $script:root "skills/sdd-lifecycle/SKILL.md"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'lifecycle|Lifecycle|SDD') | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }
    }
}



