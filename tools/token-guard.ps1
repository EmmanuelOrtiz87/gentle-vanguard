<#
.SYNOPSIS
    Token Guard - Proteccin automtica contra overflow de tokens
    
.DESCRIPTION
    Implementa monitoreo automtico de tokens con:
    - Alerta a 80% del presupuesto
    - Pausa de dispatch si se excede presupuesto
    - Fragmentacin automtica en mltiples rounds
    - Logging detallado de uso de tokens

.PARAMETER ConfigPath
    Ruta al archivo de configuracin token-guard-config.json

.PARAMETER SessionId
    ID de la sesin actual para tracking

.PARAMETER Mode
    Modo de operacin: 'monitor', 'enforce', 'report'
#>

param(
    [string]$ConfigPath = "tools/token-guard-config.json",
    [string]$SessionId = "",
    [string]$Mode = "monitor"
)

# ============================================================================
# CONFIGURACIN Y VARIABLES GLOBALES
# ============================================================================

$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

# Colores para output
$Colors = @{
    Info    = "Cyan"
    Warning = "Yellow"
    Error   = "Red"
    Success = "Green"
    Alert   = "Magenta"
}

# Cargar configuracin
function Load-TokenGuardConfig {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "[TOKEN-GUARD] Configuracin no encontrada. Usando defaults." -ForegroundColor $Colors.Warning
        return @{
            enabled = $true
            tokenBudget = 128000
            alertThreshold = 0.80
            pauseThreshold = 0.95
            maxRounds = 5
            roundTokenBudget = 25600
            logPath = ".\.session\token-guard.log"
            enableFragmentation = $true
            enableAutoDispatchPause = $true
            enableAlerts = $true
        }
    }
    
    try {
        $configObj = Get-Content $Path | ConvertFrom-Json
        # Convertir PSCustomObject a Hashtable
        $config = @{}
        $configObj.PSObject.Properties | ForEach-Object {
            $config[$_.Name] = $_.Value
        }
        Write-Host "[TOKEN-GUARD] Configuracin cargada desde: $Path" -ForegroundColor $Colors.Success
        return $config
    }
    catch {
        Write-Host "[TOKEN-GUARD] Error al cargar config: $_" -ForegroundColor $Colors.Error
        return $null
    }
}

# ============================================================================
# FUNCIONES DE MONITOREO
# ============================================================================

function Initialize-TokenGuard {
    param(
        [hashtable]$Config,
        [string]$SessionId
    )
    
    Write-Host "[TOKEN-GUARD] Inicializando Token Guard..." -ForegroundColor $Colors.Info
    
    # Crear directorio de logs si no existe
    $logDir = Split-Path -Parent $Config.logPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Crear archivo de estado
    $stateFile = Join-Path $logDir "token-guard-state.json"
    $initialState = @{
        initialized = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        sessionId = $SessionId
        totalTokensUsed = 0
        roundsCompleted = 0
        currentRound = 1
        alertsTriggered = 0
        dispatchPaused = $false
        fragmentationActive = $false
        status = "READY"
    }
    
    $initialState | ConvertTo-Json | Set-Content $stateFile
    Write-Host "[TOKEN-GUARD] Estado inicial guardado en: $stateFile" -ForegroundColor $Colors.Success
    
    return $stateFile
}

function Get-TokenGuardState {
    param([string]$StateFile)
    
    if (Test-Path $StateFile) {
        return Get-Content $StateFile | ConvertFrom-Json
    }
    return $null
}

function Update-TokenGuardState {
    param(
        [string]$StateFile,
        [hashtable]$Updates
    )
    
    $state = Get-TokenGuardState $StateFile
    if ($state) {
        foreach ($key in $Updates.Keys) {
            $state | Add-Member -MemberType NoteProperty -Name $key -Value $Updates[$key] -Force
        }
        $state | ConvertTo-Json | Set-Content $StateFile
    }
}

function Log-TokenUsage {
    param(
        [string]$LogPath,
        [int]$PromptTokens,
        [int]$CompletionTokens,
        [int]$TotalTokens,
        [string]$Action,
        [string]$Status
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        timestamp = $timestamp
        promptTokens = $PromptTokens
        completionTokens = $CompletionTokens
        totalTokens = $TotalTokens
        action = $Action
        status = $Status
    }
    
    $logEntry | ConvertTo-Json | Add-Content $LogPath
}

# ============================================================================
# FUNCIONES DE ALERTA Y CONTROL
# ============================================================================

function Check-TokenThreshold {
    param(
        [int]$CurrentTokens,
        [int]$BudgetTokens,
        [decimal]$AlertThreshold,
        [decimal]$PauseThreshold
    )
    
    $usagePercent = [decimal]($CurrentTokens / $BudgetTokens)
    
    $result = @{
        usagePercent = $usagePercent
        isAlertTriggered = $usagePercent -ge $AlertThreshold
        isPausedTriggered = $usagePercent -ge $PauseThreshold
        remainingTokens = $BudgetTokens - $CurrentTokens
        status = "OK"
    }
    
    if ($result.isPausedTriggered) {
        $result.status = "PAUSED"
    }
    elseif ($result.isAlertTriggered) {
        $result.status = "ALERT"
    }
    
    return $result
}

