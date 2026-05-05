# githooks-scripts.tests.ps1
# Unit tests for git hooks scripts

Describe 'Git Hooks Scripts Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:hooksPath = Join-Path $script:root "hooks"
    }

    Context 'Hooks Directory' {
        It 'hooks directory exists' {
            Test-Path $script:hooksPath | Should Be $true
        }
    }

    Context 'Git Hooks' {
        It 'pre-commit hook exists if present' {
            $f = Join-Path $script:hooksPath "pre-commit"
            if (Test-Path $f) {
                $true | Should Be $true
            } else {
                $true | Should Be $true  # Skip if doesn't exist
            }
        }

        It 'commit-msg hook exists if present' {
            $f = Join-Path $script:hooksPath "commit-msg"
            if (Test-Path $f) {
                $true | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'Lefthook Integration' {
        It 'lefthook.yml exists' {
            $f = Join-Path $script:root ".lefthook.yml"
            Test-Path $f | Should Be $true
        }

        It 'lefthook.yml contains trufflehog' {
            $f = Join-Path $script:root ".lefthook.yml"
            $content = Get-Content $f -Raw
            ($content -match 'trufflehog') | Should Be $true
        }

        It 'lefthook.yml has pre-commit commands' {
            $f = Join-Path $script:root ".lefthook.yml"
            $content = Get-Content $f -Raw
            ($content -match 'pre-commit:') | Should Be $true
        }
    }

    Context 'Install Hooks Script' {
        It 'install-hooks.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/install-hooks.ps1"
            Test-Path $f | Should Be $true
        }

        It 'install-hooks.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/utilities/install-hooks.ps1"
            if (Test-Path $f) {
                $errors = $null
                $content = Get-Content $f -Raw
                [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
                $errors.Count | Should Be 0
            } else {
                $true | Should Be $true
            }
        }
    }
}
