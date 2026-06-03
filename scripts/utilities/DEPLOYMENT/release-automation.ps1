<#
.SYNOPSIS
    Automated release pipeline: validates, builds, syncs, and reports.
.DESCRIPTION
    One-command release automation that:
    1. Validates VERSION aligns with tag/CHANGELOG/README badges
    2. Runs protect + create-installer to produce dist/Gentle-Vanguard.exe
    3. Verifies build artifacts
    4. Syncs public repo via sync-to-public.ps1
    5. Outputs structured report

    Must be run from repo root.
.PARAMETER Version
    Target version (e.g. "2.26.0"). If omitted, reads from VERSION file.
.PARAMETER SkipBuild
    If set, skips installer rebuild (use for post-release validation).
.PARAMETER SkipSync
    If set, skips public repo sync.
.PARAMETER DryRun
    If set, shows what would be done without executing.
.EXAMPLE
    pwsh -File scripts/utilities/DEPLOYMENT/release-automation.ps1 -Version 2.26.0
    pwsh -File scripts/utilities/DEPLOYMENT/release-automation.ps1 -SkipBuild
#>

param(
    [string]$Version = '',
    [switch]$SkipBuild,
    [switch]$SkipSync,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    if (-not $searchDir) { $searchDir = (Get-Location).Path }
    $searchDir
}

$exitCode = 0
$results = @()

