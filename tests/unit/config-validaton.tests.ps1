# config-validaton.tests.ps1
# Unit tests for config validation

Describe 'Config Validation Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:configPath = Join-Path $script:root "config"
    }

    Context 'JSON Config Files' {
        It 'All JSON files in config/ are valid JSON' {
            $jsonFiles = Get-ChildItem -Path $script:configPath -Filter "*.json" -ErrorAction SilentlyContinue
            $allValid = $true
            foreach ($file in $jsonFiles) {
                try {
                    $null = Get-Content $file.FullName -Raw | ConvertFrom-Json
                } catch {
                    $allValid = $false
                    break
                }
            }
            $allValid | Should Be $true
        }

        It 'auto-delegation.json is valid' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'orchestrator.json is valid' {
            $f = Join-Path $script:configPath "orchestrator.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'security-policy.json is valid' {
            $f = Join-Path $script:configPath "security-policy.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'security-privacy.json is valid' {
            $f = Join-Path $script:configPath "security-privacy.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }
    }

    Context 'Config Structure' {
        It 'auto-delegation.json has required top-level keys' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.keywordMappings | Should Not BeNullOrEmpty
            $json.agentCodeToSkill | Should Not BeNullOrEmpty
        }

        It 'orchestrator.json has required structure' {
            $f = Join-Path $script:configPath "orchestrator.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.orchestrator | Should Not BeNullOrEmpty
            $json.orchestrator.preProcessing | Should Not BeNullOrEmpty
        }

        It 'security-policy.json has authentication config' {
            $f = Join-Path $script:configPath "security-policy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.authentication | Should Not BeNullOrEmpty
        }
    }

    Context 'SDD Config' {
        It 'sdd-config.json exists if present' {
            $f = Join-Path $script:configPath "sdd-config.json"
            if (Test-Path $f) {
                { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }
    }
}
