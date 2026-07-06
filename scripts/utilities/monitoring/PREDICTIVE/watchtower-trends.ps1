<#
.SYNOPSIS
    Watchtower predictive monitoring with time-series storage and trend analysis.
.DESCRIPTION
    Records health check results to time-series storage, analyzes trends,
    predicts failures, and generates reports.
.PARAMETER Action
    record: Record current health check results
    trend: Analyze trends over time
    predict: Predict likely failures
    report: Generate full report
.PARAMETER HistoryDays
    How many days of history to analyze. Default: 30.
.PARAMETER Quiet
    Suppress output.
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('record','trend','predict','report')]
    [string]$Action,
    [int]$HistoryDays = 30,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$root = Split-Path -Parent $root
$telemetryDir = Join-Path $root '.telemetry'
$historyFile = Join-Path $telemetryDir 'watchtower-history.jsonl'
$watchtowerScript = Join-Path $root 'scripts\maintenance\maintenance-watchtower.ps1'

if (-not (Test-Path $telemetryDir)) {
    New-Item -ItemType Directory -Path $telemetryDir -Force | Out-Null
}

function Get-History {
    param([int]$Days = 30)
    if (-not (Test-Path $historyFile)) { return @() }
    $cutoff = (Get-Date).AddDays(-$Days)
    $entries = @()
    Get-Content $historyFile | ForEach-Object {
        try {
            $entry = $_ | ConvertFrom-Json
            $ts = [DateTime]::Parse($entry.ts)
            if ($ts -ge $cutoff) { $entries += $entry }
        } catch { }
    }
    return $entries
}

