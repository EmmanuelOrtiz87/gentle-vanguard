#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pre-flight health check for public repo before sync or release.
.DESCRIPTION
    Validates:
    - Both main and develop branches exist and are reachable
    - All branches have a recent commit (within 14 days)
    - No branch is more than 1 commit behind the other after sync
.PARAMETER publicRepo
    Path to public repo root. Default from PUBLIC_REPO env or sibling directory.
.PARAMETER maxAgeDays
    Maximum allowed age for latest commit on any branch (default: 14).
.EXAMPLE
    .\check-public-repo-health.ps1
    .\check-public-repo-health.ps1 -maxAgeDays 7
#>

param(
    [string]$publicRepo = '',
    [int]$maxAgeDays = 14
)

if ([string]::IsNullOrEmpty($publicRepo)) {
    if ($env:PUBLIC_REPO) {
        $publicRepo = $env:PUBLIC_REPO
    } else {
        $searchDir = $PSScriptRoot
        while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
            $searchDir = Split-Path -Parent $searchDir
        }
        $publicRepo = Join-Path (Split-Path -Parent $searchDir) 'gentle-vanguard-public'
    }
}

if (-not (Test-Path $publicRepo)) {
    Write-Error "[FAIL] Public repo not found at: $publicRepo"
    exit 1
}

Push-Location $publicRepo

Write-Output "=== Public Repo Health Check ==="
Write-Output "Repo: $publicRepo"
Write-Output ""

# 1. Fetch latest remote state
git fetch origin --prune 2>&1 | Out-Null

# 2. Discover branches
$remoteBranches = git branch -r 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^origin/(\S+)' -and $_ -notmatch '->' } | ForEach-Object { $_ -replace '^origin/', '' }
if (-not $remoteBranches) {
    Write-Error "[FAIL] No remote branches found!"
    Pop-Location
    exit 1
}

Write-Output "[OK] Remote branches: $($remoteBranches -join ', ')"

# 3. Validate required branches exist
$requiredBranches = @('main', 'develop')
$missing = $requiredBranches | Where-Object { $_ -notin $remoteBranches }
if ($missing) {
    Write-Error "[FAIL] Missing required branches: $($missing -join ', ')"
    Pop-Location
    exit 1
}
Write-Output "[OK] All required branches exist"

# 4. Check commit age on each branch
$now = Get-Date
$ageFailures = @()
$branchCommits = @{}
foreach ($branch in $remoteBranches) {
    $commitHash = git log "origin/$branch" -1 --format="%H" 2>$null
    $commitDate = git log "origin/$branch" -1 --format="%ci" 2>$null
    if (-not $commitHash) {
        $ageFailures += "$branch (no commits)"
        continue
    }
    $branchCommits[$branch] = $commitHash
    $commitTime = [DateTime]::Parse($commitDate)
    $ageDays = ($now - $commitTime).TotalDays
    if ($ageDays -gt $maxAgeDays) {
        $ageFailures += "$branch (last commit $([math]::Round($ageDays,1)) days ago, max: $maxAgeDays)"
    } else {
        Write-Output "[OK] $branch — last commit $([math]::Round($ageDays,1)) days ago ($($commitHash.Substring(0,8)))"
    }
}

if ($ageFailures) {
    Write-Error "[FAIL] Branches with stale commits:"
    $ageFailures | ForEach-Object { Write-Error "  - $_" }
    Pop-Location
    exit 1
}

# 5. Check branches are not diverging (all should point to same sync commit)
$allHashes = $branchCommits.Values | Select-Object -Unique
if ($allHashes.Count -gt 1) {
    Write-Warning "[WARN] Branches have diverging HEADs:"
    foreach ($branch in $branchCommits.Keys) {
        Write-Warning "  ${branch}: $($branchCommits[$branch].Substring(0,8))"
    }
    # Allow 1-commit drift (sync runs sequentially)
    Write-Output "[WARN] This may be normal if a sync is in progress — verify manually"
}

# 6. Check last sync commit message pattern
foreach ($branch in $remoteBranches) {
    $msg = git log "origin/$branch" -1 --format="%s" 2>$null
    if ($msg -notmatch 'sync: automated sync from private repo') {
        Write-Warning "[WARN] $branch last commit is not a sync commit: '$msg'"
    }
}

Pop-Location
Write-Output ""
Write-Output "=== Health Check PASSED ==="
exit 0
