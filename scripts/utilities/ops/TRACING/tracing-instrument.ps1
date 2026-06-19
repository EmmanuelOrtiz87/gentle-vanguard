#Requires -Version 7.0
<#
.SYNOPSIS
    Tracing Instrumentation — Wraps skill/agent execution with OpenTelemetry tracing

.DESCRIPTION
    Sends OTLP spans to the OpenTelemetry Collector for distributed tracing.
    Supports nested spans, error tagging, and correlation ID propagation.
    Integrates with Jaeger (visualization) and Prometheus (metrics).

.NOTES
    Part of Phase 1.3 — Distributed Tracing v4.0
    Requires OpenTelemetry Collector running on localhost:4317
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('start', 'end', 'error', 'export')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$TraceId,

    [Parameter(Mandatory = $false)]
    [string]$SpanId,

    [Parameter(Mandatory = $false)]
    [string]$ParentSpanId,

    [Parameter(Mandatory = $false)]
    [string]$SpanName = 'unnamed',

    [Parameter(Mandatory = $false)]
    [string]$ServiceName = 'gentle-vanguard',

    [Parameter(Mandatory = $false)]
    [hashtable]$Attributes = @{},

    [Parameter(Mandatory = $false)]
    [string]$Status = 'OK',

    [Parameter(Mandatory = $false)]
    [string]$ErrorMessage,

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = '.telemetry/traces/traces.jsonl',

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) } else { Get-Location }
$tracesDir = Join-Path $root '.telemetry' 'traces'
$metricsDir = Join-Path $root '.telemetry' 'metrics'
$spanDir = Join-Path $root '.telemetry' 'spans'

# Ensure directories
foreach ($dir in @($tracesDir, $metricsDir, $spanDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if (-not $Quiet) { Write-Host "[$timestamp] [TRACING] [$Level] $Message" -ForegroundColor Cyan }
}

function New-TraceId {
    return -join ((1..32) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 16) })
}

function New-SpanId {
    return -join ((1..16) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 16) })
}

function Get-Timestamp {
    return [System.Diagnostics.Stopwatch]::GetTimestamp()
}

function Get-TimestampNs {
    $epoch = [DateTime]::UnixEpoch
    return [long](([DateTime]::UtcNow - $epoch).Ticks * 100)
}

function ConvertTo-NanoSeconds {
    param([long]$Ticks)
    return $Ticks * 100
}

function New-SpanEvent {
    param(
        [string]$Name,
        [hashtable]$Attrs = @{},
        [long]$TimestampNs = (Get-TimestampNs)
    )
    return @{
        name       = $Name
        timeUnixNano = $TimestampNs
        attributes = $Attrs.GetEnumerator() | ForEach-Object { @{ key = $_.Key; value = @{ stringValue = $_.Value } } }
    }
}

function New-OtlpSpan {
    param(
        [string]$TraceId,
        [string]$SpanId,
        [string]$ParentSpanId,
        [string]$Name,
        [long]$StartTimeUnixNano,
        [long]$EndTimeUnixNano,
        [string]$StatusCode = 'STATUS_CODE_OK',
        [string]$ErrorMessage,
        [hashtable]$Attributes,
        [array]$Events = @()
    )

    $span = @{
        traceId           = $TraceId
        spanId            = $SpanId
        parentSpanId      = $ParentSpanId
        name              = $Name
        kind              = 2
        startTimeUnixNano = $StartTimeUnixNano
        endTimeUnixNano   = $EndTimeUnixNano
        attributes        = $Attributes.GetEnumerator() | ForEach-Object { @{ key = $_.Key; value = @{ stringValue = $_.Value.ToString() } } }
        events            = $Events
    }

    if ($ErrorMessage) {
        $span.status = @{
            code    = 'STATUS_CODE_ERROR'
            message = $ErrorMessage
        }
    } else {
        $span.status = @{ code = $StatusCode }
    }

    return $span
}

function Export-SpanToFile {
    param([hashtable]$Span)
    $line = $Span | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path (Join-Path $spanDir "spans-$(Get-Date -Format 'yyyyMMdd').jsonl") -Value $line
    Add-Content -Path (Join-Path $tracesDir "traces-$(Get-Date -Format 'yyyyMMdd').jsonl") -Value $line
    Write-Log "Span exported: $($Span.name) [$($Span.spanId)]" 'INFO'
}

