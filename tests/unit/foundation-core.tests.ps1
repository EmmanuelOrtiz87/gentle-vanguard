Describe 'Foundation Core Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent
    }

    Context 'Session Management' {
        It 'Session manager exists' {
            Test-Path "$script:root\scripts\utilities\session-manager.ps1" | Should Be $true
        }
    }

    Context 'Security' {
        It 'Security orchestrator exists' {
            Test-Path "$script:root\scripts\security\security-orchestrator.ps1" | Should Be $true
        }

        It 'Security config exists' {
            Test-Path "$script:root\config\security-privacy.json" | Should Be $true
        }
    }

    Context 'Skills' {
        It 'Skill router exists' {
            Test-Path "$script:root\scripts\utilities\skill-router.ps1" | Should Be $true
        }

        It 'At least 90 skills exist' {
            $skills = Get-ChildItem -Path "$script:root\skills" -Directory -ErrorAction SilentlyContinue
            $skills.Count | Should BeGreaterThan 90
        }
    }
}