<#
.SYNOPSIS
    Distributed Tracing Core - OpenTelemetry-compatible tracing system
    
.DESCRIPTION
    Provides distributed tracing capabilities with:
    - Correlation IDs for operation tracking
    - Span hierarchy for operation relationships
    - Performance metrics collection
    - Centralized telemetry reporting
    
.NOTES
    Author: foundation
    Version: 1.0
#>

# ============================================================================
# GLOBAL STATE
# ============================================================================

$script:TracingState = @{
    Enabled = $true
    SessionId = $null
    CorrelationId = $null
    RootSpanId = $null
    ActiveSpans = @{}
    Metrics = @{}
    TelemetryDir = ".telemetry"
    StartTime = Get-Date
}

# ============================================================================
# INITIALIZATION
# ============================================================================

function Initialize-DistributedTracing {
    <#
    .SYNOPSIS
        Initialize distributed tracing for a session
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        
        [string]$TelemetryDir = ".telemetry"
    )
    
    $script:TracingState.SessionId = $SessionId
    $script:TracingState.CorrelationId = Generate-CorrelationId -SessionId $SessionId
    $script:TracingState.TelemetryDir = $TelemetryDir
    
    # Create telemetry directory structure
    Create-TelemetryDirectories -BasePath $TelemetryDir
    
    # Initialize root span
    $rootSpan = Start-Span -Name "session-root" -SpanType "session" -Attributes @{
        SessionId = $SessionId
        CorrelationId = $script:TracingState.CorrelationId
        StartTime = (Get-Date -Format "o")
    }
    
    $script:TracingState.RootSpanId = $rootSpan.SpanId
    
    Write-Host "[TRACING] Distributed tracing initialized" -ForegroundColor Cyan
    Write-Host "  Session ID: $SessionId" -ForegroundColor Gray
    Write-Host "  Correlation ID: $($script:TracingState.CorrelationId)" -ForegroundColor Gray
    Write-Host "  Root Span ID: $($rootSpan.SpanId)" -ForegroundColor Gray
    
    return $script:TracingState
}

function Create-TelemetryDirectories {
    <#
    .SYNOPSIS
        Create telemetry directory structure
    #>
    param(
        [string]$BasePath = ".telemetry"
    )
    
    $directories = @(
        $BasePath,
        "$BasePath/traces",
        "$BasePath/metrics",
        "$BasePath/reports",
        "$BasePath/spans",
        "$BasePath/events"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

# ============================================================================
# CORRELATION ID MANAGEMENT
# ============================================================================

function Generate-CorrelationId {
    <#
    .SYNOPSIS
        Generate a unique correlation ID
    #>
    param(
        [string]$SessionId
    )
    
    $guid = [guid]::NewGuid().ToString().Substring(0, 8)
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    
    return "$SessionId-$timestamp-$guid"
}

function Get-CorrelationId {
    <#
    .SYNOPSIS
        Get current correlation ID
    #>
    return $script:TracingState.CorrelationId
}

function Get-SessionId {
    <#
    .SYNOPSIS
        Get current session ID
    #>
    return $script:TracingState.SessionId
}

# ============================================================================
# SPAN MANAGEMENT
# ============================================================================

function Start-Span {
    <#
    .SYNOPSIS
        Start a new span
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [string]$SpanType = "operation",
        [string]$ParentSpanId = $null,
        [hashtable]$Attributes = @{},
        [string]$CorrelationId = $null
    )
    
    if (-not $CorrelationId) {
        $CorrelationId = $script:TracingState.CorrelationId
    }
    
    $spanId = [guid]::NewGuid().ToString().Substring(0, 16)
    $traceId = $script:TracingState.CorrelationId
    
    $span = @{
        SpanId = $spanId
        TraceId = $traceId
        CorrelationId = $CorrelationId
        Name = $Name
        SpanType = $SpanType
        ParentSpanId = $ParentSpanId
        StartTime = Get-Date
        EndTime = $null
        Status = "active"
        Attributes = $Attributes
        Events = @()
        Metrics = @{}
        Duration = $null
    }
    
    $script:TracingState.ActiveSpans[$spanId] = $span
    
    Write-Verbose "[SPAN] Started: $Name (ID: $spanId)"
    
    return $span
}

function End-Span {
    <#
    .SYNOPSIS
        End a span and record its metrics
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span,
        
        [ValidateSet("success", "error", "cancelled")]
        [string]$Status = "success",
        
        [string]$ErrorMessage = $null
    )
    
    $Span.EndTime = Get-Date
    $Span.Status = $Status
    $Span.Duration = ($Span.EndTime - $Span.StartTime).TotalMilliseconds
    
    if ($ErrorMessage) {
        $Span.ErrorMessage = $ErrorMessage
    }
    
    # Record span to file
    Export-Span -Span $Span
    
    # Record metric
    Record-Metric -Name "span-duration" -Value $Span.Duration -Unit "ms" -Tags @{
        SpanName = $Span.Name
        SpanType = $Span.SpanType
        Status = $Status
    }
    
    Write-Verbose "[SPAN] Ended: $($Span.Name) (Duration: $($Span.Duration)ms, Status: $Status)"
    
    return $Span
}

