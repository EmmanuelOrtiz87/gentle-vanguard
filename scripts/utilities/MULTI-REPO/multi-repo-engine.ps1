<#
.SYNOPSIS
    Multi-Repository Orchestration Engine for Gentle-Vanguard v2.0.0
.DESCRIPTION
    Production-grade PowerShell script for managing multiple repositories.
    Supports discovery, synchronization, coordinated PRs, and dependency validation.
.PARAMETER Action
    Action to perform: discover, coordinated-pr, validate, status, sync, bulk-command, dependency-check
.PARAMETER ConfigPath
    Path to multi-repo configuration JSON
.PARAMETER RepoPath
    Override path to repository root
.PARAMETER SourceBranch
    Source branch for coordinated PRs
.PARAMETER TargetBranch
    Target branch for coordinated PRs (default: main)
.PARAMETER Title
    PR title for coordinated PRs
.PARAMETER Body
    PR body/description
.PARAMETER Command
    Command to execute in bulk-command action
.PARAMETER DryRun
    Simulate actions without executing
.PARAMETER Raw
    Output JSON instead of formatted text
.EXAMPLE
    .\multi-repo-engine.ps1 -Action status
    .\multi-repo-engine.ps1 -Action discover
    .\multi-repo-engine.ps1 -Action coordinated-pr -Title "Release v2.0" -SourceBranch release/v2.0
#>
[CmdletBinding()]
param(
    [ValidateSet("discover", "coordinated-pr", "validate", "status", "sync", "bulk-command", "dependency-check")]
    [string]$Action = "status",
    [string]$ConfigPath = "",
    [string]$RepoPath = "",
    [string]$SourceBranch = "",
    [string]$TargetBranch = "main",
    [string]$Title = "",
    [string]$Body = "",
    [string]$Command = "",
    [switch]$DryRun,
    [switch]$Raw
)

$ErrorActionPreference = "Stop"

