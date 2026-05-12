# karpathy-guidelines.tests.ps1
# Unit tests for Karpathy Guidelines enforcement (Next-Level Feature)

Describe 'Karpathy Guidelines Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'Karpathy Enforcer Script' {
        It 'karpathy-enforcer.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            Test-Path $f | Should Be $true
        }

        It 'karpathy-enforcer.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }

        It 'karpathy-enforcer.ps1 has Think guideline' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'Think|think') | Should Be $true
        }

        It 'karpathy-enforcer.ps1 has Simplicity guideline' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'Simplicity|simple') | Should Be $true
        }

        It 'karpathy-enforcer.ps1 has Goal-Driven guideline' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'Goal-Driven|goal.driven') | Should Be $true
        }
    }

    Context 'Session Autostart Integration' {
        It 'karpathy-enforcer.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            Test-Path $f | Should Be $true
        }

        It 'karpathy-enforcer.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "karpathy-enforcer.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }
    }

    Context 'Guidelines Documentation' {
        It 'auto-norm-enforcer.ps1 exists for guideline enforcement' {
            $f = Join-Path $script:root "scripts/adaptive/auto-norm-enforcer.ps1"
            Test-Path $f | Should Be $true
        }
    }
}