function Add-SpanEvent {
    <#
    .SYNOPSIS
        Add an event to a span
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span,
        
        [Parameter(Mandatory = $true)]
        [string]$EventName,
        
        [hashtable]$Attributes = @{}
    )
    
    $event = @{
        Name = $EventName
        Timestamp = Get-Date
        Attributes = $Attributes
    }
    
    $Span.Events += $event
    
    Write-Verbose "[SPAN-EVENT] $EventName on span $($Span.SpanId)"
}

function Add-SpanMetric {
    <#
    .SYNOPSIS
        Add a metric to a span
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span,
        
        [Parameter(Mandatory = $true)]
        [string]$MetricName,
        
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [string]$Unit = ""
    )
    
    if (-not $Span.Metrics[$MetricName]) {
        $Span.Metrics[$MetricName] = @()
    }
    
    $Span.Metrics[$MetricName] += @{
        Value = $Value
        Unit = $Unit
        Timestamp = Get-Date
    }
}

# ============================================================================
# METRICS COLLECTION
# ============================================================================

function Record-Metric {
    <#
    .SYNOPSIS
        Record a performance metric
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [double]$Value,
        
        [string]$Unit = "",
        [hashtable]$Tags = @{}
    )
    
    if (-not $script:TracingState.Metrics[$Name]) {
        $script:TracingState.Metrics[$Name] = @()
    }
    
    $metric = @{
        Name = $Name
        Value = $Value
        Unit = $Unit
        Timestamp = Get-Date
        Tags = $Tags
        CorrelationId = $script:TracingState.CorrelationId
    }
    
    $script:TracingState.Metrics[$Name] += $metric
    
    Write-Verbose "[METRIC] $Name = $Value $Unit"
}

function Get-Metrics {
    <#
    .SYNOPSIS
        Get all recorded metrics
    #>
    param(
        [string]$MetricName = $null
    )
    
    if ($MetricName) {
        return $script:TracingState.Metrics[$MetricName]
    }
    
    return $script:TracingState.Metrics
}

# ============================================================================
# EXPORT & PERSISTENCE
# ============================================================================

function Export-Span {
    <#
    .SYNOPSIS
        Export a span to file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span
    )
    
    $date = Get-Date -Format "yyyy-MM-dd"
    $spanType = $Span.SpanType
    $tracesDir = "$($script:TracingState.TelemetryDir)/traces"
    
    $filename = "$tracesDir/$($spanType)-traces-$date.jsonl"
    
    $spanJson = $Span | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path $filename -Value $spanJson -Encoding UTF8
}

function Export-Metrics {
    <#
    .SYNOPSIS
        Export all metrics to file
    #>
    param(
        [string]$OutputPath = $null
    )
    
    if (-not $OutputPath) {
        $OutputPath = "$($script:TracingState.TelemetryDir)/metrics"
    }
    
    $date = Get-Date -Format "yyyy-MM-dd"
    $filename = "$OutputPath/metrics-$date.json"
    
    $metricsData = @{
        SessionId = $script:TracingState.SessionId
        CorrelationId = $script:TracingState.CorrelationId
        ExportTime = Get-Date -Format "o"
        Metrics = $script:TracingState.Metrics
    }
    
    $metricsData | ConvertTo-Json -Depth 10 | Set-Content -Path $filename -Encoding UTF8
    
    Write-Host "[TRACING] Metrics exported to $filename" -ForegroundColor Green
}

