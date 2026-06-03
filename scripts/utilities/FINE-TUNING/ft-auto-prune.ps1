#!/usr/bin/env pwsh
<# 
.SYNOPSIS
    Auto-prune old raw data files from the fine-tuning dataset.

.DESCRIPTION
    Removes raw JSON files in .ft/dataset/raw/ older than -Days (default: 7).
    Keeps train/val files untouched — only prunes collected raw input.
    Logs pruned files to .ft/dataset/prune-log.csv.

    Designed for CI scheduled runs (maintenance-scheduled.yml).

.PARAMETER Days
    Age threshold in days. Files older than this are removed (default: 7).

.PARAMETER DatasetDir
    Path to the dataset directory (default: .ft/dataset).

.PARAMETER WhatIf
    Show what would be pruned without actually deleting.

.PARAMETER Json
    Output results as JSON.

.EXAMPLE
    pwsh -NoProfile -File scripts/utilities/FINE-TUNING/ft-auto-prune.ps1

.EXAMPLE
    pwsh -NoProfile -File scripts/utilities/FINE-TUNING/ft-auto-prune.ps1 -Days 14 -WhatIf

.EXAMPLE
    pwsh -NoProfile -File scripts/utilities/FINE-TUNING/ft-auto-prune.ps1 -Days 7 -Json
#>

param(
    [int]$Days = 7,
    [string]$DatasetDir = ".ft/dataset",
    [switch]$WhatIf,
    [switch]$Json
)

$ErrorActionPreference = 'Continue'

$Root = git -C $PSScriptRoot rev-parse --show-toplevel 2>$null
if (-not $Root) { $Root = (Resolve-Path "$PSScriptRoot\..\..\..").Path }

$DataDir   = Resolve-Path (Join-Path $Root $DatasetDir) -ErrorAction SilentlyContinue
$RawDir    = if ($DataDir) { Join-Path $DataDir "raw" } else { $null }
$LogDir    = if ($DataDir) { Join-Path $DataDir "." } else { Join-Path $Root ".ft/dataset" }
$PruneLog  = Join-Path $LogDir "prune-log.csv"

$Cutoff = (Get-Date).AddDays(-$Days)

$pruned   = @()
$errors   = @()
$skipped  = @()
$totalSize = 0

if (-not $DataDir -or -not (Test-Path $RawDir)) {
    $msg = "Raw directory not found: $RawDir"
    if ($Json) {
        @{ timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"); days = $Days; status = "skipped"; message = $msg } | ConvertTo-Json -Depth 3
    } else {
        Write-Host "FT Auto-Prune: $msg" -ForegroundColor Yellow
    }
    exit 0
}

$files = @(Get-ChildItem "$RawDir\*.json" -File -ErrorAction SilentlyContinue)

foreach ($f in $files) {
    if ($f.LastWriteTime -lt $Cutoff) {
        $sizeKB = [math]::Round($f.Length / 1KB, 1)
        $totalSize += $f.Length
        if ($WhatIf) {
            $skipped += $f.FullName
        } else {
            try {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
                $pruned += @{
                    file     = $f.Name
                    path     = $f.FullName
                    size_kb  = $sizeKB
                    modified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                }
            } catch {
                $errors += @{ file = $f.Name; error = $_.Exception.Message }
            }
        }
    }
}

# --- Log to CSV ---
if ($pruned.Count -gt 0 -and -not $WhatIf) {
    $logDir = Split-Path $PruneLog -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $header = -not (Test-Path $PruneLog)
    if ($header) {
        "timestamp,file,size_kb,modified,days_old" | Out-File -FilePath $PruneLog -Encoding UTF8 -Force
    }
    foreach ($p in $pruned) {
        "{0},{1},{2},{3},{4}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.file, $p.size_kb, $p.modified, $Days | Out-File -FilePath $PruneLog -Encoding UTF8 -Append
    }
}

# --- Output ---
$totalPruned = $pruned.Count
$totalSkipped = $skipped.Count
$totalErrors = $errors.Count
$prunedSizeKB = [math]::Round($totalSize / 1KB, 1)

if ($Json) {
    @{
        timestamp   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        days        = $Days
        whatif      = $WhatIf.IsPresent
        scanned     = $files.Count
        pruned      = $totalPruned
        pruned_size_kb = $prunedSizeKB
        skipped     = $totalSkipped
        errors      = $totalErrors
        error_list  = $errors
        status      = if ($totalErrors -gt 0) { "partial" } else { "ok" }
    } | ConvertTo-Json -Depth 4
} else {
    $action = if ($WhatIf) { "Would prune" } else { "Pruned" }
    Write-Host "`n=== FT Auto-Prune ===" -ForegroundColor Cyan
    Write-Host "Threshold: $Days days (cutoff: $($Cutoff.ToString('yyyy-MM-dd HH:mm')))"
    Write-Host "Scanned: $($files.Count) raw files"
    if ($WhatIf) {
        Write-Host "`n$action $totalSkipped file(s) ($prunedSizeKB KB):" -ForegroundColor Yellow
        foreach ($s in $skipped) { Write-Host "  → $s" -ForegroundColor DarkGray }
    } elseif ($totalPruned -gt 0) {
        Write-Host "`n$action $totalPruned file(s) ($prunedSizeKB KB)" -ForegroundColor Green
        Write-Host "Log: $PruneLog" -ForegroundColor DarkGray
    } else {
        Write-Host "`nNo files older than $Days days to prune." -ForegroundColor Green
    }
    if ($totalErrors -gt 0) {
        Write-Host "`nErrors: $totalErrors" -ForegroundColor Red
        foreach ($e in $errors) { Write-Host "  ✗ $($e.file): $($e.error)" -ForegroundColor Red }
    }
    Write-Host ""
}

exit $(if ($totalErrors -gt 0) { 1 } else { 0 })
