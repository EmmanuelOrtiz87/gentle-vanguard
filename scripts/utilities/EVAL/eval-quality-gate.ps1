<#
.SYNOPSIS
  Eval Quality Gate — compares eval results against thresholds and blocks/fails pipeline.
.DESCRIPTION
  Reads a skill's latest eval result and compares it against config/eval-gates.json thresholds.
  Returns PASS or FAIL. Can block pipeline steps if score is below minimum.
.PARAMETER Skill
  Skill name to check (e.g., "codegraph-search").
.PARAMETER ResultPath
  Direct path to a result file (alternative to -Skill).
.PARAMETER BlockPipeline
  Exit with error if gate fails (default: from config).
.PARAMETER Quiet
  Minimal output.
.EXAMPLE
  .\eval-quality-gate.ps1 -Skill "codegraph-search"
  .\eval-quality-gate.ps1 -Skill "codegraph-search" -BlockPipeline
#>

param(
  [string]$Skill = "",
  [string]$ResultPath = "",
  [switch]$BlockPipeline = $false,
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$gatesPath = Join-Path $repoRoot "config\eval-gates.json"
if (-not (Test-Path $gatesPath)) { Write-Error "eval-gates.json not found"; exit 1 }
$gates = Get-Content $gatesPath -Raw | ConvertFrom-Json

if ($ResultPath -and (Test-Path $ResultPath)) {
  $result = Get-Content $ResultPath -Raw | ConvertFrom-Json
  $skillName = $result.suite
} elseif ($Skill) {
  $result = & (Join-Path $PSScriptRoot "eval-registry.ps1") -Action latest -Skill $Skill
  if (-not $result) {
    if (-not $Quiet) { Write-Host "[GATE] No eval results for '$Skill' — skipping gate" -ForegroundColor Yellow }
    return @{ status = "skip"; skill = $Skill; reason = "no-results" }
  }
  $skillName = $Skill
} else {
  Write-Error "Provide -Skill or -ResultPath"; exit 1
}

$gateConfig = $gates.gates.$skillName
if (-not $gateConfig) {
  $gateConfig = @{ minScore = $gates.defaultMinScore; minPassRate = $gates.defaultMinPassRate; blockPipeline = $false; alertOnFail = $false }
}

$passRate = if ($result.totalCases -gt 0) { $result.passed / $result.totalCases } else { 0 }
$scoreOk = $result.avgScore -ge $gateConfig.minScore
$rateOk = $passRate -ge $gateConfig.minPassRate
$gatePassed = $scoreOk -and $rateOk

if (-not $Quiet) {
  Write-Host "[GATE] $skillName — score: $($result.avgScore) >= $($gateConfig.minScore)? $(if($scoreOk){'YES'}else{'NO'}) | pass rate: $([math]::Round($passRate,2)) >= $($gateConfig.minPassRate)? $(if($rateOk){'YES'}else{'NO'})" -ForegroundColor $(if($gatePassed){'Green'}else{'Red'})
}

$shouldBlock = $BlockPipeline -or ($gateConfig.blockPipeline -and -not $gatePassed)
if (-not $gatePassed -and $shouldBlock) {
  if (-not $Quiet) {
    Write-Host "[GATE] BLOCKING — $skillName failed quality gate" -ForegroundColor Red
    Write-Host "[GATE] Score: $($result.avgScore) (min: $($gateConfig.minScore))" -ForegroundColor Red
    Write-Host "[GATE] Pass rate: $([math]::Round($passRate,2)) (min: $($gateConfig.minPassRate))" -ForegroundColor Red
  }
  exit 1
}

$gateResult = @{
  status = if ($gatePassed) { "pass" } else { "fail" }
  skill = $skillName
  score = $result.avgScore
  minScore = $gateConfig.minScore
  passRate = [math]::Round($passRate, 2)
  minPassRate = $gateConfig.minPassRate
  blocked = $shouldBlock -and -not $gatePassed
}

if (-not $Quiet) {
  Write-Host "[GATE] Status: $(if($gatePassed){'PASS'}else{'FAIL'})" -ForegroundColor $(if($gatePassed){'Green'}else{'Red'})
}

return $gateResult