function Send-OtlpSpan {
    param([hashtable]$Span)
    try {
        $body = @{
            resourceSpans = @(
                @{
                    resource = @{
                        attributes = @(
                            @{ key = 'service.name'; value = @{ stringValue = $ServiceName } },
                            @{ key = 'deployment.environment'; value = @{ stringValue = 'production' } }
                        )
                    }
                    scopeSpans = @(
                        @{
                            scope = @{ name = 'gentle-vanguard-instrumentation'; version = '1.0.0' }
                            spans = @($Span)
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Method Post -Uri 'http://localhost:4318/v1/traces' `
            -ContentType 'application/json' `
            -Body $body `
            -ErrorAction SilentlyContinue

        if (-not $Quiet) { Write-Log "OTLP export successful" 'SUCCESS' }
    }
    catch {
        Write-Log "OTLP export failed (collector may not be running): $_" 'WARN'
    }
}

function Get-SpanMetricsFile {
    return Join-Path $metricsDir "span-metrics-$(Get-Date -Format 'yyyyMMdd').json"
}

function Record-SpanMetrics {
    param(
        [string]$Name,
        [long]$DurationNs,
        [bool]$IsError
    )
    $metricsFile = Get-SpanMetricsFile
    $metrics = @{ spans = @() }
    if (Test-Path $metricsFile) {
        $metrics = Get-Content $metricsFile -Raw | ConvertFrom-Json
    }
    $metrics.spans += @{
        name       = $Name
        durationNs = $DurationNs
        durationMs = [math]::Round($DurationNs / 1e6, 2)
        isError    = $IsError
        timestamp  = (Get-Date -Format 'o')
    }
    $metrics | ConvertTo-Json -Depth 10 | Set-Content $metricsFile
}

function Get-PrometheusMetrics {
    param([string]$Name, [long]$DurationMs, [bool]$IsError)
    $promFile = Join-Path $metricsDir 'prometheus-metrics.prom'
    $timestamp = [long](([DateTime]::UtcNow - [DateTime]::UnixEpoch).TotalSeconds)
    @"
# HELP gentle_vanguard_span_duration_ms Span duration in milliseconds
# TYPE gentle_vanguard_span_duration_ms gauge
gentle_vanguard_span_duration_ms{span="$Name",service="$ServiceName"} $DurationMs $timestamp
# HELP gentle_vanguard_span_total Total spans count
# TYPE gentle_vanguard_span_total counter
gentle_vanguard_span_total{span="$Name",service="$ServiceName",status="$($(if($IsError){'error'}else{'ok'}))"} 1 $timestamp
"@ | Add-Content $promFile
}

# ===== MAIN =====

switch ($Action) {
    'start' {
        $tid = if ($TraceId) { $TraceId } else { New-TraceId }
        $sid = if ($SpanId) { $SpanId } else { New-SpanId }
        $startNs = Get-TimestampNs

        $span = New-OtlpSpan -TraceId $tid -SpanId $sid -ParentSpanId $ParentSpanId -Name $SpanName `
            -StartTimeUnixNano $startNs -EndTimeUnixNano $startNs -Attributes $Attributes

        Export-SpanToFile -Span $span

        return @{
            traceId   = $tid
            spanId    = $sid
            startNs   = $startNs
            parentSpanId = $ParentSpanId
        }
    }

    'end' {
        if (-not $TraceId -or -not $SpanId) { throw 'TraceId and SpanId required for end action' }

        $endNs = Get-TimestampNs
        $startNs = [long]$Attributes['startTimeUnixNano']
        $durationNs = $endNs - $startNs
        $durationMs = [math]::Round($durationNs / 1e6, 2)

        $span = New-OtlpSpan -TraceId $TraceId -SpanId $SpanId -ParentSpanId $ParentSpanId -Name $SpanName `
            -StartTimeUnixNano $startNs -EndTimeUnixNano $endNs -Attributes $Attributes

        Export-SpanToFile -Span $span
        Send-OtlpSpan -Span $span
        Record-SpanMetrics -Name $SpanName -DurationNs $durationNs -IsError $false
        Get-PrometheusMetrics -Name $SpanName -DurationMs $durationMs -IsError $false

        Write-Log "Span completed: $SpanName (${durationMs}ms)" 'SUCCESS'
        return @{ traceId = $TraceId; spanId = $SpanId; durationMs = $durationMs }
    }

    'error' {
        if (-not $TraceId -or -not $SpanId) { throw 'TraceId and SpanId required for error action' }

        $endNs = Get-TimestampNs
        $startNs = [long]$Attributes['startTimeUnixNano']
        $durationNs = $endNs - $startNs
        $durationMs = [math]::Round($durationNs / 1e6, 2)

        $span = New-OtlpSpan -TraceId $TraceId -SpanId $SpanId -ParentSpanId $ParentSpanId -Name $SpanName `
            -StartTimeUnixNano $startNs -EndTimeUnixNano $endNs -Attributes $Attributes `
            -StatusCode 'STATUS_CODE_ERROR' -ErrorMessage $ErrorMessage

        Export-SpanToFile -Span $span
        Send-OtlpSpan -Span $span
        Record-SpanMetrics -Name $SpanName -DurationNs $durationNs -IsError $true
        Get-PrometheusMetrics -Name $SpanName -DurationMs $durationMs -IsError $true

        Write-Log "Span errored: $SpanName — $ErrorMessage" 'ERROR'
        return @{ traceId = $TraceId; spanId = $SpanId; durationMs = $durationMs; error = $ErrorMessage }
    }

    'export' {
        Write-Log "Exporting all pending spans to OTLP..." 'INFO'
        $spanFiles = Get-ChildItem -Path $spanDir -Filter '*.jsonl' | Sort-Object LastWriteTime -Descending
        $exported = 0
        foreach ($file in $spanFiles) {
            $lines = Get-Content $file.FullName
            foreach ($line in $lines) {
                try {
                    $span = $line | ConvertFrom-Json
                    Send-OtlpSpan -Span $span
                    $exported++
                }
                catch {
                    Write-Log "Failed to export span from $($file.Name): $_" 'WARN'
                }
            }
        }
        Write-Log "Exported $exported spans to OTLP collector" 'SUCCESS'
        return @{ exported = $exported }
    }
}
