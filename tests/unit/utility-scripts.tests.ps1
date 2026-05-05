# utility-scripts.tests.ps1
# Unit tests for critical utility scripts

Describe 'Utility Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'pre-process-input.ps1' {
        It 'pre-process-input.ps1 exists and is non-empty' {
            $f = Join-Path $script:utilitiesPath "pre-process-input.ps1"
            Test-Path $f | Should Be $true
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'pre-process-input.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "pre-process-input.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }

        It 'pre-process-input.ps1 accepts mandatory UserInput parameter' {
            $f = Join-Path $script:utilitiesPath "pre-process-input.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'param\(\s*\[Parameter\(Mandatory=\$true\)\]\s*\[string\]\$UserInput') | Should Be $true
        }
    }

    Context 'session-autostart.ps1' {
        It 'session-autostart.ps1 exists and is non-empty' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            Test-Path $f | Should Be $true
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'session-autostart.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }

        It 'session-autostart.ps1 defines Write-Step function' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'function Write-Step') | Should Be $true
        }
    }

    Context 'validate-configs.ps1' {
        It 'validate-configs.ps1 exists and is non-empty' {
            $f = Join-Path $script:utilitiesPath "validate-configs.ps1"
            Test-Path $f | Should Be $true
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'validate-configs.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "validate-configs.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }

        It 'validate-configs.ps1 has ConfigDir parameter' {
            $f = Join-Path $script:utilitiesPath "validate-configs.ps1"
            $content = Get-Content $f -Raw
            ($content -match '\[string\]\$ConfigDir') | Should Be $true
        }

        It 'validate-configs.ps1 checks JSON syntax' {
            $f = Join-Path $script:utilitiesPath "validate-configs.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'ConvertFrom-Json') | Should Be $true
        }
    }

    Context 'install-hooks.ps1' {
        It 'install-hooks.ps1 exists and is non-empty' {
            $f = Join-Path $script:utilitiesPath "install-hooks.ps1"
            Test-Path $f | Should Be $true
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'install-hooks.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "install-hooks.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }
    }

    Context 'agent-verify.ps1' {
        It 'agent-verify.ps1 exists and is non-empty' {
            $f = Join-Path $script:utilitiesPath "agent-verify.ps1"
            Test-Path $f | Should Be $true
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'agent-verify.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "agent-verify.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }
    }
}
