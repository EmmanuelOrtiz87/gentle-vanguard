# toggle-token-display.ps1
# Comando para activar/desactivar la visualización de tokens y notificaciones
# Uso: pwsh -File scripts/utilities/toggle-token-display.ps1 [-Status] [-Enable] [-Disable] [-Type all|token|context|cost|accumulated]

param(
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable,
    [ValidateSet("all", "token", "context", "cost", "accumulated", "compact")]
    [string]$Type = "all"
)

$ErrorActionPreference = 'Continue'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)

$configFile = Join-Path $repoRoot '.session\token-display-config.json'
$tokenNotifier = Join-Path $repoRoot 'scripts\utilities\token-usage-notifier.ps1'

if (-not (Test-Path $tokenNotifier)) {
    Write-Host "[ERROR] Token notifier not found at: $tokenNotifier" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $configFile)) {
    & $tokenNotifier -Action status
    exit 0
}

$config = Get-Content $configFile | ConvertFrom-Json

# Ensure individualToggles exist
if (-not $config.individualToggles) {
    $config | Add-Member -MemberType NoteProperty -Name "individualToggles" -Value @{
        tokenUsage = $true
        contextSize = $true
        estimatedCost = $true
        sessionAccumulated = $true
    }
}

function Save-Config {
    param($Cfg)
    $Cfg | ConvertTo-Json -Depth 10 | Set-Content $configFile
}

function Update-IndividualToggle {
    param($Type, $Value)
    switch ($Type) {
        "token" { $config.individualToggles.tokenUsage = $Value }
        "context" { $config.individualToggles.contextSize = $Value }
        "cost" { $config.individualToggles.estimatedCost = $Value }
        "accumulated" { $config.individualToggles.sessionAccumulated = $Value }
    }
}

function Show-IndividualStatus {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              NOTIFICATION STATUS                          ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    $globalEnabled = if ($config.enabled) { "ENABLED " } else { "DISABLED" }
    Write-Host "║  Global:           $globalEnabled" -ForegroundColor $(if($config.enabled){'Green'}else{'Red'}) -NoNewline
    Write-Host "                             ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    $t = if ($config.individualToggles.tokenUsage) { "ON " } else { "OFF" }
    Write-Host "║  Token Usage:      $t" -ForegroundColor $(if($config.individualToggles.tokenUsage){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    $c = if ($config.individualToggles.contextSize) { "ON " } else { "OFF" }
    Write-Host "║  Context Size:     $c" -ForegroundColor $(if($config.individualToggles.contextSize){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    $e = if ($config.individualToggles.estimatedCost) { "ON " } else { "OFF" }
    Write-Host "║  Estimated Cost:   $e" -ForegroundColor $(if($config.individualToggles.estimatedCost){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    $a = if ($config.individualToggles.sessionAccumulated) { "ON " } else { "OFF" }
    Write-Host "║  Session Accum:    $a" -ForegroundColor $(if($config.individualToggles.sessionAccumulated){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Compact Mode:     $(if($config.compactMode){'ON '}else{'OFF'})" -ForegroundColor White -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    Write-Host "║  Show After Each:  $(if($config.showAfterEachResponse){'ON '}else{'OFF'})" -ForegroundColor White -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Usage: /notif <on|off|status|toggle|token|context|cost|accumulated>" -ForegroundColor Gray
    Write-Host ""
}

if ($Status) {
    Show-IndividualStatus
} elseif ($Enable -or $Disable) {
    $val = $Enable -eq $true
    if ($Type -eq "all") {
        $config.enabled = $val
        $config.individualToggles.tokenUsage = $val
        $config.individualToggles.contextSize = $val
        $config.individualToggles.estimatedCost = $val
        $config.individualToggles.sessionAccumulated = $val
        $config.compactMode = $val
    } elseif ($Type -eq "compact") {
        $config.compactMode = $val
        if ($val) { $config.enabled = $true }
    } else {
        Update-IndividualToggle -Type $Type -Value $val
        if ($val) { $config.enabled = $true }
    }
    $config.lastToggle = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    Save-Config $config
    $label = if ($val) { "ENABLED" } else { "DISABLED" }
    $color = if ($val) { "Green" } else { "Yellow" }
    if ($Type -eq "all") {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor $color
        $padding = " " * (41 - $label.Length)
        Write-Host "║     NOTIFICATIONS $label$padding║" -ForegroundColor $color
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor $color
        Write-Host ""
    } else {
        $typeLabel = switch ($Type) {
            "token" { "Token Usage" }
            "context" { "Context Size" }
            "cost" { "Estimated Cost" }
            "accumulated" { "Session Accumulated" }
            "compact" { "Compact Mode" }
        }
        Write-Host ""
        Write-Host "  [$typeLabel] $label" -ForegroundColor $color
        Write-Host ""
    }
} else {
    # Toggle: if Type is "all", toggle global; otherwise toggle individual
    if ($Type -eq "all") {
        $newVal = -not $config.enabled
        $config.enabled = $newVal
        $config.individualToggles.tokenUsage = $newVal
        $config.individualToggles.contextSize = $newVal
        $config.individualToggles.estimatedCost = $newVal
        $config.individualToggles.sessionAccumulated = $newVal
        $config.compactMode = $newVal
    } elseif ($Type -eq "compact") {
        $config.compactMode = -not $config.compactMode
    } else {
        $current = switch ($Type) {
            "token" { $config.individualToggles.tokenUsage }
            "context" { $config.individualToggles.contextSize }
            "cost" { $config.individualToggles.estimatedCost }
            "accumulated" { $config.individualToggles.sessionAccumulated }
        }
        Update-IndividualToggle -Type $Type -Value (-not $current)
        $anyOn = $config.individualToggles.tokenUsage -or $config.individualToggles.contextSize -or $config.individualToggles.estimatedCost -or $config.individualToggles.sessionAccumulated
        $config.enabled = $anyOn
    }
    $config.lastToggle = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    Save-Config $config
    Show-IndividualStatus
}

exit 0
