#!/usr/bin/env pwsh
# =============================================================================
#  agent-verify.ps1 — Self-Verification Tool for AI Agents
# =============================================================================
#
#  Run this after completing ANY significant work to validate the result.
#  The agent MUST run this and fix all FAIL items before considering the
#  task done. WARN items should be reviewed but do not block.
#
#  Usage:
#    pwsh -File scripts/utilities/agent-verify.ps1
#    pwsh -File scripts/utilities/agent-verify.ps1 -Domain config
#    pwsh -File scripts/utilities/agent-verify.ps1 -Json
#    pwsh -File scripts/utilities/agent-verify.ps1 -Domain tests -Verbose
#
#  Domains: all | config | tests | hooks | structure | skills
#  Exit:    0 = all pass (or warnings only), 1 = one or more FAIL
# =============================================================================

param(
    [ValidateSet("all","config","tests","hooks","structure","skills")]
    [string]$Domain = "all",
    [switch]$Json,
    [switch]$Verbose
)

$ErrorActionPreference = 'SilentlyContinue'

# Resolve workspace root regardless of where the script is called from
$Root = git -C $PSScriptRoot rev-parse --show-toplevel 2>$null
if (-not $Root) { $Root = (Get-Location).Path }
Set-Location $Root

$Results  = [System.Collections.Generic.List[PSCustomObject]]::new()
$Errors   = 0
$Warnings = 0

function Add-Result {
    param([string]$Check, [string]$Status, [string]$Message, [string]$Category)
    $script:Results.Add([PSCustomObject]@{
        check    = $Check
        status   = $Status   # PASS | FAIL | WARN
        message  = $Message
        category = $Category
    })
    if ($Status -eq "FAIL") { $script:Errors++ }
    if ($Status -eq "WARN") { $script:Warnings++ }
}

# =============================================================================
#  DOMAIN: config
#  - All config/*.json files are valid JSON
#  - auto-delegation.json has required keys
#  - agentCodeToSkill values are non-empty strings
# =============================================================================
if ($Domain -in @("all","config")) {
    # JSON syntax
    $ConfigFiles = Get-ChildItem "$Root\config\*.json" -ErrorAction SilentlyContinue
    $JsonFails = @()
    foreach ($f in $ConfigFiles) {
        try { Get-Content $f.FullName -Raw | ConvertFrom-Json | Out-Null }
        catch { $JsonFails += $f.Name }
    }
    if ($JsonFails.Count -eq 0) {
        Add-Result "json-syntax" "PASS" "All $($ConfigFiles.Count) config JSONs valid" "config"
    } else {
        Add-Result "json-syntax" "FAIL" "Invalid JSON: $($JsonFails -join ', ')" "config"
    }

    # auto-delegation.json required keys
    $AdPath = "$Root\config\auto-delegation.json"
    if (Test-Path $AdPath) {
        try {
            $ad = Get-Content $AdPath -Raw | ConvertFrom-Json
            $required = @("keywordMappings","agentCodeToSkill","agentProfiles","fallbackStrategy")
            $missing  = $required | Where-Object { -not $ad.PSObject.Properties[$_] }
            if ($missing.Count -eq 0) {
                Add-Result "auto-delegation-keys" "PASS" "Required keys present ($($required -join ', '))" "config"
            } else {
                Add-Result "auto-delegation-keys" "FAIL" "Missing keys: $($missing -join ', ')" "config"
            }
        } catch {
            Add-Result "auto-delegation-keys" "FAIL" "Cannot parse auto-delegation.json: $_" "config"
        }
    } else {
        Add-Result "auto-delegation-keys" "FAIL" "config/auto-delegation.json not found" "config"
    }
}

