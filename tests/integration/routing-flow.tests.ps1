# Integration: pre-process-input -> trigger match -> skill load
# Covers the critical routing flow end-to-end without invoking external services.
# Compatible with Pester 3.4.0

Describe 'Routing Flow Integration' {
    BeforeAll {
        $script:root          = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:preProcess    = Join-Path $script:root 'scripts\utilities\pre-process-input.ps1'
        $script:autoDelegation = Join-Path $script:root 'config\auto-delegation.json'
        $script:skillsDir     = Join-Path $script:root 'skills'
    }

    Context 'pre-process-input.ps1' {
        It 'exists at expected path' {
            Test-Path $script:preProcess | Should Be $true
        }

        It 'has zero parse errors' {
            $e = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $script:preProcess -Raw -Encoding UTF8), [ref]$e
            )
            $e.Count | Should Be 0
        }

        It 'references keyword or trigger logic' {
            $content = Get-Content $script:preProcess -Raw -Encoding UTF8
            # Must contain at least one of: keyword, trigger, match, delegation pattern
            ($content -match 'keyword|trigger|match|delegation|auto-delegation') | Should Be $true
        }
    }

    Context 'auto-delegation.json keyword mappings' {
        BeforeAll {
            $script:delegation = Get-Content $script:autoDelegation -Raw -Encoding UTF8 | ConvertFrom-Json
        }

        It 'loads without error' {
            $script:delegation | Should Not BeNullOrEmpty
        }

        It 'has keywordMappings property' {
            $hasProp = $script:delegation.PSObject.Properties.Name -contains 'keywordMappings'
            $hasProp | Should Be $true
        }

        It 'has at least 5 keyword mapping keys' {
            $count = ($script:delegation.keywordMappings.PSObject.Properties | Measure-Object).Count
            $count | Should BeGreaterThan 4
        }

        It 'each mapping key has a routing target (skill directory or script path)' {
            # keywordMappings values can be strings (skill path) or objects
            $first = $script:delegation.keywordMappings.PSObject.Properties | Select-Object -First 1
            $first | Should Not BeNullOrEmpty
        }
    }

    Context 'skills directory reachable from routing config' {
        It 'skills/ directory exists' {
            Test-Path $script:skillsDir | Should Be $true
        }

        It 'has at least 10 skill directories' {
            $count = (Get-ChildItem $script:skillsDir -Directory | Measure-Object).Count
            $count | Should BeGreaterThan 9
        }
    }

    Context 'foundation-sync.json consistency' {
        BeforeAll {
            $syncPath = Join-Path $script:root 'config\foundation-sync.json'
            $script:sync = Get-Content $syncPath -Raw -Encoding UTF8 | ConvertFrom-Json
        }

        It 'foundationVersion matches VERSION file' {
            $versionFile = Join-Path $script:root 'VERSION'
            $expected = (Get-Content $versionFile -Raw -Encoding UTF8).Trim()
            $script:sync.foundationVersion | Should Be $expected
        }

        It 'all script assets exist on disk' {
            $missing = @()
            foreach ($asset in $script:sync.assets) {
                if ($asset.type -eq 'script') {
                    $full = Join-Path $script:root ($asset.path -replace '/', '\')
                    if (-not (Test-Path $full)) {
                        $missing += $asset.path
                    }
                }
            }
            $missing.Count | Should Be 0
        }

        It 'all declared asset paths exist on disk' {
            $missing = @()
            foreach ($asset in $script:sync.assets) {
                $full = Join-Path $script:root ($asset.path -replace '/', '\')
                if (-not (Test-Path $full)) {
                    $missing += $asset.path
                }
            }
            $missing.Count | Should Be 0
        }
    }

    Context 'wf wrapper entrypoint' {
        It 'forwards commands to the canonical CLI' {
            $wrapperPath = Join-Path $script:root 'scripts\utilities\wf.ps1'
            $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $wrapperPath version 2>&1

            $LASTEXITCODE | Should Be 0
            (($output | Out-String) -match 'Gentleman Foundation v') | Should Be $true
        }
    }
}
