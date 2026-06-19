#Requires -Version 7.0
<#
.SYNOPSIS
    Hybrid Cloud Executor — Route skill execution between AWS and Azure

.DESCRIPTION
    Chooses the best cloud provider by cost, latency or load and invokes the
    corresponding delegator script. Includes fallback routing and metrics.

.NOTES
    Part of Cloud Integration Phase v4.0
#>

param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Execute')]
    [string]$SkillId,

    [Parameter(Mandatory = $true, ParameterSetName = 'Execute')]
    [object]$SkillInput,

    [Parameter(Mandatory = $false)]
    [ValidateSet('RequestResponse', 'Event', 'DryRun')]
    [string]$InvocationType = 'RequestResponse',

    [Parameter(Mandatory = $false)]
    [ValidateSet('auto', 'AWS', 'Azure')]
    [string]$PreferredProvider = 'auto',

    [Parameter(Mandatory = $false)]
    [ValidateSet('cost', 'latency', 'load')]
    [string]$RoutingStrategy = 'cost',

    [Parameter(Mandatory = $false)]
    [string]$AwsRegion = 'us-east-1',

    [Parameter(Mandatory = $false)]
    [string]$AzureFunctionUrl = $env:AZURE_FUNCTION_URL,

    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3,

    [Parameter(Mandatory = $false)]
    [switch]$RecordMetrics,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$script:SkillInputJson = if ($SkillInput -is [hashtable] -or $SkillInput -is [PSCustomObject]) { $SkillInput | ConvertTo-Json -Compress } else { "$SkillInput" }

