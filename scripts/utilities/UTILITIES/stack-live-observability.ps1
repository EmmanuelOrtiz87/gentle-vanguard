#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Live observability monitor for Foundation stack.

.DESCRIPTION
  Aggregates real-time-ish operational signals from local artifacts:
  - orchestrator activation/config
  - event-bus history (recent dispatch/agent events)
  - token guard status
  - context dashboard metrics
  - latest routing quality matrix
  - latest wf benchmark report

.PARAMETER Watch
  Refresh repeatedly in console mode.

.PARAMETER RefreshSeconds
  Interval between refreshes in watch mode.

.PARAMETER Iterations
  Max refresh cycles in watch mode (0 = infinite).

.PARAMETER AsJson
  Output JSON snapshot (single run).
#>

param(
    [switch]$Watch,
    [int]$RefreshSeconds = 5,
    [int]$Iterations = 0,
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

$activationFile = Join-Path $repoRoot '.orchestrator-active'
$orchestratorConfigPath = Join-Path $repoRoot 'config\orchestrator.json'
$eventHistoryPath = Join-Path $repoRoot '.event-bus\history.json'
$routingQualityPath = Join-Path $repoRoot '.session\routing-quality-last.json'
$wfBenchmarkPath = Join-Path $repoRoot 'reports\wf-benchmark.json'
$latestSnapshotPath = Join-Path $repoRoot 'reports\stack-live-observability-latest.json'
$tokenGuardScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\token-budget-guard.ps1'
$contextDashboardScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\context-dashboard.ps1'

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $null }
}

function Get-OrchestratorSnapshot {
    $cfg = Read-JsonFile -Path $orchestratorConfigPath
    return [ordered]@{
        active = [bool](Test-Path $activationFile)
        workflow_mode = if ($cfg -and $cfg.workflow_mode) { [string]$cfg.workflow_mode } else { 'unknown' }
        communication_language = if ($cfg -and $cfg.communication_language) { [string]$cfg.communication_language } else { 'unknown' }
        response_mode = if ($cfg -and $cfg.communication_response_mode) { [string]$cfg.communication_response_mode } else { 'unknown' }
        profile = if ($cfg -and $cfg.response_profiles -and $cfg.response_profiles.active) { [string]$cfg.response_profiles.active } else { 'unknown' }
    }
}

function Get-EventSnapshot {
    $history = Read-JsonFile -Path $eventHistoryPath
    if (-not $history -or -not $history.events) {
        return [ordered]@{
            total_events = 0
            emitted = 0
            blocked = 0
            last_5m = 0
            top_events = @()
            top_agents = @()
        }
    }

    $events = @($history.events)
    $now = Get-Date
    $window = $now.AddMinutes(-5)
    $last5m = @($events | Where-Object {
        try { [datetime]::Parse($_.timestamp) -ge $window } catch { $false }
    })

    $topEvents = @($events |
        Group-Object -Property event |
        Sort-Object -Property Count -Descending |
        Select-Object -First 5 |
        ForEach-Object { [ordered]@{ event = $_.Name; count = $_.Count } })

    # Agent extraction from payload if available
    $agentNames = @()
    foreach ($e in $events) {
        if (-not $e.payload) { continue }
        try {
            $p = $e.payload | ConvertFrom-Json
            if ($p.agent) { $agentNames += [string]$p.agent }
        } catch { }
    }
    $topAgents = @($agentNames |
        Group-Object |
        Sort-Object -Property Count -Descending |
        Select-Object -First 5 |
        ForEach-Object { [ordered]@{ agent = $_.Name; count = $_.Count } })

    return [ordered]@{
        total_events = $events.Count
        emitted = @($events | Where-Object { $_.status -eq 'emitted' }).Count
        blocked = @($events | Where-Object { [string]$_.status -like 'blocked*' }).Count
        last_5m = $last5m.Count
        top_events = $topEvents
        top_agents = $topAgents
    }
}

function Get-TokenSnapshot {
    if (-not (Test-Path $tokenGuardScript)) {
        return [ordered]@{ status = 'UNKNOWN'; projected_pct = 0; used_today = 0; budget = 0 }
    }

    try {
        $json = & $tokenGuardScript -Mode status -Task general -AsJson -Quiet
        if (-not $json) { throw 'No output' }
        $t = $json | ConvertFrom-Json
        return [ordered]@{
            status = if ($t.status) { [string]$t.status } else { 'UNKNOWN' }
            projected_pct = if ($t.projected_pct) { [double]$t.projected_pct } else { 0 }
            used_today = if ($t.used_today_tokens) { [int]$t.used_today_tokens } else { 0 }
            budget = if ($t.daily_budget_tokens) { [int]$t.daily_budget_tokens } else { 0 }
        }
    } catch {
        return [ordered]@{ status = 'UNKNOWN'; projected_pct = 0; used_today = 0; budget = 0 }
    }
}

function Get-ContextSnapshot {
    if (-not (Test-Path $contextDashboardScript)) {
        return [ordered]@{ adoption_pct = 0; budget_status = 'UNKNOWN'; blocked_60s = 0 }
    }

    try {
        $json = & $contextDashboardScript -AsJson
        $c = $json | ConvertFrom-Json
        return [ordered]@{
            adoption_pct = if ($c.context_window -and $c.context_window.adoption_pct) { [double]$c.context_window.adoption_pct } else { 0 }
            budget_status = if ($c.token_budget -and $c.token_budget.status) { [string]$c.token_budget.status } else { 'UNKNOWN' }
            blocked_60s = if ($c.events -and $c.events.blocked_last_60s) { [int]$c.events.blocked_last_60s } else { 0 }
        }
    } catch {
        return [ordered]@{ adoption_pct = 0; budget_status = 'UNKNOWN'; blocked_60s = 0 }
    }
}

