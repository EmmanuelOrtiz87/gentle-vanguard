#!/usr/bin/env pwsh

Describe 'Session Autostart Integration Tests' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:sessionAutostart = Join-Path $script:root 'scripts\utilities\session-autostart.ps1'
        $script:tempRoot = Join-Path $script:root 'tmp-session-autostart-integration-tests'
        $script:originalGentle-VanguardBaseDir = $env:GV_BASE_DIR
    }

    BeforeEach {
        if (Test-Path $script:tempRoot) {
            Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        New-Item -ItemType Directory -Path (Join-Path $script:tempRoot 'config') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:tempRoot 'scripts\utilities') -Force | Out-Null
        $env:GV_BASE_DIR = $script:tempRoot
    }

    AfterEach {
        if ($null -eq $script:originalGentle-VanguardBaseDir) {
            Remove-Item Env:GV_BASE_DIR -ErrorAction SilentlyContinue
        } else {
            $env:GV_BASE_DIR = $script:originalGentle-VanguardBaseDir
        }

        if (Test-Path $script:tempRoot) {
            Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }

        $global:LASTEXITCODE = 0
    }

    function Set-TestConfig {
        param([object[]]$Steps)

        $configPath = Join-Path $script:tempRoot 'config\session-autostart.config.json'
        $config = @{
            pipeline = @{
                steps = $Steps
            }
        }

        $config | ConvertTo-Json -Depth 6 | Set-Content -Path $configPath -Encoding UTF8
        return $configPath
    }

    function Set-TestScript {
        param(
            [string]$Name,
            [string]$Content
        )

        $scriptPath = Join-Path $script:tempRoot "scripts\utilities\$Name"
        $Content | Set-Content -Path $scriptPath -Encoding UTF8
        return $scriptPath
    }

    It 'executes enabled steps with args and ignores disabled steps' {
        $markerPath = Join-Path $script:tempRoot 'echo-marker.txt'
        $disabledMarkerPath = Join-Path $script:tempRoot 'disabled-marker.txt'

        Set-TestScript -Name 'echo-step.ps1' -Content @'
param([string]$Name)
Set-Content -Path (Join-Path $env:GV_BASE_DIR 'echo-marker.txt') -Value $Name -Encoding UTF8
'@ | Out-Null

        Set-TestScript -Name 'disabled-step.ps1' -Content @'
param()
Set-Content -Path (Join-Path $env:GV_BASE_DIR 'disabled-marker.txt') -Value 'disabled' -Encoding UTF8
'@ | Out-Null

        $configPath = Set-TestConfig -Steps @(
            @{
                id = 'echo-step'
                enabled = $true
                script = 'scripts/utilities/echo-step.ps1'
                args = '-Name alpha'
                required = $true
            },
            @{
                id = 'disabled-step'
                enabled = $false
                script = 'scripts/utilities/disabled-step.ps1'
                args = ''
                required = $false
            }
        )

        $output = & $script:sessionAutostart -ConfigFile $configPath -NoExit 2>&1

        Test-Path $markerPath | Should Be $true
        (Get-Content -Path $markerPath -Raw).Trim() | Should Be 'alpha'
        Test-Path $disabledMarkerPath | Should Be $false
        $output[-1] | Should Be 0
    }

    It 'skips missing non-required scripts and still succeeds' {
        $markerPath = Join-Path $script:tempRoot 'ok-marker.txt'

        Set-TestScript -Name 'ok-step.ps1' -Content @'
param()
    Set-Content -Path (Join-Path $env:GV_BASE_DIR 'ok-marker.txt') -Value 'ok' -Encoding UTF8
'@ | Out-Null

        $configPath = Set-TestConfig -Steps @(
            @{
                id = 'missing-optional'
                enabled = $true
                script = 'scripts/utilities/missing-optional.ps1'
                args = ''
                required = $false
            },
            @{
                id = 'ok-step'
                enabled = $true
                script = 'scripts/utilities/ok-step.ps1'
                args = ''
                required = $true
            }
        )

        $output = & $script:sessionAutostart -ConfigFile $configPath -NoExit 2>&1

        Test-Path $markerPath | Should Be $true
        (Get-Content -Path $markerPath -Raw).Trim() | Should Be 'ok'
        $output[-1] | Should Be 0
    }

    It 'returns failure when the config file is missing' {
        $missingConfigPath = Join-Path $script:tempRoot 'config\missing-config.json'

        $output = & $script:sessionAutostart -ConfigFile $missingConfigPath -NoExit 2>&1

        $output[-1] | Should Be 1
    }

    It 'records non-required non-zero exit codes and continues' {
        $markerPath = Join-Path $script:tempRoot 'soft-fail-marker.txt'

        Set-TestScript -Name 'soft-fail-step.ps1' -Content @'
param()
    Set-Content -Path (Join-Path $env:GV_BASE_DIR 'soft-fail-marker.txt') -Value 'soft-fail' -Encoding UTF8
$global:LASTEXITCODE = 9
'@ | Out-Null

        $configPath = Set-TestConfig -Steps @(
            @{
                id = 'soft-fail-step'
                enabled = $true
                script = 'scripts/utilities/soft-fail-step.ps1'
                args = ''
                required = $false
            }
        )

        $output = & $script:sessionAutostart -ConfigFile $configPath -NoExit 2>&1

        Test-Path $markerPath | Should Be $true
        (Get-Content -Path $markerPath -Raw).Trim() | Should Be 'soft-fail'
        $output[-1] | Should Be 0
    }

    It 'fails when a required step throws an exception' {
        $markerPath = Join-Path $script:tempRoot 'throw-marker.txt'

        Set-TestScript -Name 'throw-step.ps1' -Content @'
param()
Set-Content -Path (Join-Path $env:GV_BASE_DIR 'throw-marker.txt') -Value 'started' -Encoding UTF8
throw 'boom'
'@ | Out-Null

        $configPath = Set-TestConfig -Steps @(
            @{
                id = 'throw-step'
                enabled = $true
                script = 'scripts/utilities/throw-step.ps1'
                args = ''
                required = $true
            }
        )

        $output = & $script:sessionAutostart -ConfigFile $configPath -NoExit 2>&1

        Test-Path $markerPath | Should Be $true
        (Get-Content -Path $markerPath -Raw).Trim() | Should Be 'started'
        $output[-1] | Should Be 1
    }

    It 'fails when a required script is missing' {
        $configPath = Set-TestConfig -Steps @(
            @{
                id = 'missing-required'
                enabled = $true
                script = 'scripts/utilities/missing-required.ps1'
                args = ''
                required = $true
            }
        )

        $output = & $script:sessionAutostart -ConfigFile $configPath -NoExit 2>&1

        Test-Path (Join-Path $script:tempRoot 'scripts\utilities\missing-required.ps1') | Should Be $false
        $output[-1] | Should Be 1
    }
}

