<#
.SYNOPSIS
  Eval Registry — store, list, compare, and prune versioned evaluation results.

.DESCRIPTION
  Manages the eval results directory. Supports listing all results for a skill,
  comparing two runs, and pruning old results beyond a retention threshold.

.PARAMETER Action
  list    — list all results for a skill (default)
  compare — compare two result files by path
  latest  — show latest result for a skill
  prune   — remove results older than -RetentionDays

.PARAMETER Skill
  Skill name to filter results.

.PARAMETER ResultA
  Path to first result file (for compare action).

.PARAMETER ResultB
  Path to second result file (for compare action).

.PARAMETER RetentionDays
  Prune results older than this many days (default: 90).

.EXAMPLE
  .\eval-registry.ps1 -Action list -Skill "codegraph-search"
  .\eval-registry.ps1 -Action latest -Skill "codegraph-search"
#>

param(
  [ValidateSet("list", "compare", "latest", "prune")]
  [string]$Action = "list",
  [string]$Skill = "",
  [string]$ResultA = "",
  [string]$ResultB = "",
  [int]$RetentionDays = 90
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$baseDir = if ($env:GENTLE_TENANT_EVAL_DIR) { $env:GENTLE_TENANT_EVAL_DIR } else { Join-Path $repoRoot ".session\eval" }
$resultsDir = Join-Path $baseDir "results"

switch ($Action) {
  "list" {
    if (-not (Test-Path $resultsDir)) {
      Write-Host "[EVAL-REG] No results found" -ForegroundColor Yellow
      return @()
    }
    $entries = if ($Skill) {
      $skillDir = Join-Path $resultsDir $Skill
      if (Test-Path $skillDir) { Get-ChildItem -Path $skillDir -Filter "*.json" | Sort-Object LastWriteTime -Descending } else { @() }
    } else {
      Get-ChildItem -Path $resultsDir -Recurse -Filter "*.json" | Sort-Object LastWriteTime -Descending
    }

    Write-Host "[EVAL-REG] Results:" -ForegroundColor Cyan
    foreach ($entry in $entries) {
      $data = Get-Content $entry.FullName -Raw | ConvertFrom-Json
      $color = if ($data.passed -eq $data.totalCases) { "Green" } elseif ($data.avgScore -ge 0.5) { "Yellow" } else { "Red" }
      Write-Host "  [$($data.suite)] $($entry.BaseName) — $($data.passed)/$($data.totalCases) passed, avg $($data.avgScore)" -ForegroundColor $color
    }
    return $entries
  }

  "latest" {
    $skillDir = Join-Path $resultsDir $Skill
    if (-not (Test-Path $skillDir)) {
      Write-Host "[EVAL-REG] No results for skill: $Skill" -ForegroundColor Yellow
      return $null
    }
    $latest = Get-ChildItem -Path $skillDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
      return Get-Content $latest.FullName -Raw | ConvertFrom-Json
    }
    return $null
  }

  "compare" {
    if (-not $ResultA -or -not $ResultB) {
      Write-Error "Provide -ResultA and -ResultB for compare action"
      exit 1
    }
    $a = Get-Content $ResultA -Raw | ConvertFrom-Json
    $b = Get-Content $ResultB -Raw | ConvertFrom-Json

    Write-Host "[EVAL-REG] Comparison:" -ForegroundColor Cyan
    Write-Host "  A: $($a.timestamp) — score $($a.avgScore), $($a.passed)/$($a.totalCases) passed" -ForegroundColor Gray
    Write-Host "  B: $($b.timestamp) — score $($b.avgScore), $($b.passed)/$($b.totalCases) passed" -ForegroundColor Gray
    $delta = [math]::Round($b.avgScore - $a.avgScore, 3)
    $deltaColor = if ($delta -gt 0) { "Green" } elseif ($delta -lt 0) { "Red" } else { "Gray" }
    Write-Host "  Δ: $delta" -ForegroundColor $deltaColor
    Write-Host "  Duration Δ: $([math]::Round($b.duration - $a.duration, 1))s" -ForegroundColor Gray

    return @{ a = $a; b = $b; delta = $delta }
  }

  "prune" {
    $cutoff = (Get-Date).AddDays(-$RetentionDays)
    $pruned = 0
    Get-ChildItem -Path $resultsDir -Recurse -Filter "*.json" | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
      Remove-Item -Path $_.FullName -Force
      $pruned++
    }
    Write-Host "[EVAL-REG] Pruned $pruned results older than $RetentionDays days" -ForegroundColor $(if ($pruned -gt 0) { "Yellow" } else { "Green" })
    return $pruned
  }
}
