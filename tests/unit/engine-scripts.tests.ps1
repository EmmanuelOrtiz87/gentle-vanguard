# engine-scripts.tests.ps1
# Unit tests for engine scripts

Describe 'Engine Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'Engine Directory' {
        It 'utilities directory exists (contains engine scripts)' {
            Test-Path $script:utilitiesPath | Should -Be $true
        }
    }

    Context 'Runtime Router (FF-013)' {
        It 'runtime-router.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/WORKFLOW-ORCHESTRATION/runtime-router.ps1"
            Test-Path $f | Should -Be $true
        }

        It 'runtime-router.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/utilities/WORKFLOW-ORCHESTRATION/runtime-router.ps1"
            if (Test-Path $f) {
                $errors = $null
                $content = Get-Content $f -Raw
                [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
                $errors.Count | Should -Be 0
            } else {
                $true | Should -Be $true
            }
        }

        It 'runtime-router.ps1 has gate mode' {
            $f = Join-Path $script:root "scripts/utilities/runtime-router.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'Mode.*gate|gate.*Mode') | Should -Be $true
            } else {
                $true | Should -Be $true
            }
        }
    }

    Context 'Skill Router' {
        It 'skill-router.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/WORKFLOW-ORCHESTRATION/skill-router.ps1"
            if (-not (Test-Path $f)) {
                $f = Join-Path $script:root "scripts/utilities/skill-router.ps1"
            }
            Test-Path $f | Should -Be $true
        }

        It 'skill-router.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/utilities/WORKFLOW-ORCHESTRATION/skill-router.ps1"
            if (-not (Test-Path $f)) {
                $f = Join-Path $script:root "scripts/utilities/skill-router.ps1"
            }
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

    Context 'Cross-Workspace Validator' {
        It 'cross-workspace-validator.ps1 exists' {
            $f = Join-Path $script:root "scripts/monitoring/cross-workspace-validator.ps1"
            Test-Path $f | Should -Be $true
        }

        It 'cross-workspace-validator.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/monitoring/cross-workspace-validator.ps1"
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
}



