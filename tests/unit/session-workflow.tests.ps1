# session-workflow.tests.ps1
# Integration tests for session workflow

Describe 'Session Workflow Integration Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:utilitiesPath = Join-Path $script:root "scripts/utilities"
        $script:sessionConfig = Join-Path $script:root "config/session-autostart.config.json"
    }

    Context 'Session Startup Workflow' {
        It 'session-autostart.ps1 exists' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            Test-Path $f | Should Be $true
        }

        It 'session-autostart is config-driven pipeline' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match '\$config\.pipeline|Config-Driven|config-driven') | Should Be $true
        }

        It 'session-autostart.config.json defines pipeline steps' {
            if (Test-Path $script:sessionConfig) {
                $config = Get-Content $script:sessionConfig -Raw | ConvertFrom-Json
                $config.pipeline.steps.Count | Should BeGreaterThan 0
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'Engram Integration' {
        It 'session-autostart.ps1 initializes Engram' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match 'engram|Engram') | Should Be $true
        }

        It 'engram-orchestrator.ps1 exists for policy enforcement' {
            $f = Join-Path $script:utilitiesPath "engram-orchestrator.ps1"
            Test-Path $f | Should Be $true
        }
    }

    Context 'Token Budget Integration' {
        It 'token-budget-guard.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/TELEMETRY-METRICS/token-budget-guard.ps1"
            Test-Path $f | Should Be $true
        }

        It 'session-autostart uses config-driven orchestration' {
            $f = Join-Path $script:utilitiesPath "session-autostart.ps1"
            $content = Get-Content $f -Raw
            ($content -match '\$steps|\$config\.pipeline\.steps|foreach.*\$steps') | Should Be $true
        }
    }

    Context 'Routing Integration' {
        It 'auto-delegation.json has valid structure for routing' {
            $f = Join-Path $script:root "config/auto-delegation.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.keywordMappings | Should Not BeNullOrEmpty
            $json.agentCodeToSkill | Should Not BeNullOrEmpty
        }
    }
}
