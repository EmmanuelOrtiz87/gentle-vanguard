# toggle-token-display.ps1
# Comando para activar/desactivar la visualización de tokens
# Uso: pwsh -File scripts/utilities/toggle-token-display.ps1

param(
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

$ErrorActionPreference = 'Continue'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)

$tokenNotifier = Join-Path $repoRoot 'scripts\utilities\token-usage-notifier.ps1'

if (-not (Test-Path $tokenNotifier)) {
    Write-Host "[ERROR] Token notifier not found at: $tokenNotifier" -ForegroundColor Red
    exit 1
}

if ($Status) {
    & $tokenNotifier -Action status
} elseif ($Enable) {
    $configFile = Join-Path $repoRoot '.session\token-display-config.json'
    if (Test-Path $configFile) {
        $config = Get-Content $configFile | ConvertFrom-Json
        $config.enabled = $true
        $config | ConvertTo-Json | Set-Content $configFile
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║     TOKEN USAGE DISPLAY ENABLED                          ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
    }
} elseif ($Disable) {
    $configFile = Join-Path $repoRoot '.session\token-display-config.json'
    if (Test-Path $configFile) {
        $config = Get-Content $configFile | ConvertFrom-Json
        $config.enabled = $false
        $config | ConvertTo-Json | Set-Content $configFile
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║     TOKEN USAGE DISPLAY DISABLED                         ║" -ForegroundColor Yellow
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    # Toggle
    & $tokenNotifier -Action toggle
}

exit 0
