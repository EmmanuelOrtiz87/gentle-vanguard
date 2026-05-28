# hooks-config.tests.ps1
# Unit tests for hooks configuration and security

Describe 'Hooks and Security Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:configPath = Join-Path $script:root "config"
    }

    Context 'lefthook.yml' {
        It 'lefthook.yml exists and is non-empty' {
            $f = Join-Path $script:root ".lefthook.yml"
            Test-Path $f | Should -Be $true
            (Get-Item $f).Length | Should -BeGreaterThan 0
        }

        It 'lefthook.yml has git hooks validation commands' {
            $f = Join-Path $script:root ".lefthook.yml"
            $content = Get-Content $f -Raw
            ($content -match 'pre-commit:|pre-push:|commit-msg:') | Should -Be $true
        }

        It 'lefthook.yml has pre-commit hooks defined' {
            $f = Join-Path $script:root ".lefthook.yml"
            $content = Get-Content $f -Raw
            ($content -match 'pre-commit:') | Should -Be $true
        }
    }

    Context 'Security Configs' {
        It 'security-policy.json is valid JSON' {
            $f = Join-Path $script:configPath "security-policy.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'security-privacy.json is valid JSON' {
            $f = Join-Path $script:configPath "security-privacy.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'security-policy.json has authentication config' {
            $f = Join-Path $script:configPath "security-policy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.authentication | Should -Not -BeNullOrEmpty
        }

        It 'security-policy.json has accessControl config' {
            $f = Join-Path $script:configPath "security-policy.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.accessControl | Should -Not -BeNullOrEmpty
        }
    }

    Context 'hooks-config.json' {
        It 'hooks-config.json exists' {
            $f = Join-Path $script:configPath "hooks-config.json"
            Test-Path $f | Should -Be $true
        }

        It 'hooks-config.json is valid JSON' {
            $f = Join-Path $script:configPath "hooks-config.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'hooks-config.json defines hook scripts' {
            $f = Join-Path $script:configPath "hooks-config.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.hooks | Should -Not -BeNullOrEmpty
        }
    }
}



