#!/usr/bin/env pwsh
<#!
.SYNOPSIS
    Validates release homologation readiness between gentle-vanguard and gentle-vanguard-public.
.DESCRIPTION
    Runs a complementary multi-repo gate before/after release actions to ensure:
    - VERSION alignment
    - clean/up-to-date main and develop branches
    - optional tag consistency without force-moving tags

    This script complements existing tests/audits/governance checks. It does not replace them.
.PARAMETER GentleVanguardRepoPath
    Path to gentle-vanguard repository. Defaults to repository root.
.PARAMETER PublicRepoPath
    Path to gentle-vanguard-public repository. Defaults to sibling folder.
.PARAMETER ExpectedTag
    Optional semver tag (e.g. v1.0.0) to validate consistency across repos.
.PARAMETER AsJson
    Emits machine-readable JSON output.
.EXAMPLE
    .\scripts\utilities\DEPLOYMENT\validate-release-homologation.ps1
.EXAMPLE
    .\scripts\utilities\DEPLOYMENT\validate-release-homologation.ps1 -ExpectedTag v1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$GentleVanguardRepoPath = '',

    [Parameter()]
    [string]$PublicRepoPath = '',

    [Parameter()]
    [string]$ExpectedTag = '',

    [Parameter()]
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
    if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
        return (Resolve-Path $env:GENTLE_VANGUARD_BASE_DIR).Path
    }

    $searchDir = Split-Path -Parent $PSCommandPath
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }

    if (-not $searchDir) {
        throw 'Could not resolve gentle-vanguard repository root from script location.'
    }

    return (Resolve-Path $searchDir).Path
}

function Invoke-Git {
    param(
        [string]$RepoPath,
        [string[]]$GitArgs
    )

    $output = & git -C $RepoPath @GitArgs 2>$null
    $code = $LASTEXITCODE

    return [pscustomobject]@{
        ExitCode = $code
        Output = $output
    }
}

function Test-BranchState {
    param(
        [string]$RepoPath,
        [string]$Branch
    )

    $branchExists = (Invoke-Git -RepoPath $RepoPath -GitArgs @('show-ref', '--verify', "refs/heads/$Branch")).ExitCode -eq 0
    if (-not $branchExists) {
        return [pscustomobject]@{
            Branch = $Branch
            Exists = $false
            UpstreamExists = $false
            Ahead = 0
            Behind = 0
            Aligned = $false
            Message = "Local branch '$Branch' not found"
        }
    }

    $upstreamExists = (Invoke-Git -RepoPath $RepoPath -GitArgs @('show-ref', '--verify', "refs/remotes/origin/$Branch")).ExitCode -eq 0
    if (-not $upstreamExists) {
        return [pscustomobject]@{
            Branch = $Branch
            Exists = $true
            UpstreamExists = $false
            Ahead = 0
            Behind = 0
            Aligned = $false
            Message = "Remote branch 'origin/$Branch' not found"
        }
    }

    $counts = Invoke-Git -RepoPath $RepoPath -GitArgs @('rev-list', '--left-right', '--count', "origin/$Branch...$Branch")
    $ahead = 0
    $behind = 0

    if ($counts.ExitCode -eq 0 -and ($counts.Output -join ' ') -match '^(\d+)\s+(\d+)$') {
        $behind = [int]$matches[1]
        $ahead = [int]$matches[2]
    }

    $aligned = ($ahead -eq 0 -and $behind -eq 0)
    $message = if ($aligned) {
        "Branch '$Branch' aligned with origin/$Branch"
    } else {
        "Branch '$Branch' drifted (ahead=$ahead, behind=$behind)"
    }

    return [pscustomobject]@{
        Branch = $Branch
        Exists = $true
        UpstreamExists = $true
        Ahead = $ahead
        Behind = $behind
        Aligned = $aligned
        Message = $message
    }
}

