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

# Detectar repo root - FIXED: mejor deteccion de path
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    # Buscar hacia arriba desde la ubicacion actual
    $root = Get-Location
    $found = $false
    $maxDepth = 5
    $depth = 0
    while ($root -and -not $found -and $depth -lt $maxDepth) {
        if ((Test-Path (Join-Path $root 'CLAUDE.md')) -or 
            (Test-Path (Join-Path $root 'config'))) {
            $found = $true
            break
        }
        $parent = Split-Path -Parent $root
        if ($parent -eq $root) { break }
        $root = $parent
        $depth++
    }
    if (-not $found) { $root = Get-Location }
    $root
}

$notifierScript = Join-Path $repoRoot "scripts/utilities/token-usage-notifier.ps1"

if (-not (Test-Path $notifierScript)) {
    Write-Warning "Token notifier not found: $notifierScript"
    exit 1
}

# Si no se proporcionaron tokens, estimar basado en caracteres
if ($InputTokens -eq 0 -and $OutputTokens -eq 0) {
    # Estimacion aproximada: ~4 caracteres por token
    $estimatedInput = [math]::Max(1, [math]::Floor($ContextChars / 4))
    $estimatedOutput = [math]::Max(1, [math]::Floor(500 / 4))
    $InputTokens = $estimatedInput
    $OutputTokens = $estimatedOutput
}

# Ejecutar accumulate que muestra metricas actuales y acumuladas
& $notifierScript -Action accumulate -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars -SessionId $SessionId

exit $LASTEXITCODE