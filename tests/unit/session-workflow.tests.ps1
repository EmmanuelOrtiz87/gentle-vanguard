# session-workflow.tests.ps1
# Integration tests for session workflow

Describe 'Session Workflow Integration Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
    }

    Context 'Session Startup Workflow' {
        It 'session-manager.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            Test-Path $f | Should Be $true
        }

        It 'session-manager.ps1 has AutoStart mode' {
            $f = Join-Path $script:utilitiesPath "session-manager.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'AutoStart|auto-start|autoStart') | Should Be $true
        }

        It 'session-autostart.ps1 calls session-manager' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'session-manager\.ps1') | Should Be $true
        }
    }

    Context 'Engram Integration' {
        It 'session-autostart.ps1 initializes Engram' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'engram|Engram') | Should Be $true
        }

        It 'session-autostart.ps1 has Engram policy enforcement' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'engram-policy|EngramPolicy') | Should Be $true
        }
    }

    Context 'Token Budget Integration' {
        It 'session-autostart.ps1 calls token-budget-guard' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'token-budget-guard') | Should Be $true
        }

        It 'session-autostart.ps1 records session-start' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'session-start.*Record|Record.*session-start') | Should Be $true
        }
    }

    Context 'Skill Router Integration' {
        It 'session-autostart.ps1 calls skill-router' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'skill-router\.ps1') | Should Be $true
        }

        It 'auto-delegation.json has valid structure for routing' {
            $f = Join-Path $script:root "config/auto-delegation.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.keywordMappings | Should Not BeNullOrEmpty
            $json.agentCodeToSkill | Should Not BeNullOrEmpty
        }
    }
}
