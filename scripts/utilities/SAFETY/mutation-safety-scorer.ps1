<#
.SYNOPSIS
  Mutation Safety Scorer — scores proposed agent mutations on safety before deployment.
.DESCRIPTION
  Combines multiple signals into a single safety score 0.0-1.0:
  - Scope Impact: how many files/agents does the mutation affect?
  - Capability Drift: does it add capabilities beyond original scope?
  - Pattern Violations: does it match blocked patterns?
  - Historical Risk: has this agent had safety issues?
  - Similarity to Bad: cosine similarity with past rollbacks
.PARAMETER AgentId
  Agent ID proposing the mutation.
.PARAMETER Mutation
  JSON string describing the proposed mutation.
.PARAMETER Action
  score  — compute safety score (default)
  config — show scoring configuration
.EXAMPLE
  .\mutation-safety-scorer.ps1 -Action score -AgentId "codegraph-search" -Mutation '{"strategy":"skill-composition","target":"file-system","changeCount":5}'
  .\mutation-safety-scorer.ps1 -Action config
#>

param(
  [ValidateSet("score", "config")]
  [string]$Action = "config",
  [string]$AgentId = "",
  [string]$Mutation = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$safetyConfigPath = Join-Path $repoRoot "config\safety-layer.json"
if (-not (Test-Path $safetyConfigPath)) { Write-Error "safety-layer.json not found"; exit 1 }
$config = Get-Content $safetyConfigPath -Raw | ConvertFrom-Json

$evolutionDir = Join-Path $repoRoot ".session\evolution"
$safetyAuditDir = Join-Path $repoRoot ".session\safety\audit"
$null = New-Item -ItemType Directory -Path $safetyAuditDir -Force

function Get-ScopeImpact {
  param($MutationData)
  $changeCount = if ($MutationData.changeCount) { $MutationData.changeCount } else { 1 }
  if ($changeCount -le 3) { return 0.9 }      # Low impact
  elseif ($changeCount -le 10) { return 0.5 }  # Medium impact
  else { return 0.2 }                           # High impact (risky)
}

function Get-CapabilityDrift {
  param($MutationData)
  $driftTargets = @("file-system", "network", "database", "security", "auth", "admin", "sudo", "root", "system", "kernel", "exec", "shell")
  $target = if ($MutationData.target) { $MutationData.target.ToLower() } else { "" }
  foreach ($dt in $driftTargets) {
    if ($target -match $dt) { return 0.3 }  # Significant capability drift
  }
  return 0.9  # No drift
}

function Get-PatternViolationScore {
  param($MutationData)
  $mutationStr = $MutationData | ConvertTo-Json -Compress
  $violations = 0
  foreach ($bp in $config.guardrails.blockedPatterns) {
    if ($mutationStr -match $bp.pattern) { $violations++ }
  }
  if ($violations -eq 0) { return 1.0 }
  return [math]::Max(0.0, 1.0 - ($violations * 0.3))
}

function Get-HistoricalRisk {
  param([string]$Agent)
  $agentDir = Join-Path $evolutionDir $Agent
  if (-not (Test-Path $agentDir)) { return 0.9 }  # No history = low risk

  $mutations = Get-ChildItem -Path $agentDir -Filter "*.json" -ErrorAction SilentlyContinue
  if ($mutations.Count -eq 0) { return 0.9 }

  $rollbacks = 0
  $total = 0
  foreach ($m in $mutations) {
    try {
      $data = Get-Content $m.FullName -Raw | ConvertFrom-Json
      $total++
      if ($data.status -eq "rolled-back" -or ($data.scoreBefore -and $data.scoreAfter -and $data.scoreAfter -lt $data.scoreBefore)) {
        $rollbacks++
      }
    } catch {}
  }

  if ($total -eq 0) { return 0.9 }
  $failureRate = $rollbacks / $total
  return [math]::Max(0.1, 1.0 - $failureRate)
}

function Get-SimilarityToBadMutations {
  param($MutationData)
  $badDir = Join-Path $safetyAuditDir "blocked"
  if (-not (Test-Path $badDir)) { return 0.9 }

  $strategy = if ($MutationData.strategy) { $MutationData.strategy.ToLower() } else { "" }
  $target = if ($MutationData.target) { $MutationData.target.ToLower() } else { "" }

  $badLogs = Get-ChildItem -Path $badDir -Filter "*.json" -ErrorAction SilentlyContinue
  $similarCount = 0
  foreach ($log in $badLogs) {
    try {
      $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
      if ($data.strategy -and $data.strategy.ToLower() -eq $strategy -and $data.target -and $data.target.ToLower() -eq $target) {
        $similarCount++
      }
    } catch {}
  }

  if ($similarCount -eq 0) { return 0.9 }
  return [math]::Max(0.1, 1.0 - ($similarCount * 0.2))
}

switch ($Action) {
  "score" {
    if (-not $AgentId) { Write-Error "Provide -AgentId"; exit 1 }
    if (-not $Mutation) { Write-Error "Provide -Mutation as JSON"; exit 1 }

    $mutationData = $Mutation | ConvertFrom-Json
    $weights = $config.scoring.signals

    $scopeImpact = Get-ScopeImpact -MutationData $mutationData
    $capabilityDrift = Get-CapabilityDrift -MutationData $mutationData
    $patternViolations = Get-PatternViolationScore -MutationData $mutationData
    $historicalRisk = Get-HistoricalRisk -AgentId $AgentId
    $similarityToBad = Get-SimilarityToBadMutations -MutationData $mutationData

    $signals = @{
      scopeImpact = [math]::Round($scopeImpact, 3)
      capabilityDrift = [math]::Round($capabilityDrift, 3)
      patternViolations = [math]::Round($patternViolations, 3)
      historicalRisk = [math]::Round($historicalRisk, 3)
      similarityToBad = [math]::Round($similarityToBad, 3)
    }

    $score = ($scopeImpact * [double]$weights.scopeImpactWeight) +
             ($capabilityDrift * [double]$weights.capabilityDriftWeight) +
             ($patternViolations * [double]$weights.patternViolationsWeight) +
             ($historicalRisk * [double]$weights.historicalRiskWeight) +
             ($similarityToBad * [double]$weights.similarityToBadWeight)
    $score = [math]::Round([math]::Max(0.0, [math]::Min(1.0, $score)), 3)

    $riskLevel = if ($score -ge $config.scoring.minAutoApproveScore) { "low" }
                 elseif ($score -ge $config.scoring.minAutoEscalateScore) { "medium" }
                 else { "high" }

    Write-Host "[SAFETY-SCORER] Mutation safety score for $AgentId:" -ForegroundColor Cyan
    Write-Host "  Overall score: $score (risk: $riskLevel)" -ForegroundColor $(if($riskLevel -eq "low"){'Green'}elseif($riskLevel -eq "medium"){'Yellow'}else{'Red'})
    Write-Host "  Signals:" -ForegroundColor Gray
    foreach ($s in $signals.Keys) { Write-Host "    $s: $($signals[$s])" -ForegroundColor Gray }

    $result = @{
      agentId = $AgentId
      timestamp = Get-Date -Format "o"
      score = $score
      riskLevel = $riskLevel
      signals = $signals
      config = @{
        minAutoApprove = $config.scoring.minAutoApproveScore
        minAutoEscalate = $config.scoring.minAutoEscalateScore
      }
    }

    $logFile = Join-Path $safetyAuditDir "scorer-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $result | ConvertTo-Json -Depth 5 | Set-Content $logFile -Encoding utf8

    return $result
  }

  "config" {
    Write-Host "[SAFETY-SCORER] Scoring configuration:" -ForegroundColor Cyan
    Write-Host "  Min auto-approve score: $($config.scoring.minAutoApproveScore)" -ForegroundColor Green
    Write-Host "  Min auto-escalate score: $($config.scoring.minAutoEscalateScore)" -ForegroundColor Yellow
    Write-Host "  Signal weights:" -ForegroundColor Gray
    foreach ($s in $config.scoring.signals.PSObject.Properties) {
      Write-Host "    $($s.Name): $($s.Value)" -ForegroundColor Gray
    }
    return $config.scoring
  }
}
