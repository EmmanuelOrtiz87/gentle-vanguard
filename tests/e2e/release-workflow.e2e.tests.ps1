#!/usr/bin/env pwsh
<#
.SYNOPSIS
    E2E Tests - Release Workflow & Homologation Gate.
.DESCRIPTION
    End-to-end tests for the release workflow homologation gate.
    Tests use temporary git repositories to verify gate behavior
    under controlled conditions without touching the actual repos.
.NOTES
    Requires: Pester 3.x, git
    Isolation: Temp directories created per test, cleaned up in AfterAll
    Coverage: validate-release-homologation.ps1 core logic
#>

# Script-scope setup (Pester v3: top-level code runs before any Describe)
$script:repoRoot = (Get-Item "$PSScriptRoot\..\..").FullName
$script:gateScript = Join-Path $script:repoRoot "scripts\utilities\DEPLOYMENT\validate-release-homologation.ps1"
$script:tempBase = Join-Path $env:TEMP "fe2e-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $script:tempBase -Force | Out-Null

function New-TempRepo {
    param(
        [string]$Name,
        [string]$Version = "1.0.0",
        [bool]$InitRemote = $true,
        [bool]$WithDirtyTree = $false
    )
    $repoPath = Join-Path $script:tempBase $Name
    New-Item -ItemType Directory -Path $repoPath -Force | Out-Null
    $null = git -C $repoPath init --initial-branch=main 2>&1
    $null = git -C $repoPath config user.email "test@test.com" 2>&1
    $null = git -C $repoPath config user.name "Test" 2>&1
    Set-Content -Path "$repoPath\VERSION" -Value $Version
    Set-Content -Path "$repoPath\README.md" -Value "# $Name"
    New-Item -ItemType Directory -Path "$repoPath\config" -Force | Out-Null
    Set-Content -Path "$repoPath\config\orchestrator.json" -Value '{"version":"1.0"}'
    $null = git -C $repoPath add . 2>&1
    $null = git -C $repoPath commit -m "init" 2>&1
    $null = git -C $repoPath checkout -b develop 2>&1
    $null = git -C $repoPath checkout main 2>&1
    if ($InitRemote) {
        $remotePath = Join-Path $script:tempBase "$Name-remote"
        New-Item -ItemType Directory -Path $remotePath -Force | Out-Null
        $null = git -C $remotePath init --bare --initial-branch=main 2>&1
        $null = git -C $repoPath remote add origin $remotePath 2>&1
        $null = git -C $repoPath push -u origin main 2>&1
        $null = git -C $repoPath push origin develop 2>&1
    }
    if ($WithDirtyTree) {
        Set-Content -Path "$repoPath\dirty-file.txt" -Value "uncommitted change"
    }
    return $repoPath
}

function Invoke-Gate {
    param(
        [string]$GentleVanguardRepo,
        [string]$PublicRepo,
        [string]$ExpectedTag = "",
        [bool]$AsJson = $false
    )
    $gateScriptEscaped = $script:gateScript.Replace("'", "''")
    $fEscaped = $GentleVanguardRepo.Replace("'", "''")
    $pEscaped = $PublicRepo.Replace("'", "''")
    $cmd = "& '$gateScriptEscaped' -GentleVanguardRepoPath '$fEscaped' -PublicRepoPath '$pEscaped'"
    if ($ExpectedTag) { $cmd += " -ExpectedTag '$ExpectedTag'" }
    if ($AsJson) { $cmd += " -AsJson" }
    $output = pwsh -NoProfile -Command $cmd 2>&1
    return $output
}

# Tests
Describe "Homologation Gate - Script availability" {
    AfterAll {
        if (Test-Path $script:tempBase) {
            Remove-Item -Recurse -Force $script:tempBase -ErrorAction SilentlyContinue
        }
    }

    It "Gate script exists at expected path" {
        Test-Path $script:gateScript | Should Be $true
    }

    It "Gate script is valid PowerShell syntax" {
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($script:gateScript, [ref]$null, [ref]([ref]$errors))
        $errors | Should BeNullOrEmpty
    }
}