switch ($Action) {
    'record' {
        if (-not $Quiet) { Write-Host "[WT] Recording health check..." -ForegroundColor Cyan }

        # Run health check and capture output
        $output = & $watchtowerScript -Action health 2>&1 | Out-String

        # Parse pass/warn/fail counts
        $pass = 0; $warn = 0; $fail = 0; $skip = 0
        if ($output -match 'PASS:\s*(\d+)') { $pass = [int]$Matches[1] }
        if ($output -match 'WARN:\s*(\d+)') { $warn = [int]$Matches[1] }
        if ($output -match 'FAIL:\s*(\d+)') { $fail = [int]$Matches[1] }
        if ($output -match 'SKIP:\s*(\d+)') { $skip = [int]$Matches[1] }

        # Parse component statuses
        $components = @{}
        $componentLines = $output | Select-String -Pattern '^\s+(\S+):\s+(PASS|WARN|FAIL|SKIP|OK)$' -AllMatches
        foreach ($match in $componentLines.Matches) {
            $name = $match.Groups[1].Value
            $status = $match.Groups[2].Value
            if ($status -eq 'OK') { $status = 'PASS' }
            $components[$name] = $status.ToLower()
        }

        $entry = @{
            ts = (Get-Date).ToString('o')
            pass = $pass
            warn = $warn
            fail = $fail
            skip = $skip
            total = $pass + $warn + $fail + $skip
            components = $components
        }

        $entry | ConvertTo-Json -Compress -Depth 5 | Out-File -Append -FilePath $historyFile -Encoding UTF8

        # Prune old entries (keep 30 days)
        $entries = Get-History -Days 30
        $entries | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 5 } | Out-File -FilePath $historyFile -Encoding UTF8

        if (-not $Quiet) {
            Write-Host "[WT] Recorded: $pass PASS / $warn WARN / $fail FAIL / $skip SKIP" -ForegroundColor Green
            Write-Host "[WT] Components tracked: $($components.Count)" -ForegroundColor Gray
        }
    }

    'trend' {
        $entries = Get-History -Days $HistoryDays
        if ($entries.Count -eq 0) {
            if (-not $Quiet) { Write-Host "[WT] No history data found. Run 'record' first." -ForegroundColor Yellow }
            exit 0
        }

        if (-not $Quiet) {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " [WT] Watchtower Trends (last $HistoryDays days)" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host " Data points: $($entries.Count)" -ForegroundColor Gray
            Write-Host ""
        }

        # Get all component names
        $allComponents = @{}
        foreach ($e in $entries) {
            if ($e.components) {
                foreach ($key in $e.components.PSObject.Properties.Name) {
                    $allComponents[$key] = $true
                }
            }
        }

        $trends = @{}
        foreach ($comp in $allComponents.Keys) {
            $passCount = 0
            $failCount = 0
            $totalChecks = 0
            $recentPass = 0
            $recentTotal = 0
            $olderPass = 0
            $olderTotal = 0
            $midpoint = $entries.Count / 2

            for ($i = 0; $i -lt $entries.Count; $i++) {
                $e = $entries[$i]
                $status = $e.components.$comp
                if ($status) {
                    $totalChecks++
                    if ($status -eq 'pass') { $passCount++ }
                    else { $failCount++ }

                    if ($i -ge $midpoint) {
                        $recentTotal++
                        if ($status -eq 'pass') { $recentPass++ }
                    } else {
                        $olderTotal++
                        if ($status -eq 'pass') { $olderPass++ }
                    }
                }
            }

            $passRate = if ($totalChecks -gt 0) { [math]::Round(($passCount / $totalChecks) * 100, 1) } else { 100 }
            $recentRate = if ($recentTotal -gt 0) { [math]::Round(($recentPass / $recentTotal) * 100, 1) } else { 100 }
            $olderRate = if ($olderTotal -gt 0) { [math]::Round(($olderPass / $olderTotal) * 100, 1) } else { 100 }

            $trend = 'stable'
            if ($recentRate -lt $olderRate - 5) { $trend = 'degrading' }
            elseif ($recentRate -gt $olderRate + 5) { $trend = 'improving' }

            $trends[$comp] = @{
                passRate = $passRate
                failCount = $failCount
                recentRate = $recentRate
                trend = $trend
            }

            if (-not $Quiet) {
                $color = if ($trend -eq 'degrading') { 'Red' } elseif ($trend -eq 'improving') { 'Green' } else { 'Gray' }
                $icon = if ($trend -eq 'degrading') { '!!' } elseif ($trend -eq 'improving') { '++' } else { '--' }
                Write-Host (" $icon {0,-20} pass={1,5}%  recent={2,5}%  fails={3,2}  [{4}]" -f $comp, $passRate, $recentRate, $failCount, $trend) -ForegroundColor $color
            }
        }

        if (-not $Quiet) { Write-Host "" }

        # Output JSON for programmatic use
        $trends | ConvertTo-Json -Depth 3
    }

    'predict' {
        $entries = Get-History -Days $HistoryDays
        if ($entries.Count -lt 3) {
            if (-not $Quiet) { Write-Host "[WT] Need at least 3 data points for prediction. Run 'record' multiple times." -ForegroundColor Yellow }
            exit 0
        }

        if (-not $Quiet) {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Magenta
            Write-Host " [WT] Failure Predictions" -ForegroundColor Magenta
            Write-Host "============================================" -ForegroundColor Magenta
            Write-Host ""
        }

        $allComponents = @{}
        foreach ($e in $entries) {
            if ($e.components) {
                foreach ($key in $e.components.PSObject.Properties.Name) {
                    $allComponents[$key] = $true
                }
            }
        }

        $predictions = @{}
        foreach ($comp in $allComponents.Keys) {
            $failTimestamps = @()
            for ($i = 0; $i -lt $entries.Count; $i++) {
                $status = $entries[$i].components.$comp
                if ($status -and $status -ne 'pass') {
                    $failTimestamps += [DateTime]::Parse($entries[$i].ts)
                }
            }

            $riskScore = 0
            $mtbf = $null
            $estimatedFailIn = $null

            if ($failTimestamps.Count -ge 2) {
                # Calculate MTBF
                $intervals = @()
                for ($i = 1; $i -lt $failTimestamps.Count; $i++) {
                    $intervals += ($failTimestamps[$i] - $failTimestamps[$i-1]).TotalHours
                }
                $mtbf = [math]::Round(($intervals | Measure-Object -Average).Average, 1)

                # Estimate next failure
                $lastFail = $failTimestamps[-1]
                $estimatedFailIn = [math]::Round($mtbf - ((Get-Date) - $lastFail).TotalHours, 1)

                # Risk score (0-100)
                $totalChecks = $entries.Count
                $failRate = $failTimestamps.Count / $totalChecks
                $riskScore = [math]::Min(100, [math]::Round($failRate * 200 + ($mtbf -lt 24 ? 20 : 0)))
            } elseif ($failTimestamps.Count -eq 1) {
                $riskScore = 15
            }

            $predictions[$comp] = @{
                failCount = $failTimestamps.Count
                mtbf = $mtbf
                estimatedHoursUntilFail = $estimatedFailIn
                riskScore = $riskScore
            }

            if (-not $Quiet) {
                $color = if ($riskScore -ge 50) { 'Red' } elseif ($riskScore -ge 25) { 'Yellow' } else { 'Green' }
                $status = if ($riskScore -ge 50) { 'HIGH' } elseif ($riskScore -ge 25) { 'MED' } else { 'LOW' }
                $mtbfStr = if ($mtbf) { "${mtbf}h" } else { "N/A" }
                $etaStr = if ($estimatedFailIn -and $estimatedFailIn -gt 0) { "${estimatedFailIn}h" } elseif ($estimatedFailIn -le 0) { "OVERDUE" } else { "N/A" }
                Write-Host (" [{0}] {1,-20} risk={2,3}/100  MTBF={3,6}  ETA={4}" -f $status, $comp, $riskScore, $mtbfStr, $etaStr) -ForegroundColor $color
            }
        }

        if (-not $Quiet) { Write-Host "" }
        $predictions | ConvertTo-Json -Depth 3
    }

    'report' {
        if (-not $Quiet) {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor White
            Write-Host " [WT] Watchtower Predictive Report" -ForegroundColor White
            Write-Host " Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
            Write-Host "============================================" -ForegroundColor White
            Write-Host ""
        }

        # Latest health
        $latest = Get-History -Days 1
        if ($latest.Count -gt 0) {
            $l = $latest[-1]
            if (-not $Quiet) {
                Write-Host " LATEST CHECK:" -ForegroundColor Cyan
                Write-Host "   PASS: $($l.pass) | WARN: $($l.warn) | FAIL: $($l.fail) | SKIP: $($l.skip)" -ForegroundColor Gray
                Write-Host ""
            }
        }

        # Trends
        if (-not $Quiet) { Write-Host " TRENDS:" -ForegroundColor Cyan }
        & $PSCommandPath -Action trend -HistoryDays $HistoryDays -Quiet:$Quiet

        # Predictions
        if (-not $Quiet) { Write-Host " PREDICTIONS:" -ForegroundColor Cyan }
        & $PSCommandPath -Action predict -HistoryDays $HistoryDays -Quiet:$Quiet

        if (-not $Quiet) { Write-Host "" }
    }
}
