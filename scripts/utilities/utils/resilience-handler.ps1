<#
.SYNOPSIS
    Resilience Handler — retry, timeout, circuit-breaker, user notification
.DESCRIPTION
    Wraps any command with resilience patterns:
    - Invoke-ResilientCommand: retry + timeout + user notification
    - Invoke-WithTimeout: execute with timeout, graceful handling
    - Get-CircuitState: check circuit breaker state
    - Send-UserNotification: standardized failure notification
.PARAMETER ScriptBlock
    The command to execute (script block)
.PARAMETER TimeoutSeconds
    Max execution time before timeout
.PARAMETER RetryAttempts
    Number of retry attempts on failure
.PARAMETER RetryDelayMs
    Delay between retries (ms)
.PARAMETER RetryBackoffFactor
    Multiplier for exponential backoff
.PARAMETER OperationName
    Name for logging and user notification
.PARAMETER FallbackAction
    What to do on failure: 'notify_user', 'warn_skip', 'warn_continue', 'throw'
.PARAMETER CircuitBreakerName
    Name for circuit breaker state tracking
.EXAMPLE
    Invoke-ResilientCommand -ScriptBlock { & scripts/utilities/AGENT/agent-verify.ps1 -Quick } -TimeoutSeconds 120 -OperationName "agent-verify" -FallbackAction notify_user
#>

param(
    [scriptblock]$ScriptBlock,
    [int]$TimeoutSeconds = 30,
    [int]$RetryAttempts = 3,
    [int]$RetryDelayMs = 1000,
    [float]$RetryBackoffFactor = 2.0,
    [string]$OperationName = 'unknown',
    [ValidateSet('notify_user', 'warn_skip', 'warn_continue', 'throw')]
    [string]$FallbackAction = 'warn_continue',
    [string]$CircuitBreakerName = '',
    [switch]$PassThru
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')
$configPath = Join-Path $repoRoot 'config/resilience-config.json'
$circuitDir = Join-Path $repoRoot '.session/circuit-breakers'

# Load config
$config = @{}
if (Test-Path $configPath) {
    try { $config = Get-Content $configPath -Raw | ConvertFrom-Json } catch { Write-Output "[RESILIENCE] No config loaded, using defaults" }
}

function Get-OperationConfig {
    param([string]$Name)
    $nameKey = $Name -replace '-', '_'
    if ($config.timeouts.$nameKey) { return $config.timeouts.$nameKey }
    return $null
}

function Write-ResLog {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] [$Level] [RESILIENCE:$OperationName] $Message"
    Write-Host $logLine -ForegroundColor $(if ($Level -eq 'ERROR') { 'Red' } elseif ($Level -eq 'WARN') { 'Yellow' } elseif ($Level -eq 'OK') { 'Green' } else { 'Gray' })
}

function Get-CircuitState {
    param([string]$Name)
    if (-not $Name) { return 'closed' }
    $stateFile = Join-Path $circuitDir "$Name.json"
    if (-not (Test-Path $stateFile)) { return 'closed' }
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($state.state -eq 'open') {
            $elapsed = [datetime]::Now - [datetime]::Parse($state.opened_at)
            if ($elapsed.TotalSeconds -ge $state.reset_seconds) { return 'half-open' }
            return 'open'
        }
        return $state.state
    } catch { return 'closed' }
}

function Set-CircuitState {
    param([string]$Name, [string]$State, [int]$ResetSeconds = 60)
    if (-not $Name) { return }
    if (-not (Test-Path $circuitDir)) { New-Item -ItemType Directory -Path $circuitDir -Force | Out-Null }
    $stateFile = Join-Path $circuitDir "$Name.json"
    $data = @{ state = $State; opened_at = [datetime]::Now.ToString('o'); reset_seconds = $ResetSeconds; failures = 0 }
    if (Test-Path $stateFile) { try { $existing = Get-Content $stateFile -Raw | ConvertFrom-Json; $data.failures = $existing.failures + 1 } catch { $data.failures = 1 } }
    $data | ConvertTo-Json | Set-Content $stateFile -Force
}

function Reset-CircuitState {
    param([string]$Name)
    if (-not $Name) { return }
    $stateFile = Join-Path $circuitDir "$Name.json"
    if (Test-Path $stateFile) { Remove-Item $stateFile -Force }
}

function Get-UserSuggestion {
    param([string]$Fallback)
    $suggestions = @{ timeout = @("Reintentar con mas tiempo", "Omitir este paso", "Continuar con lo demas", "Cancelar operacion"); generic = @("Reintentar", "Omitir y continuar", "Reportar falla") }
    $key = if ($Fallback -eq 'timeout') { 'timeout' } else { 'generic' }
    return ($suggestions.$key -join ', ')
}

function Invoke-WithTimeout {
    param([scriptblock]$Block, [int]$TimeoutSec)
    $job = Start-Job -ScriptBlock $Block
    $wait = $job | Wait-Job -Timeout $TimeoutSec
    if (-not $wait) {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        return $null, $true
    }
    $result = $job | Receive-Job -ErrorAction SilentlyContinue
    $hasError = $job.JobStateInfo.State -eq 'Failed'
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    return $result, $hasError
}