function Get-RepoSnapshot {
    param([string]$RepoPath)

    if (-not (Test-Path $RepoPath)) {
        throw "Repository path not found: $RepoPath"
    }

    $repo = (Resolve-Path $RepoPath).Path
    $gitDirPath = Join-Path $repo '.git'
    if (-not (Test-Path $gitDirPath)) {
        throw "Not a git repository: $repo"
    }

    $versionPath = Join-Path $repo 'VERSION'
    if (-not (Test-Path $versionPath)) {
        throw "VERSION file not found: $versionPath"
    }

    $status = Invoke-Git -RepoPath $repo -GitArgs @('status', '--porcelain')
    $dirty = $status.ExitCode -ne 0 -or (($status.Output | Out-String).Trim().Length -gt 0)

    return [pscustomobject]@{
        Path = $repo
        Version = (Get-Content -Path $versionPath -Raw -Encoding UTF8).Trim()
        IsDirty = $dirty
        Main = Test-BranchState -RepoPath $repo -Branch 'main'
        Develop = Test-BranchState -RepoPath $repo -Branch 'develop'
    }
}

function Get-TagState {
    param(
        [string]$RepoPath,
        [string]$Tag
    )

    if ([string]::IsNullOrWhiteSpace($Tag)) {
        return $null
    }

    $localRef = Invoke-Git -RepoPath $RepoPath -GitArgs @('rev-parse', '--verify', "refs/tags/$Tag")
    $remoteRef = Invoke-Git -RepoPath $RepoPath -GitArgs @('ls-remote', '--tags', 'origin', $Tag)

    $localSha = if ($localRef.ExitCode -eq 0) { ($localRef.Output | Select-Object -First 1).ToString().Trim() } else { '' }
    $remoteSha = ''
    if ($remoteRef.ExitCode -eq 0 -and $remoteRef.Output) {
        $firstLine = ($remoteRef.Output | Select-Object -First 1).ToString().Trim()
        if ($firstLine -match '^([0-9a-fA-F]{40})\s+') {
            $remoteSha = $matches[1]
        }
    }

    $localExists = -not [string]::IsNullOrWhiteSpace($localSha)
    $remoteExists = -not [string]::IsNullOrWhiteSpace($remoteSha)
    $requiresForceMove = $localExists -and $remoteExists -and ($localSha -ne $remoteSha)

    return [pscustomobject]@{
        Tag = $Tag
        LocalExists = $localExists
        RemoteExists = $remoteExists
        LocalSha = $localSha
        RemoteSha = $remoteSha
        RequiresForceMove = $requiresForceMove
    }
}

$gentleVanguardRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($GentleVanguardRepoPath)) { $GentleVanguardRepoPath = $gentleVanguardRoot }
if ([string]::IsNullOrWhiteSpace($PublicRepoPath)) {
    $PublicRepoPath = Join-Path (Split-Path -Parent $gentleVanguardRoot) 'gentle-vanguard-public'
}

$gentleVanguard = Get-RepoSnapshot -RepoPath $GentleVanguardRepoPath
$public = Get-RepoSnapshot -RepoPath $PublicRepoPath

$checks = New-Object System.Collections.Generic.List[object]

$checks.Add([pscustomobject]@{ Name = 'VERSION alignment'; Passed = ($gentleVanguard.Version -eq $public.Version); Detail = "gentle-vanguard=$($gentleVanguard.Version) | gentle-vanguard-public=$($public.Version)" })
$checks.Add([pscustomobject]@{ Name = 'gentle-vanguard working tree clean'; Passed = (-not $gentleVanguard.IsDirty); Detail = if ($gentleVanguard.IsDirty) { 'Uncommitted changes detected' } else { 'Clean' } })
$checks.Add([pscustomobject]@{ Name = 'gentle-vanguard-public working tree clean'; Passed = (-not $public.IsDirty); Detail = if ($public.IsDirty) { 'Uncommitted changes detected' } else { 'Clean' } })
$checks.Add([pscustomobject]@{ Name = 'gentle-vanguard main aligned'; Passed = $gentleVanguard.Main.Aligned; Detail = $gentleVanguard.Main.Message })
$checks.Add([pscustomobject]@{ Name = 'gentle-vanguard develop aligned'; Passed = $gentleVanguard.Develop.Aligned; Detail = $gentleVanguard.Develop.Message })
$checks.Add([pscustomobject]@{ Name = 'gentle-vanguard-public main aligned'; Passed = $public.Main.Aligned; Detail = $public.Main.Message })
$checks.Add([pscustomobject]@{ Name = 'gentle-vanguard-public develop aligned'; Passed = $public.Develop.Aligned; Detail = $public.Develop.Message })

