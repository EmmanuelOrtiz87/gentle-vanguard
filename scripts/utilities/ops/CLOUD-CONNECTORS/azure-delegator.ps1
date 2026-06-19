#Requires -Version 7.0
<#
.SYNOPSIS
    Azure Function Delegator — Route skill executions to Azure Functions

.DESCRIPTION
    Wraps skill calls to Azure Function endpoints for distributed execution with:
    - HTTP invocation via Azure Functions URL
    - Optional Azure function key or access token
    - Automatic retries with exponential backoff
    - Session state persistence simulation for Cosmos/backup
    - Cost and latency tracking

.NOTES
    Part of Cloud Integration Phase v4.0
#>

param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Invoke')]
    [string]$SkillId,

    [Parameter(Mandatory = $true, ParameterSetName = 'Invoke')]
    [object]$SkillInput,

    [Parameter(Mandatory = $false)]
    [ValidateSet('RequestResponse', 'Event', 'DryRun')]
    [string]$InvocationType = 'RequestResponse',

    [Parameter(Mandatory = $false)]
    [string]$FunctionUrl = $env:AZURE_FUNCTION_URL,

    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3,

    [Parameter(Mandatory = $false)]
    [switch]$RecordMetrics,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
if ($SkillInput -is [string]) { $SkillInput = $SkillInput | ConvertFrom-Json }

