<#
.SYNOPSIS
    Auto-compact engram observations older than retention threshold.
.DESCRIPTION
    Prunes old engram observations while preserving important types (decisions, architecture, bugfixes).
    Enforces the 90-day retention policy that was declared but never enforced.
.PARAMETER RetentionDays
    Observations older than this are candidates for pruning. Default: 90.
.PARAMETER MinKeepCount
    Always keep at least this many recent observations. Default: 50.
.PARAMETER DryRun
    Show what would be deleted without actually deleting.
.PARAMETER Force
    Skip confirmation prompt.
.PARAMETER Quiet
    Suppress output.
#>
param(
    [int]$RetentionDays = 90,
    [int]$MinKeepCount = 50,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$root = Split-Path -Parent $root
$engramExe = Join-Path $root 'tools\engram.exe'
$logDir = Join-Path $root '.session'
$logFile = Join-Path $logDir 'compaction-log.jsonl'
$engramDataDir = Join-Path $root '.engram-data'
$engramDb = Join-Path $engramDataDir 'engram.db'

if (-not $Quiet) {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " [EC] Engram Auto-Compact v1.0" -ForegroundColor Cyan
    Write-Host " Retention: $RetentionDays days | MinKeep: $MinKeepCount" -ForegroundColor Cyan
    Write-Host " DryRun: $DryRun | Force: $Force" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}

# Check engram is available
if (-not (Test-Path $engramExe)) {
    if (-not $Quiet) { Write-Host " [WARN] engram.exe not found, skipping compaction" -ForegroundColor Yellow }
    exit 0
}

# Check DB exists
if (-not (Test-Path $engramDb)) {
    if (-not $Quiet) { Write-Host " [WARN] engram.db not found, skipping compaction" -ForegroundColor Yellow }
    exit 0
}

# Ensure log directory exists
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Check last compaction time
$lastCompaction = $null
if (Test-Path $logFile) {
    $lastLine = Get-Content $logFile -Tail 1
    try {
        $lastEntry = $lastLine | ConvertFrom-Json
        $lastCompaction = [DateTime]::Parse($lastEntry.timestamp)
    } catch { }
}

$hoursSinceLast = if ($lastCompaction) { ((Get-Date) - $lastCompaction).TotalHours } else { 999 }
if ($hoursSinceLast -lt 24 -and -not $Force) {
    if (-not $Quiet) { Write-Host " [OK] Last compaction was $([math]::Round($hoursSinceLast, 1))h ago (<24h), skipping" -ForegroundColor Green }
    exit 0
}

# Get total observation count
$totalCount = 0
try {
    $result = & $engramExe search --limit 1 --project gentle-vanguard 2>&1
    if ($result -match '"total"\s*:\s*(\d+)') {
        $totalCount = [int]$Matches[1]
    }
} catch { }

if ($totalCount -lt 100) {
    if (-not $Quiet) { Write-Host " [OK] Only $totalCount observations (<100), skipping compaction" -ForegroundColor Green }
    exit 0
}

if (-not $Quiet) { Write-Host " [INFO] Total observations: $totalCount" -ForegroundColor Gray }

# Calculate cutoff date
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
$cutoffStr = $cutoffDate.ToString('yyyy-MM-dd')

if (-not $Quiet) { Write-Host " [INFO] Cutoff date: $cutoffStr ($RetentionDays days ago)" -ForegroundColor Gray }

# Fetch observations (batch of 500)
$allObs = @()
$offset = 0
$batchSize = 500
do {
    try {
        $json = & $engramExe search --limit $batchSize --offset $offset --project gentle-vanguard 2>&1 | Out-String
        $parsed = $json | ConvertFrom-Json
        if ($parsed.observations) {
            $allObs += $parsed.observations
        }
        $offset += $batchSize
    } catch {
        break
    }
} while ($allObs.Count -lt $totalCount -and $allObs.Count -lt 2000)

if (-not $Quiet) { Write-Host " [INFO] Fetched $($allObs.Count) observations" -ForegroundColor Gray }

# Identify candidates for pruning
$candidates = @()
$protectedTypes = @('decision', 'architecture', 'bugfix')

foreach ($obs in $allObs) {
    $createdAt = $null
    try {
        $createdAt = [DateTime]::Parse($obs.created_at)
    } catch {
        continue
    }

    # Skip recent observations
    if ($createdAt -gt $cutoffDate) { continue }

    # Skip pinned observations
    if ($obs.pinned -eq $true) { continue }

    # Skip protected types (but allow if very old > 180 days)
    $ageDays = ((Get-Date) - $createdAt).TotalDays
    if ($obs.type -in $protectedTypes -and $ageDays -lt 180) { continue }

    $candidates += @{
        id = $obs.id
        title = $obs.title
        type = $obs.type
        created_at = $obs.created_at
        ageDays = [math]::Round($ageDays, 0)
        topic_key = $obs.topic_key
    }
}

# Sort by age (oldest first)
$candidates = $candidates | Sort-Object -Property ageDays -Descending

if (-not $Quiet) { Write-Host " [INFO] Candidates for pruning: $($candidates.Count)" -ForegroundColor Gray }

# Apply MinKeepCount limit
$toPrune = $candidates
if ($candidates.Count -gt 0) {
    $maxPrune = [math]::Max(0, $totalCount - $MinKeepCount)
    if ($toPrune.Count -gt $maxPrune) {
        $toPrune = $toPrune[0..($maxPrune - 1)]
        if (-not $Quiet) { Write-Host " [INFO] Limited to $maxPrune (respecting MinKeepCount=$MinKeepCount)" -ForegroundColor Gray }
    }

    # Safety: never delete more than 30% of total
    $maxSafe = [math]::Floor($totalCount * 0.3)
    if ($toPrune.Count -gt $maxSafe) {
        $toPrune = $toPrune[0..($maxSafe - 1)]
        if (-not $Quiet) { Write-Host " [INFO] Limited to $maxSafe (30% safety limit)" -ForegroundColor Yellow }
    }
}

if ($toPrune.Count -eq 0) {
    if (-not $Quiet) { Write-Host " [OK] No observations to prune" -ForegroundColor Green }

    # Log even when nothing to prune
    $logEntry = @{
        timestamp = (Get-Date).ToString('o')
        action = 'compact'
        totalObs = $totalCount
        candidates = 0
        pruned = 0
        kept = $totalCount
        dryRun = $DryRun.IsPresent
    }
    $logEntry | ConvertTo-Json -Compress | Out-File -Append -FilePath $logFile -Encoding UTF8
    exit 0
}

if (-not $Quiet) {
    Write-Host ""
    Write-Host " [PLAN] Will prune $($toPrune.Count) observations:" -ForegroundColor Yellow
    foreach ($obs in $toPrune[0..9]) {
        Write-Host "   - [$($obs.type)] $($obs.title) ($($obs.ageDays)d old)" -ForegroundColor Gray
    }
    if ($toPrune.Count -gt 10) {
        Write-Host "   ... and $($toPrune.Count - 10) more" -ForegroundColor Gray
    }
    Write-Host ""
}

# Execute pruning (unless DryRun)
$prunedCount = 0
if (-not $DryRun) {
    foreach ($obs in $toPrune) {
        try {
            & $engramExe delete --id $obs.id 2>&1 | Out-Null
            $prunedCount++
            if (-not $Quiet -and ($prunedCount % 10) -eq 0) {
                Write-Host "   Pruned $prunedCount/$($toPrune.Count)..." -ForegroundColor Gray
            }
        } catch {
            if (-not $Quiet) { Write-Host "   [WARN] Failed to delete id=$($obs.id): $_" -ForegroundColor Yellow }
        }
    }
} else {
    $prunedCount = $toPrune.Count
    if (-not $Quiet) { Write-Host " [DRY-RUN] Would prune $prunedCount observations" -ForegroundColor Magenta }
}

# Log results
$logEntry = @{
    timestamp = (Get-Date).ToString('o')
    action = 'compact'
    totalObs = $totalCount
    candidates = $candidates.Count
    pruned = $prunedCount
    kept = $totalCount - $prunedCount
    retentionDays = $RetentionDays
    dryRun = $DryRun.IsPresent
}
$logEntry | ConvertTo-Json -Compress | Out-File -Append -FilePath $logFile -Encoding UTF8

if (-not $Quiet) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " [DONE] Compaction complete" -ForegroundColor Green
    Write-Host "   Pruned: $prunedCount | Kept: $($totalCount - $prunedCount)" -ForegroundColor Green
    Write-Host "   Log: $logFile" -ForegroundColor Gray
    Write-Host "============================================" -ForegroundColor Green
}