function Invoke-ResilientWrapper {
    $operationConfig = Get-OperationConfig -Name $OperationName
    if ($operationConfig) {
        if ($operationConfig.timeout_seconds) { $TimeoutSeconds = $operationConfig.timeout_seconds }
        if ($operationConfig.retry_attempts -ge 0) { $RetryAttempts = $operationConfig.retry_attempts }
        if ($operationConfig.retry_delay_ms) { $RetryDelayMs = $operationConfig.retry_delay_ms }
        if ($operationConfig.retry_backoff_factor) { $RetryBackoffFactor = $operationConfig.retry_backoff_factor }
        if ($operationConfig.fallback_action) { $FallbackAction = $operationConfig.fallback_action }
    }

    if ($CircuitBreakerName) {
        $circuitState = Get-CircuitState -Name $CircuitBreakerName
        if ($circuitState -eq 'open') {
            Write-ResLog "Circuit breaker OPEN for '$CircuitBreakerName' — skipping" -Level 'WARN'
            $threshold = if ($config.circuit_breakers.$CircuitBreakerName) { $config.circuit_breakers.$CircuitBreakerName.failure_threshold } else { 5 }
            $resetSec = if ($config.circuit_breakers.$CircuitBreakerName) { $config.circuit_breakers.$CircuitBreakerName.reset_seconds } else { 60 }
            Write-ResLog "Circuit will reset in ${resetSec}s (threshold: $threshold failures)" -Level 'INFO'
            return $null
        }
        if ($circuitState -eq 'half-open') {
            Write-ResLog "Circuit breaker HALF-OPEN for '$CircuitBreakerName' — allowing probe" -Level 'WARN'
        }
    }

    $lastError = $null
    $currentDelay = $RetryDelayMs

    for ($attempt = 1; $attempt -le $RetryAttempts; $attempt++) {
        Write-ResLog "Attempt $attempt of $RetryAttempts (timeout: ${TimeoutSeconds}s)"

        $result, $timedOut = Invoke-WithTimeout -Block $ScriptBlock -TimeoutSec $TimeoutSeconds

        if ($timedOut) {
            Write-ResLog "TIMEOUT after ${TimeoutSeconds}s" -Level 'WARN'
            $lastError = "Operation timed out after ${TimeoutSeconds}s"
            if ($attempt -lt $RetryAttempts) {
                Write-ResLog "Retrying in ${currentDelay}ms..."
                Start-Sleep -Milliseconds $currentDelay
                $currentDelay = [int]($currentDelay * $RetryBackoffFactor)
                continue
            }
        } elseif ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-ResLog "FAILED with exit code $LASTEXITCODE" -Level 'WARN'
            $lastError = "Exit code: $LASTEXITCODE"
            if ($attempt -lt $RetryAttempts) {
                Write-ResLog "Retrying in ${currentDelay}ms..."
                Start-Sleep -Milliseconds $currentDelay
                $currentDelay = [int]($currentDelay * $RetryBackoffFactor)
                continue
            }
        } else {
            if ($CircuitBreakerName) { Reset-CircuitState -Name $CircuitBreakerName }
            Write-ResLog "SUCCESS on attempt $attempt" -Level 'OK'
            if ($PassThru) { return $result }
            return $true
        }
    }

    if ($CircuitBreakerName) {
        Set-CircuitState -Name $CircuitBreakerName -State 'open'
        Write-ResLog "Circuit breaker OPENED for '$CircuitBreakerName'" -Level 'ERROR'
    }

    Write-ResLog "All $RetryAttempts attempts failed: $lastError" -Level 'ERROR'

    switch ($FallbackAction) {
        'notify_user' {
            Write-Host "`n============================================" -ForegroundColor Yellow
            Write-Host "  [STACK] Error en: $OperationName" -ForegroundColor Red
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host "  Detalle: $lastError" -ForegroundColor Gray
            Write-Host "  Intentos: $RetryAttempts" -ForegroundColor Gray
            Write-Host "  Timeout: ${TimeoutSeconds}s" -ForegroundColor Gray
            Write-Host "`n  Sugerencias: $(Get-UserSuggestion -Fallback $(if ($lastError -match 'timeout'){'timeout'}else{'generic'}))" -ForegroundColor Cyan
            Write-Host "============================================`n" -ForegroundColor Yellow
        }
        'warn_skip' {
            Write-Host "[STACK] WARN: $OperationName falló — omitiendo paso ($lastError)" -ForegroundColor Yellow
        }
        'warn_continue' {
            Write-Host "[STACK] WARN: $OperationName falló — continuando ($lastError)" -ForegroundColor Yellow
        }
        'throw' {
            throw "[STACK] ERROR: $OperationName falló después de $RetryAttempts intentos: $lastError"
        }
    }

    if ($PassThru) { return $null }
    return $false
}

Invoke-ResilientWrapper
