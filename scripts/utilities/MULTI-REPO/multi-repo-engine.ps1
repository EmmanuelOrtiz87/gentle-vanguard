param(
    [ValidateSet("discover", "coordinated-pr", "validate", "status")]
    [string]$Action = "status",
    [string]$ConfigPath = "",
    [string]$RepoPath = "",
    [string]$SourceBranch = "",
    [string]$TargetBranch = "main",
    [string]$Title = "",
    [string]$Body = "",
    [switch]$DryRun,
    [switch]$Raw
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = if ($RepoPath) { $RepoPath } else { $PSScriptRoot }
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
if (-not $ConfigPath) { $ConfigPath = Join-Path $ProjectRoot "config\multi-repo-orchestration.json" }

function Get-DefaultConfig {
    return @{
        version = "1.0.0"
        enabled = $true
        repos = @(
            @{
                name = "gentle-vanguard"
                path = $ProjectRoot
                remote = "origin"
                defaultBranch = "main"
                roles = @("core")
            }
        )
        coordination = @{
            autoDetectDependencies = $true
            validateVersionAlignment = $true
            createCoordinatedPRs = $false
            maxParallelPRs = 3
        }
    }
}

function Get-MultiRepoConfig {
    if (Test-Path $ConfigPath) {
        try {
            $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            if ($Raw) { return $json }
            $reposList = if ($json.repos) { $json.repos } elseif ($json.multiRepoOrchestration -and $json.multiRepoOrchestration.strategies.polyrepo.repositories) {
                $json.multiRepoOrchestration.strategies.polyrepo.repositories | ForEach-Object { @{ name = $_; path = ""; roles = @("community") } }
            } else { @() }
            $result = @{
                version = $json.version
                enabled = if ($null -ne $json.enabled) { $json.enabled } elseif ($json.multiRepoOrchestration) { $json.multiRepoOrchestration.enabled } else { $false }
                repoCount = @($reposList).Count
                repos = @()
            }
            foreach ($r in $reposList) {
                $rPath = if ($r.path) { $r.path } else { Join-Path $ProjectRoot "..\$($r.name)" }
                $result.repos += @{
                    name = $r.name
                    path = $rPath
                    exists = (Test-Path $rPath)
                    roles = @(if ($r.roles) { $r.roles } else { @("unknown") })
                }
            }
            return $result
        } catch {
            Write-Warning "Failed to parse config: $_"
            return $null
        }
    }
    return $null
}

function Initialize-Config {
    if (Test-Path $ConfigPath) {
        Write-Host "[CONFIG] Already exists at $ConfigPath" -ForegroundColor Yellow
        return
    }
    $cfg = Get-DefaultConfig
    $json = $cfg | ConvertTo-Json -Depth 5
    $json | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Host "[CONFIG] Created $ConfigPath" -ForegroundColor Green
}

function Discover-Repos {
    Write-Host "=== Discovering Repositories ===" -ForegroundColor Cyan
    $siblings = Join-Path $ProjectRoot ".."
    $candidates = @()
    $known = @("gentle-vanguard-public", "gentle-vanguard-web-ui", "gentle-vanguard-docs", "gentle-vanguard-plugins")
    foreach ($name in $known) {
        $path = Join-Path $siblings $name
        if (Test-Path (Join-Path $path ".git")) {
            $candidates += @{ name = $name; path = $path; detected = $true }
        }
    }
    if ($candidates.Count -eq 0) {
        Write-Host "  No sibling repos detected." -ForegroundColor Yellow
    } else {
        foreach ($c in $candidates) {
            Write-Host "  [DETECTED] $($c.name) at $($c.path)" -ForegroundColor Green
        }
    }
    return $candidates
}

function Validate-VersionAlignment {
    param($Repos)
    Write-Host "=== Version Alignment ===" -ForegroundColor Cyan
    $versions = @{}
    foreach ($r in $Repos) {
        $verFile = Join-Path $r.path "VERSION"
        if (Test-Path $verFile) {
            $ver = (Get-Content $verFile -Raw).Trim()
            $versions[$r.name] = $ver
        }
    }
    $unique = @($versions.Values | Select-Object -Unique)
    if ($unique.Count -le 1) {
        Write-Host "  All repos aligned: $($unique -join ', ')" -ForegroundColor Green
        return $true
    }
    Write-Host "  MISMATCH detected:" -ForegroundColor Red
    foreach ($entry in $versions.GetEnumerator()) {
        Write-Host "    $($entry.Key): $($entry.Value)" -ForegroundColor Yellow
    }
    return $false
}

function Create-CoordinatedPRs {
    param($Repos)
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would create coordinated PRs across $($Repos.Count) repos" -ForegroundColor Magenta
        foreach ($r in $Repos) {
            Write-Host "  Would PR $($r.name): $SourceBranch -> $TargetBranch" -ForegroundColor DarkGray
        }
        return $true
    }
    Write-Host "=== Coordinated PRs ===" -ForegroundColor Cyan
    $results = @()
    foreach ($r in $Repos) {
        try {
            $currentBranch = git -C $r.path rev-parse --abbrev-ref HEAD 2>$null
            if (-not $SourceBranch) { $SourceBranch = $currentBranch }
            $prBody = if ($Body) { $Body } else { "Coordinated PR: $Title`n`nAuto-generated by multi-repo-engine.ps1" }
            $result = git -C $r.path push origin "${SourceBranch}:${TargetBranch}" 2>&1
            $results += @{ repo = $r.name; status = "pushed"; detail = "$result" }
            Write-Host "  [OK] $($r.name): pushed $SourceBranch -> $TargetBranch" -ForegroundColor Green
        } catch {
            $results += @{ repo = $r.name; status = "failed"; detail = "$_" }
            Write-Host "  [FAIL] $($r.name): $_" -ForegroundColor Red
        }
    }
    return $results
}

