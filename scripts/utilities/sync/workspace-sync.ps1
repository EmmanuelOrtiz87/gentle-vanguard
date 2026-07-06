<#
.SYNOPSIS
    Multi-workspace synchronization for Gentle-Vanguard.
.DESCRIPTION
    Synchronizes knowledge base, engram memory, embeddings, and configurations
    between multiple Gentle-Vanguard workspaces via Git.
.PARAMETER Action
    sync: Synchronize from source to target workspace
    list: List available workspaces
    status: Show sync status for all workspaces
    init: Initialize a new workspace for sync
.PARAMETER SourceWorkspace
    Source workspace path (default: current workspace)
.PARAMETER TargetWorkspace
    Target workspace path (required for sync)
.PARAMETER DryRun
    Show what would be synced without making changes
.PARAMETER Quiet
    Suppress output.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('sync','list','status','init')]
    [string]$Action,
    [string]$SourceWorkspace = "",
    [string]$TargetWorkspace = "",
    [switch]$DryRun,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$root = Split-Path -Parent $root
$configFile = Join-Path $root 'config\workspace-sync.json'
$logDir = Join-Path $root '.session'
$logFile = Join-Path $logDir 'workspace-sync-log.jsonl'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Get-SyncConfig {
    if (-not (Test-Path $configFile)) {
        return @{
            version = "1.0"
            workspaces = @()
            syncItems = @(
                @{ name = "knowledge-base"; path = "knowledge-base"; enabled = $true }
                @{ name = "engram-data"; path = ".engram-data"; enabled = $true }
                @{ name = "skill-embeddings"; path = ".atl\skill-embeddings.json"; enabled = $true }
                @{ name = "ml-index"; path = ".atl\ml-index.json"; enabled = $true }
                @{ name = "configs"; path = "config"; enabled = $true }
                @{ name = "skills"; path = "skills"; enabled = $true }
            )
            excludePatterns = @(
                ".session\*",
                ".telemetry\*",
                ".runtime\*",
                "node_modules\*",
                "dist\*",
                ".git\*"
            )
        }
    }
    return Get-Content $configFile -Raw | ConvertFrom-Json
}

function Save-SyncConfig {
    param($Config)
    $Config | ConvertTo-Json -Depth 5 | Set-Content -Path $configFile -Encoding UTF8
}

function Get-WorkspaceId {
    param([string]$Path)
    $gitDir = Join-Path $Path '.git'
    if (Test-Path $gitDir) {
        $remote = & git -C $Path remote get-url origin 2>$null
        if ($remote) { return $remote }
    }
    return $Path
}

function Test-IsExcluded {
    param([string]$Path, [array]$Excludes)
    foreach ($pattern in $Excludes) {
        $cleanPattern = $pattern -replace '\\', '/'
        $cleanPath = $Path -replace '\\', '/'
        if ($cleanPath -like "*$cleanPattern*") { return $true }
    }
    return $false
}

