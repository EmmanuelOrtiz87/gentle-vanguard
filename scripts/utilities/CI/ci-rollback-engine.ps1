<#
.SYNOPSIS
  Rollback Engine — revert deployment and re-deploy previous version on failure.

.DESCRIPTION
  On permanent CI/CD failure, reverts the last commit via git, re-deploys the
  previous workflow artifact, and logs the incident to audit + dashboard alerts.

.PARAMETER Action
  rollback — perform rollback (default)
  status   — check if rollback is needed/available
  log      — show rollback history

.PARAMETER JobName
  Name of the failed job for logging.

.PARAMETER Reason
  Reason for rollback (logged to audit).

.PARAMETER DryRun
  Show what would be done without executing.

.EXAMPLE
  .\ci-rollback-engine.ps1 -Action rollback -JobName "deploy-main" -Reason "Build failed"
  .\ci-rollback-engine.ps1 -Action status
#>

param(
  [ValidateSet("rollback", "status", "log")]
  [string]$Action = "rollback",
  [string]$JobName = "unknown",
  [string]$Reason = "No reason provided",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$configPath = Join-Path $repoRoot "config\ci-self-heal.json"
$config = @{ rollback = @{ autoRollback = $true; maxRollbackAttempts = 2; safeBranches = @("main", "master", "develop"); notifyChannels = @("dashboard", "audit"); requireApproval = $false } }
if (Test-Path $configPath) {
  try { $config = Get-Content $configPath -Raw | ConvertFrom-Json } catch {}
}

$rollbackDir = Join-Path $repoRoot ".session\rollbacks"
$null = New-Item -ItemType Directory -Path $rollbackDir -Force

switch ($Action) {
  "status" {
    $currentBranch = git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null
    $isSafe = $currentBranch -in $config.rollback.safeBranches
    $lastCommit = git -C $repoRoot log --oneline -1 2>$null
    $rollbackLogs = Get-ChildItem -Path $rollbackDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 5

    Write-Host "[ROLLBACK] Status:" -ForegroundColor Cyan
    Write-Host "  Branch: $currentBranch $(if($isSafe){'(safe)'}else{'(not safe — rollback requires approval)'})" -ForegroundColor $(if($isSafe){"Green"}else{"Yellow"})
    Write-Host "  Last commit: $lastCommit" -ForegroundColor Gray
    Write-Host "  Auto-rollback: $($config.rollback.autoRollback)" -ForegroundColor Gray
    Write-Host "  Recent rollbacks:" -ForegroundColor Gray
    foreach ($log in $rollbackLogs) {
      $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
      Write-Host "    $($data.timestamp) — $($data.jobName): $($data.reason)" -ForegroundColor Yellow
    }
    return @{ branch = $currentBranch; isSafe = $isSafe; autoRollback = $config.rollback.autoRollback }
  }

  "rollback" {
    $currentBranch = git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null
    $isSafe = $currentBranch -in $config.rollback.safeBranches

    if (-not $isSafe -and -not $config.rollback.requireApproval -eq $false) {
      Write-Error "[ROLLBACK] Branch '$currentBranch' is not in safe list and requires approval"
      exit 1
    }

    if (-not $config.rollback.autoRollback) {
      Write-Host "[ROLLBACK] Auto-rollback is disabled — manual intervention required" -ForegroundColor Yellow
      return @{ status = "skipped"; reason = "autoRollback disabled" }
    }

    Write-Host "[ROLLBACK] Initiating rollback for job: $JobName" -ForegroundColor Cyan
    Write-Host "[ROLLBACK] Reason: $Reason" -ForegroundColor Yellow

    if ($DryRun) {
      Write-Host "[DRY-RUN] Would execute: git revert HEAD --no-edit" -ForegroundColor Yellow
      Write-Host "[DRY-RUN] Would execute: git push origin $currentBranch" -ForegroundColor Yellow
      return @{ status = "dryrun"; commands = @("git revert HEAD --no-edit", "git push origin $currentBranch") }
    }

    $rollbackRecord = @{
      timestamp = Get-Date -Format "o"
      jobName = $JobName
      reason = $Reason
      branch = $currentBranch
      commitBefore = git -C $repoRoot rev-parse HEAD
    }

    try {
      git -C $repoRoot revert HEAD --no-edit 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "git revert failed with exit code $LASTEXITCODE" }

      git -C $repoRoot push origin $currentBranch 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "git push failed with exit code $LASTEXITCODE" }

      $commitAfter = git -C $repoRoot rev-parse HEAD
      $rollbackRecord.commitAfter = $commitAfter
      $rollbackRecord.status = "success"

      Write-Host "[ROLLBACK] Success — reverted to $commitAfter" -ForegroundColor Green

      # Log to audit
      $auditDir = if ($env:GENTLE_TENANT_AUDIT_DIR) { $env:GENTLE_TENANT_AUDIT_DIR } else { Join-Path $repoRoot ".session\audit" }
      $incidentsDir = Join-Path $auditDir "incidents"
      $null = New-Item -ItemType Directory -Path $incidentsDir -Force
      $incidentFile = Join-Path $incidentsDir "$(Get-Date -Format 'yyyyMMdd-HHmmss')-rollback.json"
      $rollbackRecord | ConvertTo-Json | Set-Content $incidentFile -Encoding utf8
      Write-Host "[ROLLBACK] Incident logged: $incidentFile" -ForegroundColor Gray

    } catch {
      $rollbackRecord.status = "failed"
      $rollbackRecord.error = $_.Exception.Message
      Write-Error "[ROLLBACK] Failed: $($_.Exception.Message)"
    }

    # Store rollback log
    $logFile = Join-Path $rollbackDir "$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $rollbackRecord | ConvertTo-Json | Set-Content $logFile -Encoding utf8

    return $rollbackRecord
  }

  "log" {
    $logs = Get-ChildItem -Path $rollbackDir -Filter "*.json" | Sort-Object LastWriteTime -Descending
    if ($logs.Count -eq 0) {
      Write-Host "[ROLLBACK] No rollback history" -ForegroundColor Gray
      return @()
    }
    Write-Host "[ROLLBACK] History:" -ForegroundColor Cyan
    foreach ($log in $logs) {
      $data = Get-Content $log.FullName -Raw | ConvertFrom-Json
      $color = if ($data.status -eq "success") { "Green" } else { "Red" }
      Write-Host "  $($data.timestamp) | $($data.jobName) | $($data.status) | $($data.reason)" -ForegroundColor $color
    }
    return $logs
  }
}
