# foundation-manager.tests.ps1
# Unit tests for foundation-manager-skill (FF-017 Auto-update)

Describe 'Foundation Manager Skill Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:skillPath = Join-Path $script:root "skills/foundation-manager-skill"
    }

    Context 'Foundation Manager Skill' {
        It 'foundation-manager-skill directory exists' {
            Test-Path $script:skillPath | Should Be $true
        }

        It 'SKILL.md exists' {
            $f = Join-Path $script:skillPath "SKILL.md"
            Test-Path $f | Should Be $true
        }

        It 'SKILL.md is non-empty' {
            $f = Join-Path $script:skillPath "SKILL.md"
            (Get-Item $f).Length | Should BeGreaterThan 0
        }

        It 'SKILL.md mentions auto-update' {
            $f = Join-Path $script:skillPath "SKILL.md"
            $content = Get-Content $f -Raw
            ($content -match 'auto-update|auto_update|AutoUpdate') | Should Be $true
        }

        It 'SKILL.md mentions update/sync/maintenance patterns' {
            $f = Join-Path $script:skillPath "SKILL.md"
            $content = Get-Content $f -Raw
            ($content -match 'update|sync|maintenance') | Should Be $true
        }
    }

    Context 'Foundation Manager Implementation' {
        It 'SKILL.md is the main implementation document' {
            $f = Join-Path $script:skillPath "SKILL.md"
            Test-Path $f | Should Be $true
        }

        It 'Skill follows FF-017 auto-update pattern' {
            $f = Join-Path $script:skillPath "SKILL.md"
            $content = Get-Content $f -Raw
            ($content -match 'auto-update|self-update|update.*skill') | Should Be $true
        }
    }
}
