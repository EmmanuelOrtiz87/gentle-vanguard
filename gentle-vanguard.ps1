<#
.SYNOPSIS
    Gentle-Vanguard Launcher
.DESCRIPTION
    Main entry point for Gentle-Vanguard executable.
    Launches the dashboard or CLI based on parameters.
    Supports auto-update and version checking.
.PARAMETER Dashboard
    Start the web dashboard.
.PARAMETER CLI
    Start CLI mode (default).
.PARAMETER Version
    Show version information.
.PARAMETER Update
    Check for and install updates.
.PARAMETER CheckVersion
    Check if a new version is available.
#>
[CmdletBinding()]
param(
    [switch]$Dashboard,
    [switch]$CLI,
    [switch]$Version,
    [switch]$Update,
    [switch]$CheckVersion
)

$versionFile = Join-Path $PSScriptRoot "VERSION"
if (Test-Path $versionFile) {
    $script:AppVersion = (Get-Content $versionFile -Raw).Trim()
} else {
    $script:AppVersion = "0.0.0"
}

$checkScript = Join-Path $PSScriptRoot "scripts\utilities\check-version.ps1"
$updateScript = Join-Path $PSScriptRoot "scripts\utilities\auto-update.ps1"

function Check-ForUpdates {
    if (Test-Path $checkScript) {
        $result = & $checkScript -Quiet 2>&1
        $parts = $result -split '\|'
        if ($parts[0] -eq "UPDATE_AVAILABLE") {
            Write-Host "Update available: v$($parts[1]) -> v$($parts[2])" -ForegroundColor Yellow
            Write-Host "Run with -Update to install." -ForegroundColor Gray
            return $true
        }
    }
    return $false
}

if ($Version) {
    Write-Host "Gentle-Vanguard v$script:AppVersion"
    exit 0
}

if ($Update) {
    if (Test-Path $updateScript) {
        & $updateScript
        exit $LASTEXITCODE
    } else {
        Write-Host "Update script not found at $updateScript" -ForegroundColor Red
        exit 1
    }
}

if ($CheckVersion) {
    if (Test-Path $checkScript) {
        & $checkScript
        exit $LASTEXITCODE
    } else {
        Write-Host "Version check script not found at $checkScript" -ForegroundColor Red
        exit 1
    }
}

if ($Dashboard) {
    Write-Host "Starting Gentle-Vanguard Dashboard v$script:AppVersion..."
    $null = Check-ForUpdates
    Write-Host "Opening browser at http://localhost:3000"
    Start-Process "http://localhost:3000"
    
    $dashboardPath = Join-Path $PSScriptRoot "apps\web-dashboard"
    if (Test-Path $dashboardPath) {
        Push-Location $dashboardPath
        try {
            & pnpm dev
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Dashboard not found at $dashboardPath" -ForegroundColor Red
        exit 1
    }
} else {
    $null = Check-ForUpdates
    Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Gentle-Vanguard v$script:AppVersion                              ║
║   AI-Powered Development Orchestrator                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  gentle-vanguard.exe -Dashboard      Start the web dashboard"
    Write-Host "  gentle-vanguard.exe -CLI            Start CLI mode (default)"
    Write-Host "  gentle-vanguard.exe -Version        Show version"
    Write-Host "  gentle-vanguard.exe -CheckVersion   Check for updates"
    Write-Host "  gentle-vanguard.exe -Update         Auto-update to latest version"
    
    Write-Host "`nFor more information, visit: https://github.com/EmmanuelOrtiz87/gentle-vanguard" -ForegroundColor Gray
}
