Describe 'Gentle-Vanguard Core Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    }

    Context 'Pre-Processing Hook' {
        It 'pre-process-input.ps1 exists and is non-empty' {
            $f = "$script:root\scripts\utilities\pre-process-input.ps1"
            Test-Path $f | Should Be $true
            (Get-Item $f).Length | Should BeGreaterThan 0
        }
    }

    Context 'Session Tools' {
        It 'session-autostart.cmd exists' {
            Test-Path "$script:root\scripts\utilities\session-autostart.cmd" | Should Be $true
        }

        It 'install-hooks.ps1 exists' {
            Test-Path "$script:root\scripts\utilities\install-hooks.ps1" | Should Be $true
        }

        It 'validate-configs.ps1 exists' {
            Test-Path "$script:root\scripts\utilities\validate-configs.ps1" | Should Be $true
        }

        It 'agent-verify.ps1 exists' {
            Test-Path "$script:root\scripts\utilities\agent-verify.ps1" | Should Be $true
        }
    }

    Context 'Security' {
        It 'security-policy.json is valid JSON' {
            { Get-Content "$script:root\config\security-policy.json" -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'security-privacy.json is valid JSON' {
            { Get-Content "$script:root\config\security-privacy.json" -Raw | ConvertFrom-Json } | Should Not Throw
        }
    }

    Context 'Canonical Config' {
        It 'auto-delegation.json is valid JSON' {
            { Get-Content "$script:root\config\auto-delegation.json" -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It 'auto-delegation.json has agentCodeToSkill' {
            $ad = Get-Content "$script:root\config\auto-delegation.json" -Raw | ConvertFrom-Json
            ($ad.agentCodeToSkill -ne $null) | Should Be $true
        }

        It 'auto-delegation.json has at least 10 keyword mappings' {
            $ad = Get-Content "$script:root\config\auto-delegation.json" -Raw | ConvertFrom-Json
            ($ad.keywordMappings | Get-Member -MemberType NoteProperty).Count | Should BeGreaterThan 10
        }
    }

    Context 'Skills' {
        It 'At least 80 skill directories exist' {
            $skills = Get-ChildItem -Path "$script:root\skills" -Directory -ErrorAction SilentlyContinue
            $skills.Count | Should BeGreaterThan 80
        }

        It 'sdd-lifecycle skill exists' {
            Test-Path "$script:root\skills\sdd-lifecycle" | Should Be $true
        }
    }

    Context 'Routing Regression Guards' {
        BeforeAll {
            $script:preProcess = Join-Path $script:root 'scripts\utilities\pre-process-input.ps1'
        }

        It 'routes new project creation to BA/SDD lifecycle' {
            $result = & $script:preProcess -UserInput 'pedi crear un nuevo proyecto' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.Skill | Should Be 'sdd-lifecycle'
            $summary.AgentCode | Should Be 'BA'
        }

        It 'routes new component creation to BA/SDD lifecycle' {
            $result = & $script:preProcess -UserInput 'crear componente nuevo' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.Skill | Should Be 'sdd-lifecycle'
            $summary.AgentCode | Should Be 'BA'
        }

        It 'routes Portuguese new project requests to BA/SDD lifecycle' {
            $result = & $script:preProcess -UserInput 'quero criar um novo projeto do zero' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.Skill | Should Be 'sdd-lifecycle'
            $summary.AgentCode | Should Be 'BA'
        }

        It 'routes explicit PR requests to branch-pr and not BA' {
            $result = & $script:preProcess -UserInput 'necesito abrir un PR' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.Skill | Should Be 'branch-pr'
            $summary.AgentCode | Should Be 'QA'
        }
    }

    Context 'SDD Feature Intent Detection (PLAN_MODE_REQUIRED)' {
        BeforeAll {
            $script:preProcess = Join-Path $script:root 'scripts\utilities\pre-process-input.ps1'
        }

        It 'forces PlanMode for Spanish feature request "implementar"' {
            $result = & $script:preProcess -UserInput 'implementar login con jwt' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.PlanMode | Should Be $true
            $summary.AgentCode | Should Be 'BA'
            $summary.Skill | Should Be 'sdd-lifecycle'
        }

        It 'forces PlanMode for "nueva funcionalidad"' {
            $result = & $script:preProcess -UserInput 'necesito una nueva funcionalidad de usuarios' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.PlanMode | Should Be $true
            $summary.AgentCode | Should Be 'BA'
        }

        It 'forces PlanMode for English "implement" without SDD mention' {
            $result = & $script:preProcess -UserInput 'implement login feature for the app' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.PlanMode | Should Be $true
            $summary.AgentCode | Should Be 'BA'
        }

        It 'forces PlanMode for English "new feature" keyword' {
            $result = & $script:preProcess -UserInput 'create a new feature for user dashboard' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.PlanMode | Should Be $true
            $summary.AgentCode | Should Be 'BA'
        }

        It 'does NOT force PlanMode for bug fix requests' {
            $result = & $script:preProcess -UserInput 'fix login bug error 401' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            # Bug fix goes to DEV/sdd-lifecycle, not PlanMode
            $summary.Skill | Should Be 'sdd-lifecycle'
        }

        It 'forces PlanMode for "feature request" keyword' {
            $result = & $script:preProcess -UserInput 'feature request: add dark mode' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.PlanMode | Should Be $true
            $summary.AgentCode | Should Be 'BA'
        }

        It 'forces PlanMode for "new component" in English' {
            $result = & $script:preProcess -UserInput 'create a new component for onboarding flow' -WorkspaceRoot $script:root
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            ($summary -ne $null) | Should Be $true
            $summary.HasMatch | Should Be $true
            $summary.PlanMode | Should Be $true
            $summary.AgentCode | Should Be 'BA'
        }
    }
}