function Write-Log {
    param([string]$Message, [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')][string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = @{'INFO' = 'Cyan'; 'WARN' = 'Yellow'; 'ERROR' = 'Red'; 'SUCCESS' = 'Green'}[$Level]
    if (-not $Quiet) { Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color }
    Add-Content -Path "$root/.session/azure-delegator.log" -Value "[$timestamp] [$Level] $Message" -ErrorAction SilentlyContinue
}

class CircuitBreaker {
    [int]$FailureThreshold = 5
    [int]$SuccessThreshold = 2
    [int]$TimeoutSeconds = 60
    [string]$State = 'CLOSED'
    [int]$FailureCount = 0
    [int]$SuccessCount = 0
    [datetime]$LastFailureTime = (Get-Date).AddHours(-1)

    [bool] CanExecute() {
        if ($this.State -eq 'OPEN') {
            $timeSinceLastFailure = ((Get-Date) - $this.LastFailureTime).TotalSeconds
            if ($timeSinceLastFailure -gt $this.TimeoutSeconds) {
                $this.State = 'HALF_OPEN'
                return $true
            }
            return $false
        }
        return $true
    }

    [void] RecordSuccess() {
        if ($this.State -eq 'HALF_OPEN') {
            $this.SuccessCount++
            if ($this.SuccessCount -ge $this.SuccessThreshold) {
                $this.State = 'CLOSED'
                $this.FailureCount = 0
                $this.SuccessCount = 0
            }
        }
        else {
            $this.FailureCount = 0
        }
    }

    [void] RecordFailure() {
        $this.FailureCount++
        $this.LastFailureTime = Get-Date
        if ($this.FailureCount -ge $this.FailureThreshold) {
            $this.State = 'OPEN'
        }
    }
}

$circuitBreaker = [CircuitBreaker]::new()

function Start-TracingSpan {
    param([string]$Name)
    $tracer = Join-Path $PSScriptRoot '../TRACING/tracing-instrument.ps1'
    if (Test-Path $tracer) {
        return & $tracer -Action start -SpanName $Name -Attributes @{ skillId = $SkillId; provider = 'Azure' } -Quiet 2>&1
    }
    return $null
}
function Stop-TracingSpan {
    param([string]$Name, [bool]$Success, [int]$Duration, [string]$Error)
    $tracer = Join-Path $PSScriptRoot '../TRACING/tracing-instrument.ps1'
    if (-not (Test-Path $tracer)) { return }
    if ($Success) { & $tracer -Action end -SpanName $Name -Attributes @{ durationMs = $Duration; skillId = $SkillId } -Quiet | Out-Null }
    else { & $tracer -Action error -SpanName $Name -ErrorMessage $Error -Attributes @{ durationMs = $Duration; skillId = $SkillId } -Quiet | Out-Null }
}

function Log-Audit {
    param([string]$Status, [string]$Detail)
    $audit = Join-Path $PSScriptRoot '../../../security/audit-pipeline.ps1'
    if (Test-Path $audit) { & $audit -Action log -EventType skill.exec -Component cloud -Operation azure-invoke -Actor system -Target $SkillId -Status $Status -Message $Detail -Quiet | Out-Null }
}

function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$InitialDelayMs = 1000
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            if (-not $circuitBreaker.CanExecute()) {
                throw "Circuit breaker is OPEN"
            }

            $result = & $ScriptBlock
            $circuitBreaker.RecordSuccess()
            return $result
        }
        catch {
            $circuitBreaker.RecordFailure()
            if ($attempt -eq $MaxRetries) {
                Write-Log "Failed after $MaxRetries attempts: $_" ERROR
                throw
            }

            $delayMs = $InitialDelayMs * [math]::Pow(2, $attempt - 1)
            Write-Log "Attempt $attempt failed. Retrying in $($delayMs)ms..." WARN
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

function Get-AzureAuthorizationHeader {
    if ($env:AZURE_FUNCTION_KEY) {
        return @{ 'x-functions-key' = $env:AZURE_FUNCTION_KEY }
    }

    if ($env:AZURE_ACCESS_TOKEN) {
        return @{ Authorization = "Bearer $env:AZURE_ACCESS_TOKEN" }
    }

    if (Get-Command az.exe -ErrorAction SilentlyContinue) {
        try {
            $tokenResponse = az account get-access-token --resource https://management.azure.com --output json | ConvertFrom-Json
            if ($tokenResponse.accessToken) {
                return @{ Authorization = "Bearer $($tokenResponse.accessToken)" }
            }
        }
        catch {
            Write-Log "Azure CLI token retrieval failed: $_" WARN
        }
    }

    return @{}
}

function Invoke-SkillOnAzureFunction {
    param([string]$SkillId, [object]$Input)

    Write-Log "Invoking skill on Azure Function: $FunctionUrl" INFO

    $payload = @{
        skillId   = $SkillId
        input     = $Input
        timestamp = (Get-Date -Format 'o')
        sessionId = [Environment]::GetEnvironmentVariable('SESSION_ID', 'User')
    } | ConvertTo-Json -Depth 10

    if ($InvocationType -eq 'DryRun') {
        Write-Log 'Dry run detected, skipping actual Azure invocation' INFO
        return @{ StatusCode = 202; Payload = @{ success = $true; skillId = $SkillId; output = 'Dry run completed' } | ConvertTo-Json }
    }

    $headers = Get-AzureAuthorizationHeader

    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Method Post -Uri $FunctionUrl -Headers $headers -ContentType 'application/json' -Body $payload -ErrorAction Stop
        $duration = [math]::Round(((Get-Date) - $start).TotalMilliseconds)

        Write-Log "Azure Function invocation successful" SUCCESS

        if ($RecordMetrics) {
            Record-CloudMetrics -Provider 'Azure' -Duration $duration -Success $true -Cost 0.00002
        }

        return @{ StatusCode = 200; Payload = ($response | ConvertTo-Json -Depth 10) }
    }
    catch {
        Write-Log "Azure Function invocation failed: $_" ERROR
        if ($RecordMetrics) {
            Record-CloudMetrics -Provider 'Azure' -Duration 0 -Success $false -Cost 0
        }
        throw
    }
}

function Record-CloudMetrics {
    param(
        [string]$Provider,
        [int]$Duration,
        [bool]$Success,
        [double]$Cost
    )

    $metricsPath = "$root/.session/cloud-metrics.json"
    $metrics = @{ executions = @() }

    if (Test-Path $metricsPath) {
        $metrics = Get-Content $metricsPath -Raw | ConvertFrom-Json
    }

    $metrics.executions += @{
        provider  = $Provider
        timestamp = Get-Date -Format 'o'
        duration  = $Duration
        success   = $Success
        cost      = $Cost
    }

    $metrics | ConvertTo-Json -Depth 10 | Set-Content $metricsPath
}

function Save-SessionStateToCosmos {
    param([object]$SessionState)

    Write-Log "Saving session state simulation to Cosmos backup" INFO

    try {
        $backupPath = "$root/.session/azure-backups"
        if (-not (Test-Path $backupPath)) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }

        $fileName = "azure-session-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $SessionState | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $backupPath $fileName)

        Write-Log "Session state saved to backup: $fileName" SUCCESS
    }
    catch {
        Write-Log "Failed to save Azure session state: $_" ERROR
    }
}

try {
    Write-Log "Azure Delegator started for skill: $SkillId" INFO

    if (-not $SkillId -or -not $SkillInput) {
        throw 'SkillId and SkillInput are required'
    }

    if (-not $FunctionUrl) {
        throw 'Azure FunctionUrl is required either via parameter or AZURE_FUNCTION_URL environment variable'
    }

    $result = Invoke-WithRetry -ScriptBlock {
        Invoke-SkillOnAzureFunction -SkillId $SkillId -Input $SkillInput
    } -MaxRetries $MaxRetries

    if ($RecordMetrics) {
        Save-SessionStateToCosmos @{
            skillId   = $SkillId
            result    = $result
            timestamp = Get-Date -Format 'o'
            provider  = 'Azure'
        }
    }

    Write-Log 'Azure delegator completed successfully' SUCCESS
    return $result
}
catch {
    Write-Log "Azure delegator fatal error: $_" ERROR
    throw
}
