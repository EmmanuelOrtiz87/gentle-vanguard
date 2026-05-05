# skills-discovery.tests.ps1
# Unit tests for skills auto-discovery

Describe 'Skills Auto-Discovery Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:skillsPath = Join-Path $script:root "skills"
        $script:configPath = Join-Path $script:root "config"
    }

    Context 'Skills Directory' {
        It 'skills directory exists' {
            Test-Path $script:skillsPath | Should Be $true
        }

        It 'At least 100 skill directories exist' {
            $skills = Get-ChildItem -Path $script:skillsPath -Directory -ErrorAction SilentlyContinue
            $skills.Count | Should BeGreaterThan 100
        }

        It 'All skills have SKILL.md file' {
            $skills = Get-ChildItem -Path $script:skillsPath -Directory -ErrorAction SilentlyContinue
            $missingSkillDocs = @()
            foreach ($skill in $skills) {
                $skillDoc = Join-Path $skill.FullName "SKILL.md"
                if (-not (Test-Path $skillDoc)) {
                    $missingSkillDocs += $skill.Name
                }
            }
            $missingSkillDocs.Count | Should Be 0
        }
    }

    Context 'Auto-Delegation Config' {
        It 'auto-delegation.json exists' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            Test-Path $f | Should Be $true
        }

        It 'auto-delegation.json is valid JSON' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            { Get-Content $f -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'auto-delegation.json has keywordMappings' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.keywordMappings | Should Not BeNullOrEmpty
        }

        It 'auto-delegation.json has agentCodeToSkill' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            $json.agentCodeToSkill | Should Not BeNullOrEmpty
        }

        It 'auto-delegation.json has at least 10 keyword mappings' {
            $f = Join-Path $script:configPath "auto-delegation.json"
            $json = Get-Content $f -Raw | ConvertFrom-Json
            ($json.keywordMappings | Get-Member -MemberType NoteProperty).Count | Should BeGreaterThan 10
        }
    }

    Context 'Skills Auto-Discovery Script' {
        It 'skills-auto-discovery.ps1 exists' {
            $f = Join-Path $script:root "scripts/utilities/skills-auto-discovery.ps1"
            Test-Path $f | Should Be $true
        }

        It 'skills-auto-discovery.ps1 has valid PowerShell syntax' {
            $f = Join-Path $script:root "scripts/utilities/skills-auto-discovery.ps1"
            $errors = $null
            $content = Get-Content $f -Raw
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors) | Out-Null
            $errors.Count | Should Be 0
        }
    }
}
