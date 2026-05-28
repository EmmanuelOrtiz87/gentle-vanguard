# orchestrator.tests.ps1
# Unit tests for Orchestrator

Describe 'Orchestrator Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:configPath = Join-Path $script:root "config"
    }

    Context 'Orchestrator Config' {
        It 'orchestrator.json exists' {
            $f = Join-Path $script:configPath "orchestrator.json"
            Test-Path $f | Should -Be $true
        }

        It 'orchestrator.json is valid JSON' {
            $f = Join-Path $script:configPath "orchestrator.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'orchestrator.json has toolsSupported in preProcessing' {
            $f = Join-Path $script:configPath "orchestrator.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.orchestrator.preProcessing.toolsSupported | Should -Not -BeNullOrEmpty
        }

        It 'orchestrator.json has orchestrator as selectable tool' {
            $f = Join-Path $script:configPath "orchestrator.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            ($json.toolsSupported -match 'orchestrator|Orchestrator') | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Pre-Processing Hook' {
        It 'pre-process-input.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/pre-process-input.ps1"
            Test-Path $f | Should -Be $true
        }

        It 'pre-process-input.ps1 is called by orchestrator' {
            $f = Join-Path $script:configPath "orchestrator.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.orchestrator.preProcessing.script | Should -Match 'pre-process-input\.ps1'
        }
    }

    Context 'Session Manager' {
        It 'session-manager.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/session-manager.ps1"
            Test-Path $f | Should -Be $true
        }

        It 'session-manager.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/utilities/session-manager.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0
        }
    }
}



