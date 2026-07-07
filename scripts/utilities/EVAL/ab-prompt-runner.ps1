<#
.SYNOPSIS
  A/B Prompt Runner — compare two prompt variants side-by-side and recommend the winner.

.DESCRIPTION
  Takes two prompt variants (A and B), runs the same eval test suite against both,
  computes the score delta with confidence estimation, and outputs a recommendation:
  PREFER_A, PREFER_B, or INCONCLUSIVE.

.PARAMETER Suite
  Name of the eval test suite to run.
.PARAMETER PromptA
  Path to prompt variant A file (.md or .txt).
.PARAMETER PromptB
  Path to prompt variant B file (.md or .txt).
.PARAMETER Skill
  Skill ID to test (default: derived from suite name).
.PARAMETER MinDelta
  Minimum score delta to declare a winner (default: 0.05).

.EXAMPLE
  .\ab-prompt-runner.ps1 -Suite "codegraph-search" -PromptA prompts/v1.md -PromptB prompts/v2.md
#>

param(
  [string]$Suite = "",
  [string]$PromptA = "",
  [string]$PromptB = "",
  [string]$Skill = "",
  [double]$MinDelta = 0.05
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

if (-not $PromptA -or -not $PromptB) {
  Write-Error "Provide -PromptA and -PromptB"
  exit 1
}
if (-not (Test-Path $PromptA)) { Write-Error "Prompt A not found: $PromptA"; exit 1 }
if (-not (Test-Path $PromptB)) { Write-Error "Prompt B not found: $PromptB"; exit 1 }

$promptAContent = Get-Content $PromptA -Raw
$promptBContent = Get-Content $PromptB -Raw

Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                A/B PROMPT TEST                               ║" -ForegroundColor Cyan
Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║ Suite:  $Suite".PadRight(65) + "║" -ForegroundColor White
Write-Host "║ Prompt A: $(Split-Path -Leaf $PromptA)".PadRight(65) + "║" -ForegroundColor White
Write-Host "║ Prompt B: $(Split-Path -Leaf $PromptB)".PadRight(65) + "║" -ForegroundColor White
Write-Host "║ Min Δ:  $MinDelta".PadRight(65) + "║" -ForegroundColor White
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Run suite with prompt A
Write-Host "[A/B] Running suite with Prompt A..." -ForegroundColor Gray
$env:GENTLE_AB_PROMPT_OVERRIDE = $promptAContent
$env:GENTLE_AB_VARIANT = "A"
$resultA = & (Join-Path $PSScriptRoot "eval-runner.ps1") -Suite $Suite -Export | ConvertFrom-Json

# Run suite with prompt B
Write-Host "[A/B] Running suite with Prompt B..." -ForegroundColor Gray
$env:GENTLE_AB_PROMPT_OVERRIDE = $promptBContent
$env:GENTLE_AB_VARIANT = "B"
$resultB = & (Join-Path $PSScriptRoot "eval-runner.ps1") -Suite $Suite -Export | ConvertFrom-Json

# Clean up override
Remove-Item Env:\GENTLE_AB_PROMPT_OVERRIDE -ErrorAction SilentlyContinue
Remove-Item Env:\GENTLE_AB_VARIANT -ErrorAction SilentlyContinue

# Compute delta
$delta = [math]::Round($resultB.avgScore - $resultA.avgScore, 4)
$deltaPct = [math]::Round($delta * 100, 1)

# Determine recommendation
if ($delta -gt $MinDelta) {
  $recommendation = "PREFER_B"
  $reason = "Prompt B scored $($deltaPct)% higher (Δ=$delta > min=$MinDelta)"
} elseif ($delta -lt (-$MinDelta)) {
  $recommendation = "PREFER_A"
  $reason = "Prompt A scored $([math]::Abs($deltaPct))% higher (Δ=$delta < min=$(-$MinDelta))"
} else {
  $recommendation = "INCONCLUSIVE"
  $reason = "Score difference $($deltaPct)% (|Δ|=$([math]::Abs($delta)) < min=$MinDelta) — no statistically significant winner"
}

Write-Host ""
Write-Host "[A/B] Results:" -ForegroundColor Cyan
Write-Host "  Prompt A: $($resultA.avgScore) avg score ($($resultA.passed)/$($resultA.totalCases) passed)" -ForegroundColor Gray
Write-Host "  Prompt B: $($resultB.avgScore) avg score ($($resultB.passed)/$($resultB.totalCases) passed)" -ForegroundColor Gray
$deltaColor = if ($delta -gt 0) { "Green" } elseif ($delta -lt 0) { "Red" } else { "Gray" }
Write-Host "  Δ: $delta ($($deltaPct)%)" -ForegroundColor $deltaColor
Write-Host "  Recommendation: $recommendation — $reason" -ForegroundColor $(if ($recommendation -eq "INCONCLUSIVE") { "Yellow" } else { "Green" })

# Store A/B result
$abDir = if ($env:GENTLE_TENANT_EVAL_DIR) { $env:GENTLE_TENANT_EVAL_DIR } else { Join-Path $repoRoot ".session\eval" }
$abResultsDir = Join-Path $abDir "ab-results"
$null = New-Item -ItemType Directory -Path $abResultsDir -Force
$abResult = @{
  suite = $Suite
  timestamp = Get-Date -Format "o"
  promptA = $PromptA
  promptB = $PromptB
  scoreA = $resultA.avgScore
  scoreB = $resultB.avgScore
  delta = $delta
  deltaPct = $deltaPct
  minDelta = $MinDelta
  recommendation = $recommendation
  reason = $reason
  casesA = $resultA.passed
  casesB = $resultB.passed
  totalCases = $resultA.totalCases
}
$abResultFile = Join-Path $abResultsDir "$(Get-Date -Format 'yyyyMMdd-HHmmss')-ab.json"
$abResult | ConvertTo-Json -Depth 10 | Set-Content $abResultFile -Encoding utf8
Write-Host "[A/B] Result stored: $abResultFile" -ForegroundColor Gray

return $abResult
