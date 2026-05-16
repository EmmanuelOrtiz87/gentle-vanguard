#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Continuously refreshes unified dashboard artifacts for live executive and developer visibility.

.DESCRIPTION
  This loop keeps data and dashboard HTML fresh by orchestrating:
  - stack-live-observability snapshot generation
  - optional full stack benchmark refresh at a slower cadence
  - dashboard HTML regeneration with browser auto-refresh metadata

.PARAMETER RefreshSeconds
  Interval in seconds between dashboard refresh cycles.

.PARAMETER BenchmarkEvery
  Run full benchmark every N cycles.

.PARAMETER OutputPath
  Dashboard HTML target path.

.PARAMETER Open
  Open dashboard in default browser on first cycle.

.PARAMETER Iterations
  Number of cycles to run. 0 means infinite.

.PARAMETER AutoRemediateOnFail
  Enable local auto-remediation when full benchmark fails.
#>

param(
  [int]$RefreshSeconds = 15,
  [int]$BenchmarkEvery = 4,
  [string]$OutputPath = '',
  [switch]$Open,
  [int]$Iterations = 0,
  [switch]$AutoRemediateOnFail,
  [string]$WebhookUrl = '',
  [ValidateSet('slack', 'teams', 'discord', 'generic')]
  [string]$WebhookProvider = 'slack',
  [switch]$EnablePredictor,
  [switch]$EnableSLADashboard,
  [string]$GitHubToken = $env:GITHUB_TOKEN,
  [string]$GitHubRepo = ''
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

$generateDashboard = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1'
$liveObs = Join-Path $repoRoot 'scripts\utilities\UTILITIES\stack-live-observability.ps1'
$stackBenchmark = Join-Path $repoRoot 'scripts\utilities\gv-stack-benchmark.ps1'
$webhookScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\webhook-alerting.ps1'
$predictorScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\baseline-predictor.ps1'
$slaScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\sla-dashboard-generator.ps1'
$escalationScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\auto-escalation.ps1'
$predictorOutputPath = Join-Path $repoRoot 'reports\baseline-predictor-latest.json'
$liveServerScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\websocket-live-server.ps1'
$liveServerPort = 8090

if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot 'reports\dashboard.html'
}

if (-not (Test-Path $generateDashboard)) {
    throw "generate-dashboard.ps1 not found: $generateDashboard"
}
if (-not (Test-Path $liveObs)) {
    throw "stack-live-observability.ps1 not found: $liveObs"
}
if (-not (Test-Path $stackBenchmark)) {
    throw "gv-stack-benchmark.ps1 not found: $stackBenchmark"
}

$refreshSafe = [Math]::Max(5, $RefreshSeconds)
$cycle = 0
$opened = $false
$failureCount = 0
$lastTrafficLight = 'GREEN'

function Get-MapValue {
  param(
    $Map,
    [string[]]$Path,
    $Default = $null
  )

  $cursor = $Map
  foreach ($part in $Path) {
    if ($null -eq $cursor) { return $Default }
    if ($cursor -is [System.Collections.IDictionary]) {
      if (-not $cursor.Contains($part)) { return $Default }
      $cursor = $cursor[$part]
      continue
    }
    if ($cursor.PSObject.Properties.Name -contains $part) {
      $cursor = $cursor.$part
      continue
    }
    return $Default
  }

  if ($null -eq $cursor) { return $Default }
  return $cursor
}

  function Test-LiveServer {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri ("http://localhost:{0}/health" -f $liveServerPort) -TimeoutSec 2 -ErrorAction Stop
      return $resp.StatusCode -eq 200
    } catch {
      return $false
    }
  }

  function Ensure-LiveServer {
    if (-not (Test-Path $liveServerScript)) {
      return $false
    }
    if (Test-LiveServer) {
      return $true
    }

    $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwshPath) {
      $pwshPath = 'pwsh'
    }

    $stdoutLog = Join-Path $repoRoot 'reports/live-server-stdout.log'
    $stderrLog = Join-Path $repoRoot 'reports/live-server-stderr.log'
    if (Test-Path $stdoutLog) {
      Remove-Item $stdoutLog -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $stderrLog) {
      Remove-Item $stderrLog -Force -ErrorAction SilentlyContinue
    }

    $args = @(
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', $liveServerScript,
      '-Port', [string]$liveServerPort,
      '-DashboardPath', $OutputPath
    )
    Start-Process -FilePath $pwshPath -ArgumentList $args -WorkingDirectory $repoRoot -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog | Out-Null
    Start-Sleep -Milliseconds 1200
    return (Test-LiveServer)
  }

Write-Host ''
Write-Host '=== DASHBOARD LIVE REFRESH ===' -ForegroundColor Cyan
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host "RefreshSeconds: $refreshSafe | BenchmarkEvery: $BenchmarkEvery" -ForegroundColor Gray
if ($WebhookUrl) { Write-Host "Webhook: $WebhookProvider enabled" -ForegroundColor Gray }
if ($EnablePredictor) { Write-Host "Predictor: enabled" -ForegroundColor Gray }
if ($EnableSLADashboard) { Write-Host "SLA Dashboard: enabled" -ForegroundColor Gray }
Write-Host ''