$tagResult = $null
if (-not [string]::IsNullOrWhiteSpace($ExpectedTag)) {
    $tagGentleVanguard = Get-TagState -RepoPath $gentleVanguard.Path -Tag $ExpectedTag
    $tagPublic = Get-TagState -RepoPath $public.Path -Tag $ExpectedTag

    $presenceAligned = ($tagGentleVanguard.LocalExists -eq $tagPublic.LocalExists)
    $noForceMoveGentleVanguard = -not $tagGentleVanguard.RequiresForceMove
    $noForceMovePublic = -not $tagPublic.RequiresForceMove

    $checks.Add([pscustomobject]@{
        Name = "Tag presence alignment ($ExpectedTag)"
        Passed = $presenceAligned
        Detail = "gentle-vanguard(local=$($tagGentleVanguard.LocalExists)) | gentle-vanguard-public(local=$($tagPublic.LocalExists))"
    })
    $checks.Add([pscustomobject]@{ Name = "gentle-vanguard tag no force-move ($ExpectedTag)"; Passed = $noForceMoveGentleVanguard; Detail = if ($noForceMoveGentleVanguard) { 'No mismatch local/remote tag SHA' } else { 'Local/remote tag SHA mismatch' } })
    $checks.Add([pscustomobject]@{ Name = "gentle-vanguard-public tag no force-move ($ExpectedTag)"; Passed = $noForceMovePublic; Detail = if ($noForceMovePublic) { 'No mismatch local/remote tag SHA' } else { 'Local/remote tag SHA mismatch' } })

    $tagResult = [pscustomobject]@{
        'Gentle-Vanguard' = $tagGentleVanguard
        Public = $tagPublic
    }
}

$failed = @($checks | Where-Object { -not $_.Passed })
$passed = @($checks | Where-Object { $_.Passed })

$result = [pscustomobject]@{
    timestamp = (Get-Date).ToString('o')
    'gentle-vanguard' = $gentleVanguard
    public = $public
    expectedTag = if ([string]::IsNullOrWhiteSpace($ExpectedTag)) { $null } else { $ExpectedTag }
    tag = $tagResult
    checks = $checks
    summary = [pscustomobject]@{
        total = $checks.Count
        passed = $passed.Count
        failed = $failed.Count
        status = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host ''
    Write-Host '=== Release Homologation Gate ===' -ForegroundColor Cyan
    Write-Host "gentle-vanguard:       $($gentleVanguard.Path)" -ForegroundColor Gray
    Write-Host "gentle-vanguard-public:$($public.Path)" -ForegroundColor Gray
    Write-Host ''

    foreach ($check in $checks) {
        if ($check.Passed) {
            Write-Host "[PASS] $($check.Name)" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] $($check.Name)" -ForegroundColor Red
        }
        Write-Host "       $($check.Detail)" -ForegroundColor DarkGray
    }

    Write-Host ''
    $color = if ($failed.Count -eq 0) { 'Green' } else { 'Red' }
    Write-Host "Result: $($result.summary.status) ($($result.summary.passed)/$($result.summary.total) checks passed)" -ForegroundColor $color
}

if ($failed.Count -gt 0) {
    exit 1
}

exit 0