function Write-Log {
    param([string]$Message, [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')][string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = @{'INFO' = 'Cyan'; 'WARN' = 'Yellow'; 'ERROR' = 'Red'; 'SUCCESS' = 'Green'}[$Level]
    if (-not $Quiet) { Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color }
    Add-Content -Path "$root/.session/hybrid-executor.log" -Value "[$timestamp] [$Level] $Message" -ErrorAction SilentlyContinue
}

function Get-ProviderCatalog {
    return @(
        @{ provider = 'AWS'; cost = [double]($env:AWS_ESTIMATED_COST ?? 0.0000167); latency = [int]($env:AWS_ESTIMATED_LATENCY_MS ?? 45); load = [double]($env:AWS_CURRENT_LOAD ?? 0.7); capacity = 1000; reliability = 0.99 },
        @{ provider = 'Azure'; cost = [double]($env:AZURE_ESTIMATED_COST ?? 0.00002); latency = [int]($env:AZURE_ESTIMATED_LATENCY_MS ?? 60); load = [double]($env:AZURE_CURRENT_LOAD ?? 0.5); capacity = 500; reliability = 0.985 }
    )
}

function Select-Provider {
    param([array]$Providers)

    if ($PreferredProvider -ne 'auto') {
        return $Providers | Where-Object { $_.provider -eq $PreferredProvider } | Select-Object -First 1
    }

    switch ($RoutingStrategy) {
        'latency' { return $Providers | Sort-Object latency | Select-Object -First 1 }
        'load' {
            return $Providers | Sort-Object @{Expression = { $_.load / $_.capacity } } | Select-Object -First 1
        }
        default { return $Providers | Sort-Object cost | Select-Object -First 1 }
    }
}

function Get-DelegateScriptPath {
    param([string]$Provider)

    switch ($Provider) {
        'AWS' { return Join-Path $PSScriptRoot 'aws-delegator.ps1' }
        'Azure' { return Join-Path $PSScriptRoot 'azure-delegator.ps1' }
        default { throw "Unsupported provider: $Provider" }
    }
}

function Invoke-CloudProvider {
    param([string]$Provider)

    $delegatePath = Get-DelegateScriptPath -Provider $Provider
    if (-not (Test-Path $delegatePath)) {
        throw "Delegator script not found for provider $Provider"
    }

    Write-Log "Invoking provider $Provider via $delegatePath" INFO

    $splat = @{
        SkillId        = $SkillId
        SkillInput     = $script:SkillInputJson
        InvocationType = $InvocationType
        MaxRetries     = $MaxRetries
    }
    if ($Quiet) { $splat.Quiet = $true }
    if ($RecordMetrics) { $splat.RecordMetrics = $true }

    if ($Provider -eq 'AWS') {
        $splat.AwsRegion = $AwsRegion
    }
    elseif ($Provider -eq 'Azure') {
        if (-not $AzureFunctionUrl) { throw 'AzureFunctionUrl is required for Azure provider' }
        $splat.FunctionUrl = $AzureFunctionUrl
    }

    return & $delegatePath @splat
}

function Get-ProviderOrder {
    param([object]$Selected)
    if ($Selected.provider -eq 'AWS') {
        return @('AWS', 'Azure')
    }
    return @('Azure', 'AWS')
}

function Save-HybridMetrics {
    param(
        [string]$Provider,
        [string]$Outcome,
        [int]$Duration,
        [bool]$Success
    )

    $metricsPath = "$root/.session/hybrid-metrics.json"
    $metrics = @{ executions = @() }

    if (Test-Path $metricsPath) {
        $metrics = Get-Content $metricsPath -Raw | ConvertFrom-Json
    }

    $metrics.executions += @{
        provider  = $Provider
        timestamp = Get-Date -Format 'o'
        duration  = $Duration
        success   = $Success
        outcome   = $Outcome
        strategy  = $RoutingStrategy
    }

    $metrics | ConvertTo-Json -Depth 10 | Set-Content $metricsPath

    # Also write to shared cloud-metrics.json for dashboard consumption
    $cloudPath = "$root/.session/cloud-metrics.json"
    $cloudMetrics = @{ executions = @() }
    if (Test-Path $cloudPath) {
        $cloudMetrics = Get-Content $cloudPath -Raw | ConvertFrom-Json
    }
    $cloudMetrics.executions += @{
        provider   = "hybrid-$Provider"
        timestamp  = (Get-Date -Format 'o')
        duration   = $Duration
        success    = $Success
        cost       = if ($Provider -eq 'AWS') { 0.0000167 } else { 0.00002 }
        strategy   = $RoutingStrategy
        outcome    = $Outcome
    }
    $cloudMetrics | ConvertTo-Json -Depth 10 | Set-Content $cloudPath
}

function Start-TracingSpan {
    param([string]$Name)
    $tracer = Join-Path $PSScriptRoot '../TRACING/tracing-instrument.ps1'
    if (Test-Path $tracer) {
        return & $tracer -Action start -SpanName $Name -Attributes @{ skillId = $SkillId; strategy = $RoutingStrategy } -Quiet 2>&1
    }
    return $null
}

function Stop-TracingSpan {
    param([string]$SpanName, [bool]$Success, [int]$Duration, [string]$TraceId, [string]$SpanId)
    $tracer = Join-Path $PSScriptRoot '../TRACING/tracing-instrument.ps1'
    if (Test-Path $tracer) {
        if ($Success) {
            & $tracer -Action end -SpanName $SpanName -TraceId $TraceId -SpanId $SpanId -Attributes @{ durationMs = $Duration; skillId = $SkillId } -Quiet 2>&1 | Out-Null
        } else {
            & $tracer -Action error -SpanName $SpanName -TraceId $TraceId -SpanId $SpanId -ErrorMessage "Provider failed" -Attributes @{ durationMs = $Duration; skillId = $SkillId } -Quiet 2>&1 | Out-Null
        }
    }
}

function Log-AuditEvent {
    param([string]$Provider, [string]$Status, [string]$Detail)
    $auditPipe = Join-Path $PSScriptRoot '../../../security/audit-pipeline.ps1'
    if (Test-Path $auditPipe) {
        & $auditPipe -Action log -EventType delegation -Component cloud -Operation hybrid-executor -Actor system -Target $Provider -Status $Status -Message $Detail -Quiet 2>&1 | Out-Null
    }
}

try {
    Write-Log "Hybrid executor started for skill: $SkillId" INFO

    if (-not $SkillId -or -not $SkillInput) {
        throw 'SkillId and SkillInput are required'
    }

    $providers = Get-ProviderCatalog
    $selected = Select-Provider -Providers $providers
    $orderedProviders = Get-ProviderOrder -Selected $selected

    foreach ($provider in $orderedProviders) {
        try {
            $span = Start-TracingSpan -Name "cloud-$provider"
            $start = Get-Date
            $result = Invoke-CloudProvider -Provider $provider
            $duration = [math]::Round(((Get-Date) - $start).TotalMilliseconds)
            Save-HybridMetrics -Provider $provider -Outcome 'success' -Duration $duration -Success $true
            Stop-TracingSpan -SpanName "cloud-$provider" -Success $true -Duration $duration -TraceId $span.traceId -SpanId $span.spanId
            Log-AuditEvent -Provider $provider -Status success -Detail "Hybrid routed to $provider (${duration}ms)"
            Write-Log "Provider $provider succeeded in $duration ms" SUCCESS
            return $result
        }
        catch {
            $duration = [math]::Round(((Get-Date) - $start).TotalMilliseconds)
            Save-HybridMetrics -Provider $provider -Outcome 'failure' -Duration $duration -Success $false
            Stop-TracingSpan -SpanName "cloud-$provider" -Success $false -Duration $duration -TraceId $span.traceId -SpanId $span.spanId
            Log-AuditEvent -Provider $provider -Status failure -Detail "Hybrid failed for ${provider}: $_"
            Write-Log "Provider $provider failed: $_" ERROR
            continue
        }
    }

    throw 'Hybrid executor failed for all configured providers'
}
catch {
    Write-Log "Hybrid executor fatal error: $_" ERROR
    throw
}