function Export-AllSpans {
    <#
    .SYNOPSIS
        Export all active spans
    #>
    param(
        [string]$OutputPath = $null
    )
    
    if (-not $OutputPath) {
        $OutputPath = "$($script:TracingState.TelemetryDir)/spans"
    }
    
    $date = Get-Date -Format "yyyy-MM-dd"
    $filename = "$OutputPath/spans-$date.json"
    
    $spansData = @{
        SessionId = $script:TracingState.SessionId
        CorrelationId = $script:TracingState.CorrelationId
        ExportTime = Get-Date -Format "o"
        Spans = $script:TracingState.ActiveSpans.Values
    }
    
    $spansData | ConvertTo-Json -Depth 10 | Set-Content -Path $filename -Encoding UTF8
    
    Write-Host "[TRACING] Spans exported to $filename" -ForegroundColor Green
}

# ============================================================================
# REPORTING
# ============================================================================

function Get-TracingSummary {
    <#
    .SYNOPSIS
        Get summary of tracing data
    #>
    
    $summary = @{
        SessionId = $script:TracingState.SessionId
        CorrelationId = $script:TracingState.CorrelationId
        RootSpanId = $script:TracingState.RootSpanId
        TotalSpans = $script:TracingState.ActiveSpans.Count
        TotalMetrics = ($script:TracingState.Metrics.Values | Measure-Object -Sum).Count
        SessionDuration = ((Get-Date) - $script:TracingState.StartTime).TotalSeconds
        ActiveSpans = @($script:TracingState.ActiveSpans.Values | Where-Object { $_.Status -eq "active" }).Count
    }
    
    return $summary
}

function Show-TracingSummary {
    <#
    .SYNOPSIS
        Display tracing summary
    #>
    
    $summary = Get-TracingSummary
    
    Write-Host "`n=== Distributed Tracing Summary ===" -ForegroundColor Cyan
    Write-Host "Session ID: $($summary.SessionId)" -ForegroundColor Gray
    Write-Host "Correlation ID: $($summary.CorrelationId)" -ForegroundColor Gray
    Write-Host "Total Spans: $($summary.TotalSpans)" -ForegroundColor Gray
    Write-Host "Total Metrics: $($summary.TotalMetrics)" -ForegroundColor Gray
    Write-Host "Session Duration: $($summary.SessionDuration)s" -ForegroundColor Gray
    Write-Host "Active Spans: $($summary.ActiveSpans)" -ForegroundColor Gray
    Write-Host "===================================`n" -ForegroundColor Cyan
}

# ============================================================================
# CLEANUP
# ============================================================================

function Finalize-DistributedTracing {
    <#
    .SYNOPSIS
        Finalize tracing and export all data
    #>
    
    # End root span
    if ($script:TracingState.RootSpanId -and $script:TracingState.ActiveSpans[$script:TracingState.RootSpanId]) {
        End-Span -Span $script:TracingState.ActiveSpans[$script:TracingState.RootSpanId] -Status "success"
    }
    
    # Export all data
    Export-AllSpans
    Export-Metrics
    
    Show-TracingSummary
    
    Write-Host "[TRACING] Distributed tracing finalized" -ForegroundColor Green
}

# Export functions (only if running as module)
if ($MyInvocation.MyCommand.Module) {
    Export-ModuleMember -Function @(
        'Initialize-DistributedTracing',
        'Generate-CorrelationId',
        'Get-CorrelationId',
         'Get-SessionId',
         'Start-Span',
         'End-Span',
         'Add-SpanEvent',
         'Add-SpanMetric',
         'Record-Metric',
         'Get-Metrics',
         'Export-Span',
         'Export-Metrics',
         'Export-AllSpans',
         'Get-TracingSummary',
         'Show-TracingSummary',
         'Finalize-DistributedTracing'
     )
 }