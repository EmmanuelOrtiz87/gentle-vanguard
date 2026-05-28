#Requires -Version 7.0

Describe "Routing Critical Flows" {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
        $script:preProcess = Join-Path $script:repoRoot 'scripts\utilities\pre-process-input.ps1'
    }

    Context "Trigger-based routing" {
        It "Routes OPS deployment requests to docker-devops skill" {
            $result = & $script:preProcess -UserInput 'deploy to kubernetes with docker and helm' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should -Not -BeNullOrEmpty
            $summary.HasMatch | Should -Be $true
            $summary.Skill | Should -Be 'docker-devops-skill'
            $summary.AgentCode | Should -Be 'OPS'
        }

        It "Routes reporting requests to reporting skill" {
            $result = & $script:preProcess -UserInput 'crear dashboard con metrics y reporte ejecutivo' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should -Not -BeNullOrEmpty
            $summary.HasMatch | Should -Be $true
            @('reporting-skill', 'documentation-governance') -contains $summary.Skill | Should -Be $true
        }

        It "Routes new project requests to BA/SDD lifecycle" {
            $result = & $script:preProcess -UserInput 'pedi crear un nuevo proyecto' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should -Not -BeNullOrEmpty
            $summary.HasMatch | Should -Be $true
            $summary.Skill | Should -Be 'sdd-lifecycle'
            $summary.AgentCode | Should -Be 'BA'
        }

        It "Routes explicit PR requests to branch-pr" {
            $result = & $script:preProcess -UserInput 'necesito abrir un PR' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should -Not -BeNullOrEmpty
            $summary.HasMatch | Should -Be $true
            $summary.Skill | Should -Be 'branch-pr'
            $summary.AgentCode | Should -Be 'QA'
        }

        It "Routes Portuguese session start requests to session workflow" {
            $result = & $script:preProcess -UserInput 'iniciar sessao no gentle-vanguard' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should -Not -BeNullOrEmpty
            $summary.HasMatch | Should -Be $true
            $summary.Skill | Should -Be 'session-workflow-skill'
        }
    }

    Context "Low-confidence routing" {
        It "Activates BA plan mode for ambiguous requests" {
            $result = & $script:preProcess -UserInput 'do stuff quickly' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should -Not -BeNullOrEmpty
            $summary.HasMatch | Should -Be $false
            $summary.PlanMode | Should -Be $true
        }
    }
}




