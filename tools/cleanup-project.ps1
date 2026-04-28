#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Project Cleanup - Removes temporary files and optimizes project structure
    
.DESCRIPTION
    Cleans up temporary files, logs, caches, and unnecessary files
    while preserving all important project files.
    
.PARAMETER Mode
    Mode: full, safe, dry-run
    
.EXAMPLE
    .\cleanup-project.ps1 -Mode dry-run
    .\cleanup-project.ps1 -Mode safe
    .\cleanup-project.ps1 -Mode full
#>

param(
    [ValidateSet('full', 'safe', 'dry-run')]
    [string]$Mode = 'safe',
    [string]$ProjectRoot = '.',
    [string]$LogLevel = 'info'
)

$CleanupVersion = "1.0.0"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Get-CleanupTargets {
    Write-Log "Scanning for cleanup targets..." "info"
    
    $targets = @{
        tempFiles = @()
        logFiles = @()
        cacheFiles = @()
        backupFiles = @()
        unnecessary = @()
    }
    
    $tempPatterns = @('*.tmp', '*.temp', '*.bak', '*.backup')
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter $pattern -ErrorAction SilentlyContinue
        $targets.tempFiles += $files
    }
    
    $logFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.log" -ErrorAction SilentlyContinue | 
                Where-Object { $_.FullName -notlike "*docs\judgment*" }
    $targets.logFiles += $logFiles
    
    $cacheDirs = Get-ChildItem -Path $ProjectRoot -Recurse -Directory -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Name -like "*cache*" }
    $targets.cacheFiles += $cacheDirs
    
    $backupFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*backup*" -ErrorAction SilentlyContinue
    $targets.backupFiles += $backupFiles
    
    Write-Log "Found: $($targets.tempFiles.Count) temp, $($targets.logFiles.Count) logs, $($targets.cacheFiles.Count) caches" "info"
    
    return $targets
}

function Show-CleanupPlan {
    param([hashtable]$Targets)
    
    Write-Log "=== CLEANUP PLAN ===" "info"
    
    if ($Targets.tempFiles.Count -gt 0) {
        Write-Log "Temporary Files ($($Targets.tempFiles.Count)):" "info"
        $Targets.tempFiles | ForEach-Object { Write-Log "  - $($_.FullName)" "debug" }
    }
    
    if ($Targets.logFiles.Count -gt 0) {
        Write-Log "Log Files ($($Targets.logFiles.Count)):" "info"
        $Targets.logFiles | ForEach-Object { Write-Log "  - $($_.FullName)" "debug" }
    }
    
    if ($Targets.cacheFiles.Count -gt 0) {
        Write-Log "Cache Directories ($($Targets.cacheFiles.Count)):" "info"
        $Targets.cacheFiles | ForEach-Object { Write-Log "  - $($_.FullName)" "debug" }
    }
    
    if ($Targets.backupFiles.Count -gt 0) {
        Write-Log "Backup Files ($($Targets.backupFiles.Count)):" "info"
        $Targets.backupFiles | ForEach-Object { Write-Log "  - $($_.FullName)" "debug" }
    }
}

function Execute-Cleanup {
    param([hashtable]$Targets, [string]$Mode)
    
    $cleaned = 0
    
    if ($Mode -eq 'dry-run') {
        Write-Log "DRY-RUN MODE: No files will be deleted" "warn"
        Show-CleanupPlan $Targets
        return 0
    }
    
    foreach ($file in $Targets.tempFiles) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Log "Deleted: $($file.FullName)" "info"
            $cleaned++
        }
        catch {
            Write-Log "Failed to delete: $($file.FullName)" "error"
        }
    }
    
    if ($Mode -eq 'full') {
        foreach ($file in $Targets.logFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                Write-Log "Deleted: $($file.FullName)" "info"
                $cleaned++
            }
            catch {
                Write-Log "Failed to delete: $($file.FullName)" "error"
            }
        }
    }
    
    foreach ($dir in $Targets.cacheFiles) {
        try {
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
            Write-Log "Deleted: $($dir.FullName)" "info"
            $cleaned++
        }
        catch {
            Write-Log "Failed to delete: $($dir.FullName)" "error"
        }
    }
    
    return $cleaned
}

function Verify-ProjectIntegrity {
    Write-Log "Verifying project integrity..." "info"
    
    $requiredDirs = @('config', 'tools', 'docs', 'skills', 'demos')
    $requiredFiles = @('AGENTS.md', 'README.md')
    
    $allGood = $true
    
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path "$ProjectRoot\$dir")) {
            Write-Log "Missing directory: $dir" "error"
            $allGood = $false
        }
    }
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path "$ProjectRoot\$file")) {
            Write-Log "Missing file: $file" "error"
            $allGood = $false
        }
    }
    
    if ($allGood) {
        Write-Log "Project integrity verified" "info"
    }
    else {
        Write-Log "Project integrity check failed" "error"
    }
    
    return $allGood
}

function Save-EngramContext {
    Write-Log "Saving context to Engram before cleanup..." "info"
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
    
    if (Test-Path $engramBin) {
        $summaryContent = @"
## Pre-Cleanup Summary
Cleanup initiated in mode: $Mode
Timestamp: $timestamp

Context preserved before cleanup operation.
"@
        & $engramBin save --title "Pre-Cleanup Context Save" --content $summaryContent --project "gentleman-foundation" --type manual 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Context saved to Engram" "info"
        } else {
            Write-Log "Failed to save to Engram (code: $LASTEXITCODE)" "warn"
        }
    } else {
        Write-Log "Engram not found, skipping context save" "warn"
    }
}

function Main {
    Write-Log "Project Cleanup v$CleanupVersion" "info"
    Write-Log "Mode: $Mode" "info"
    
    # Save context to Engram BEFORE any cleanup
    Save-EngramContext
    
    $targets = Get-CleanupTargets
    Show-CleanupPlan $targets
    $cleaned = Execute-Cleanup $targets $Mode
    
    Write-Log "Cleanup completed: $cleaned items processed" "info"
    
    $integrity = Verify-ProjectIntegrity
    
    if ($integrity) {
        Write-Log "[OK] Project is clean and ready" "info"
        return 0
    }
    else {
        Write-Log "[FAIL] Project integrity issues detected" "error"
        return 1
    }
}

exit (Main)