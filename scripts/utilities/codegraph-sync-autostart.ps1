# codegraph-sync-autostart.ps1
# CodeGraph sync step for session-autostart pipeline
# Verifies index freshness and syncs if stale

param(
    [string]$WorkspaceRoot = ".",
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
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

# Check all SQLite files (main DB + WAL + SHM) since writes go to WAL in WAL mode
$dbInfo = Get-Item $dbPath
$dbLastWrite = $dbInfo.LastWriteTime
$walPath = Join-Path $codegraphDir "codegraph.db-wal"
$shmPath = Join-Path $codegraphDir "codegraph.db-shm"

if (Test-Path $walPath) {
    $walWrite = (Get-Item $walPath).LastWriteTime
    if ($walWrite -gt $dbLastWrite) { $dbLastWrite = $walWrite }
}
if (Test-Path $shmPath) {
    $shmWrite = (Get-Item $shmPath).LastWriteTime
    if ($shmWrite -gt $dbLastWrite) { $dbLastWrite = $shmWrite }
}

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