<#
.SYNOPSIS
    Gentle-Vanguard Launcher
.DESCRIPTION
    Main entry point for Gentle-Vanguard executable.
    Launches the dashboard or CLI based on parameters.
#>
[CmdletBinding()]
param(
    [switch]$Dashboard,
    [switch]$CLI,
    [switch]$Version
)

$script:Version = "3.1.0"

if ($Version) {
    Write-Host "Gentle-Vanguard v$script:Version"
    exit 0
}

if ($Dashboard) {
    Write-Host "Starting Gentle-Vanguard Dashboard v$script:Version..."
    Write-Host "Opening browser at http://localhost:3000"
    Start-Process "http://localhost:3000"
    
    # Start the dashboard server
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
    # Default to CLI
    Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Gentle-Vanguard v$script:Version                              ║
║   AI-Powered Development Orchestrator                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  gentle-vanguard.exe -Dashboard    Start the web dashboard"
    Write-Host "  gentle-vanguard.exe -CLI          Start CLI mode (default)"
    Write-Host "  gentle-vanguard.exe -Version      Show version"
    
    Write-Host "`nFor more information, visit: https://github.com/EmmanuelOrtiz87/gentle-vanguard" -ForegroundColor Gray
}
