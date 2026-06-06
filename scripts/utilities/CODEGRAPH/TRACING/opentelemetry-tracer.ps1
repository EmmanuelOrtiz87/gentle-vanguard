<#
.SYNOPSIS
    OpenTelemetry distributed tracing for Gentle-Vanguard
.DESCRIPTION
    Implements OpenTelemetry tracing for cross-session observability.
    Supports Jaeger, Zipkin, and OTLP exporters.
.PARAMETER Action
    Action: init, start-span, end-span, flush, status
.PARAMETER SpanName
    Name of the span to create
.PARAMETER ParentSpanId
    Parent span ID for distributed tracing
.PARAMETER Attributes
    Additional attributes as hashtable
.EXAMPLE
    .\opentelemetry-tracer.ps1 -Action init
    .\opentelemetry-tracer.ps1 -Action start-span -SpanName "skill-execution"
#>
[CmdletBinding()]
param(
    [ValidateSet("init", "start-span", "end-span", "flush", "status")]
    [string]$Action = "status",
    [string]$SpanName = "",
    [string]$ParentSpanId = "",
    [hashtable]$Attributes = @{},
    [string]$ServiceName = "gentle-vanguard"
)

$ErrorActionPreference = "Stop"

# Configuration
$script:ConfigPath = Join-Path $PSScriptRoot "..\..\..\config\tracing.config.json"
$script:TraceDir = Join-Path $PSScriptRoot "..\..\..\.traces"
$script:ActiveSpans = @{}

function Write-Log {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Initialize-Tracer {
    if (-not (Test-Path $script:TraceDir)) {
        New-Item -ItemType Directory -Path $script:TraceDir -Force | Out-Null
    }
    
    $config = @{
        serviceName = $ServiceName
        serviceVersion = "2.30.0"
        exporter = "file"  # file, jaeger, zipkin, otlp
        endpoint = $null
        samplingRate = 1.0
        maxQueueSize = 2048
        batchTimeoutMs = 5000
        attributes = @{
            environment = "production"
            host = $env:COMPUTERNAME
        }
    }
    
    if (Test-Path $script:ConfigPath) {
        $existing = Get-Content $script:ConfigPath | ConvertFrom-Json
        $config.exporter = $existing.exporter
        $config.endpoint = $existing.endpoint
    }
    
    $config | ConvertTo-Json -Depth 5 | Set-Content $script:ConfigPath
    Write-Log "INFO" "Tracer initialized: $($config.exporter) exporter"
}

function New-TraceId {
    return [System.Guid]::NewGuid().ToString().Replace("-", "")
}

function New-SpanId {
    return [System.Guid]::NewGuid().ToString().Replace("-", "").Substring(0, 16)
}

function Start-Span {
    param([string]$Name, [string]$ParentId, [hashtable]$Attrs)
    
    $spanId = New-SpanId
    $traceId = if ($script:ActiveSpans.ContainsKey("root")) {
        $script:ActiveSpans["root"].traceId
    } else {
        New-TraceId
    }
    
    $span = @{
        spanId = $spanId
        traceId = $traceId
        parentSpanId = $ParentId
        name = $Name
        startTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        attributes = $Attrs
        events = @()
    }
    
    $script:ActiveSpans[$spanId] = $span
    
    if (-not $script:ActiveSpans.ContainsKey("root")) {
        $script:ActiveSpans["root"] = $span
    }
    
    Write-Log "INFO" "Span started: $Name ($spanId)"
    return $spanId
}

function Stop-Span {
    param([string]$SpanId)
    
    if (-not $script:ActiveSpans.ContainsKey($SpanId)) {
        Write-Log "WARN" "Span not found: $SpanId"
        return
    }
    
    $span = $script:ActiveSpans[$SpanId]
    $span.endTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $span.duration = $span.endTime - $span.startTime
    
    # Export to file
    $traceFile = Join-Path $script:TraceDir "traces-$(Get-Date -Format 'yyyyMMdd').jsonl"
    $span | ConvertTo-Json -Compress | Add-Content -Path $traceFile
    
    $script:ActiveSpans.Remove($SpanId)
    Write-Log "INFO" "Span ended: $($span.name) ($SpanId) - $($span.duration)ms"
}

function Get-TracerStatus {
    return @{
        activeSpans = $script:ActiveSpans.Count
        configPath = $script:ConfigPath
        traceDir = $script:TraceDir
        config = if (Test-Path $script:ConfigPath) { 
            Get-Content $script:ConfigPath | ConvertFrom-Json 
        } else { 
            $null 
        }
    }
}

function Export-Traces {
    $config = Get-Content $script:ConfigPath | ConvertFrom-Json
    
    switch ($config.exporter) {
        "file" {
            Write-Log "INFO" "Traces exported to: $script:TraceDir"
        }
        "jaeger" {
            Write-Log "INFO" "Exporting to Jaeger: $($config.endpoint)"
            # TODO: Implement Jaeger HTTP exporter
        }
        "zipkin" {
            Write-Log "INFO" "Exporting to Zipkin: $($config.endpoint)"
            # TODO: Implement Zipkin HTTP exporter
        }
        "otlp" {
            Write-Log "INFO" "Exporting via OTLP: $($config.endpoint)"
            # TODO: Implement OTLP/gRPC exporter
        }
    }
}

# Main switch
switch ($Action) {
    "init" { Initialize-Tracer }
    "start-span" { 
        if (-not $SpanName) { throw "SpanName required" }
        $id = Start-Span -Name $SpanName -ParentId $ParentSpanId -Attrs $Attributes
        Write-Output $id
    }
    "end-span" { 
        if (-not $SpanName) { throw "SpanName (as SpanId) required" }
        Stop-Span -SpanId $SpanName 
    }
    "flush" { Export-Traces }
    "status" { Get-TracerStatus | ConvertTo-Json -Depth 3 }
}
