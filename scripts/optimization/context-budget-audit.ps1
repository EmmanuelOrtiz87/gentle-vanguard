#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Context budget audit — token consumption across agents/skills/rules
.DESCRIPTION
  Scans skills/*/SKILL.md, rules/*.md, config/*.json for file sizes,
  estimates token cost (chars/4), flags files exceeding threshold,
  and ranks optimization opportunities.
.PARAMETER Threshold
  Token threshold to flag files (default: 2000)
.PARAMETER Path
  Root path to scan (default: current directory)
.PARAMETER OutputFormat
  Output format: Console (default), Json, CSV
.EXAMPLE
  ./context-budget-audit.ps1
  ./context-budget-audit.ps1 -Threshold 1500 -OutputFormat Json
  ./context-budget-audit.ps1 -Path "C:\project" -OutputFormat CSV
#>

param(
  [int]$Threshold = 2000,
  [string]$Path = ".",
  [ValidateSet("Console", "Json", "CSV")]
  [string]$OutputFormat = "Console"
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path $Path

$patterns = @(
  "skills/*/SKILL.md",
  "rules/*.md",
  "config/*.json"
)

$results = @()

foreach ($pattern in $patterns) {
  $files = Get-ChildItem -Path $root -Filter (Split-Path $pattern -Leaf) -Recurse `
    | Where-Object { $_.DirectoryName -like "*$((Split-Path $pattern -Parent -Resolve | Split-Path -Leaf))*" -or $pattern -like "config/*" -and $_.DirectoryName -like "*config*" }

  if (-not $files -and $pattern -like "skills/*") {
    $files = Get-ChildItem -Path (Join-Path $root "skills") -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue
  }
  if (-not $files -and $pattern -like "rules/*") {
    $files = Get-ChildItem -Path (Join-Path $root "rules") -Filter "*.md" -ErrorAction SilentlyContinue
  }
  if (-not $files -and $pattern -like "config/*") {
    $files = Get-ChildItem -Path (Join-Path $root "config") -Filter "*.json" -ErrorAction SilentlyContinue
  }

  foreach ($file in $files) {
    $relPath = [System.IO.Path]::GetRelativePath($root, $file.FullName)
    $charCount = (Get-Content $file.FullName -Raw).Length
    $estTokens = [math]::Max(1, [math]::Round($charCount / 4, 0))
    $overThreshold = $estTokens -gt $Threshold
    $savings = if ($overThreshold) { $estTokens - $Threshold } else { 0 }

    $results += [PSCustomObject]@{
      File = $relPath
      Category = $pattern.Split("/")[0]
      Chars = $charCount
      EstimatedTokens = $estTokens
      Threshold = $Threshold
      OverThreshold = $overThreshold
      SavingsPotential = $savings
    }
  }
}

$sorted = $results | Sort-Object EstimatedTokens -Descending
$flagged = $sorted | Where-Object { $_.OverThreshold }
$withinLimit = $sorted | Where-Object { -not $_.OverThreshold }
$totalTokens = ($sorted | Measure-Object EstimatedTokens -Sum).Sum

switch ($OutputFormat) {
  "Json" {
    $report = @{
      Summary = @{
        TotalFiles = $sorted.Count
        FilesFlagged = $flagged.Count
        FilesWithinLimit = $withinLimit.Count
        TotalEstimatedTokens = $totalTokens
        Threshold = $Threshold
      }
      Flagged = $flagged
      WithinLimit = $withinLimit
    }
    Write-Output ($report | ConvertTo-Json -Depth 3)
  }

  "CSV" {
    $sorted | Export-Csv -NoTypeInformation
  }

  "Console" {
    Write-Host "`n=== Context Budget Audit ===" -ForegroundColor Cyan
    Write-Host "Threshold: $Threshold tokens | Total: $totalTokens tokens across $($sorted.Count) files`n" -ForegroundColor Gray

    if ($flagged.Count -gt 0) {
      Write-Host "--- Flagged (over $Threshold tokens) ---" -ForegroundColor Yellow
      foreach ($item in $flagged) {
        $savingsStr = if ($item.SavingsPotential -gt 0) { " [save $($item.SavingsPotential) tokens]" } else { "" }
        Write-Host "[FLAG] $($item.File)" -ForegroundColor Red
        Write-Host "       $($item.EstimatedTokens) tokens ($($item.Chars) chars)$savingsStr" -ForegroundColor Gray
      }
    }

    if ($withinLimit.Count -gt 0) {
      Write-Host "`n--- Within Limit ---" -ForegroundColor Green
      foreach ($item in $withinLimit) {
        Write-Host "[OK]   $($item.File) — $($item.EstimatedTokens) tokens" -ForegroundColor Gray
      }
    }

    Write-Host "`n=== Audit Complete: $($flagged.Count) flagged, $($withinLimit.Count) within limit ===" -ForegroundColor Cyan
  }
}