switch ($Action) {
    'list' {
        $config = Get-SyncConfig
        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [WS] Registered Workspaces" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            if ($config.workspaces.Count -eq 0) {
                Write-Host " No workspaces registered. Use 'init' to add one." -ForegroundColor Yellow
            } else {
                foreach ($ws in $config.workspaces) {
                    $exists = Test-Path $ws.path
                    $color = if ($exists) { 'Green' } else { 'Red' }
                    $status = if ($exists) { 'EXISTS' } else { 'MISSING' }
                    Write-Host (" [{0}] {1} — {2}" -f $status, $ws.name, $ws.path) -ForegroundColor $color
                }
            }
            Write-Host ""
        }
        $config.workspaces
    }

    'init' {
        if (-not $TargetWorkspace) {
            if (-not $Quiet) { Write-Host " [ERROR] TargetWorkspace required for init" -ForegroundColor Red }
            exit 1
        }
        if (-not (Test-Path $TargetWorkspace)) {
            if (-not $Quiet) { Write-Host " [ERROR] Target path does not exist: $TargetWorkspace" -ForegroundColor Red }
            exit 1
        }

        $config = Get-SyncConfig
        $wsId = Get-WorkspaceId $TargetWorkspace
        $exists = $config.workspaces | Where-Object { $_.path -eq $TargetWorkspace }

        if ($exists) {
            if (-not $Quiet) { Write-Host " [OK] Workspace already registered: $TargetWorkspace" -ForegroundColor Green }
            exit 0
        }

        $config.workspaces += @{
            name = (Split-Path $TargetWorkspace -Leaf)
            path = $TargetWorkspace
            id = $wsId
            lastSync = $null
            enabled = $true
        }
        Save-SyncConfig $config

        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Green
            Write-Host " [WS] Workspace registered: $TargetWorkspace" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
        }
    }

    'status' {
        $config = Get-SyncConfig
        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [WS] Sync Status" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " Source: $(if($SourceWorkspace){$SourceWorkspace}else{'(current)'})" -ForegroundColor Gray
            Write-Host " Sync items: $($config.syncItems.Count)" -ForegroundColor Gray
            Write-Host " Workspaces: $($config.workspaces.Count)" -ForegroundColor Gray
            Write-Host ""
        }

        foreach ($item in $config.syncItems) {
            $sourcePath = if ($SourceWorkspace) { Join-Path $SourceWorkspace $item.path } else { Join-Path $root $item.path }
            $exists = Test-Path $sourcePath
            $status = if ($item.enabled) { if ($exists) { 'OK' } else { 'MISSING' } } else { 'DISABLED' }
            $color = switch ($status) { 'OK' { 'Green' } 'MISSING' { 'Yellow' } default { 'Gray' } }
            Write-Host (" [{0}] {1,-25} {2}" -f $status, $item.name, $item.path) -ForegroundColor $color
        }
        Write-Host ""
    }

    'sync' {
        if (-not $TargetWorkspace) {
            if (-not $Quiet) { Write-Host " [ERROR] TargetWorkspace required for sync" -ForegroundColor Red }
            exit 1
        }

        $config = Get-SyncConfig
        $source = if ($SourceWorkspace) { $SourceWorkspace } else { $root }
        $target = $TargetWorkspace

        if (-not (Test-Path $target)) {
            if (-not $Quiet) { Write-Host " [ERROR] Target path does not exist: $target" -ForegroundColor Red }
            exit 1
        }

        if (-not $Quiet) {
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [WS] Workspace Sync" -ForegroundColor Cyan
            Write-Host " Source: $source" -ForegroundColor Gray
            Write-Host " Target: $target" -ForegroundColor Gray
            Write-Host " DryRun: $DryRun" -ForegroundColor Gray
            Write-Host "============================================" -ForegroundColor Cyan
        }

        $syncedCount = 0
        $skippedCount = 0
        $errorCount = 0

        foreach ($item in $config.syncItems) {
            if (-not $item.enabled) {
                if (-not $Quiet) { Write-Host " [SKIP] $($item.name) — disabled" -ForegroundColor Gray }
                $skippedCount++
                continue
            }

            $srcPath = Join-Path $source $item.path
            $dstPath = Join-Path $target $item.path

            if (-not (Test-Path $srcPath)) {
                if (-not $Quiet) { Write-Host " [SKIP] $($item.name) — source not found" -ForegroundColor Yellow }
                $skippedCount++
                continue
            }

            if (-not $Quiet) { Write-Host " [SYNC] $($item.name)..." -ForegroundColor White -NoNewline }

            try {
                if ($DryRun) {
                    Write-Host " (dry-run)" -ForegroundColor Magenta
                } else {
                    $srcIsDir = (Get-Item $srcPath).PSIsContainer
                    if ($srcIsDir) {
                        $dstDir = Split-Path $dstPath -Parent
                        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
                        Copy-Item -Path $srcPath -Destination $dstPath -Recurse -Force
                    } else {
                        $dstDir = Split-Path $dstPath -Parent
                        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
                        Copy-Item -Path $srcPath -Destination $dstPath -Force
                    }
                    Write-Host " OK" -ForegroundColor Green
                }
                $syncedCount++
            } catch {
                Write-Host " ERROR: $_" -ForegroundColor Red
                $errorCount++
            }
        }

        # Log sync
        $logEntry = @{
            timestamp = (Get-Date).ToString('o')
            action = 'sync'
            source = $source
            target = $target
            synced = $syncedCount
            skipped = $skippedCount
            errors = $errorCount
            dryRun = $DryRun.IsPresent
        }
        $logEntry | ConvertTo-Json -Compress | Out-File -Append -FilePath $logFile -Encoding UTF8

        # Update last sync time in config
        $wsEntry = $config.workspaces | Where-Object { $_.path -eq $target }
        if ($wsEntry) {
            $wsEntry.lastSync = (Get-Date).ToString('o')
            Save-SyncConfig $config
        }

        if (-not $Quiet) {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
            Write-Host " [DONE] Synced: $syncedCount | Skipped: $skippedCount | Errors: $errorCount" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
            Write-Host "============================================" -ForegroundColor $(if($errorCount -gt 0){'Yellow'}else{'Green'})
        }
    }
}
