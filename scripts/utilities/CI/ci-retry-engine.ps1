<#
.SYNOPSIS
  Retry Engine — execute commands with exponential backoff and failure classification.

.DESCRIPTION
  Wraps any scriptblock with retry logic. Classifies failures as TRANSIENT,
  PERMANENT, or SECURITY based on output patterns. TRANSIENT failures retry
  with backoff; PERMANENT triggers rollback; SECURITY halts and alerts.

.PARAMETER ScriptBlock
  The command to execute with retry protection.
.PARAMETER JobName
  Name of the job (for logging).
.PARAMETER MaxRetries
  Override max retries (default: from config, 3).
.PARAMETER ConfigPath
  Path to ci-self-heal.json config (default: config/ci-self-heal.json).

.EXAMPLE
  .\ci-retry-engine.ps1 -ScriptBlock { npm run build } -JobName "npm-build"
#>

param(
  [scriptblock]$ScriptBlock,
  [string]$JobName = "unknown",
  [int]$MaxRetries = -1,
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Continue"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

# Load config
if (-not $ConfigPath) { $ConfigPath = Join-Path $repoRoot "config\ci-self-heal.json" }
$config = @{ retry = @{ maxRetries = 3; baseDelayMs = 5000; jitterMaxMs = 2000; classify = @{ transientPatterns = @(); securityPatterns = @(); permanentPatterns = @() } } }
if (Test-Path $ConfigPath) {
  try { $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json } catch {}
}

$maxRetries = if ($MaxRetries -ge 0) { $MaxRetries } else { $config.retry.maxRetries }
$baseDelay = $config.retry.baseDelayMs
$jitterMax = $config.retry.jitterMaxMs

function Classify-Failure {
  param([string]$Output)
  foreach ($pattern in $config.retry.classify.securityPatterns) {
    if ($Output -match $pattern) { return "SECURITY" }
  }
  foreach ($pattern in $config.retry.classify.permanentPatterns) {
    if ($Output -match $pattern) { return "PERMANENT" }
  }
  foreach ($pattern in $config.retry.classify.transientPatterns) {
    if ($Output -match $pattern) { return "TRANSIENT" }
  }
  return "PERMANENT"
}

$attempt = 0
$lastError = $null

Write-Host "[RETRY] Job: $JobName (max retries: $maxRetries)" -ForegroundColor Cyan

while ($attempt -le $maxRetries) {
  if ($attempt -gt 0) {
    $delay = [math]::Min($baseDelay * [math]::Pow(2, $attempt - 1) + (Get-Random -Maximum $jitterMax), 60000)
    Write-Host "[RETRY] Attempt $attempt/$maxRetries — waiting ${delay}ms..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds $delay
  }

  $attempt++
  Write-Host "[RETRY] Attempt $attempt/$($maxRetries + 1)..." -ForegroundColor White

  try {
    $result = & $ScriptBlock
    if ($LASTEXITCODE -eq 0 -or -not $LASTEXITCODE) {
      Write-Host "[RETRY] Job succeeded on attempt $attempt" -ForegroundColor Green
      return @{ status = "success"; attempts = $attempt; result = $result }
    }
    $lastError = "Exit code: $LASTEXITCODE"
    throw $lastError
  } catch {
    $lastError = $_.Exception.Message
    $failureType = Classify-Failure -Output $lastError
    Write-Host "[RETRY] Attempt $attempt failed: $failureType — $lastError" -ForegroundColor $(if ($failureType -eq "TRANSIENT") { "Yellow" } else { "Red" })

    if ($failureType -eq "SECURITY") {
      Write-Host "[RETRY] SECURITY failure — halting immediately!" -ForegroundColor Red
      return @{ status = "security"; attempts = $attempt; error = $lastError; failureType = $failureType }
    }

    if ($failureType -eq "PERMANENT" -or $attempt -gt $maxRetries) {
      if ($failureType -eq "PERMANENT") {
        Write-Host "[RETRY] PERMANENT failure — will trigger rollback" -ForegroundColor Red
      } else {
        Write-Host "[RETRY] Max retries exceeded" -ForegroundColor Red
      }
      return @{ status = "failed"; attempts = $attempt; error = $lastError; failureType = $failureType }
    }
  }
}

return @{ status = "failed"; attempts = $attempt; error = $lastError; failureType = "UNKNOWN" }