# =============================================================================
#  DOMAIN: skills
#  - Every agentCodeToSkill value resolves to a real directory
#    (checks user skill store first, then local skills/)
# =============================================================================
if ($Domain -in @("all","skills")) {
    $AdPath = "$Root\config\auto-delegation.json"
    if (Test-Path $AdPath) {
        try {
            $ad = Get-Content $AdPath -Raw | ConvertFrom-Json
            $skillMap  = $ad.agentCodeToSkill
            $UserBase  = "C:\Users\emman\.claude\skills"
            $LocalBase = "$Root\skills"
            $badSkills = @()
            foreach ($prop in $skillMap.PSObject.Properties) {
                if ($prop.Name -eq "description") { continue }
                $skillName = $prop.Value
                $inUser    = Test-Path (Join-Path $UserBase  $skillName)
                $inLocal   = Test-Path (Join-Path $LocalBase $skillName)
                if (-not $inUser -and -not $inLocal) {
                    $badSkills += "$($prop.Name)=$skillName"
                }
            }
            if ($badSkills.Count -eq 0) {
                Add-Result "skill-references" "PASS" "All agentCodeToSkill entries resolve to real dirs" "skills"
            } else {
                Add-Result "skill-references" "WARN" "Unresolved skills (check path): $($badSkills -join '; ')" "skills"
            }
        } catch {
            Add-Result "skill-references" "WARN" "Cannot check skill references: $_" "skills"
        }
    }
}

