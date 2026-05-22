# codegraph-sync-autostart.ps1
# CodeGraph sync step for session-autostart pipeline
# Verifies index freshness and syncs if stale

param(
    [string]$WorkspaceRoot = ".",
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { 
        Split-Path -Parent $MyInvocation.MyCommand.Path 
    } else { 
        Get-Location 
    }
    $root = Split-Path -Parent $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { 
        $root = Split-Path -Parent $root 
    }
    if (-not $root) { $root = $scriptRoot }
    $root
}

$codegraphDir = Join-Path $repoRoot ".codegraph"
$dbPath = Join-Path $codegraphDir "codegraph.db"
$configPath = Join-Path $codegraphDir "config.json"

function Write-Result {
    param([string]$Status, [string]$Message, [hashtable]$Data = @{})
    if ($AsJson) {
        $result = @{ status = $Status; message = $Message; timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") }
        foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
        Write-Output ($result | ConvertTo-Json -Compress)
    } else {
        $color = if ($Status -eq "OK") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
        Write-Host "[$Status] $Message" -ForegroundColor $color
    }
}

if (-not (Test-Path $codegraphDir)) {
    Write-Result "WARN" "CodeGraph directory not found. Run 'codegraph init -i' first."
    exit 0
}

if (-not (Test-Path $dbPath)) {
    Write-Result "WARN" "CodeGraph database not found. Run 'codegraph init -i' first."
    exit 0
}

$dbInfo = Get-Item $dbPath
$dbLastWrite = $dbInfo.LastWriteTime
$dbAgeMinutes = [math]::Round(((Get-Date) - $dbLastWrite).TotalMinutes, 1)
$dbSizeMB = [math]::Round($dbInfo.Length / 1MB, 2)

$stalenessThresholdMinutes = 30
$needsSync = $dbAgeMinutes -gt $stalenessThresholdMinutes

if ($needsSync) {
    Write-Host "[INFO] CodeGraph index is $($dbAgeMinutes)min old (threshold: ${stalenessThresholdMinutes}min). Syncing..." -ForegroundColor Yellow
    try {
        $syncResult = & codegraph sync 2>&1
        $syncExit = $LASTEXITCODE
        if ($syncExit -eq 0) {
            Write-Result "OK" "CodeGraph index synced successfully (was $($dbAgeMinutes)min old)" @{ dbSizeMB = $dbSizeMB; ageMinutes = $dbAgeMinutes; action = "synced" }
        } else {
            Write-Result "WARN" "CodeGraph sync exited with code $syncExit. Index may be stale." @{ dbSizeMB = $dbSizeMB; ageMinutes = $dbAgeMinutes; action = "sync_failed" }
        }
    } catch {
        Write-Result "WARN" "CodeGraph sync failed: $($_.Exception.Message)" @{ dbSizeMB = $dbSizeMB; ageMinutes = $dbAgeMinutes; action = "sync_error" }
    }
} else {
    Write-Result "OK" "CodeGraph index is fresh ($($dbAgeMinutes)min old, ${dbSizeMB}MB)" @{ dbSizeMB = $dbSizeMB; ageMinutes = $dbAgeMinutes; action = "fresh" }
}

exit 0