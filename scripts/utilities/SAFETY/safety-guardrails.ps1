<#
.SYNOPSIS
  Safety Guardrails — validates agent mutations against constitutional rules, blocked patterns, and resource limits.
.DESCRIPTION
  Central safety engine. Every mutation must pass guardrail validation before deployment.
  Three guardrail types: constitutional rules (immutable), blocked patterns (regex), resource limits (quotas).
.PARAMETER Action
  validate — test a mutation against all guardrails (default)
  status   — show active guardrails and current state
  rules    — list all constitutional rules and blocked patterns
.PARAMETER AgentId
  Agent ID proposing the mutation.
.PARAMETER ProposedMutation
  JSON string describing the proposed mutation: @{ strategy = "..."; changes = @(...); target = "..." }
.EXAMPLE
  .\safety-guardrails.ps1 -Action validate -AgentId "codegraph-search" -ProposedMutation '{"strategy":"prompt-tuning","changes":["add -Concise flag"],"target":"system-prompt"}'
  .\safety-guardrails.ps1 -Action status
#>

param(
  [ValidateSet("validate", "status", "rules")]
  [string]$Action = "status",
  [string]$AgentId = "",
  [string]$ProposedMutation = ""
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

$safetyAuditDir = Join-Path $repoRoot ".session\safety\audit"
$null = New-Item -ItemType Directory -Path $safetyAuditDir -Force

function Test-ConstitutionalRules {
  param($Mutation)
  $violations = @()
  $mutationStr = $Mutation | ConvertTo-Json -Compress
  foreach ($rule in $config.guardrails.constitutional) {
    $ruleLower = $rule.ToLower()
    $mutationLower = $mutationStr.ToLower()
    if ($mutationLower -match [regex]::Escape($ruleLower.Substring(0, [math]::Min(30, $ruleLower.Length)))) {
      $violations += @{ rule = $rule; type = "constitutional"; severity = "critical" }
    }
  }
  return $violations
}

function Test-BlockedPatterns {
  param($Mutation)
  $violations = @()
  $mutationStr = $Mutation | ConvertTo-Json -Compress
  foreach ($bp in $config.guardrails.blockedPatterns) {
    if ($mutationStr -match $bp.pattern) {
      $violations += @{ rule = $bp.pattern; type = "blocked-pattern"; severity = $bp.severity }
    }
  }
  return $violations
}

function Test-ResourceLimits {
  param($Mutation)
  $violations = @()
  if ($Mutation.changes -and $Mutation.changes.Count -gt $config.guardrails.resourceLimits.maxFilesPerMutation) {
    $violations += @{ rule = "maxFilesPerMutation ($($config.guardrails.resourceLimits.maxFilesPerMutation))"; type = "resource-limit"; severity = "warning"; current = $Mutation.changes.Count }
  }
  return $violations
}

switch ($Action) {
  "validate" {
    if (-not $AgentId) { Write-Error "Provide -AgentId"; exit 1 }
    if (-not $ProposedMutation) { Write-Error "Provide -ProposedMutation as JSON"; exit 1 }

    $mutation = $ProposedMutation | ConvertFrom-Json

    $constitutionalViolations = Test-ConstitutionalRules -Mutation $mutation
    $patternViolations = Test-BlockedPatterns -Mutation $mutation
    $resourceViolations = Test-ResourceLimits -Mutation $mutation
    $allViolations = $constitutionalViolations + $patternViolations + $resourceViolations

    $hasCritical = ($allViolations | Where-Object { $_.severity -eq "critical" }).Count -gt 0
    $hasHigh = ($allViolations | Where-Object { $_.severity -eq "high" }).Count -gt 0
    $allowed = (-not $hasCritical) -and (-not ($hasHigh -and $config.global.blockOnViolation))

    $result = @{
      allowed = $allowed
      timestamp = Get-Date -Format "o"
      agentId = $AgentId
      violations = $allViolations
      violationCount = $allViolations.Count
      blockedBy = if (-not $allowed) { if ($hasCritical) { "constitutional" } else { "blocked-pattern" } } else { $null }
    }

    Write-Host "[SAFETY] Guardrails check for $AgentId:" -ForegroundColor Cyan
    if ($allowed) {
      Write-Host "[SAFETY] ALLOWED — no violations" -ForegroundColor Green
    } else {
      Write-Host "[SAFETY] BLOCKED — $($allViolations.Count) violation(s)" -ForegroundColor Red
      foreach ($v in $allViolations) {
        $color = if ($v.severity -eq "critical") { "Red" } elseif ($v.severity -eq "high") { "Yellow" } else { "Gray" }
        Write-Host "  [$($v.severity)] $($v.type): $($v.rule)" -ForegroundColor $color
      }
    }

    $logEntry = $result | ConvertTo-Json -Depth 5
    $logFile = Join-Path $safetyAuditDir "guardrail-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $result | ConvertTo-Json -Depth 5 | Set-Content $logFile -Encoding utf8

    return $result
  }

  "status" {
    Write-Host "[SAFETY] Guardrails status:" -ForegroundColor Cyan
    Write-Host "  Enabled: $($config.global.enabled)" -ForegroundColor $(if($config.global.enabled){'Green'}else{'Red'})
    Write-Host "  Constitutional rules: $($config.guardrails.constitutional.Count)" -ForegroundColor Gray
    Write-Host "  Blocked patterns: $($config.guardrails.blockedPatterns.Count)" -ForegroundColor Gray
    Write-Host "  Resource limits: $($config.guardrails.resourceLimits.Count)" -ForegroundColor Gray
    Write-Host "  Block on violation: $($config.global.blockOnViolation)" -ForegroundColor Gray
    Write-Host "  Audit log: $safetyAuditDir" -ForegroundColor Gray

    $recentLogs = Get-ChildItem -Path $safetyAuditDir -Filter "guardrail-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if ($recentLogs.Count -gt 0) {
      Write-Host "  Recent validations:" -ForegroundColor Gray
      foreach ($log in $recentLogs) {
        $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
        $c = if ($data.allowed) { "Green" } else { "Red" }
        Write-Host "    $($data.timestamp) | $($data.agentId) | $(if($data.allowed){'ALLOWED'}else{'BLOCKED'}) ($($data.violationCount) violations)" -ForegroundColor $c
      }
    }

    return @{
      enabled = $config.global.enabled
      constitutionalRules = $config.guardrails.constitutional.Count
      blockedPatterns = $config.guardrails.blockedPatterns.Count
      blockOnViolation = $config.global.blockOnViolation
      auditDir = $safetyAuditDir
    }
  }

  "rules" {
    Write-Host "[SAFETY] Constitutional rules:" -ForegroundColor Cyan
    foreach ($rule in $config.guardrails.constitutional) {
      Write-Host "  • $rule" -ForegroundColor White
    }
    Write-Host "[SAFETY] Blocked patterns:" -ForegroundColor Cyan
    foreach ($bp in $config.guardrails.blockedPatterns) {
      $color = if ($bp.severity -eq "critical") { "Red" } elseif ($bp.severity -eq "high") { "Yellow" } else { "Gray" }
      Write-Host "  [$($bp.severity)] $($bp.pattern)" -ForegroundColor $color
    }
    Write-Host "[SAFETY] Resource limits:" -ForegroundColor Cyan
    Write-Host "  Max files per mutation: $($config.guardrails.resourceLimits.maxFilesPerMutation)" -ForegroundColor Gray
    Write-Host "  Max tokens per prompt: $($config.guardrails.resourceLimits.maxTokensPerPrompt)" -ForegroundColor Gray
    Write-Host "  Max network calls: $($config.guardrails.resourceLimits.maxNetworkCallsPerMutation)" -ForegroundColor Gray
    return $config.guardrails
  }
}
