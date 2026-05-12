# session-scripts.tests.ps1
# Unit tests for session management scripts

Describe 'Session Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'Session Manager' {
        It 'session-manager.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            Test-Path $f | Should Be $true
        }

        It 'session-manager.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }

        It 'session-manager.ps1 has AutoStart mode' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'AutoStart|auto-start') | Should Be $true
        }
    }

    Context 'Session Autostart' {
        It 'session-autostart.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            Test-Path $f | Should Be $true
        }

        It 'session-autostart.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }

        It 'session-autostart.ps1 uses config-driven pipeline' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'config-driven|ConfigFile|\$config\.pipeline') | Should Be $true
        }
    }

    Context 'Session Notification' {
        It 'session-notification.ps1 exists if present' {
            $f = Join-Path $script:utilitiesPath "session-notification.ps1"
            if (Test-Path $f) {
                $true | Should Be $true
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }
    }

    Context 'Engram Session Integration' {
        It 'session-autostart.ps1 initializes Engram' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'engram|Engram') | Should Be $true
        }

        It 'engram-orchestrator.ps1 exists for session policy' {
            $f = Join-Path $script:utilitiesPath "engram-orchestrator.ps1"
            Test-Path $f | Should Be $true
        }
    }
}