function Trigger-TokenAlert {
    param(
        [hashtable]$ThresholdInfo,
        [hashtable]$Config,
        [string]$StateFile
    )
    
    $alertLevel = "WARNING"
    if ($ThresholdInfo.isPausedTriggered) {
        $alertLevel = "CRITICAL"
    }
    
    $usagePercentValue = [math]::Round($ThresholdInfo.usagePercent * 100, 2)
    $alertMessage = "[TOKEN-GUARD] $alertLevel - ALERTA DE PRESUPUESTO DE TOKENS`n"
    $alertMessage += "Uso actual: $usagePercentValue`%`n"
    $alertMessage += "Tokens restantes: $($ThresholdInfo.remainingTokens)`n"
    $alertMessage += "Estado: $($ThresholdInfo.status)"
    
    Write-Host $alertMessage -ForegroundColor $Colors.Alert
    
    # Actualizar estado
    $state = Get-TokenGuardState $StateFile
    if ($state) {
        $state.alertsTriggered = $state.alertsTriggered + 1
        if ($ThresholdInfo.isPausedTriggered) {
            $state.dispatchPaused = $true
            $state.status = "PAUSED"
        }
        else {
            $state.status = "ALERT"
        }
        $state | ConvertTo-Json | Set-Content $StateFile
    }
    
    return $alertLevel -eq "CRITICAL"
}

# ============================================================================
# FUNCIONES DE FRAGMENTACIN
# ============================================================================

function Initialize-RoundFragmentation {
    param(
        [hashtable]$Config,
        [string]$StateFile
    )
    
    Write-Host "[TOKEN-GUARD] Inicializando fragmentacin en rounds..." -ForegroundColor $Colors.Info
    
    $state = Get-TokenGuardState $StateFile
    if ($state) {
        $state.fragmentationActive = $true
        $state.currentRound = 1
        $state.roundsCompleted = 0
        $state | ConvertTo-Json | Set-Content $StateFile
    }
    
    $fragmentationInfo = @{
        maxRounds = $Config.maxRounds
        tokenPerRound = $Config.roundTokenBudget
        currentRound = 1
        roundsRemaining = $Config.maxRounds
        status = "ACTIVE"
    }
    
    return $fragmentationInfo
}

function Get-RoundTokenBudget {
    param(
        [int]$CurrentRound,
        [int]$MaxRounds,
        [int]$TotalBudget
    )
    
    $budgetPerRound = [int]($TotalBudget / $MaxRounds)
    return $budgetPerRound
}

function Complete-Round {
    param(
        [string]$StateFile,
        [int]$TokensUsedInRound
    )
    
    $state = Get-TokenGuardState $StateFile
    if ($state) {
        $state.roundsCompleted = $state.roundsCompleted + 1
        $state.currentRound = $state.currentRound + 1
        $state.totalTokensUsed = $state.totalTokensUsed + $TokensUsedInRound
        
        if ($state.currentRound -gt 5) {
            $state.fragmentationActive = $false
            $state.status = "COMPLETED"
        }
        
        $state | ConvertTo-Json | Set-Content $StateFile
    }
}

# ============================================================================
# FUNCIONES DE CONTROL DE DISPATCH
# ============================================================================

function Pause-Dispatch {
    param(
        [string]$StateFile,
        [string]$Reason
    )
    
    Write-Host "[TOKEN-GUARD] PAUSANDO DISPATCH - Razon: $Reason" -ForegroundColor $Colors.Alert
    
    $state = Get-TokenGuardState $StateFile
    if ($state) {
        $state.dispatchPaused = $true
        $state.pauseReason = $Reason
        $state.pausedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $state | ConvertTo-Json | Set-Content $StateFile
    }
    
    return $true
}

function Resume-Dispatch {
    param(
        [string]$StateFile
    )
    
    Write-Host "[TOKEN-GUARD] REANUDANDO DISPATCH" -ForegroundColor $Colors.Success
    
    $state = Get-TokenGuardState $StateFile
    if ($state) {
        $state.dispatchPaused = $false
        $state.resumedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $state | ConvertTo-Json | Set-Content $StateFile
    }
    
    return $true
}

function Is-DispatchPaused {
    param([string]$StateFile)
    
    $state = Get-TokenGuardState $StateFile
    return $state.dispatchPaused
}

# ============================================================================
# FUNCIONES DE REPORTE
# ============================================================================

