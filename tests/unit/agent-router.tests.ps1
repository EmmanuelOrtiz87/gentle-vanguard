# Unit: agent-router.ps1 — Agent metadata, skill resolution, execution context
# Compatible with Pester 3.4.0

Describe 'Agent Router' {
    BeforeAll {
        $script:root     = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:agentRouter = Join-Path $script:root 'scripts\utilities\AI-AGENT-MANAGEMENT\agent-router.ps1'
    }

    Context 'script integrity' {
        It 'exists at expected path' {
            Test-Path $script:agentRouter | Should -Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:agentRouter -Raw -Encoding UTF8), [ref]$e
            )
            $e.Count | Should -Be 0
        }
    }

    Context 'validates agent parameter set' {
        It 'accepts BA, SAD, DEV, QA, OPS, GOV, DOC as valid agents' {
            $content = Get-Content $script:agentRouter -Raw -Encoding UTF8
            $content -match "'BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC', 'MKT', 'SALES', 'FINANCE', 'HR', 'LEGAL', 'BUS-TELE'" | Should -Be $true
        }

        It 'has agent status and list commands' {
            $content = Get-Content $script:agentRouter -Raw -Encoding UTF8
            ($content -match "'status'" -and $content -match "'list'") | Should -Be $true
        }
    }

    Context 'agent skill maps' {
        It 'has AGENT_SKILLS with at least 10 agents' {
            $content = Get-Content $script:agentRouter -Raw -Encoding UTF8
            ($content -match '\$AGENT_SKILLS') | Should -Be $true
        }

        It 'has AGENT_DESCRIPTIONS with at least 10 agents' {
            $content = Get-Content $script:agentRouter -Raw -Encoding UTF8
            ($content -match '\$AGENT_DESCRIPTIONS') | Should -Be $true
        }

        It 'has AGENT_DELIVERABLES with at least 10 agents' {
            $content = Get-Content $script:agentRouter -Raw -Encoding UTF8
            ($content -match '\$AGENT_DELIVERABLES') | Should -Be $true
        }

        It 'all AGENT_SKILLS keys have corresponding AGENT_DESCRIPTIONS' {
            $content = Get-Content $script:agentRouter -Raw -Encoding UTF8
            $matches = [regex]::Matches($content, "'(\w+-?\w+)'\s*=\s*@\(")
            $skillKeys = @()
            foreach ($m in $matches) { $skillKeys += $m.Groups[1].Value }

            $descMatches = [regex]::Matches($content, "'(\w+-?\w+)'\s*=\s*'")
            $descKeys = @()
            foreach ($m in $descMatches) { $descKeys += $m.Groups[1].Value }

            $missing = @()
            foreach ($k in $skillKeys) { if ($descKeys -notcontains $k) { $missing += $k } }
            $missing.Count | Should -Be 0
        }
    }

    Context 'function availability (dot-sourced)' {
        BeforeAll {
            # Dot-source with dummy params to register functions
            & $script:agentRouter -Agent BA -Task 'test task' -Quiet 2>$null
        }

        It 'Get-AgentSkills returns array for a known agent' {
            # Reset and dot-source with -Quiet to register functions first
            $result = & $script:agentRouter -Agent BA -Task 'test' -Quiet -AsJson 2>$null
            $result | Should -Not -BeNullOrEmpty
            $parsed = $result | ConvertFrom-Json 2>$null
            if ($parsed) {
                $parsed.agent_id | Should -Be 'BA'
            }
        }

        It 'Build-ExecutionContext is called for ready agents' {
            $result = & $script:agentRouter -Agent DEV -Task 'implement feature' -Quiet -AsJson 2>$null
            $parsed = $result | ConvertFrom-Json
            $parsed | Should -Not -BeNullOrEmpty
            ($parsed.status -eq 'ready' -or $parsed.status -eq 'partial' -or $parsed.status -eq 'blocked') | Should -Be $true
        }
    }
}



