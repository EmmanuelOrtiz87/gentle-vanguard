<#
.SYNOPSIS
    Initialize Distributed Tracing for session
    
.DESCRIPTION
    Sets up distributed tracing with correlation IDs, spans, and metrics collection
    
.PARAMETER SessionId
    Session ID to use for tracing
    
.PARAMETER ConfigPath
    Path to distributed tracing configuration
    
.EXAMPLE
    .\initialize-distributed-tracing.ps1 -SessionId "session-2026-04-23-24"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    
    [string]$ConfigPath = "config/distributed-tracing-config.json",
    [string]$TelemetryDir = ".telemetry"
)

# ============================================================================
# LOAD TRACING CORE
# ============================================================================

$tracingCorePath = ".\skills\distributed-tracing-skill\distributed-tracing-core.ps1"

if (-not (Test-Path $tracingCorePath)) {
    Write-Host "[TRACING] ERROR: Distributed tracing core not found: $tracingCorePath" -ForegroundColor Red
    exit 1
}

# Source the tracing core
. $tracingCorePath

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

function Load-TracingConfig {
    param([string]$ConfigPath)
    
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath | ConvertFrom-Json
            return $config.distributedTracing
        }
        catch {
            Write-Host "[TRACING] WARNING: Failed to load config from $ConfigPath, using defaults" -ForegroundColor Yellow
            return $null
        }
    }
    
    return $null
}

# ============================================================================
# INITIALIZATION
# ============================================================================

function Initialize-DistributedTracingSession {
    param(
        [string]$SessionId,
        [string]$TelemetryDir,
        [PSObject]$Config
    )
    
    Write-Host "[TRACING] Initializing Distributed Tracing System..." -ForegroundColor Cyan
    
    # Initialize tracing
    $tracingState = Initialize-DistributedTracing -SessionId $SessionId -TelemetryDir $TelemetryDir
    
    # Store in global scope for access by other scripts
    $global:DistributedTracingState = $tracingState
    
    # Create root span for session
    $sessionSpan = Start-Span -Name "session-initialization" -SpanType "session" -Attributes @{
        SessionId = $SessionId
        Timestamp = Get-Date -Format "o"
        ConfigPath = $ConfigPath
    }
    
    Write-Host "[TRACING] Session tracing initialized successfully" -ForegroundColor Green
    Write-Host "  Telemetry Directory: $TelemetryDir" -ForegroundColor Gray
    Write-Host "  Correlation ID: $($tracingState.CorrelationId)" -ForegroundColor Gray
    
    return @{
        TracingState = $tracingState
        SessionSpan = $sessionSpan
    }
}

# ============================================================================
# MAIN
# ============================================================================

try {
    # Load configuration
    $config = Load-TracingConfig -ConfigPath $ConfigPath
    
    # Initialize tracing
    $result = Initialize-DistributedTracingSession -SessionId $SessionId -TelemetryDir $TelemetryDir -Config $config
    
    # Export initialization data
    $initData = @{
        SessionId = $SessionId
        CorrelationId = $result.TracingState.CorrelationId
        RootSpanId = $result.TracingState.RootSpanId
        TelemetryDir = $TelemetryDir
        InitializationTime = Get-Date -Format "o"
        ConfigPath = $ConfigPath
    }
    
    # Save initialization data
    $initFile = "$TelemetryDir/initialization-$SessionId.json"
    $initData | ConvertTo-Json -Depth 10 | Set-Content -Path $initFile -Encoding UTF8
    
    Write-Host "[TRACING] Initialization data saved to: $initFile" -ForegroundColor Green
    
    # Return success
    exit 0
}
catch {
    Write-Host "[TRACING] ERROR: Failed to initialize distributed tracing: $_" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
    exit 1
}