while ($true) {
    $cycle++
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # 1) Refresh live observability snapshot artifact.
  $liveSnapshot = & $liveObs -AsJson | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
  if ($liveSnapshot) {
    $currentTrafficLight = [string](Get-MapValue -Map $liveSnapshot -Path @('executive_traffic_light') -Default 'GREEN')
    if ($WebhookUrl -and $currentTrafficLight -ne $lastTrafficLight -and (Test-Path $webhookScript)) {
      $statusAlert = @{
        previous_status = $lastTrafficLight
        current_status = $currentTrafficLight
        dashboard_url = 'http://localhost:8090/dashboard.html'
      }
      & $webhookScript -WebhookUrl $WebhookUrl -Status $currentTrafficLight -AlertType 'status-change' -Provider $WebhookProvider -Details $statusAlert 2>$null | Out-Null
    }
    $lastTrafficLight = $currentTrafficLight
  }

    # 2) Run full benchmark periodically to keep baseline/trend data fresh.
    if ($BenchmarkEvery -gt 0 -and ($cycle % $BenchmarkEvery -eq 0)) {
      $benchOutput = if ($AutoRemediateOnFail) {
        & $stackBenchmark -AsJson -AutoRemediate 2>&1
      } else {
        & $stackBenchmark -AsJson 2>&1
      }
        
      $benchResult = $benchOutput | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
      if ($benchResult) {
        $currentStatus = $benchResult.summary.status ?? 'UNKNOWN'
        if ($currentStatus -eq 'FAIL') {
          $failureCount++
          $failedLayers = @(Get-MapValue -Map $benchResult -Path @('summary', 'failed_layers') -Default @())
          $wfAverage = 0
          $wfResults = @(Get-MapValue -Map $benchResult -Path @('layers', 'wf_benchmark', 'data', 'results') -Default @())
          if ($wfResults.Count -gt 0) {
            $wfAverage = [math]::Round((($wfResults | Measure-Object -Property elapsed_s -Average).Average), 3)
          }
          $routingAccuracy = [double](Get-MapValue -Map $benchResult -Path @('layers', 'routing_matrix', 'data', 'accuracy') -Default 0)
                
          # Send webhook alert on benchmark failure
          if ($WebhookUrl -and (Test-Path $webhookScript)) {
            $alertDetails = @{
              layers_failed = ($failedLayers -join ', ')
              latency_wf = "$wfAverage s"
              routing_accuracy = "$routingAccuracy%"
                        dashboard_url = "http://localhost:8090/dashboard.html"
            }
            & $webhookScript -WebhookUrl $WebhookUrl -Status 'RED' -AlertType 'benchmark-fail' `
              -Provider $WebhookProvider -Details $alertDetails 2>$null | Out-Null
          }
                
          # Auto-escalate to GitHub if threshold reached
          if ($GitHubRepo -and $GitHubToken -and $failureCount -ge 3 -and (Test-Path $escalationScript)) {
            & $escalationScript -Repository $GitHubRepo -GitHubToken $GitHubToken `
              -FailureCount $failureCount -IncidentDetails $alertDetails 2>$null | Out-Null
            $failureCount = 0  # Reset after escalation
          }
        } else {
          $failureCount = 0  # Reset on success
        }
      }
    }
    
    # 2b) Generate baseline prediction if enabled
    if ($EnablePredictor -and (($cycle -eq 1) -or ($cycle % ([Math]::Max(1, $BenchmarkEvery) * 2) -eq 0)) -and (Test-Path $predictorScript)) {
      $predictorJson = & $predictorScript -ForecastHours 24 -AsJson 2>$null
      if ($predictorJson) {
        Set-Content -Path $predictorOutputPath -Value $predictorJson -Encoding UTF8
      }
    }
    
    # 2c) Generate SLA dashboard if enabled
    if ($EnableSLADashboard -and (($cycle -eq 1) -or ($cycle % ([Math]::Max(1, $BenchmarkEvery) * 4) -eq 0)) -and (Test-Path $slaScript)) {
      $slaPath = Join-Path $repoRoot 'reports\sla-dashboard.html'
      & $slaScript -OutputPath $slaPath -MonthlyTarget 99.5 2>$null
    }

    $pushReady = Test-LiveServer
    if ($Open -and -not $opened -and -not $pushReady) {
      $pushReady = Ensure-LiveServer
    }

    # 3) Regenerate dashboard HTML. Prefer SSE push updates, but keep timed refresh as fallback.
    $autoRefreshSeconds = if ($pushReady) { 0 } else { $refreshSafe }
    & $generateDashboard -OutputPath $OutputPath -AutoRefreshSeconds $autoRefreshSeconds | Out-Null

    if ($Open -and -not $opened) {
      $liveUrl = "http://localhost:$liveServerPort/dashboard.html"
      $openedTarget = $OutputPath
      if ($pushReady -or (Ensure-LiveServer)) {
        $openedTarget = $liveUrl
      }

      if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        Start-Process $openedTarget
        } elseif ($IsMacOS) {
        & open $openedTarget
        } else {
        & xdg-open $openedTarget 2>$null
        }
        $opened = $true
    }

    $failureInfo = if ($failureCount -gt 0) { " | failures=$failureCount" } else { "" }
    Write-Host "[$ts] cycle=$cycle dashboard refreshed$failureInfo" -ForegroundColor Green

    if ($Iterations -gt 0 -and $cycle -ge $Iterations) {
        break
    }

    Start-Sleep -Seconds $refreshSafe
}

Write-Host ''
Write-Host 'Live refresh finished.' -ForegroundColor Cyan
exit 0

