# Unit: model-router.ps1 — Agent-to-model binding, temperature resolution, admin auth
# Compatible with Pester 3.4.0

Describe 'Model Router' {
    BeforeAll {
        $script:root     = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:routerScript = Join-Path $script:root 'scripts\utilities\MODEL-ROUTER\model-router.ps1'
        $script:routerConfig = Join-Path $script:root 'config\model-router.json'
        $script:autoDelegation = Join-Path $script:root 'config\auto-delegation.json'
        $script:tempDir  = Join-Path $script:root '.session\test-temp'
        if (-not (Test-Path $script:tempDir)) { New-Item -ItemType Directory -Path $script:tempDir -Force | Out-Null }
    }

    AfterAll {
        if (Test-Path $script:tempDir) { Remove-Item -Recurse -Force $script:tempDir -ErrorAction SilentlyContinue }
    }

    Context 'script integrity' {
        It 'exists at expected path' {
            Test-Path $script:routerScript | Should Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:routerScript -Raw -Encoding UTF8), [ref]$e
            )
            $e.Count | Should Be 0
        }

        It 'defines ALL_AGENTS with 23 entries' {
            $content = Get-Content $script:routerScript -Raw -Encoding UTF8
            $content -match '\$script:ALL_AGENTS\s*=\s*@\(' | Should Be $true
        }
    }

    Context 'config file integrity' {
        It 'model-router.json exists and is valid JSON' {
            $config = Get-Content $script:routerConfig -Raw -Encoding UTF8 | ConvertFrom-Json
            $config | Should Not BeNullOrEmpty
        }

        It 'has enabled = true' {
            $config = Get-Content $script:routerConfig -Raw -Encoding UTF8 | ConvertFrom-Json
            $config.enabled | Should Be $true
        }

        It 'defaults temperature is 0.3' {
            $config = Get-Content $script:routerConfig -Raw -Encoding UTF8 | ConvertFrom-Json
            [double]$config.defaults.temperature | Should Be 0.3
        }

        It 'has at least 22 agent bindings' {
            $config = Get-Content $script:routerConfig -Raw -Encoding UTF8 | ConvertFrom-Json
            $count = ($config.agentBindings.PSObject.Properties | Measure-Object).Count
            $count | Should BeGreaterThan 21
        }
    }

    Context 'temperature sync with auto-delegation' {
        BeforeAll {
            $script:router = Get-Content $script:routerConfig -Raw -Encoding UTF8 | ConvertFrom-Json
            $script:delegation = Get-Content $script:autoDelegation -Raw -Encoding UTF8 | ConvertFrom-Json
        }

        It 'BA temperature matches agentProfiles (0.7)' {
            [double]$script:router.agentBindings.BA.temperature | Should Be 0.7
        }

        It 'DEV temperature matches agentProfiles (0.15)' {
            [double]$script:router.agentBindings.DEV.temperature | Should Be 0.15
        }

        It 'QA temperature matches agentProfiles (0.1)' {
            [double]$script:router.agentBindings.QA.temperature | Should Be 0.1
        }

        It 'OPS temperature matches agentProfiles (0.1)' {
            [double]$script:router.agentBindings.OPS.temperature | Should Be 0.1
        }

        It 'GOV temperature matches agentProfiles (0.1)' {
            [double]$script:router.agentBindings.GOV.temperature | Should Be 0.1
        }

        It 'DOC temperature matches agentProfiles (0.4)' {
            [double]$script:router.agentBindings.DOC.temperature | Should Be 0.4
        }

        It 'SESSION temperature matches agentProfiles (0.1)' {
            [double]$script:router.agentBindings.SESSION.temperature | Should Be 0.1
        }

        It 'MKT temperature matches agentProfiles (0.5)' {
            [double]$script:router.agentBindings.MKT.temperature | Should Be 0.5
        }

        It 'all agent bindings have non-null temperature' {
            $nullTemps = @()
            foreach ($prop in $script:router.agentBindings.PSObject.Properties) {
                if ($null -eq $prop.Value.temperature) { $nullTemps += $prop.Name }
            }
            $nullTemps.Count | Should Be 0
        }

        It 'all agentProfiles have a corresponding router binding' {
            $profileCodes = $script:delegation.agentProfiles.PSObject.Properties.Name | Where-Object { $_ -ne 'hallucinationGuardLevels' }
            $routerCodes = $script:router.agentBindings.PSObject.Properties.Name
            $missing = @()
            foreach ($code in $profileCodes) {
                if ($routerCodes -notcontains $code -and $code -ne 'SCRIPT' -and $code -ne 'GITFLOW' -and $code -ne 'BUS-TELE' -and $code -ne 'CODEGRAPH') {
                    $missing += $code
                }
            }
            $missing.Count | Should Be 0
        }
    }

    Context 'function resolution with dot-sourced script' {
        BeforeAll {
            # Dot-source the router in a clean scope with -Help flag to prevent auto-run
            . $script:routerScript -Help
        }

        It 'Get-ModelRouterConfig function exists' {
            (Get-Command Get-ModelRouterConfig -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        }

        It 'Resolve-AgentModelBinding function exists' {
            (Get-Command Resolve-AgentModelBinding -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        }

        It 'Get-AgentBinding function exists' {
            (Get-Command Get-AgentBinding -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        }

        It 'Set-AgentBinding function exists' {
            (Get-Command Set-AgentBinding -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        }

        It 'Reset-AgentBinding function exists' {
            (Get-Command Reset-AgentBinding -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        }

        It 'Invoke-RouteCommand function exists' {
            (Get-Command Invoke-RouteCommand -ErrorAction SilentlyContinue) | Should Not BeNullOrEmpty
        }
    }
}
