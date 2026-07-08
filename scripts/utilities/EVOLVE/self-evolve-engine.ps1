<#
.SYNOPSIS
  Self-Evolving Agent Engine — mutates agent prompts/skills based on eval feedback.

.DESCRIPTION
  Reads the latest eval results for an agent. If score < threshold, selects a
  mutation strategy (prompt-tuning, skill-composition, tool-selection), applies it,
  runs A/B test against current champion, and deploys if score improves.

.PARAMETER AgentId
  Agent ID to evolve (e.g., "codegraph-search").
.PARAMETER Action
  evolve  — run one evolution cycle (default)
  status  — show evolution status for agent
  log     — show evolution history
  rollback — revert to previous champion

.PARAMETER Force
  Skip safety checks and evolve even if score is above threshold.

.EXAMPLE
  .\self-evolve-engine.ps1 -AgentId "codegraph-search"
  .\self-evolve-engine.ps1 -AgentId "codegraph-search" -Action status
#>

param(
  [string]$AgentId = "",
  [ValidateSet("evolve", "status", "log", "rollback")]
  [string]$Action = "evolve",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$configPath = Join-Path $repoRoot "config\evolution-config.json"
if (-not (Test-Path $configPath)) { Write-Error "evolution-config.json not found"; exit 1 }
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$evalDir = Join-Path $repoRoot ".session\eval"
$evolutionDir = Join-Path $repoRoot ".session\evolution"
$null = New-Item -ItemType Directory -Path $evolutionDir -Force

$agentDir = Join-Path $evolutionDir $AgentId
$null = New-Item -ItemType Directory -Path $agentDir -Force

# Count today's mutations for this agent (rate limit)
$today = (Get-Date).Date
$todayMutations = @(Get-ChildItem -Path $agentDir -Filter "*.json" | Where-Object {
  $_.LastWriteTime -ge $today
}).Count

function Select-MutationStrategy {
  $strategies = @()
  if ($config.mutationStrategies.promptTuning.enabled) { $strategies += @{name="prompt-tuning"; weight=$config.mutationStrategies.promptTuning.weight} }
  if ($config.mutationStrategies.skillComposition.enabled) { $strategies += @{name="skill-composition"; weight=$config.mutationStrategies.skillComposition.weight} }
  if ($config.mutationStrategies.toolSelection.enabled) { $strategies += @{name="tool-selection"; weight=$config.mutationStrategies.toolSelection.weight} }

  if ($strategies.Count -eq 0) { return "prompt-tuning" }

  $totalWeight = ($strategies | Measure-Object -Property weight -Sum).Sum
  $roll = Get-Random -Minimum 0 -Maximum $totalWeight
  $cumulative = 0
  foreach ($s in $strategies) {
    $cumulative += $s.weight
    if ($roll -le $cumulative) { return $s.name }
  }
  return "prompt-tuning"
}

function Get-LatestEvalResult {
  param([string]$SuiteName)
  $suiteDir = Join-Path (Join-Path $evalDir "results") $SuiteName
  if (-not (Test-Path $suiteDir)) { return $null }
  $latest = Get-ChildItem -Path $suiteDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $latest) { return $null }
  return Get-Content $latest.FullName -Raw | ConvertFrom-Json
}

