param([switch]$Quiet)
$ErrorActionPreference = 'Continue'

$ok = 0; $total = 0; $failures = @()

function Check {
    param([string]$Name, [scriptblock]$Block)
    $script:total++
    try {
        $result = & $Block
        if ($result) { $script:ok++; if (-not $Quiet) { Write-Host "  [OK] $Name" -ForegroundColor Green } }
        else { $script:failures += $Name; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
    } catch {
        $script:failures += $Name; Write-Host "  [FAIL] $Name — $_" -ForegroundColor Red
    }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

if (-not $Quiet) { Write-Host "=== FINAL COMPREHENSIVE VALIDATION ===" -ForegroundColor Cyan }

# 1. Pipeline
Check "Collector runs" { & "$repoRoot\scripts\metrics\collector.ps1" -Scope full -Quiet *>&1; $? }
Check "Dashboard renders" { & "$repoRoot\scripts\metrics\dashboard-render.ps1" *>&1; $? }
Check "Board report" { & "$repoRoot\scripts\utilities\generate-board-report.ps1" *>&1; $? }
Check "SLA dashboard" { & "$repoRoot\scripts\utilities\TELEMETRY-METRICS\sla-dashboard-generator.ps1" *>&1; $? }

# 3. Background processes
$statusOut = & "$repoRoot\scripts\utilities\live-feed-manager.ps1" -Action status *>&1 | Out-String
Check "Live-feed RUNNING" { $statusOut.Contains('RUNNING') }
Check "Metrics-server RUNNING" { $statusOut.Contains('RUNNING') -and $statusOut.Contains('Metrics-server') }

# 4. HTTP endpoints
$health = try { Invoke-WebRequest -Uri 'http://localhost:8090/health' -UseBasicParsing -TimeoutSec 5 } catch { $null }
Check "HTTP health endpoint" { $null -ne $health -and $health.Content -match 'liveFeedAlive.*true' }
$api = try { Invoke-WebRequest -Uri 'http://localhost:8090/api/live' -UseBasicParsing -TimeoutSec 5 } catch { $null }
Check "Live API returns data" { $null -ne $api -and $api.Content -match 'collectedAt' }

# 5. File integrity
$files = @(
    'reports/dashboard.html', 'reports/sla-dashboard.html', 'reports/MANAGEMENT-REPORT-2026-05.md',
    '.runtime/metrics/consolidated.json', '.runtime/metrics/git.json', '.runtime/metrics/token.json',
    '.runtime/metrics/cost.json', '.runtime/metrics/pr.json', '.runtime/metrics/live.json',
    '.runtime/metrics/sessions.json', '.session/live-feed-state.json',
    '.runtime/metrics/live/feed.json', '.runtime/metrics/live/daemon-health.json',
    '.session/metrics/current-session.json'
)
foreach ($f in $files) {
    Check "File: $f" { Test-Path (Join-Path $repoRoot $f) }
}

# 6. Dashboard JS
$dashHtml = Get-Content (Join-Path $repoRoot 'reports/dashboard.html') -Raw
Check "JS GV_LIVE.liveUpdate" { $dashHtml -match 'GV_LIVE\.liveUpdate' }
Check "JS daemonStatus" { $dashHtml -match 'daemonStatus' }
Check "JS fetch /api/live" { $dashHtml -match 'fetch.*api/live' }
Check "JS liveStatus span" { $dashHtml -match 'id="liveStatus"' }

# 7. Config integrity
$autostart = Get-Content (Join-Path $repoRoot 'config/session-autostart.config.json') -Raw
Check "Autostart: dashboard-render" { $autostart -match 'dashboard-render' }
Check "Autostart: live-feed-start" { $autostart -match 'live-feed-start' }
Check "Autostart: OpenDashboard flag" { $autostart -match 'OpenDashboard' }

$sessionMgr = Get-Content (Join-Path $repoRoot 'scripts/utilities/session-manager.ps1') -Raw
Check "Session-close: dashboard-render" { $sessionMgr -match 'dashboard-render' }
Check "Session-close: collector refresh" { $sessionMgr -match 'collector.*refresh' }
Check "Session-close: live-feed stop" { $sessionMgr -match 'live-feed-manager' }

# 8. Cost rate consistency
$badRates = Get-ChildItem -Recurse -Filter '*.ps1' -Path (Join-Path $repoRoot 'scripts') |
    Select-String -Pattern 'costPer1M|ratePer1M' |
    Where-Object { $_.Line -match '=\s*15\d*\.?\d*' -and $_.Line -notmatch '#|//|example' }
Check "No `$15 cost rates" { $badRates.Count -eq 0 }

# 9. SLA dashboard has real data
$slaHtml = Get-Content (Join-Path $repoRoot 'reports/sla-dashboard.html') -Raw
Check "SLA: Traffic Light GREEN" { $slaHtml -match 'GREEN' }
Check "SLA: Compliance PASS" { $slaHtml -match 'PASS' }

Write-Host "`n=== $ok/$total checks passed ===" -ForegroundColor $(if ($failures.Count -eq 0) { 'Green' } else { 'Red' })
if ($failures.Count -gt 0) {
    Write-Host "FAILURES: $($failures -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
exit 0
