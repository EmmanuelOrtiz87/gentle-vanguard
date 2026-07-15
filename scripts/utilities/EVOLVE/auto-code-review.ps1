<#
.SYNOPSIS
  Autonomous Code Review — pre-commit + PR review without human trigger.

.DESCRIPTION
  Reviews staged files for style, security, performance, and SDD compliance issues.
  Auto-fixes style issues, blocks commits on security issues, and posts warnings
  for correctness concerns.

.PARAMETER Action
  pre-commit — review staged files in pre-commit hook (default)
  pr        — review a PR (requires -PrNumber)
  scan      — scan a specific file or directory

.PARAMETER Path
  Path to file or directory to scan (for -Action scan).

.PARAMETER PrNumber
  PR number to review (for -Action pr).

.PARAMETER AutoFix
  Auto-fix style issues (default: true).

.EXAMPLE
  .\auto-code-review.ps1 -Action pre-commit
  .\auto-code-review.ps1 -Action scan -Path scripts/utilities/TENANT/
#>

param(
  [ValidateSet("pre-commit", "pr", "scan")]
  [string]$Action = "pre-commit",
  [string]$Path = "",
  [string]$PrNumber = "",
  [switch]$AutoFix = $true
)

$ErrorActionPreference = "Continue"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

function Invoke-StyleReview {
  param([string]$FilePath)
  $issues = @()
  $content = Get-Content $FilePath -Raw

  # Check for trailing whitespace
  if ($content -match "[^\n] +\n") { $issues += @{ type = "style"; severity = "warning"; message = "Trailing whitespace found" } }

  # Check for tabs vs spaces (prefer spaces)
  if ($content -match "`t") { $issues += @{ type = "style"; severity = "info"; message = "Tabs found — consider using spaces" } }

  # Check line length > 120
  $longLines = ($content -split "`n" | Where-Object { $_.Length -gt 120 }).Count
  if ($longLines -gt 0) { $issues += @{ type = "style"; severity = "info"; message = "$longLines lines exceed 120 chars" } }

  return $issues
}

function Invoke-SecurityReview {
  param([string]$FilePath)
  $issues = @()

  # Skip upstream skill docs — they contain security examples, not real secrets
  if ($FilePath -match '\.opencode[/\\]skills[/\\]') { return $issues }

  $content = Get-Content $FilePath -Raw

  # Check for hardcoded secrets patterns
  if ($content -match '(?i)(password|secret|api_key|apikey|token|credential)\s*[:=]\s*["'']{0,1}[^"'',;\s]{8,}') {
    $issues += @{ type = "security"; severity = "error"; message = "Possible hardcoded secret detected" }
  }

  # Check for eval/exec usage
  if ($FilePath -match '\.ps1$' -and $content -match '(Invoke-Expression|iex|eval\()') {
    $issues += @{ type = "security"; severity = "warning"; message = "Use of Invoke-Expression/eval detected — potential injection risk" }
  }

  # Check for SQL injection vectors
  if ($content -match 'SELECT.*FROM.*WHERE.*\+') {
    $issues += @{ type = "security"; severity = "error"; message = "Possible SQL injection — string concatenation in query" }
  }

  return $issues
}

function Invoke-PerformanceReview {
  param([string]$FilePath)
  $issues = @()
  $content = Get-Content $FilePath -Raw

  # Check for N+1 query patterns (in JS/TS)
  if ($FilePath -match '\.(ts|js)x?$' -and $content -match '\.forEach\(.*=>.*\.(find|fetch|query)') {
    $issues += @{ type = "performance"; severity = "warning"; message = "Possible N+1 query pattern in forEach" }
  }

  # Check for large file operations
  if ($content -match 'Get-Content\s+.*-Raw' -and (Get-Item $FilePath).Length -gt 1MB) {
    $issues += @{ type = "performance"; severity = "info"; message = "Reading entire file with -Raw on large file" }
  }

  return $issues
}

function Invoke-SddComplianceReview {
  param([string]$FilePath)
  $issues = @()
  if (-not (Test-Path $FilePath)) { return $issues }
  $content = Get-Content $FilePath -Raw

  # Check .ps1 files for help comment
  if ($FilePath -match '\.ps1$' -and -not ($content -match '<#\s*\..*SYNOPSIS' -or $content -match '<#\s*\n.SYNOPSIS')) {
    $issues += @{ type = "sdd"; severity = "info"; message = "Missing SYNOPSIS comment block" }
  }

  # Check for error handling
  if ($FilePath -match '\.ps1$' -and $content -match '^\s*try\s*\{' -and -not ($content -match 'catch')) {
    $issues += @{ type = "sdd"; severity = "warning"; message = "try block without catch" }
  }

  return $issues
}

function Review-File {
  param([string]$FilePath)
  if (-not (Test-Path $FilePath)) { return @() }

  $ext = [System.IO.Path]::GetExtension($FilePath)
  $reviewable = @('.ps1', '.psm1', '.ts', '.tsx', '.js', '.jsx', '.py', '.go', '.rs', '.md', '.json', '.yaml', '.yml')

  if ($ext -notin $reviewable) { return @() }

  $allIssues = @()
  $allIssues += Invoke-StyleReview -FilePath $FilePath
  $allIssues += Invoke-SecurityReview -FilePath $FilePath
  $allIssues += Invoke-PerformanceReview -FilePath $FilePath
  $allIssues += Invoke-SddComplianceReview -FilePath $FilePath

  return $allIssues
}

