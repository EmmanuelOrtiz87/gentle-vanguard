# token-usage-wrapper.ps1
# Wrapper para integrar token-usage-notifier con el flujo de respuesta del agente
# Este script debe ser llamado después de cada respuesta del agente

param(
    [Parameter(Mandatory=$true)]
    [int]$InputTokens,
    
    [Parameter(Mandatory=$true)]
    [int]$OutputTokens,
    
    [Parameter(Mandatory=$false)]
    [int]$ContextChars = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$SessionId = ""
)

$ErrorActionPreference = 'Continue'

# Detectar repo root
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    $root = $scriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { 
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

# Ejecutar accumulate que muestra métricas actuales y acumuladas
& $notifierScript -Action accumulate -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars -SessionId $SessionId

exit $LASTEXITCODE
