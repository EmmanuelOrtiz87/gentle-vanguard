# security-checks.tests.ps1
# Unit tests for security checks and trufflehog

Describe 'Security Checks Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:configPath = Join-Path $script:root "config"
    }

    Context 'Trufflehog Integration' {
        It 'lefthook.yml contains trufflehog command' {
            $f = Join-Path $script:root ".lefthook.yml"
            $content = Get-Content $f -Raw
            ($content -match 'trufflehog') | Should Be $true
        }

        It 'lefthook.yml runs trufflehog on pre-commit' {
            $f = Join-Path $script:root ".lefthook.yml"
            $content = Get-Content $f -Raw
            ($content -match 'pre-commit:[^`]*trufflehog') | Should Be $true
        }
    }

    Context 'Security Orchestrator' {
        It 'security-orchestrator.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/security-orchestrator.ps1"
            Test-Path $f | Should Be $true
        }

        It 'security-orchestrator.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/utilities/security-orchestrator.ps1"
            $errors = $null
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
                $errors.Count | Should Be 0
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }

        It 'security-orchestrator.ps1 has init action' {
            $f = Join-Path $script:root "scripts/utilities/security-orchestrator.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'Action.*init|init.*Action') | Should Be $true
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }
    }

    Context 'Security Policy' {
        It 'security-policy.json has enforced mode' {
            $f = Join-Path $script:configPath "security-policy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.accessControl.mode | Should Be "enforced"
        }

        It 'security-policy.json requires auth for critical operations' {
            $f = Join-Path $script:configPath "security-policy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            ($json.authentication.requiredFor | Where-Object { $_.requireAuth -eq $true }).Count | Should BeGreaterThan 0
        }
    }

    Context 'Privacy Gateway' {
        It 'security-privacy.json exists' {
            $f = Join-Path $script:configPath "security-privacy.json"
            Test-Path $f | Should Be $true
        }

        It 'security-privacy.json is valid JSON' {
            $f = Join-Path $script:configPath "security-privacy.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'security-privacy.json has prohibited patterns' {
            $f = Join-Path $script:configPath "security-privacy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.privacy.prohibited | Should Not BeNullOrEmpty
        }

        It 'security-privacy.json has criticalBlock patterns' {
            $f = Join-Path $script:configPath "security-privacy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.privacy.criticalBlock | Should Not BeNullOrEmpty
        }
    }
}