# Logging Functions
function Write-Log {
    param(
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Retry Logic
function Invoke-WithRetry {
    param([scriptblock]$ScriptBlock, [int]$MaxRetries = 3, [int]$DelaySeconds = 2)
    $attempt = 1
    while ($attempt -le $MaxRetries) {
        try { return & $ScriptBlock }
        catch {
            if ($attempt -eq $MaxRetries) { throw }
            Write-Log "WARN" "Attempt $attempt failed, retrying..."
            Start-Sleep -Seconds ($DelaySeconds * $attempt)
        }
        $attempt++
    }
}

# Project Root Resolution
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

Write-Log "INFO" "Multi-Repo Engine v2.0.0 | Action: $Action"

# Configuration Functions
function Get-DefaultConfig {
    return @{
        version = "2.0.0"
        enabled = $true
        repos = @(@{ name = "gentle-vanguard"; path = $ProjectRoot; remote = "origin"; defaultBranch = "main"; roles = @("core") })
        coordination = @{ autoDetectDependencies = $true; validateVersionAlignment = $true; createCoordinatedPRs = $false; maxParallelPRs = 3; retryAttempts = 3 }
    }
}

function Get-MultiRepoConfig {
    if (Test-Path $ConfigPath) {
        try {
            $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            $reposList = if ($json.repos) { $json.repos } elseif ($json.multiRepoOrchestration -and $json.multiRepoOrchestration.strategies.polyrepo.repositories) {
                $json.multiRepoOrchestration.strategies.polyrepo.repositories | ForEach-Object { @{ name = $_; path = ""; roles = @("community") } }
            } else { @() }
            $result = @{
                version = if ($json.version) { $json.version } else { "2.0.0" }
                enabled = if ($null -ne $json.enabled) { $json.enabled } else { $json.multiRepoOrchestration.enabled }
                repoCount = @($reposList).Count
                repos = @()
            }
            foreach ($r in $reposList) {
                $rPath = if ($r.path) { $r.path } else { Join-Path $ProjectRoot "..\$($r.name)" }
                $result.repos += @{ name = $r.name; path = $rPath; exists = (Test-Path $rPath); hasGit = (Test-Path (Join-Path $rPath ".git")); roles = @(if ($r.roles) { $r.roles } else { @("unknown") }) }
            }
            return $result
        } catch {
            Write-Log "ERROR" "Failed to parse config: $_"
            return $null
        }
    }
    return $null
}

function Initialize-Config {
    if (Test-Path $ConfigPath) { Write-Log "WARN" "Config already exists"; return }
    $cfg = Get-DefaultConfig
    $cfg | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Log "SUCCESS" "Created config at $ConfigPath"
}

# Repository Discovery
function Discover-Repos {
    Write-Log "INFO" "Discovering sibling repositories..."
    $siblings = Join-Path $ProjectRoot ".."
    $candidates = @()
    $known = @("gentle-vanguard-public", "gentle-vanguard-web-ui", "gentle-vanguard-docs", "gentle-vanguard-plugins")
    foreach ($name in $known) {
        $path = Join-Path $siblings $name
        if (Test-Path (Join-Path $path ".git")) {
            $candidates += @{ name = $name; path = $path; detected = $true }
            Write-Log "SUCCESS" "Detected: $name"
        }
    }
    if ($candidates.Count -eq 0) { Write-Log "WARN" "No sibling repos detected" }
    return $candidates
}

# Version Validation
function Test-VersionAlignment {
    param($Repos)
    Write-Log "INFO" "Validating version alignment..."
    $versions = @{}
    foreach ($r in $Repos) {
        $verFile = Join-Path $r.path "VERSION"
        if (Test-Path $verFile) { $versions[$r.name] = (Get-Content $verFile -Raw).Trim() }
    }
    $unique = @($versions.Values | Select-Object -Unique)
    $aligned = $unique.Count -le 1
    if ($aligned) { Write-Log "SUCCESS" "All repos aligned: $($unique -join ', ')" }
    else {
        Write-Log "ERROR" "Version mismatch detected"
        foreach ($entry in $versions.GetEnumerator()) { Write-Host "  $($entry.Key): $($entry.Value)" -ForegroundColor Yellow }
    }
    return $aligned
}

# Coordinated PRs
function New-CoordinatedPRs {
    param($Repos)
    if ($DryRun) { Write-Log "INFO" "[DRY-RUN] Would create PRs across $($Repos.Count) repos"; return @{ dryRun = $true } }
    if (-not $Title) { throw "Parameter -Title is required" }
    Write-Log "INFO" "Creating coordinated PRs: $SourceBranch -> $TargetBranch"
    $results = @()
    foreach ($r in $Repos) {
        try {
            Invoke-WithRetry -ScriptBlock {
                $current = git -C $r.path rev-parse --abbrev-ref HEAD 2>$null
                $source = if ($SourceBranch) { $SourceBranch } else { $current }
                if (git -C $r.path status --porcelain) { throw "Uncommitted changes in $($r.name)" }
                git -C $r.path push origin "$source" 2>&1 | Out-Null
                if (Get-Command gh -ErrorAction SilentlyContinue) {
                    $prBody = if ($Body) { $Body } else { "Coordinated PR: $Title`n`nAuto-generated" }
                    gh pr create --repo $r.name --title "$Title" --body "$prBody" --base $TargetBranch 2>&1 | Out-Null
                }
            } -MaxRetries 3
            $results += @{ repo = $r.name; status = "success" }
            Write-Log "SUCCESS" "[$($r.name)] PR created"
        } catch {
            $results += @{ repo = $r.name; status = "failed"; error = $_.Exception.Message }
            Write-Log "ERROR" "[$($r.name)] Failed: $($_.Exception.Message)"
        }
    }
    return $results
}

# Sync Operation
function Sync-Repos {
    param($Repos)
    Write-Log "INFO" "Syncing $($Repos.Count) repositories..."
    $results = @()
    foreach ($r in $Repos) {
        try {
            Invoke-WithRetry -ScriptBlock {
                git -C $r.path fetch origin 2>&1 | Out-Null
                $branch = git -C $r.path rev-parse --abbrev-ref HEAD
                git -C $r.path pull origin $branch 2>&1 | Out-Null
            } -MaxRetries 3
            $results += @{ repo = $r.name; status = "synced" }
            Write-Log "SUCCESS" "[$($r.name)] Synced"
        } catch {
            $results += @{ repo = $r.name; status = "failed"; error = $_.Exception.Message }
            Write-Log "ERROR" "[$($r.name)] Sync failed"
        }
    }
    return $results
}

# Bulk Command
function Invoke-BulkCommand {
    param($Repos, [string]$Command)
    if (-not $Command) { throw "Parameter -Command is required" }
    Write-Log "INFO" "Executing bulk command..."
    $results = @()
    foreach ($r in $Repos) {
        try {
            $output = Invoke-Expression "cd '$($r.path)'; $Command" 2>&1
            $results += @{ repo = $r.name; status = "success"; output = $output }
            Write-Log "SUCCESS" "[$($r.name)] Executed"
        } catch {
            $results += @{ repo = $r.name; status = "failed"; error = $_.Exception.Message }
            Write-Log "ERROR" "[$($r.name)] Failed"
        }
    }
    return $results
}

# Dependency Check
function Test-Dependencies {
    param($Repos)
    Write-Log "INFO" "Checking cross-repo dependencies..."
    $results = @()
    foreach ($r in $Repos) {
        $pkg = Join-Path $r.path "package.json"
        if (Test-Path $pkg) {
            try {
                $json = Get-Content $pkg -Raw | ConvertFrom-Json
                $deps = @()
                if ($json.dependencies) { $deps += $json.dependencies.PSObject.Properties.Name }
                if ($json.devDependencies) { $deps += $json.devDependencies.PSObject.Properties.Name }
                $internal = $deps | Where-Object { $_ -like "@gentle-vanguard/*" }
                $results += @{ repo = $r.name; internalDeps = $internal; hasInternalDeps = $internal.Count -gt 0 }
            } catch { Write-Log "WARN" "[$($r.name)] Failed to parse package.json" }
        }
    }
    return $results
}

# Main Switch
switch ($Action) {
    "discover" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Initialize-Config; $cfg = Get-MultiRepoConfig }
        $candidates = Discover-Repos
        $aligned = Test-VersionAlignment @($cfg.repos)
        if ($Raw) { @{ config = $cfg; discovered = $candidates; versionAligned = $aligned } | ConvertTo-Json -Depth 10 }
        else { Write-Host "`nVersion aligned: $aligned" -ForegroundColor $(if ($aligned) { "Green" } else { "Red" }) }
    }
    "coordinated-pr" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg -or $cfg.repoCount -lt 2) { Write-Log "ERROR" "Need at least 2 repos"; exit 1 }
        $results = New-CoordinatedPRs $cfg.repos
        if ($Raw) { $results | ConvertTo-Json -Depth 3 }
    }
    "validate" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Write-Log "WARN" "No config found"; exit 0 }
        $aligned = Test-VersionAlignment @($cfg.repos)
        if ($Raw) { @{ versionAligned = $aligned; repos = $cfg.repos } | ConvertTo-Json -Depth 3 }
    }
    "sync" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Write-Log "ERROR" "No config found"; exit 1 }
        $results = Sync-Repos $cfg.repos
        if ($Raw) { $results | ConvertTo-Json -Depth 3 }
    }
    "bulk-command" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Write-Log "ERROR" "No config found"; exit 1 }
        $results = Invoke-BulkCommand $cfg.repos $Command
        if ($Raw) { $results | ConvertTo-Json -Depth 3 }
    }
    "dependency-check" {
        $cfg = Get-MultiRepoConfig
        if (-not $cfg) { Write-Log "ERROR" "No config found"; exit 1 }
        $results = Test-Dependencies $cfg.repos
        if ($Raw) { $results | ConvertTo-Json -Depth 3 }
        else {
            foreach ($r in $results) {
                Write-Host "`n[$($r.repo)]" -ForegroundColor Cyan
                if ($r.hasInternalDeps) { Write-Host "  Internal deps: $($r.internalDeps -join ', ')" -ForegroundColor Yellow }
                else { Write-Host "  No internal dependencies" -ForegroundColor Green }
            }
        }
    }
    "status" {
        $cfg = Get-MultiRepoConfig
        if ($Raw) {
            if (-not $cfg) { @{ configured = $false } | ConvertTo-Json; return }
            $cfg | ConvertTo-Json -Depth 10; return
        }
        Write-Log "INFO" "=== Multi-Repo Orchestration Status ==="
        if (-not $cfg) { Write-Log "WARN" "Status: NOT CONFIGURED"; exit 0 }
        Write-Host "  Version: $($cfg.version)" -ForegroundColor DarkGray
        Write-Host "  Enabled: $($cfg.enabled)" -ForegroundColor DarkGray
        Write-Host "  Repos: $($cfg.repoCount)" -ForegroundColor Cyan
        foreach ($r in $cfg.repos) {
            $status = if ($r.exists) { if ($r.hasGit) { "OK" } else { "NO-GIT" } } else { "MISSING" }
            $color = if ($status -eq "OK") { "Green" } elseif ($status -eq "NO-GIT") { "Yellow" } else { "Red" }
            Write-Host "    [$status] $($r.name) ($($r.roles -join ', '))" -ForegroundColor $color
        }
    }
}

