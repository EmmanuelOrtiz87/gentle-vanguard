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

            $summary | Should Not BeNullOrEmpty
            $summary.HasMatch | Should Be $true
            $summary.Skill | Should Be 'docker-devops-skill'
            $summary.AgentCode | Should Be 'OPS'
        }

        It "Routes reporting requests to reporting skill" {
            $result = & $script:preProcess -UserInput 'crear dashboard con metrics y reporte ejecutivo' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should Not BeNullOrEmpty
            $summary.HasMatch | Should Be $true
            $summary.Skill | Should Be 'reporting-skill'
        }
    }

    Context "Low-confidence routing" {
        It "Activates BA plan mode for ambiguous requests" {
            $result = & $script:preProcess -UserInput 'do stuff quickly' -WorkspaceRoot $script:repoRoot
            $summary = $result | Where-Object { $_ -is [hashtable] } | Select-Object -Last 1

            $summary | Should Not BeNullOrEmpty
            $summary.HasMatch | Should Be $false
            $summary.PlanMode | Should Be $true
        }
    }
}
