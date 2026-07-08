<#
.SYNOPSIS
  Incident Logger — writes structured CI/CD incidents to audit + dashboard alerts.
.DESCRIPTION
  Logs CI/CD failures with structured fields (failureType, job, attempts, resolution, duration).
  Pushes alerts to the dashboard alerts system and writes to .session/audit/incidents/.
.PARAMETER JobName
  Name of the failed job.
.PARAMETER FailureType
  Classification: TRANSIENT, PERMANENT, SECURITY.
.PARAMETER Attempts
  Number of attempts before failure.
.PARAMETER Resolution
  How the failure was resolved: retried, rolled-back, manual, unhandled.
.PARAMETER Duration
  Total duration in seconds.
.PARAMETER Error
  Error message from the failure.
.PARAMETER AlertDashboard
  Send alert to dashboard (default: true).
.EXAMPLE
  .\ci-incident-logger.ps1 -JobName "deploy-main" -FailureType PERMANENT -Attempts 3 -Resolution rolled-back -Duration 45 -Error "Build failed with exit code 1"
#>

param(
  [string]$JobName = "unknown",
  [ValidateSet("TRANSIENT", "PERMANENT", "SECURITY", "UNKNOWN")]
  [string]$FailureType = "UNKNOWN",
  [int]$Attempts = 0,
  [ValidateSet("retried", "rolled-back", "manual", "unhandled", "skipped")]
  [string]$Resolution = "unhandled",
  [int]$Duration = 0,
  [string]$Error = "",
  [switch]$AlertDashboard = $true
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$auditDir = if ($env:GENTLE_TENANT_AUDIT_DIR) { $env:GENTLE_TENANT_AUDIT_DIR } else { Join-Path $repoRoot ".session\audit" }
$incidentsDir = Join-Path $auditDir "incidents"
$null = New-Item -ItemType Directory -Path $incidentsDir -Force

$incident = @{
  timestamp = Get-Date -Format "o"
  jobName = $JobName
  failureType = $FailureType
  attempts = $Attempts
  resolution = $Resolution
  duration = $Duration
  error = $Error
  source = "ci-self-heal"
}

$incidentFile = Join-Path $incidentsDir "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$($JobName -replace '[^\w-]', '').json"
$incident | ConvertTo-Json -Depth 10 | Set-Content $incidentFile -Encoding utf8
Write-Host "[INCIDENT] Logged: $incidentFile" -ForegroundColor $(if ($FailureType -eq "SECURITY") { "Red" } elseif ($FailureType -eq "PERMANENT") { "Yellow" } else { "Gray" })

if ($AlertDashboard) {
  $wsPort = $env:WS_PORT
  if ($wsPort) {
    try {
      $alertPayload = @{
        type = "ci-incident"
        severity = if ($FailureType -eq "SECURITY") { "critical" } elseif ($FailureType -eq "PERMANENT") { "error" } else { "warning" }
        title = "CI/CD: $JobName"
        message = "$FailureType after $Attempts attempt(s) — $Resolution"
        timestamp = $incident.timestamp
      } | ConvertTo-Json
      Invoke-WebRequest -Uri "http://localhost:$wsPort/api/alerts" -Method Post -Body $alertPayload -ContentType "application/json" -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
    } catch {}
  }
}

return $incident
