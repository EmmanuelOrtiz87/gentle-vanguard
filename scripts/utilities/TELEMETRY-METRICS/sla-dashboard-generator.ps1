<#
.SYNOPSIS
    SLA Dashboard Generator: Uptime tracking, incident metrics, compliance reporting.

.DESCRIPTION
    Creates HTML dashboard with SLA-focused metrics:
    - Monthly/Weekly/Daily uptime percentage
    - Incident count, MTTR (Mean Time To Recovery)
    - SLO compliance status (latency p95, routing accuracy)
    - Trend charts (uptime, incidents, availability)

    Reads from:
    - reports/incidents/*.md (auto-remediation reports)
    - reports/stack-benchmark-history.json
    - reports/stack-live-observability-latest.json

.PARAMETER OutputPath
    Path for generated HTML. Default: ./reports/sla-dashboard.html

.PARAMETER MonthlyTarget
    Target monthly uptime %. Default: 99.5

.PARAMETER WeeklyTarget
    Target weekly uptime %. Default: 99.9

.PARAMETER Open
    Open dashboard in default browser

.EXAMPLE
    .\\sla-dashboard-generator.ps1 -MonthlyTarget 99.5 -Open
#>

param(
    [string]$OutputPath = './reports/sla-dashboard.html',
    [decimal]$MonthlyTarget = 99.5,
    [decimal]$WeeklyTarget = 99.9,
    [switch]$Open
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

$OutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $repoRoot ($OutputPath -replace '^\.\\?', '')
}
$incidentsDir = Join-Path $repoRoot 'reports\incidents'
$benchmarkPath = Join-Path $repoRoot 'reports\stack-benchmark.json'
$snapshotPath = Join-Path $repoRoot 'reports\stack-live-observability-latest.json'

# Helper functions
function Get-IncidentMetrics {
    if (-not (Test-Path $incidentsDir)) {
        return @{
            total_incidents = 0
            mttr_minutes = 0
            incidents_7d = 0
            incidents_30d = 0
        }
    }

    $incidents = @(Get-ChildItem -Path $incidentsDir -Filter '*.md' -ErrorAction SilentlyContinue)
    $now = Get-Date
    
    $incidents_7d = @($incidents | Where-Object {
        (($now) - $_.CreationTime).Days -le 7
    }).Count
    
    $incidents_30d = @($incidents | Where-Object {
        (($now) - $_.CreationTime).Days -le 30
    }).Count

    $durations = @()
    foreach ($incident in $incidents) {
        try {
            $content = Get-Content $incident.FullName -Raw
            $match = [regex]::Match($content, '(?im)(mttr|duration|recovery)\D+(\d+(?:\.\d+)?)\s*(min|minute|minutes)')
            if ($match.Success) {
                $durations += [double]$match.Groups[2].Value
            }
        } catch {
        }
    }

    $mttr_minutes = if ($durations.Count -gt 0) {
        [Math]::Round((($durations | Measure-Object -Average).Average), 1)
    } elseif ($incidents.Count -gt 0) {
        15
    } else {
        0
    }

    return @{
        total_incidents = $incidents.Count
        mttr_minutes    = $mttr_minutes
        incidents_7d    = $incidents_7d
        incidents_30d   = $incidents_30d
    }
}

function Calculate-Uptime {
    param([int]$IncidentCount, [decimal]$IncidentDuration, [int]$PeriodDays)
    
    $periodSeconds = $PeriodDays * 24 * 3600
    
    $downtimeSeconds = $IncidentCount * $IncidentDuration * 60  # Convert minutes to seconds
    $uptimePercent = (($periodSeconds - $downtimeSeconds) / $periodSeconds) * 100
    
    return [Math]::Max(0, [Math]::Min(100, $uptimePercent))
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
}

# Load incident metrics
$metrics = Get-IncidentMetrics

$benchmark = Read-JsonFile -Path $benchmarkPath
$snapshot = Read-JsonFile -Path $snapshotPath

# Calculate uptime
$monthly_uptime = Calculate-Uptime -IncidentCount $metrics.incidents_30d -IncidentDuration $metrics.mttr_minutes -PeriodDays 30
$weekly_uptime = Calculate-Uptime -IncidentCount $metrics.incidents_7d -IncidentDuration $metrics.mttr_minutes -PeriodDays 7

# Compliance status
$monthly_compliant = $monthly_uptime -ge $MonthlyTarget
$weekly_compliant = $weekly_uptime -ge $WeeklyTarget
$routingAccuracy = if ($benchmark -and $benchmark.layers -and $benchmark.layers.routing_matrix -and $benchmark.layers.routing_matrix.data) { [double]$benchmark.layers.routing_matrix.data.accuracy } else { 0 }
$latencyAverage = if ($benchmark -and $benchmark.layers -and $benchmark.layers.wf_benchmark -and $benchmark.layers.wf_benchmark.data -and $benchmark.layers.wf_benchmark.data.results) {
    [Math]::Round(((@($benchmark.layers.wf_benchmark.data.results | Measure-Object -Property elapsed_s -Average).Average)), 3)
} else {
    0
}
$trafficLight = if ($snapshot -and $snapshot.executive_traffic_light) { [string]$snapshot.executive_traffic_light } else { 'UNKNOWN' }
$updatedAtUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')
$monthlyStatusClass = if ($monthly_compliant) { 'status-compliant' } else { 'status-critical' }
$weeklyStatusClass = if ($weekly_compliant) { 'status-compliant' } else { 'status-warning' }
$monthlyStatusLabel = if ($monthly_compliant) { 'PASS' } else { 'FAIL' }
$weeklyStatusLabel = if ($weekly_compliant) { 'PASS' } else { 'WARN' }
$reportsDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

# HTML Generation
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>SLA Dashboard — Foundation Stack</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e1e2e 0%, #2d2d44 100%);
            color: #e0e0e0;
            padding: 20px;
            min-height: 100vh;
        }
        
        .container { max-width: 1400px; margin: 0 auto; }
        
        header {
            text-align: center;
            margin-bottom: 40px;
            border-bottom: 2px solid #3a3a4a;
            padding-bottom: 20px;
        }
        
        h1 { font-size: 2.5em; color: #00d4ff; margin-bottom: 5px; }
        .subtitle { color: #888; font-size: 0.95em; }
        
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px; }
        .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; margin-bottom: 30px; }
        .grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 30px; }
        
        .card {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 20px;
            backdrop-filter: blur(10px);
            transition: all 0.3s ease;
        }
        
        .card:hover { border-color: rgba(0, 212, 255, 0.5); transform: translateY(-2px); }
        
        .metric {
            text-align: center;
            padding: 20px;
        }
        
        .metric-value {
            font-size: 3em;
            font-weight: bold;
            color: #00d4ff;
            margin: 10px 0;
        }
        
        .metric-label {
            font-size: 0.9em;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 0.9em;
        }
        
        .status-compliant {
            background: rgba(0, 176, 80, 0.2);
            color: #00b050;
            border: 1px solid #00b050;
        }
        
        .status-warning {
            background: rgba(255, 185, 0, 0.2);
            color: #ffb900;
            border: 1px solid #ffb900;
        }
        
        .status-critical {
            background: rgba(255, 0, 0, 0.2);
            color: #ff6b6b;
            border: 1px solid #ff6b6b;
        }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 4px;
            overflow: hidden;
            margin-top: 10px;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #00d4ff, #00b050);
            width: 0%;
        }
        
        .table-container {
            overflow-x: auto;
            background: rgba(255, 255, 255, 0.02);
            border-radius: 8px;
            padding: 15px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.9em;
        }
        
        th {
            background: rgba(0, 212, 255, 0.1);
            color: #00d4ff;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            border-bottom: 1px solid rgba(0, 212, 255, 0.3);
        }
        
        td {
            padding: 10px 12px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }
        
        tr:hover { background: rgba(0, 212, 255, 0.05); }
        
        .footer {
            text-align: center;
            color: #666;
            font-size: 0.85em;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        @media (max-width: 768px) {
            .grid-2, .grid-3, .grid-4 { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 SLA Dashboard</h1>
            <p class="subtitle">Foundation Stack — Uptime & Compliance Tracking</p>
            <p class="subtitle">Updated: $updatedAtUtc UTC</p>
        </header>
        
        <!-- KPI Cards -->
        <div class="grid-2">
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Monthly Uptime</div>
                    <div class="metric-value">$([Math]::Round($monthly_uptime, 2))%</div>
                    <div class="status-badge $monthlyStatusClass">
                        $monthlyStatusLabel vs $($MonthlyTarget)%
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: $($monthly_uptime)%"></div>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Weekly Uptime</div>
                    <div class="metric-value">$([Math]::Round($weekly_uptime, 2))%</div>
                    <div class="status-badge $weeklyStatusClass">
                        $weeklyStatusLabel vs $($WeeklyTarget)%
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: $($weekly_uptime)%"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Incident Metrics -->
        <div class="grid-4">
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Total Incidents</div>
                    <div class="metric-value">$($metrics.total_incidents)</div>
                </div>
            </div>
            
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Incidents (30d)</div>
                    <div class="metric-value">$($metrics.incidents_30d)</div>
                </div>
            </div>
            
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Incidents (7d)</div>
                    <div class="metric-value">$($metrics.incidents_7d)</div>
                </div>
            </div>
            
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Avg MTTR</div>
                    <div class="metric-value">$($metrics.mttr_minutes)m</div>
                </div>
            </div>
        </div>

        <div class="grid-3">
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Traffic Light</div>
                    <div class="metric-value">$trafficLight</div>
                </div>
            </div>
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Routing Accuracy</div>
                    <div class="metric-value">$routingAccuracy%</div>
                </div>
            </div>
            <div class="card">
                <div class="metric">
                    <div class="metric-label">Avg Latency</div>
                    <div class="metric-value">$latencyAverage s</div>
                </div>
            </div>
        </div>
        
        <!-- SLO Targets -->
        <div class="card" style="margin-bottom: 30px;">
            <h3 style="color: #00d4ff; margin-bottom: 15px;">SLO Compliance Targets</h3>
            <table>
                <thead>
                    <tr>
                        <th>Metric</th>
                        <th>Target</th>
                        <th>Current</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Monthly Uptime</td>
                        <td>$($MonthlyTarget)%</td>
                        <td>$([Math]::Round($monthly_uptime, 2))%</td>
                        <td><span class="status-badge $monthlyStatusClass">$monthlyStatusLabel</span></td>
                    </tr>
                    <tr>
                        <td>Weekly Uptime</td>
                        <td>$($WeeklyTarget)%</td>
                        <td>$([Math]::Round($weekly_uptime, 2))%</td>
                        <td><span class="status-badge $weeklyStatusClass">$weeklyStatusLabel</span></td>
                    </tr>
                    <tr>
                        <td>Routing Accuracy</td>
                        <td>95%</td>
                        <td>$routingAccuracy%</td>
                        <td><span class="status-badge $(if ($routingAccuracy -ge 95) { 'status-compliant' } else { 'status-warning' })">$(if ($routingAccuracy -ge 95) { 'PASS' } else { 'WARN' })</span></td>
                    </tr>
                    <tr>
                        <td>Average Workflow Latency</td>
                        <td>1.5s</td>
                        <td>$latencyAverage s</td>
                        <td><span class="status-badge $(if ($latencyAverage -le 1.5) { 'status-compliant' } else { 'status-warning' })">$(if ($latencyAverage -le 1.5) { 'PASS' } else { 'WARN' })</span></td>
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>SLA Dashboard — Foundation Stack v1.0</p>
            <p>Generated by <code>sla-dashboard-generator.ps1</code></p>
            <p>For incidents, see: <code>reports/incidents/</code></p>
        </div>
    </div>
</body>
</html>
"@

try {
    Set-Content -Path $OutputPath -Value $html -Force
    Write-Host "[OK] SLA Dashboard generated: $OutputPath" -ForegroundColor Green
    
    if ($Open) {
        Start-Process $OutputPath
        Write-Host "[OK] Opened in default browser" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to generate SLA dashboard: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

exit 0
