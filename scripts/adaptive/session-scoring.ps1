param(
    [ValidateSet("record", "report", "init")]
    [string]$Action = "report",
    [string]$EventType = "",
    [string]$Detail = "",
    [switch]$Success = $true,
    [int]$DurationSeconds = 0,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..') | Select-Object -ExpandProperty Path
$loggerModule = Join-Path $scriptDir '..\common\Logger.psm1'
if (Test-Path $loggerModule) { Import-Module $loggerModule -Force }
$metricsPath = Join-Path (Join-Path $repoRoot ".session") "metrics-report.json"
$sessionTokenPath = Join-Path (Join-Path $repoRoot ".session") "token-usage.json"

function Write-Score {
    param([string]$Message)
    if ($VerboseOutput) { Write-Host "[SCORE] $Message" -ForegroundColor Cyan }
    try { Write-Log -Level DEBUG -Message $Message -Component 'session-scoring' } catch {}
}

function Get-MetricsData {
    if (-not (Test-Path $metricsPath)) {
        return @{
            agents = @{}
            summary = @{
            total_delegations = 0
            success_rate = 0
            uptime_seconds = 0
            total_corrections = 0
            total_proactive_suggestions = 0
            total_cloud_calls = 0
            total_checkpoints = 0
            total_tracing_spans = 0
            total_audit_events = 0
            quality_score = 0
        }
            delegations = @{}
            corrections = @()
            proactive_hits = 0
            proactive_misses = 0
            timestamp = (Get-Date -Format 'o')
        }
    }
    return Get-Content $metricsPath -Raw | ConvertFrom-Json -AsHashtable
}

function Save-MetricsData {
    param($Data)
    $Data.timestamp = Get-Date -Format 'o'
    $Data | ConvertTo-Json -Depth 10 | Set-Content $metricsPath
}

function Initialize-Metrics {
    Write-Score "Initializing metrics system..."
    $data = Get-MetricsData
    $data.summary.total_delegations = 0
    $data.summary.success_rate = 100
    $data.summary.quality_score = 100
    $data.summary.total_corrections = 0
    $data.summary.total_proactive_suggestions = 0
    $data.corrections = @()
    $data.proactive_hits = 0
    $data.proactive_misses = 0
    Save-MetricsData $data
    Write-Host "[SCORE] Metrics initialized" -ForegroundColor Green
    Write-Log -Level INFO -Message "Sistema de métricas inicializado" -Component 'session-scoring'
}

function Record-Event {
    param($Type, $Detail, $IsSuccess, $Duration)

    $data = Get-MetricsData
    if (-not $data.summary) { $data.summary = @{} }

    $now = Get-Date -Format 'o'

    # Track by event type
    if (-not $data.delegations.ContainsKey($Type)) {
        $data.delegations[$Type] = @{
            total = 0
            successes = 0
            failures = 0
            avg_duration = 0
            last_event = $null
        }
    }
    $agent = $data.delegations[$Type]
    $agent.total++
    if ($IsSuccess) { $agent.successes++ } else { $agent.failures++ }
    $agent.avg_duration = [Math]::Round(($agent.avg_duration * ($agent.total - 1) + $Duration) / $agent.total)
    $agent.last_event = $now

    # Update summary
    $all = @($data.delegations.Values)
    $data.summary.total_delegations = ($all | ForEach-Object { $_.total } | Measure-Object -Sum).Sum
    $totalSuccess = ($all | ForEach-Object { $_.successes } | Measure-Object -Sum).Sum
    $data.summary.success_rate = if ($data.summary.total_delegations -gt 0) {
        [Math]::Round(($totalSuccess / $data.summary.total_delegations) * 100)
    } else { 100 }

    # Calculate quality score (includes cloud, checkpoint, tracing, audit metrics)
    $correctionPenalty = $data.summary.total_corrections * 5
    $proactiveBonus = $data.proactive_hits * 3
    $failPenalty = ($data.summary.total_delegations - $totalSuccess) * 10
    $cloudBonus = $data.summary.total_cloud_calls * 0.5
    $checkpointBonus = $data.summary.total_checkpoints * 1
    $tracingBonus = $data.summary.total_tracing_spans * 0.3
    $auditBonus = $data.summary.total_audit_events * 0.2
    $rawScore = 100 - $correctionPenalty - $failPenalty + $proactiveBonus + $cloudBonus + $checkpointBonus + $tracingBonus + $auditBonus
    $data.summary.quality_score = [Math]::Max(0, [Math]::Min(100, $rawScore))

    # Estimate uptime from first event to now
    $data.summary.uptime_seconds = 0

    # Track corrections separately
    if ($Type -eq 'correction') {
        $data.summary.total_corrections++
        $corrections = $data.corrections
        if (-not $corrections) { $corrections = @() }
        $corrections += @{
            timestamp = $now
            detail = $Detail
            resolved = $IsSuccess
        }
        $data.corrections = $corrections
    }

    # Track proactive suggestions
    if ($Type -eq 'proactive') {
        $data.summary.total_proactive_suggestions++
        if ($IsSuccess) { $data.proactive_hits++ } else { $data.proactive_misses++ }
    }

    # Track cloud calls
    if ($Type -eq 'cloud') { $data.summary.total_cloud_calls++ }
    # Track checkpoints
    if ($Type -eq 'checkpoint') { $data.summary.total_checkpoints++ }
    # Track tracing spans
    if ($Type -eq 'tracing') { $data.summary.total_tracing_spans++ }
    # Track audit events
    if ($Type -eq 'audit') { $data.summary.total_audit_events++ }

    Save-MetricsData $data
    Write-Score "Recorded $Type (success=$IsSuccess, dur=${Duration}s)"
}

function Get-Report {
    $data = Get-MetricsData
    $summary = $data.summary

    Write-Host "`n=== SESSION SCORING REPORT ===" -ForegroundColor Cyan
    Write-Host "Quality Score: $($summary.quality_score)/100" -ForegroundColor $(if ($summary.quality_score -ge 80) { 'Green' } elseif ($summary.quality_score -ge 50) { 'Yellow' } else { 'Red' })
    Write-Host "Delegations: $($summary.total_delegations) | Success Rate: $($summary.success_rate)%" -ForegroundColor White
    Write-Host "Corrections: $($summary.total_corrections) | Proactive: $($summary.total_proactive_suggestions) (hits: $($data.proactive_hits), misses: $($data.proactive_misses))" -ForegroundColor White
    Write-Host "Cloud: $($summary.total_cloud_calls) | Checkpoints: $($summary.total_checkpoints) | Tracing: $($summary.total_tracing_spans) | Audit: $($summary.total_audit_events)" -ForegroundColor White
    Write-Log -Level INFO -Message "Score calculado: $($summary.quality_score)/100" -Component 'session-scoring' -Data @{qualityScore=$summary.quality_score;delegations=$summary.total_delegations;corrections=$summary.total_corrections;cloudCalls=$summary.total_cloud_calls;checkpoints=$summary.total_checkpoints;tracingSpans=$summary.total_tracing_spans;auditEvents=$summary.total_audit_events;proactiveHits=$data.proactive_hits;proactiveMisses=$data.proactive_misses}

    if ($data.delegations.Count -gt 0) {
        Write-Host "`n--- Per-Type Breakdown ---" -ForegroundColor Yellow
        foreach ($type in $data.delegations.Keys | Sort-Object) {
            $a = $data.delegations[$type]
            $rate = if ($a.total -gt 0) { [Math]::Round(($a.successes / $a.total) * 100) } else { 0 }
            Write-Host "  $type : $($a.total) calls, $rate% success, avg ${($a.avg_duration)}s" -ForegroundColor White
        }
    }

    return $data
}

switch ($Action) {
    'init' { Initialize-Metrics }
    'record' { Record-Event -Type $EventType -Detail $Detail -IsSuccess $Success -Duration $DurationSeconds }
    'report' { $null = Get-Report }
}