function Invoke-AutoFix {
  param([string]$FilePath, $Issues)
  if (-not $AutoFix) { return }
  $content = Get-Content $FilePath -Raw
  $changed = $false

  foreach ($issue in $Issues) {
    if ($issue.type -eq "style" -and $issue.severity -eq "warning") {
      # Fix trailing whitespace
      if ($issue.message -eq "Trailing whitespace found") {
        $content = $content -replace "[^\n] +\n", "`n"
        $changed = $true
      }
    }
  }

  if ($changed) {
    Set-Content -Path $FilePath -Value $content -Encoding utf8 -NoNewline
    Write-Host "  [AUTOFIX] Applied style fixes to $(Split-Path -Leaf $FilePath)" -ForegroundColor Yellow
  }
}

# ---- Main ----

switch ($Action) {
  "pre-commit" {
    Write-Host "[REVIEW] Pre-commit review..." -ForegroundColor Cyan
    $stagedFiles = git -C $repoRoot diff --cached --name-only 2>$null
    if (-not $stagedFiles) {
      Write-Host "[REVIEW] No staged files to review" -ForegroundColor Gray
      return @{ status = "clean"; issues = @() }
    }

    $allIssues = @()
    $blockers = @()

    foreach ($file in $stagedFiles) {
      $fullPath = Join-Path $repoRoot $file
      $issues = Review-File -FilePath $fullPath
      foreach ($issue in $issues) {
        $issue.file = $file
        $allIssues += $issue
        if ($issue.severity -eq "error") { $blockers += $issue }
      }
    }

    # Auto-fix style issues
    if ($AutoFix) {
      foreach ($file in $stagedFiles) {
        $fullPath = Join-Path $repoRoot $file
        $fileIssues = $allIssues | Where-Object { $_.file -eq $file }
        Invoke-AutoFix -FilePath $fullPath -Issues $fileIssues
      }
      # Re-stage auto-fixed files
      if ($allIssues | Where-Object { $_.type -eq "style" -and $_.severity -eq "warning" }) {
        git -C $repoRoot diff --name-only --cached | ForEach-Object { git -C $repoRoot add $_ 2>$null }
      }
    }

    if ($blockers.Count -gt 0) {
      Write-Host "[REVIEW] BLOCKING — $($blockers.Count) security/critical issues found:" -ForegroundColor Red
      foreach ($b in $blockers) {
        Write-Host "  [BLOCKER] $($b.file): $($b.message)" -ForegroundColor Red
      }
      Write-Host "[REVIEW] Commit blocked — fix issues before committing" -ForegroundColor Red
      return @{ status = "blocked"; blockers = $blockers.Count; issues = $allIssues }
    }

    if ($allIssues.Count -gt 0) {
      Write-Host "[REVIEW] $($allIssues.Count) issue(s) found (non-blocking):" -ForegroundColor Yellow
      foreach ($issue in $allIssues) {
        $color = if ($issue.severity -eq "error") { "Red" } elseif ($issue.severity -eq "warning") { "Yellow" } else { "Gray" }
        Write-Host "  [$($issue.type)/$($issue.severity)] $($issue.file): $($issue.message)" -ForegroundColor $color
      }
      return @{ status = "warning"; issues = $allIssues }
    }

    Write-Host "[REVIEW] Code review PASS — no issues found" -ForegroundColor Green
    return @{ status = "pass"; issues = @() }
  }

  "scan" {
    if (-not $Path) { Write-Error "Provide -Path for scan action"; exit 1 }
    $target = Join-Path $repoRoot $Path
    if (-not (Test-Path $target)) { Write-Error "Path not found: $target"; exit 1 }

    $files = if (Test-Path -Path $target -PathType Container) {
      Get-ChildItem -Path $target -Recurse -File
    } else {
      Get-Item -Path $target
    }

    $allIssues = @()
    Write-Host "[REVIEW] Scanning $($files.Count) file(s)..." -ForegroundColor Cyan
    foreach ($f in $files) {
      $issues = Review-File -FilePath $f.FullName
      foreach ($issue in $issues) {
        $issue.file = $f.FullName
        $allIssues += $issue
      }
    }

    Write-Host "[REVIEW] Scan complete — $($allIssues.Count) issue(s) found" -ForegroundColor $(if($allIssues.Count -eq 0){"Green"}else{"Yellow"})
    return $allIssues
  }

  "pr" {
    if (-not $PrNumber) { Write-Error "Provide -PrNumber for PR review"; exit 1 }
    Write-Host "[REVIEW] Reviewing PR #$PrNumber..." -ForegroundColor Cyan
    # GitHub Actions integration would fetch PR diff here
    Write-Host "[REVIEW] PR review ready — integrate with GitHub Actions workflow" -ForegroundColor Gray
    return @{ status = "ready"; prNumber = $PrNumber; action = "github-actions-integration-needed" }
  }
}
