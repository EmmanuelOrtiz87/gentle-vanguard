# codegraph-post-modification-sync.ps1
# Post-modification hook to sync CodeGraph index after significant changes
# Called after file modifications, commits, or branch switches

param(
    [string]$WorkspaceRoot = ".",
    [string]$Trigger = "manual",
    [int]$MinChangesThreshold = 3,
    [switch]$Force,
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$codegraphDir = Join-Path $repoRoot ".codegraph"
$dbPath = Join-Path $codegraphDir "codegraph.db"

function Write-Result {
    param([string]$Status, [string]$Message, [hashtable]$Data = @{})
    if ($AsJson) {
        $result = @{ status = $Status; message = $Message; trigger = $Trigger; timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") }
        foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
        Write-Output ($result | ConvertTo-Json -Compress)
    } else {
        $color = if ($Status -eq "OK") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
        Write-Host "[$Status] $Message" -ForegroundColor $color
    }
}

if (-not (Test-Path $dbPath)) {
    Write-Result "WARN" "CodeGraph database not found. Skipping sync."
    exit 0
}

$changedFiles = 0
if ($Trigger -eq "post-commit" -or $Trigger -eq "git") {
    try {
        $gitStatus = & git -C $repoRoot status --porcelain 2>&1
        $changedFiles = ($gitStatus | Where-Object { $_ -match '^\s*[MADRC]' }).Count
    } catch {
        $changedFiles = 0
    }
}

if ($Force -or $changedFiles -ge $MinChangesThreshold -or $Trigger -eq "manual" -or $Trigger -eq "branch-switch") {
    Write-Host "[INFO] Syncing CodeGraph index (trigger: $Trigger, changed: $changedFiles files)..." -ForegroundColor Cyan
    try {
        $syncResult = & codegraph sync 2>&1
        $syncExit = $LASTEXITCODE
        if ($syncExit -eq 0) {
            Write-Result "OK" "CodeGraph index synced (trigger: $Trigger, $changedFiles changed files)" @{ changedFiles = $changedFiles; trigger = $Trigger }
        } else {
            Write-Result "WARN" "CodeGraph sync exited with code $syncExit" @{ changedFiles = $changedFiles; trigger = $Trigger }
        }
    } catch {
        Write-Result "WARN" "CodeGraph sync failed: $($_.Exception.Message)" @{ changedFiles = $changedFiles; trigger = $Trigger }
    }
} else {
    Write-Result "OK" "CodeGraph sync skipped (only $changedFiles changed files, threshold: $MinChangesThreshold)" @{ changedFiles = $changedFiles; trigger = $Trigger }
}

exit 0