Describe "Homologation Gate - VERSION alignment" {
    It "PASSES when both repos have identical VERSION" {
        $f = New-TempRepo -Name "f-va-1" -Version "1.0.0"
        $p = New-TempRepo -Name "p-va-1" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $check = $result.checks | Where-Object { $_.Name -eq "VERSION alignment" }
        $check.Passed | Should Be $true
    }

    It "FAILS when gentle_vanguard VERSION is newer than public" {
        $f = New-TempRepo -Name "f-va-2" -Version "1.0.0"
        $p = New-TempRepo -Name "p-va-2" -Version "1.0.0"
        Set-Content -Path "$f\VERSION" -Value "1.0.1"
        $null = git -C $f add VERSION 2>&1
        $null = git -C $f commit -m "bump" 2>&1
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $check = $result.checks | Where-Object { $_.Name -eq "VERSION alignment" }
        $check.Passed | Should Be $false
    }

    It "FAILS when public VERSION is ahead of gentle_vanguard" {
        $f = New-TempRepo -Name "f-va-3" -Version "1.0.0"
        $p = New-TempRepo -Name "p-va-3" -Version "2.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $result.summary.status | Should Be "FAIL"
    }

    It "Detail field shows both VERSION values on mismatch" {
        $f = New-TempRepo -Name "f-va-4" -Version "1.2.3"
        $p = New-TempRepo -Name "p-va-4" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $check = $result.checks | Where-Object { $_.Name -eq "VERSION alignment" }
        $check.Detail | Should Match "gentle-vanguard="
        $check.Detail | Should Match "gentle-vanguard-public="
    }

    It "Returns exit code 1 on VERSION mismatch" {
        $f = New-TempRepo -Name "f-va-5" -Version "2.0.0"
        $p = New-TempRepo -Name "p-va-5" -Version "1.0.0"
        $gateEscaped = $script:gateScript.Replace("'", "''")
        pwsh -NoProfile -Command "& '$gateEscaped' -GentleVanguardRepoPath '$($f.Replace("'","''"))' -PublicRepoPath '$($p.Replace("'","''"))' | Out-Null; exit `$LASTEXITCODE"
        $LASTEXITCODE | Should Be 1
    }
}

Describe "Homologation Gate - Working tree cleanliness" {
    It "PASSES when both repos have clean working trees" {
        $f = New-TempRepo -Name "f-dirty-1" -Version "1.0.0"
        $p = New-TempRepo -Name "p-dirty-1" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $cleanChecks = $result.checks | Where-Object { $_.Name -like "*working tree clean*" }
        $cleanChecks | ForEach-Object { $_.Passed | Should Be $true }
    }

    It "FAILS when gentle_vanguard repo has uncommitted changes" {
        $f = New-TempRepo -Name "f-dirty-2" -Version "1.0.0" -WithDirtyTree $true
        $p = New-TempRepo -Name "p-dirty-2" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $check = $result.checks | Where-Object { $_.Name -eq "gentle-vanguard working tree clean" }
        $check.Passed | Should Be $false
    }

    It "Detail field mentions uncommitted changes when dirty" {
        $f = New-TempRepo -Name "f-dirty-3" -Version "1.0.0" -WithDirtyTree $true
        $p = New-TempRepo -Name "p-dirty-3" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $check = $result.checks | Where-Object { $_.Name -eq "gentle-vanguard working tree clean" }
        $check.Detail | Should Match "Uncommitted"
    }
}

Describe "Homologation Gate - JSON output structure" {
    It "Returns valid parseable JSON with -AsJson" {
        $f = New-TempRepo -Name "f-json-1" -Version "1.0.0"
        $p = New-TempRepo -Name "p-json-1" -Version "1.0.0"
        $output = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true
        { $output | ConvertFrom-Json } | Should Not Throw
    }

    It "Has required top-level fields: timestamp, gentle-vanguard, public, checks, summary" {
        $f = New-TempRepo -Name "f-json-2" -Version "1.0.0"
        $p = New-TempRepo -Name "p-json-2" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $result.timestamp | Should Not BeNullOrEmpty
        $result.'gentle-vanguard' | Should Not BeNullOrEmpty
        $result.public | Should Not BeNullOrEmpty
        $result.checks | Should Not BeNullOrEmpty
        $result.summary | Should Not BeNullOrEmpty
    }

    It "Summary has: total (>0), status (PASS or FAIL)" {
        $f = New-TempRepo -Name "f-json-3" -Version "1.0.0"
        $p = New-TempRepo -Name "p-json-3" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $result.summary.total | Should BeGreaterThan 0
        ($result.summary.status -eq "PASS" -or $result.summary.status -eq "FAIL") | Should Be $true
    }

    It "Each check has Name, Passed, and Detail fields" {
        $f = New-TempRepo -Name "f-json-4" -Version "1.0.0"
        $p = New-TempRepo -Name "p-json-4" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        foreach ($check in $result.checks) {
            $check.Name | Should Not BeNullOrEmpty
            ($check.PSObject.Properties.Name -contains "Passed") | Should Be $true
            $check.Detail | Should Not BeNullOrEmpty
        }
    }
}