function Get-RoutingSnapshot {
    $r = Read-JsonFile -Path $routingQualityPath
    if (-not $r -or -not $r.summary) {
        return [ordered]@{ accuracy = 'n/a'; total = 0; failed = 0; timestamp = '' }
    }

    return [ordered]@{
        accuracy = "$($r.summary.accuracy)%"
        total = [int]$r.summary.total
        failed = [int]$r.summary.failed
        timestamp = if ($r.timestamp) { [string]$r.timestamp } else { '' }
    }
}

function Get-BenchmarkSnapshot {
    $b = Read-JsonFile -Path $wfBenchmarkPath
    if (-not $b -or -not $b.results) {
        return [ordered]@{ pass = 0; warn = 0; fail = 0; last_report = '' }
    }

    $rows = @($b.results)
    return [ordered]@{
        pass = @($rows | Where-Object { $_.status -eq 'PASS' }).Count
        warn = @($rows | Where-Object { $_.status -eq 'WARN' }).Count
        fail = @($rows | Where-Object { $_.status -in @('FAIL', 'ERROR') }).Count
        last_report = if ($b.as_of) { [string]$b.as_of } else { '' }
    }
}

function Build-Snapshot {
    $snapshot = [ordered]@{
        timestamp = (Get-Date).ToString('o')
        orchestrator = Get-OrchestratorSnapshot
        events = Get-EventSnapshot
        token = Get-TokenSnapshot
        context = Get-ContextSnapshot
        routing = Get-RoutingSnapshot
        benchmark = Get-BenchmarkSnapshot
    }

    $traffic = 'GREEN'
    if (-not $snapshot.orchestrator.active -or $snapshot.token.status -eq 'HARD_LIMIT' -or $snapshot.benchmark.fail -gt 0 -or $snapshot.routing.failed -gt 0) {
        $traffic = 'RED'
    } elseif ($snapshot.token.status -eq 'SOFT_LIMIT' -or $snapshot.events.blocked -gt 0 -or $snapshot.benchmark.warn -gt 0) {
        $traffic = 'YELLOW'
    }

    $snapshot['executive_traffic_light'] = $traffic
    return $snapshot
}

function Save-LatestSnapshot {
    param($Snapshot)

    $dir = Split-Path -Parent $latestSnapshotPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    try {
        $Snapshot | ConvertTo-Json -Depth 8 | Set-Content -Path $latestSnapshotPath -Encoding UTF8
    } catch {
        # Non-blocking: live monitor should continue even if report write fails.
    }
}

function Show-Snapshot {
    param($s)

    Clear-Host
    Write-Host ''
    Write-Host '=== FOUNDATION LIVE OBSERVABILITY ===' -ForegroundColor Cyan
    Write-Host "Timestamp: $($s.timestamp)" -ForegroundColor Gray
    Write-Host ''

    Write-Host '[Orchestrator]' -ForegroundColor White
    Write-Host "  Active: $($s.orchestrator.active) | Mode: $($s.orchestrator.workflow_mode) | Lang: $($s.orchestrator.communication_language) | Response: $($s.orchestrator.response_mode)"

    Write-Host ''
    Write-Host '[Agents / Events]' -ForegroundColor White
    Write-Host "  Total: $($s.events.total_events) | Emitted: $($s.events.emitted) | Blocked: $($s.events.blocked) | Last5m: $($s.events.last_5m)"
    if ($s.events.top_agents.Count -gt 0) {
        $top = @($s.events.top_agents | ForEach-Object { "$($_.agent):$($_.count)" }) -join ' | '
        Write-Host "  Top agents: $top" -ForegroundColor Gray
    }

    Write-Host ''
    Write-Host '[Tokens / Context]' -ForegroundColor White
    Write-Host "  TokenGuard: $($s.token.status) | Projected: $($s.token.projected_pct)% | Used/Budget: $($s.token.used_today)/$($s.token.budget)"
    Write-Host "  Adoption: $($s.context.adoption_pct)% | BudgetStatus: $($s.context.budget_status) | Blocked(60s): $($s.context.blocked_60s)"

    Write-Host ''
    Write-Host '[Quality / Benchmark]' -ForegroundColor White
    Write-Host "  Routing matrix: accuracy=$($s.routing.accuracy) total=$($s.routing.total) failed=$($s.routing.failed)"
    Write-Host "  WF benchmark: pass=$($s.benchmark.pass) warn=$($s.benchmark.warn) fail=$($s.benchmark.fail)"

    $tlColor = switch ($s.executive_traffic_light) {
        'RED' { 'Red' }
        'YELLOW' { 'Yellow' }
        default { 'Green' }
    }
    Write-Host ''
    Write-Host "Executive Traffic Light: $($s.executive_traffic_light)" -ForegroundColor $tlColor
    Write-Host ''
}

if ($AsJson -or -not $Watch) {
    $single = Build-Snapshot
    Save-LatestSnapshot -Snapshot $single
    if ($AsJson) {
        $single | ConvertTo-Json -Depth 8
    } else {
        Show-Snapshot -s $single
    }
    exit 0
}

$counter = 0
while ($true) {
    $counter++
    $snap = Build-Snapshot
    Save-LatestSnapshot -Snapshot $snap
    Show-Snapshot -s $snap

    if ($Iterations -gt 0 -and $counter -ge $Iterations) {
        break
    }

    Start-Sleep -Seconds $RefreshSeconds
}

exit 0