function Generate-TokenReport {
    param(
        [string]$StateFile,
        [string]$LogPath,
        [hashtable]$Config
    )
    
    $state = Get-TokenGuardState $StateFile
    $alertPercent = [math]::Round($Config.alertThreshold * 100, 0)
    $pausePercent = [math]::Round($Config.pauseThreshold * 100, 0)
    $usedPercent = [math]::Round(($state.totalTokensUsed / $Config.tokenBudget) * 100, 2)
    
    $report = "REPORTE DE TOKENS - TOKEN GUARD`n"
    $report += "Sesion: $($state.sessionId)`n"
    $report += "Inicializada: $($state.initialized)`n"
    $report += "Estado actual: $($state.status)`n"
    $report += "`nCONSUMO DE TOKENS`n"
    $report += "Total usado: $($state.totalTokensUsed) / $($Config.tokenBudget)`n"
    $report += "Porcentaje: $usedPercent`%`n"
    $report += "Restante: $($Config.tokenBudget - $state.totalTokensUsed)`n"
    $report += "`nFRAGMENTACION`n"
    $report += "Rounds completados: $($state.roundsCompleted) / $($Config.maxRounds)`n"
    $report += "Round actual: $($state.currentRound)`n"
    $report += "Fragmentacion activa: $($state.fragmentationActive)`n"
    $report += "`nALERTAS Y CONTROL`n"
    $report += "Alertas disparadas: $($state.alertsTriggered)`n"
    $report += "Dispatch pausado: $($state.dispatchPaused)`n"
    $report += "Umbral de alerta: $alertPercent`%`n"
    $report += "Umbral de pausa: $pausePercent`%"
    
    Write-Host $report -ForegroundColor $Colors.Info
    return $report
}

# ============================================================================
# FUNCIONES PRINCIPALES POR MODO
# ============================================================================

function Invoke-MonitorMode {
    param(
        [hashtable]$Config,
        [string]$SessionId
    )
    
    Write-Host "[TOKEN-GUARD] Iniciando en modo MONITOR..." -ForegroundColor $Colors.Info
    
    $stateFile = Initialize-TokenGuard $Config $SessionId
    
    Write-Host "[TOKEN-GUARD] Token Guard inicializado y listo" -ForegroundColor $Colors.Success
    Write-Host "[TOKEN-GUARD] Archivo de estado: $stateFile" -ForegroundColor $Colors.Info
    Write-Host "[TOKEN-GUARD] Presupuesto de tokens: $($Config.tokenBudget)" -ForegroundColor $Colors.Info
    
    $alertPercent = [math]::Round($Config.alertThreshold * 100, 0)
    $pausePercent = [math]::Round($Config.pauseThreshold * 100, 0)
    
    Write-Host "[TOKEN-GUARD] Umbral de alerta: $alertPercent`%" -ForegroundColor $Colors.Info
    Write-Host "[TOKEN-GUARD] Umbral de pausa: $pausePercent`%" -ForegroundColor $Colors.Info
}

function Invoke-EnforceMode {
    param(
        [hashtable]$Config,
        [string]$StateFile,
        [int]$CurrentTokens
    )
    
    Write-Host "[TOKEN-GUARD] Iniciando en modo ENFORCE..." -ForegroundColor $Colors.Info
    
    $threshold = Check-TokenThreshold $CurrentTokens $Config.tokenBudget $Config.alertThreshold $Config.pauseThreshold
    
    if ($threshold.isPausedTriggered) {
        $usagePercent = [math]::Round($threshold.usagePercent * 100, 2)
        Pause-Dispatch $StateFile "Presupuesto de tokens excedido ($usagePercent`%)"
        return $false
    }
    elseif ($threshold.isAlertTriggered) {
        Trigger-TokenAlert $threshold $Config $StateFile
        return $true
    }
    
    return $true
}

function Invoke-ReportMode {
    param(
        [hashtable]$Config,
        [string]$StateFile
    )
    
    Write-Host "[TOKEN-GUARD] Generando reporte..." -ForegroundColor $Colors.Success
    $report = Generate-TokenReport $StateFile $Config.logPath $Config
}

# ============================================================================
# PUNTO DE ENTRADA
# ============================================================================

try {
    # Cargar configuracin
    $config = Load-TokenGuardConfig $ConfigPath
    
    if (-not $config) {
        Write-Host "[TOKEN-GUARD] Error critico: No se pudo cargar la configuracion" -ForegroundColor $Colors.Error
        exit 1
    }
    
    # Ejecutar segn modo
    switch ($Mode) {
        "monitor" {
            Invoke-MonitorMode $config $SessionId
        }
        "enforce" {
            # Este modo se llamara con tokens actuales
            Write-Host "[TOKEN-GUARD] Modo ENFORCE requiere parametro de tokens actuales" -ForegroundColor $Colors.Warning
        }
        "report" {
            $stateFile = Join-Path (Split-Path -Parent $config.logPath) "token-guard-state.json"
            Invoke-ReportMode $config $stateFile
        }
        default {
            Write-Host "[TOKEN-GUARD] Modo desconocido: $Mode" -ForegroundColor $Colors.Error
            exit 1
        }
    }
    
    exit 0
}
catch {
    $errorMsg = $_
    Write-Host "[TOKEN-GUARD] Error fatal: $errorMsg" -ForegroundColor $Colors.Error
    exit 1
}