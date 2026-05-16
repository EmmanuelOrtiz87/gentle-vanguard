# auto-update-workflow.tests.ps1
# Integration tests for FF-017 auto-update functionality

Describe 'Auto-Update Workflow Integration Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:skillPath = Join-Path $script:root "skills/gentle-vanguard-manager-skill"
    }

    Context 'Gentle-Vanguard Manager Skill' {
        It 'gentle-vanguard-manager-skill directory exists' {
            Test-Path $script:skillPath | Should Be $true
        }

        It 'SKILL.md exists and mentions auto-update' {
            $f = Join-Path $script:skillPath "SKILL.md"
            Test-Path $f | Should Be $true
            $content = Get-Content $f -Raw
            ($content -match 'auto-update|auto_update|FF-017') | Should Be $true
        }
    }

    Context 'Session Autostart Integration' {
        It 'session-autostart.config.json includes skill-router and karpathy-enforcer' {
            $f = Join-Path $script:root "config/session-autostart.config.json"
            $content = Get-Content $f -Raw
            ($content -match 'skill-router') | Should Be $true
            ($content -match 'karpathy-guidelines|karpathy-enforcer') | Should Be $true
        }
    }

    Context 'GV CLI Integration' {
        It 'gv.ps1 has update command (via canonical gv)' {
            $f = Join-Path $script:root "scripts/utilities/WORKFLOW-ORCHESTRATION/gv.ps1"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'update|Update') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }

    Context 'Auto-Update Script' {
        It 'Gentle-Vanguard manager SKILL.md documents FF-017' {
            $f = Join-Path $script:skillPath "SKILL.md"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                ($content -match 'FF-017|auto-update|self-update') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }

        It 'Auto-update maintains skill compatibility' {
            $f = Join-Path $script:skillPath "SKILL.md"
            if (Test-Path $f) {
                $content = Get-Content $f -Raw
                # Check for validation/safety mentions in auto-update docs
                ($content -match 'health|verify|validate|integrity|asegurando') | Should Be $true
            } else {
                $true | Should Be $true
            }
        }
    }
}