function Write-Step { param([string]$M) Write-Host "`n=== $M ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$M) Write-Host "  [OK] $M" -ForegroundColor Green }
function Write-Warn { param([string]$M) Write-Host "  [WARN] $M" -ForegroundColor Yellow }
function Write-Err  { param([string]$M) Write-Host "  [FAIL] $M" -ForegroundColor Red; $script:exitCode = 1 }

function Add-Result {
    param([string]$Check, [bool]$Passed, [string]$Detail)
    $script:results += [pscustomobject]@{ Check = $Check; Passed = $Passed; Detail = $Detail }
    if ($Passed) { Write-Ok "$Check — $Detail" } else { Write-Err "$Check — $Detail" }
}

function Read-BadgeVersion {
    param([string]$FilePath, [string]$Label)
    $content = Get-Content $FilePath -Raw
    $m = [regex]::Match($content, 'Version-(\d+\.\d+\.\d+)')
    if ($m.Success) { $m.Groups[1].Value } else { 'unknown' }
}

function Read-ChangelogVersion {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw
    $m = [regex]::Match($content, "^\#\# \[(\d+\.\d+\.\d+)\]", 'Multiline')
    if ($m.Success) { $m.Groups[1].Value } else { 'unknown' }
}

# --- Resolve version ---
if (-not $Version) {
    $Version = (Get-Content (Join-Path $repoRoot 'VERSION') -Raw).Trim()
}
$tagVersion = "v$Version"

Write-Step "Release Automation v$Version"

# ============================================================================
# Phase 1: Validation
# ============================================================================
Write-Step "Phase 1: Pre-flight validation"

# 1a. Working tree clean
$status = git -C $repoRoot status --porcelain
Add-Result "Working tree clean" (-not $status) "Git status: $(if ($status) {'uncommitted changes'} else {'clean'})"

# 1b. VERSION file
$versionFile = Join-Path $repoRoot 'VERSION'
$fileVersion = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { 'missing' }
Add-Result "VERSION file = $Version" ($fileVersion -eq $Version) "File says '$fileVersion', expected '$Version'"

# 1c. CHANGELOG has entry
$changelogFile = Join-Path $repoRoot 'CHANGELOG.md'
$changelogRaw = Get-Content $changelogFile -Raw
$hasEntry = $changelogRaw -match "## \[$Version\]"
Add-Result "CHANGELOG.md has [$Version] entry" $hasEntry "Found: $hasEntry"

# 1d. README.md badge
$readmeBadge = Read-BadgeVersion (Join-Path $repoRoot 'README.md')
Add-Result "README.md badge Version-$Version" ($readmeBadge -eq $Version) "Badge says '$readmeBadge'"

# 1e. README-PUBLIC.md badge
$readmePublicFile = Join-Path $repoRoot 'README-PUBLIC.md'
if (Test-Path $readmePublicFile) {
    $publicBadge = Read-BadgeVersion $readmePublicFile
    Add-Result "README-PUBLIC.md badge Version-$Version" ($publicBadge -eq $Version) "Badge says '$publicBadge'"
} else {
    Add-Result "README-PUBLIC.md exists" $false "File not found"
}

# 1f. Footer version in README.md
$readmeContent = Get-Content (Join-Path $repoRoot 'README.md') -Raw
$footerOk = $readmeContent -match "Gentle-Vanguard v$Version"
Add-Result "README.md footer v$Version" $footerOk "Found: $footerOk"

# 1g. Footer version in README-PUBLIC.md
if (Test-Path $readmePublicFile) {
    $publicContent = Get-Content $readmePublicFile -Raw
    $publicFooterOk = $publicContent -match "Gentle-Vanguard v$Version"
    Add-Result "README-PUBLIC.md footer v$Version" $publicFooterOk "Found: $publicFooterOk"
}

# 1h. Installer prerequisites
$nsisPaths = @(
    'C:\Program Files (x86)\NSIS\makensis.exe',
    'C:\Program Files\NSIS\makensis.exe'
)
$nsisFound = $false
foreach ($p in $nsisPaths) { if (Test-Path $p) { $nsisFound = $true; break } }
$nsisFound = $nsisFound -or ((Get-Command 'makensis' -ErrorAction SilentlyContinue) -ne $null)
Add-Result "NSIS available" $nsisFound "makensis.exe: $(if ($nsisFound) {'found'} else {'NOT FOUND — cannot build installer'})"

$buildScript = Join-Path $repoRoot 'build\create-installer.ps1'
Add-Result "build/create-installer.ps1 exists" (Test-Path $buildScript) "Path: $buildScript"

$protectScript = Join-Path $repoRoot 'build\protect-gentle-vanguard.ps1'
Add-Result "build/protect-gentle-vanguard.ps1 exists" (Test-Path $protectScript) "Path: $protectScript"

# 1i. Sync-to-public script
$syncScript = Join-Path $repoRoot 'scripts\utilities\DEPLOYMENT\sync-to-public.ps1'
Add-Result "sync-to-public.ps1 exists" (Test-Path $syncScript) "Path: $syncScript"

# ============================================================================
# Phase 2: Build installer
# ============================================================================
if (-not $SkipBuild -and $exitCode -eq 0) {
    Write-Step "Phase 2: Building installer"
    if ($DryRun) {
        Write-Warn "[DRY RUN] Would execute: pwsh -File $buildScript"
    } else {
        try {
            Push-Location $repoRoot
            & $buildScript
            if ($LASTEXITCODE -eq 0 -or $?) {
                $exePath = Join-Path $repoRoot 'dist\Gentle-Vanguard.exe'
                if (Test-Path $exePath) {
                    $exeInfo = Get-Item $exePath
                    Add-Result "Gentle-Vanguard.exe built" $true "$($exeInfo.Length) bytes, $($exeInfo.LastWriteTime)"
                } else {
                    Add-Result "Gentle-Vanguard.exe built" $false "File not found at $exePath"
                }
            } else {
                Add-Result "create-installer.ps1 succeeded" $false "Exit code: $LASTEXITCODE"
            }
        } catch {
            Add-Result "create-installer.ps1 succeeded" $false $_.Exception.Message
        } finally {
            Pop-Location
        }
    }
} else {
    if ($SkipBuild) { Write-Step "Phase 2: Skipped (SkipBuild)" }
    # Still verify existing exe
    $exePath = Join-Path $repoRoot 'dist\Gentle-Vanguard.exe'
    if (Test-Path $exePath) {
        $exeInfo = Get-Item $exePath
        Add-Result "dist/Gentle-Vanguard.exe exists" $true "$($exeInfo.Length) bytes, $($exeInfo.LastWriteTime)"
    } else {
        Add-Result "dist/Gentle-Vanguard.exe exists" $false "File not found"
    }
}

# ============================================================================
# Phase 3: Sync public repo
# ============================================================================
if (-not $SkipSync -and $exitCode -eq 0) {
    Write-Step "Phase 3: Syncing public repo"
    if ($DryRun) {
        Write-Warn "[DRY RUN] Would execute: pwsh -File $syncScript"
    } else {
        try {
            Push-Location $repoRoot
            & $syncScript
            if ($LASTEXITCODE -eq 0 -or $?) {
                Add-Result "Public repo sync" $true "sync-to-public.ps1 completed"
            } else {
                Add-Result "Public repo sync" $false "Exit code: $LASTEXITCODE"
            }
        } catch {
            Add-Result "Public repo sync" $false $_.Exception.Message
        } finally {
            Pop-Location
        }
    }
} else {
    if ($SkipSync) { Write-Step "Phase 3: Skipped (SkipSync)" }
}

# ============================================================================
# Phase 4: Report
# ============================================================================
Write-Step "Phase 4: Release Summary"
Write-Host ""

$passed = ($results | Where-Object { $_.Passed }).Count
$failed = ($results | Where-Object { -not $_.Passed }).Count
$total = $results.Count

Write-Host "Results: $passed/$total passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
Write-Host ""

$results | Format-Table -Property @{L='Check';E={$_.Check}}, @{L='Passed';E={if ($_.Passed) {'✅'} else {'❌'}}}, @{L='Detail';E={$_.Detail}} -AutoSize | Out-Host

if ($exitCode -ne 0) {
    Write-Err "Release automation completed with $failed failure(s)"
}

exit $exitCode
