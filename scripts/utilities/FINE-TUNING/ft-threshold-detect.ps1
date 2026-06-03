#!/usr/bin/env pwsh
<# 
.SYNOPSIS
    Detect domains with sufficient data for fine-tuning training.

.DESCRIPTION
    Checks the raw dataset directory and warns when any domain has >= $Threshold
    records. Also reports train/val splits. Returns exit code 2 if any domain
    exceeds threshold (CI signal), 0 if none do, 1 on error.

    Designed for CI pipeline (maintenance-scheduled.yml) and manual use.

.PARAMETER Threshold
    Minimum raw records per domain to trigger a training-ready warning (default: 100).

.PARAMETER RegistryPath
    Path to the FT registry JSON (default: .ft/registry.json).

.PARAMETER DatasetDir
    Path to the dataset directory (default: .ft/dataset).

.PARAMETER Json
    Output results as JSON (for dashboard / CI consumption).

.EXAMPLE
    pwsh -NoProfile -File scripts/utilities/FINE-TUNING/ft-threshold-detect.ps1

.EXAMPLE
    pwsh -NoProfile -File scripts/utilities/FINE-TUNING/ft-threshold-detect.ps1 -Threshold 50 -Json
#>

param(
    [int]$Threshold = 100,
    [string]$RegistryPath = ".ft/registry.json",
    [string]$DatasetDir = ".ft/dataset",
    [switch]$Json
)

$ErrorActionPreference = 'Continue'

$Root = git -C $PSScriptRoot rev-parse --show-toplevel 2>$null
if (-not $Root) { $Root = (Resolve-Path "$PSScriptRoot\..\..\..").Path }

$RegPath = Join-Path $Root $RegistryPath
$DataDir = Join-Path $Root $DatasetDir
$RawDir  = Join-Path $DataDir "raw"

$results = [System.Collections.Generic.List[PSObject]]::new()
$domainsAboveThreshold = @()
$totalRaw = 0

# --- Registry ---
if (Test-Path $RegPath) {
    try {
        $reg = Get-Content $RegPath -Raw | ConvertFrom-Json
        $results.Add([PSCustomObject]@{ check = "registry"; status = "ok"; message = "Registry loaded" })
    } catch {
        $results.Add([PSCustomObject]@{ check = "registry"; status = "error"; message = "Cannot parse registry: $_" })
    }
} else {
    $results.Add([PSCustomObject]@{ check = "registry"; status = "warn"; message = "Registry not found at $RegPath" })
}

# --- Raw files per domain ---
if (Test-Path $RawDir) {
    $rawFiles = @(Get-ChildItem "$RawDir\*.json" -File -ErrorAction SilentlyContinue)
    $totalRaw = $rawFiles.Count
    $results.Add([PSCustomObject]@{ check = "raw-count"; status = "ok"; message = "Total raw files: $totalRaw" })

    $domains = @{}
    foreach ($f in $rawFiles) {
        try {
            $content = Get-Content $f.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $domain = if ($content.domain) { [string]$content.domain } else { "unknown" }
            if (-not $domains.ContainsKey($domain)) { $domains[$domain] = 0 }
            $domains[$domain]++
        } catch {
            $domains["unknown"]++
        }
    }

    foreach ($d in $domains.Keys | Sort-Object) {
        $count = $domains[$d]
        if ($count -ge $Threshold) {
            $domainsAboveThreshold += $d
            $results.Add([PSCustomObject]@{
                check   = "domain-$d"
                status  = "warn"
                message = "$count raw records (>= $Threshold) — ready for training"
            })
        } else {
            $results.Add([PSCustomObject]@{
                check   = "domain-$d"
                status  = "ok"
                message = "$count raw records (< $Threshold)"
            })
        }
    }
} else {
    $results.Add([PSCustomObject]@{ check = "raw-directory"; status = "warn"; message = "Raw dataset directory not found" })
}

# --- Train/val counts ---
$TrainDir = Join-Path $DataDir "train"
$ValDir   = Join-Path $DataDir "val"
$trainCount = @(Get-ChildItem "$TrainDir\*.json" -File -ErrorAction SilentlyContinue).Count
$valCount   = @(Get-ChildItem "$ValDir\*.json" -File -ErrorAction SilentlyContinue).Count
$results.Add([PSCustomObject]@{ check = "train-count"; status = "ok"; message = "Train files: $trainCount" })
$results.Add([PSCustomObject]@{ check = "val-count";   status = "ok"; message = "Val files: $valCount" })

# --- Summary ---
$readyCount = $domainsAboveThreshold.Count

if ($Json) {
    @{
        timestamp   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        threshold   = $Threshold
        total_raw   = $totalRaw
        train       = $trainCount
        val         = $valCount
        domains     = $domains
        ready       = $domainsAboveThreshold
        results     = $results
        exit_code   = if ($readyCount -gt 0) { 2 } else { 0 }
    } | ConvertTo-Json -Depth 5
} else {
    Write-Host "`n=== Fine-Tuning Threshold Detection ===" -ForegroundColor Cyan
    Write-Host "Threshold: $Threshold records per domain"
    Write-Host "Total raw: $totalRaw | Train: $trainCount | Val: $valCount`n"
    foreach ($r in $results) {
        $color = switch ($r.status) { "ok" { "Green" } "warn" { "Yellow" } "error" { "Red" } }
        Write-Host "  [$($r.status.ToUpper())] $($r.check): $($r.message)" -ForegroundColor $color
    }
    if ($readyCount -gt 0) {
        Write-Host "`n⚠ READY FOR TRAINING: $readyCount domain(s) above threshold!" -ForegroundColor Yellow
        foreach ($d in $domainsAboveThreshold) {
            Write-Host "  → $d ($($domains[$d]) records)" -ForegroundColor Yellow
        }
        Write-Host "  Run: .\scripts\utilities\FINE-TUNING\ft-trainer.ps1 -Mode python-unsloth -Force`n" -ForegroundColor DarkGray
    } else {
        Write-Host "`nNo domain exceeds threshold. Keep collecting data.`n" -ForegroundColor Green
    }
}

exit $(if ($readyCount -gt 0) { 2 } else { 0 })