switch ($Action) {
    "discover" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Initialize-Config; $cfg = Get-MultiRepoConfig }
        $candidates = Discover-Repos
        $aligned = Validate-VersionAlignment @($cfg.repos)
        if ($Raw) {
            @{ config = $cfg; discovered = $candidates; versionAligned = $aligned } | ConvertTo-Json -Depth 10
            return
        }
        Write-Host "`nVersion aligned: $aligned" -ForegroundColor $(if ($aligned) { "Green" } else { "Red" })
    }

    "coordinated-pr" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg -or $cfg.repoCount -lt 2) {
            Write-Host "Need at least 2 repos configured for coordinated PRs. Run 'discover' first." -ForegroundColor Yellow
            exit 1
        }
        if (-not $Title) { Write-Error "Parameter -Title is required for coordinated-pr"; exit 1 }
        $results = Create-CoordinatedPRs $cfg.repos
        if ($Raw) { $results | ConvertTo-Json -Depth 3; return }
    }

    "validate" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Write-Host "No multi-repo config found. Run 'discover' first." -ForegroundColor Yellow; exit 0 }
        $aligned = Validate-VersionAlignment @($cfg.repos)
        if ($Raw) { @{ versionAligned = $aligned; repos = $cfg.repos } | ConvertTo-Json -Depth 3; return }
    }

    "status" {
        $cfg = Get-MultiRepoConfig
        if ($Raw) {
            if (-not $cfg) { @{ configured = $false } | ConvertTo-Json; return }
            $cfg | ConvertTo-Json -Depth 10; return
        }
        Write-Host "=== Multi-Repo Orchestration Status ===" -ForegroundColor Cyan
        if (-not $cfg) {
            Write-Host "  Status: NOT CONFIGURED" -ForegroundColor Yellow
            Write-Host "  Run: multi-repo-engine.ps1 -Action discover" -ForegroundColor DarkGray
            exit 0
        }
        Write-Host "  Version:   $($cfg.version)" -ForegroundColor DarkGray
        Write-Host "  Enabled:   $($cfg.enabled)" -ForegroundColor DarkGray
        Write-Host "  Repos:     $($cfg.repoCount)" -ForegroundColor Cyan
        foreach ($r in $cfg.repos) {
            $status = if ($r.exists) { "OK" } else { "MISSING" }
            $color = if ($r.exists) { "Green" } else { "Red" }
            Write-Host "    [$status] $($r.name) ($($r.roles -join ', '))" -ForegroundColor $color
        }
    }
}
