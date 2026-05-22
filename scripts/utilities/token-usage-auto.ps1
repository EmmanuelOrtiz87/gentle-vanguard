# token-usage-auto.ps1
# Script para mostrar notificaciones de token usage automaticamente
# Uso: Ejecutar despues de cada respuesta del agente

param(
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [string]$SessionId = ""
)

$ErrorActionPreference = 'Continue'

# Detectar repo root
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    $root = $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { 
        $root = Split-Path -Parent $root 
    }
    if (-not $root) { $root = (Get-Location).Path }
    $root
}

$notifierScript = Join-Path $repoRoot "scripts\utilities\token-usage-notifier.ps1"

if (-not (Test-Path $notifierScript)) {
    Write-Warning "Token notifier not found: $notifierScript"
    exit 1
}

# Si no se proporcionaron tokens, estimar basado en caracteres
if ($InputTokens -eq 0 -and $OutputTokens -eq 0) {
    # Estimacion aproximada: ~4 caracteres por token
    $estimatedInput = [math]::Max(1, [math]::Floor($ContextChars / 4))
    $estimatedOutput = [math]::Max(1, [math]::Floor(500 / 4))  # Asumimos ~500 chars de respuesta
    $InputTokens = $estimatedInput
    $OutputTokens = $estimatedOutput
}

# Ejecutar accumulate que muestra metricas actuales y acumuladas
& $notifierScript -Action accumulate -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars -SessionId $SessionId

exit $LASTEXITCODE
