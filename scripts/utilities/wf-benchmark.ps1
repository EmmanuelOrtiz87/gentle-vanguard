# gv-benchmark.ps1
# FF-006: Local Workflow Performance - profiles key gv commands and compares
# against SLO thresholds. Emits advisory if any command exceeds its SLO.
#
# SLO defaults (configurable in config/testing.config.json under "benchmark"):
#   status   <=  5 s
#   health   <= 15 s
#   verify   <= 30 s
#
# Usage:
#   pwsh -File scripts/utilities/gv-benchmark.ps1
#   gv benchmark [-AsJson] [-Commands status,health]

param(
    [string[]]$Commands = @('status', 'health'),
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$wfScript  = Join-Path $repoRoot 'scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1'

# --- SLO defaults ------------------------------------------------------------
$sloDefaults = @{
    status = 5
    health = 15
    verify = 30
    'sdd-metrics' = 10
    'sync-drift'  = 10
}

# Try to read custom SLOs from config
$testingConfigPath = Join-Path $repoRoot 'config\testing.config.json'
if (Test-Path $testingConfigPath) {
    try {
        $cfg = Get-Content $testingConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.PSObject.Properties['benchmark'] -and $cfg.benchmark.PSObject.Properties['slo']) {
            foreach ($k in $cfg.benchmark.slo.PSObject.Properties.Name) {
                $sloDefaults[$k] = [int]$cfg.benchmark.slo.$k
            }
        }
    } catch {}
}

if (-not $Commands -or $Commands.Count -eq 0) {
    $Commands = @('status', 'health')
}

# --- Run benchmarks -----------------------------------------------------------
$results = @()
foreach ($cmd in $Commands) {
    $slo = if ($sloDefaults.ContainsKey($cmd)) { $sloDefaults[$cmd] } else { 30 }

    if (-not (Test-Path $wfScript)) {
        $results += [ordered]@{
            command    = $cmd
            elapsed_s  = -1
            slo_s      = $slo
            status     = 'SKIP'
            note       = 'gv.ps1 not found'
        }
        continue
    }

    $elapsedSec = -1
    $exitCode   = -1
    $note       = ''

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $wfScript $cmd *>&1 | Out-Null
        $sw.Stop()
        $exitCode  = $LASTEXITCODE
        $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
    } catch {
        $note = "Error: $_"
    }

    $benchStatus = if ($elapsedSec -lt 0) { 'ERROR' }
                   elseif ($elapsedSec -le $slo) { 'PASS' }
                   elseif ($elapsedSec -le ($slo * 1.5)) { 'WARN' }
                   else { 'FAIL' }

    $results += [ordered]@{
        command    = $cmd
        elapsed_s  = $elapsedSec
        slo_s      = $slo
        status     = $benchStatus
        exit_code  = $exitCode
        note       = $note
    }
}

# --- Persist to reports/ ------------------------------------------------------
$reportsDir = Join-Path $repoRoot 'reports'
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }
$reportPath = Join-Path $reportsDir 'gv-benchmark.json'

$report = [ordered]@{
    as_of   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
    results = $results
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8

if ($AsJson) {
    $report | ConvertTo-Json -Depth 5
    exit 0
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host '=== GV Benchmark ===' -ForegroundColor Cyan
    Write-Host "  Report: $reportPath"
    Write-Host ''
    $colW = @(12, 10, 6, 6, 8)
    Write-Host ('  {0,-12} {1,10} {2,6} {3,6} {4,-8}' -f 'Command','Elapsed(s)','SLO(s)','Exit','Status')
    Write-Host ('  ' + ('-' * 48))
    foreach ($r in $results) {
        $color = switch ($r.status) { 'PASS' { 'Green' } 'WARN' { 'Yellow' } 'FAIL' { 'Red' } default { 'Gray' } }
        $elapsed = if ($r.elapsed_s -ge 0) { '{0:N2}' -f $r.elapsed_s } else { 'n/a' }
        Write-Host ('  {0,-12} {1,10} {2,6} {3,6} {4,-8}' -f $r.command, $elapsed, $r.slo_s, $r.exit_code, $r.status) -ForegroundColor $color
    }
    Write-Host ''
}

$failures = @($results | Where-Object { $_.status -in @('FAIL','ERROR') })
exit ($failures.Count -gt 0 ? 1 : 0)