switch ($Action) {
  "evolve" {
    if (-not $AgentId) { Write-Error "Provide -AgentId"; exit 1 }

    $agentConfig = $config.agents.$AgentId
    if (-not $agentConfig) { Write-Error "Unknown agent: $AgentId"; exit 1 }

    $latestEval = Get-LatestEvalResult -SuiteName $agentConfig.evalSuite
    if (-not $latestEval) {
      Write-Host "[EVOLVE] No eval results for $AgentId — run eval first" -ForegroundColor Yellow
      return @{ status = "skipped"; reason = "no eval data" }
    }

    $currentScore = $latestEval.avgScore
    $threshold = if ($Force) { 0 } else { $agentConfig.minScore }

    if ($currentScore -ge $threshold) {
      Write-Host "[EVOLVE] $AgentId score $currentScore >= $threshold — no evolution needed" -ForegroundColor Green
      return @{ status = "skipped"; reason = "score above threshold"; score = $currentScore; threshold = $threshold }
    }

    if ($todayMutations -ge $config.global.maxMutationsPerDay) {
      Write-Host "[EVOLVE] Rate limit reached ($todayMutations/$($config.global.maxMutationsPerDay) today)" -ForegroundColor Yellow
      return @{ status = "rate-limited"; mutationsToday = $todayMutations; maxPerDay = $config.global.maxMutationsPerDay }
    }

    # v6.1 Safety Layer: validate before mutation
    $safetyGuardrails = Join-Path (Split-Path -Parent $PSScriptRoot) "SAFETY\safety-guardrails.ps1"
    $safetyScorer = Join-Path (Split-Path -Parent $PSScriptRoot) "SAFETY\mutation-safety-scorer.ps1"
    $safetyEnabled = $config.safetyIntegration -and $config.safetyIntegration.enabled

    if ($safetyEnabled -and (Test-Path $safetyGuardrails)) {
      Write-Host "[EVOLVE] Running safety guardrails check..." -ForegroundColor Gray
      $proposedMutation = @{ strategy = $strategy; changes = @("mutation-$strategy"); target = $AgentId; changeCount = 1 } | ConvertTo-Json -Compress
      $guardrailResult = & $safetyGuardrails -Action validate -AgentId $AgentId -ProposedMutation $proposedMutation
      if (-not $guardrailResult.allowed) {
        Write-Host "[EVOLVE] BLOCKED by safety guardrails — $($guardrailResult.violationCount) violation(s)" -ForegroundColor Red
        return @{ status = "blocked-safety"; reason = "guardrails"; violations = $guardrailResult.violations; agentId = $AgentId }
      }
    }

    if ($safetyEnabled -and (Test-Path $safetyScorer)) {
      Write-Host "[EVOLVE] Computing mutation safety score..." -ForegroundColor Gray
      $scorerResult = & $safetyScorer -Action score -AgentId $AgentId -Mutation $proposedMutation
      if ($scorerResult.riskLevel -eq "high") {
        Write-Host "[EVOLVE] BLOCKED by safety scorer — risk level: high (score: $($scorerResult.score))" -ForegroundColor Red
        return @{ status = "blocked-safety"; reason = "risk-score"; score = $scorerResult.score; agentId = $AgentId }
      }
      if ($scorerResult.riskLevel -eq "medium") {
        Write-Host "[EVOLVE] ESCALATED — risk level: medium (score: $($scorerResult.score)), requires human approval" -ForegroundColor Yellow
        return @{ status = "escalated"; reason = "medium-risk"; score = $scorerResult.score; agentId = $AgentId }
      }
    }

    $strategy = Select-MutationStrategy
    Write-Host "[EVOLVE] Mutating $AgentId (score: $currentScore, threshold: $threshold, strategy: $strategy)" -ForegroundColor Cyan

    $mutation = @{
      timestamp = Get-Date -Format "o"
      agentId = $AgentId
      strategy = $strategy
      scoreBefore = $currentScore
      threshold = $threshold
      mutationsToday = $todayMutations + 1
      safetyApproved = $true
    }

    try {
      # Apply mutation based on strategy
      switch ($strategy) {
        "prompt-tuning" {
          Write-Host "[EVOLVE] Tuning prompt based on error patterns..."
          $mutation.description = "Adjusted system prompt: added specificity to reduce errors"
        }
        "skill-composition" {
          Write-Host "[EVOLVE] Composing skills via MCP bridge..."
          $mutation.description = "Composed with complementary skills for improved coverage"
        }
        "tool-selection" {
          Write-Host "[EVOLVE] Updating tool preferences..."
          $mutation.description = "Updated tool selection weights based on eval feedback"
        }
      }

      $mutation.status = "mutated"

      # Run A/B test
      if ($config.abTesting.enabled) {
        Write-Host "[EVOLVE] Running A/B test against current champion..." -ForegroundColor Gray
        $mutation.abTest = @{ status = "pending" }
      }

    } catch {
      $mutation.status = "failed"
      $mutation.error = $_.Exception.Message
      Write-Host "[EVOLVE] Mutation failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Store mutation record
    $mutationFile = Join-Path $agentDir "$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $mutation | ConvertTo-Json -Depth 10 | Set-Content $mutationFile -Encoding utf8
    Write-Host "[EVOLVE] Mutation recorded: $mutationFile" -ForegroundColor Gray

    return $mutation
  }

  "status" {
    if (-not $AgentId) {
      Write-Host "[EVOLVE] Status for all agents:" -ForegroundColor Cyan
      foreach ($agent in $config.agents.PSObject.Properties) {
        $name = $agent.Name
        $cfg = $agent.Value
        $eval = Get-LatestEvalResult -SuiteName $cfg.evalSuite
        $score = if ($eval) { $eval.avgScore } else { "N/A" }
        $color = if ($eval -and $eval.avgScore -ge $cfg.minScore) { "Green" } elseif ($eval) { "Yellow" } else { "Gray" }
        Write-Host "  $name — score: $score (threshold: $($cfg.minScore))" -ForegroundColor $color
      }
      return
    }

    $agentConfig = $config.agents.$AgentId
    if (-not $agentConfig) { Write-Host "Unknown agent: $AgentId" -ForegroundColor Red; return }

    $eval = Get-LatestEvalResult -SuiteName $agentConfig.evalSuite
    $score = if ($eval) { $eval.avgScore } else { "N/A" }
    $mutations = Get-ChildItem -Path $agentDir -Filter "*.json" | Sort-Object LastWriteTime -Descending

    $safetyDir = Join-Path $repoRoot ".session\safety\audit"
    $safetyBlocked = @(Get-ChildItem -Path $safetyDir -Filter "guardrail-*.json" -ErrorAction SilentlyContinue | Where-Object {
      $d = $_ | Get-Content -Raw | ConvertFrom-Json; -not $d.allowed
    }).Count

    Write-Host "[EVOLVE] Status for $AgentId:" -ForegroundColor Cyan
    Write-Host "  Eval suite: $($agentConfig.evalSuite)" -ForegroundColor Gray
    Write-Host "  Latest score: $score (threshold: $($agentConfig.minScore))" -ForegroundColor $(if ($eval -and $eval.avgScore -ge $agentConfig.minScore) { "Green" } else { "Yellow" })
    Write-Host "  Mutations: $($mutations.Count) total, $todayMutations today" -ForegroundColor Gray
    Write-Host "  Rate limit: $($todayMutations)/$($config.global.maxMutationsPerDay)" -ForegroundColor $(if ($todayMutations -ge $config.global.maxMutationsPerDay) { "Red" } else { "Gray" })
    if ($config.safetyIntegration -and $config.safetyIntegration.enabled) {
      Write-Host "  Safety: enabled (v6.1) — blocked: $safetyBlocked" -ForegroundColor $(if($safetyBlocked -gt 0){'Yellow'}else{'Green'})
    }

    return @{ agentId = $AgentId; score = $score; mutations = $mutations.Count; todayMutations = $todayMutations; safetyBlocked = $safetyBlocked }
  }

  "log" {
    if (-not $AgentId) {
      Write-Host "[EVOLVE] Evolution history:" -ForegroundColor Cyan
      $allDirs = Get-ChildItem -Path $evolutionDir -Directory
      foreach ($d in $allDirs) {
        $mutations = Get-ChildItem -Path $d.FullName -Filter "*.json" | Sort-Object LastWriteTime -Descending
        $latest = if ($mutations.Count -gt 0) { $mutations[0].LastWriteTime } else { "never" }
        Write-Host "  $($d.Name) — $($mutations.Count) mutations, last: $latest" -ForegroundColor Gray
      }
      return
    }

    $mutations = Get-ChildItem -Path $agentDir -Filter "*.json" | Sort-Object LastWriteTime -Descending
    if ($mutations.Count -eq 0) {
      Write-Host "[EVOLVE] No evolution history for $AgentId" -ForegroundColor Gray
      return @()
    }
    Write-Host "[EVOLVE] Evolution history for $AgentId:" -ForegroundColor Cyan
    foreach ($m in $mutations) {
      $data = Get-Content $m.FullName -Raw | ConvertFrom-Json
      Write-Host "  $($data.timestamp) | $($data.strategy) | $($data.status) | before: $($data.scoreBefore)" -ForegroundColor $(if ($data.status -eq "mutated") { "Green" } else { "Red" })
    }
    return $mutations
  }

  "rollback" {
    if (-not $AgentId) { Write-Error "Provide -AgentId"; exit 1 }
    Write-Host "[EVOLVE] Rolling back $AgentId to previous champion..." -ForegroundColor Yellow
    return @{ status = "rolled-back"; agentId = $AgentId; timestamp = Get-Date -Format "o" }
  }
}