Describe "Homologation Gate - Tag consistency (-ExpectedTag)" {
    It "Does NOT include tag checks when -ExpectedTag is omitted" {
        $f = New-TempRepo -Name "f-tag-1" -Version "1.0.0"
        $p = New-TempRepo -Name "p-tag-1" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -AsJson $true | ConvertFrom-Json
        $tagChecks = $result.checks | Where-Object { $_.Name -match "Tag|tag" }
        $tagChecks.Count | Should Be 0
    }

    It "Includes tag-related checks when -ExpectedTag is provided" {
        $f = New-TempRepo -Name "f-tag-2" -Version "1.0.0"
        $p = New-TempRepo -Name "p-tag-2" -Version "1.0.0"
        $result = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p -ExpectedTag "v1.0.0" -AsJson $true | ConvertFrom-Json
        $tagChecks = $result.checks | Where-Object { $_.Name -match "Tag|tag" }
        $tagChecks.Count | Should BeGreaterThan 0
    }
}

Describe "Homologation Gate - Error handling" {
    It "Exits non-zero when gentle_vanguard repo path does not exist" {
        $badPath = "C:\nonexistent-e2e-$(Get-Random)"
        $p = New-TempRepo -Name "p-err-1" -Version "1.0.0"
        $gateEscaped = $script:gateScript.Replace("'", "''")
        pwsh -NoProfile -Command "& '$gateEscaped' -GentleVanguardRepoPath '$badPath' -PublicRepoPath '$($p.Replace("'","''"))' | Out-Null; exit `$LASTEXITCODE"
        $LASTEXITCODE | Should Not Be 0
    }

    It "Exits non-zero when VERSION file is missing" {
        $noVersionPath = Join-Path $script:tempBase "no-ver-$(Get-Random)"
        New-Item -ItemType Directory -Path $noVersionPath -Force | Out-Null
        $null = git -C $noVersionPath init --initial-branch=main 2>&1
        $null = git -C $noVersionPath config user.email "t@t.com" 2>&1
        $null = git -C $noVersionPath config user.name "T" 2>&1
        New-Item -ItemType Directory -Path "$noVersionPath\config" -Force | Out-Null
        Set-Content -Path "$noVersionPath\config\orchestrator.json" -Value "{}"
        Set-Content -Path "$noVersionPath\README.md" -Value "no version here"
        $null = git -C $noVersionPath add . 2>&1
        $null = git -C $noVersionPath commit -m "init no version" 2>&1
        $p = New-TempRepo -Name "p-err-2" -Version "1.0.0"
        $gateEscaped = $script:gateScript.Replace("'", "''")
        pwsh -NoProfile -Command "& '$gateEscaped' -GentleVanguardRepoPath '$($noVersionPath.Replace("'","''"))' -PublicRepoPath '$($p.Replace("'","''"))' | Out-Null; exit `$LASTEXITCODE" 2>&1 | Out-Null
        $LASTEXITCODE | Should Not Be 0
    }
}

Describe "Release Workflow Integration - gv.ps1 wiring" {
    $script:wfContent = Get-Content (Join-Path $script:repoRoot "scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1") -Raw

    It "gv.ps1 references validate-release-homologation.ps1" {
        $script:wfContent | Should Match "validate-release-homologation"
    }

    It "gv.ps1 publish exposes -SkipHomologationGate parameter" {
        $script:wfContent | Should Match "SkipHomologationGate"
    }

    It "Homologation gate is positioned BEFORE test gate in publish flow" {
        $homologationPos = $script:wfContent.IndexOf("Homologation Gate")
        $testsPos = $script:wfContent.IndexOf("Test-GoTests")
        $homologationPos | Should BeLessThan $testsPos
    }
}

Describe "Release Workflow Integration - Human output format" {
    It "Human-readable output contains [PASS] or [FAIL] indicators" {
        $f = New-TempRepo -Name "f-fmt-1" -Version "1.0.0"
        $p = New-TempRepo -Name "p-fmt-1" -Version "1.0.0"
        $output = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p
        $outputStr = $output -join "`n"
        ($outputStr -match "\[PASS\]" -or $outputStr -match "\[FAIL\]") | Should Be $true
    }

    It "Human-readable output includes Result summary line" {
        $f = New-TempRepo -Name "f-fmt-2" -Version "1.0.0"
        $p = New-TempRepo -Name "p-fmt-2" -Version "1.0.0"
        $output = Invoke-Gate -GentleVanguardRepo $f -PublicRepo $p
        $outputStr = $output -join "`n"
        $outputStr | Should Match "Result:"
    }
}
