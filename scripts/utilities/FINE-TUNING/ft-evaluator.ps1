param(
    [string]$RegistryPath = "",
    [string]$ReportPath = "",
    [string]$DatasetPath = "",
    [switch]$CompareBaseline,
    [string]$MLRouterPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
if (-not $RegistryPath) { $RegistryPath = Join-Path $ProjectRoot ".ft" "registry.json" }
if (-not $ReportPath) { $ReportPath = Join-Path $ProjectRoot ".ft" "benchmarks" "eval-$(Get-Date -Format 'yyyyMMdd-HHmmss').json" }
if (-not $DatasetPath) { $DatasetPath = Join-Path $ProjectRoot ".ft" "dataset" }
if (-not $MLRouterPath) { $MLRouterPath = Join-Path $ProjectRoot "scripts" "utilities" "AUTO-DELEGATION" "ml-router.ps1" }

$domains = @("BA", "SAD", "DEV", "QA")

function Get-DatasetStats {
    param([string]$Domain)
    $trainFile = Join-Path $DatasetPath "train" "$Domain.jsonl"
    $valFile = Join-Path $DatasetPath "val" "$Domain.jsonl"
    $trainCount = if (Test-Path $trainFile) { (Get-Content $trainFile -ErrorAction SilentlyContinue | Measure-Object).Count } else { 0 }
    $valCount = if (Test-Path $valFile) { (Get-Content $valFile -ErrorAction SilentlyContinue | Measure-Object).Count } else { 0 }
    return @{ train = $trainCount; val = $valCount }
}

function Measure-TFIDFLatency {
    param([string]$Query)
    if (-not (Test-Path $MLRouterPath)) { return @{ latencyMs = -1; error = "router not found" } }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $null = & $MLRouterPath -Query $Query -TopN 3 -Raw -ErrorAction SilentlyContinue
        $sw.Stop()
        return @{ latencyMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1); error = $null }
    } catch {
        $sw.Stop()
        return @{ latencyMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1); error = $_.Exception.Message }
    }
}

Write-Host "=== FT Evaluator ===" -ForegroundColor Cyan

$report = @{
    evalDate = (Get-Date -Format "o")
    registry = if (Test-Path $RegistryPath) { (Get-Content $RegistryPath -Raw | ConvertFrom-Json) } else { $null }
    dataset = @{}
    baseline = @{}
    adapters = @{}
}

foreach ($domain in $domains) {
    $stats = Get-DatasetStats -Domain $domain
    $report.dataset[$domain] = $stats

    $testQuery = "task for $domain domain: example query"
    $latency = Measure-TFIDFLatency -Query $testQuery
    $report.baseline[$domain] = $latency
}

if (Test-Path $RegistryPath) {
    try {
        $reg = Get-Content $RegistryPath -Raw | ConvertFrom-Json
        foreach ($adapter in $reg.adapters) {
            $report.adapters[$adapter.domain] = @{
                model = $adapter.model
                version = $adapter.version
                active = $adapter.active
                trainedAt = $adapter.trainedAt
            }
        }
    } catch {
        Write-Output "[FT-EVALUATOR] No adapter data found"
    }
}

$null = New-Item -ItemType Directory -Path (Split-Path $ReportPath -Parent) -Force
$report | ConvertTo-Json -Depth 4 | Out-File $ReportPath -Encoding utf8

Write-Host ""
Write-Host "=== Evaluation Report ===" -ForegroundColor Green
Write-Host "Report: $ReportPath"
Write-Host ""

foreach ($domain in $domains) {
    $ds = $report.dataset[$domain]
    $bl = $report.baseline[$domain]
    $adp = $report.adapters[$domain]
    $adpStatus = if ($adp) { "FT: $($adp.model) v$($adp.version) [ACTIVE]" } else { "FT: no adapter" }
    Write-Host "  $domain — Train: $($ds.train) | Val: $($ds.val) | TF-IDF: $($bl.latencyMs)ms | $($adpStatus)"
}

if ($CompareBaseline) {
    Write-Host ""
    Write-Host "[FT-EVAL] Comparison mode enabled" -ForegroundColor Cyan
    Write-Host "[FT-EVAL] Full eval requires trained adapters. Use ft-trainer.ps1 first."
}