# =============================================================================
#  DOMAIN: tests
#  - Unit tests (Pester 3.4.0) all pass
# =============================================================================
if ($Domain -in @("all","tests")) {
    $TestFile = "$Root\tests\unit\foundation-core.tests.ps1"
    if (Test-Path $TestFile) {
        $TestOut = & pwsh -NoProfile -ExecutionPolicy Bypass -Command @"
            Import-Module Pester -RequiredVersion 3.4.0 -ErrorAction Stop
            `$r = Invoke-Pester '$TestFile' -PassThru -Quiet
            Write-Output "PESTER_RESULT:`$(`$r.PassedCount):`$(`$r.FailedCount)"
"@ 2>&1
        $PesterLine = $TestOut | Select-String "PESTER_RESULT:" | Select-Object -Last 1
        if ($PesterLine) {
            $parts  = "$PesterLine".Split(":")
            $passed = [int]$parts[1]
            $failed = [int]$parts[2]
            if ($failed -eq 0) {
                Add-Result "unit-tests" "PASS" "$passed tests passed, 0 failed" "tests"
            } else {
                Add-Result "unit-tests" "FAIL" "$passed passed, $failed FAILED — run tests manually for details" "tests"
            }
        } else {
            # Fallback: parse last summary line
            $summary = $TestOut | Select-String "passed" | Select-Object -Last 1
            if ($summary -match "0 Failed") {
                Add-Result "unit-tests" "PASS" "$summary" "tests"
            } else {
                Add-Result "unit-tests" "WARN" "Could not parse test output — check manually: pwsh -File '$TestFile'" "tests"
            }
        }
    } else {
        Add-Result "unit-tests" "WARN" "Test file not found: tests/unit/foundation-core.tests.ps1" "tests"
    }
}

# =============================================================================
#  DOMAIN: hooks
#  - Hook script files exist
#  - Git pre-commit hook is installed in .git/hooks/
# =============================================================================
if ($Domain -in @("all","hooks")) {
    $HookScripts = @(
        "hooks/pre-commit.ps1",
        "hooks/pre-commit-privacy.ps1"
    )
    $missing = $HookScripts | Where-Object { -not (Test-Path "$Root\$_") }
    if ($missing.Count -eq 0) {
        Add-Result "hook-scripts" "PASS" "All hook scripts present" "hooks"
    } else {
        Add-Result "hook-scripts" "FAIL" "Missing: $($missing -join ', ')" "hooks"
    }

    if (Test-Path "$Root\.git\hooks\pre-commit") {
        Add-Result "git-hook-installed" "PASS" ".git/hooks/pre-commit is installed" "hooks"
    } else {
        Add-Result "git-hook-installed" "WARN" ".git/hooks/pre-commit not installed — run: pwsh -File scripts/utilities/install-hooks.ps1" "hooks"
    }
}

# =============================================================================
#  DOMAIN: structure
#  - Required root files exist
#  - Critical scripts exist
# =============================================================================
if ($Domain -in @("all","structure")) {
    $RequiredFiles = @(
        "config/auto-delegation.json",
        "config/orchestrator.json",
        "rules/AI-NORMATIVES.md",
        "CLAUDE.md"
    )
    $missing = $RequiredFiles | Where-Object { -not (Test-Path "$Root\$_") }
    if ($missing.Count -eq 0) {
        Add-Result "required-files" "PASS" "All required files present" "structure"
    } else {
        Add-Result "required-files" "FAIL" "Missing files: $($missing -join ', ')" "structure"
    }

    $RequiredScripts = @(
        "scripts/utilities/pre-process-input.ps1",
        "scripts/utilities/validate-configs.ps1",
        "scripts/utilities/install-hooks.ps1"
    )
    $missingScripts = $RequiredScripts | Where-Object { -not (Test-Path "$Root\$_") }
    if ($missingScripts.Count -eq 0) {
        Add-Result "critical-scripts" "PASS" "All critical utility scripts present" "structure"
    } else {
        Add-Result "critical-scripts" "FAIL" "Missing scripts: $($missingScripts -join ', ')" "structure"
    }

    # Detect uncommitted changes (unstaged or staged)
    $DirtyFiles = git -C $Root status --porcelain 2>$null | Where-Object { $_ -match "^\s*[MADRCU?]" }
    if ($DirtyFiles.Count -gt 0) {
        Add-Result "uncommitted-changes" "WARN" "$($DirtyFiles.Count) uncommitted file(s) — commit or stash before closing task" "structure"
    } else {
        Add-Result "uncommitted-changes" "PASS" "Working tree clean" "structure"
    }
}

# =============================================================================
#  OUTPUT
# =============================================================================
$Total  = $Results.Count
$Passed = ($Results | Where-Object { $_.status -eq "PASS" }).Count
$FinalResult = if ($Errors -gt 0) { "FAIL" } elseif ($Warnings -gt 0) { "PASS_WITH_WARNINGS" } else { "PASS" }

if ($Json) {
    @{
        timestamp  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        domain     = $Domain
        summary    = @{ total = $Total; passed = $Passed; failed = $Errors; warnings = $Warnings }
        result     = $FinalResult
        checks     = $Results
    } | ConvertTo-Json -Depth 5
} else {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  AGENT SELF-VERIFICATION" -ForegroundColor Cyan
    Write-Host "  Domain: $Domain | $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""

    $lastCategory = ""
    foreach ($r in $Results) {
        if ($r.category -ne $lastCategory) {
            Write-Host "  --- $($r.category.ToUpper()) ---" -ForegroundColor DarkGray
            $lastCategory = $r.category
        }
        $color = switch ($r.status) { "PASS" { "Green" } "FAIL" { "Red" } "WARN" { "Yellow" } default { "White" } }
        Write-Host "  [$($r.status.PadRight(4))] $($r.check)" -ForegroundColor $color -NoNewline
        Write-Host ": $($r.message)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  $Passed/$Total passed  |  $Errors error(s)  |  $Warnings warning(s)" -ForegroundColor $(
        if ($Errors -gt 0) { "Red" } elseif ($Warnings -gt 0) { "Yellow" } else { "Green" }
    )
    Write-Host ""

    switch ($FinalResult) {
        "PASS" {
            Write-Host "  RESULT: ALL CHECKS PASS — work verified clean." -ForegroundColor Green
        }
        "PASS_WITH_WARNINGS" {
            Write-Host "  RESULT: PASS with $Warnings warning(s) — review before closing." -ForegroundColor Yellow
        }
        "FAIL" {
            Write-Host "  RESULT: $Errors FAILURE(S) — fix before marking task done." -ForegroundColor Red
            Write-Host ""
            Write-Host "  FAILED CHECKS:" -ForegroundColor Red
            $Results | Where-Object { $_.status -eq "FAIL" } | ForEach-Object {
                Write-Host "    - [$($_.category)] $($_.check): $($_.message)" -ForegroundColor Red
            }
        }
    }
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

exit $(if ($Errors -gt 0) { 1 } else { 0 })
