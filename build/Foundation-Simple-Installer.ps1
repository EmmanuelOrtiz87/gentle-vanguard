# Foundation Simple Installer (PowerShell)
# No NSIS required - extracts and sets up Foundation

param(
    [string]$InstallDir = "$env:ProgramFiles\Foundation"
)

$ErrorActionPreference = "Stop"
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Output "========================================"
Write-Output "  Foundation Simple Installer"
Write-Output "========================================"
Write-Output ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Administrator privileges required. Right-click and 'Run as Administrator'."
    exit 1
}

# Create install directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Write-Output "[1/4] Install directory: $InstallDir"

# Copy protected files
if (Test-Path "build\protected") {
    Copy-Item "build\protected\*" -Destination $InstallDir -Recurse -Force
    Write-Output "[2/4] Copied protected files"
}

# Copy public stubs
if (Test-Path "build\public") {
    Copy-Item "build\public\*" -Destination $InstallDir -Recurse -Force
    Write-Output "[3/4] Copied public stubs"
}

# Copy launcher
if (Test-Path "build\Foundation-Launcher.ps1") {
    Copy-Item "build\Foundation-Launcher.ps1" -Destination $InstallDir -Force
    Write-Output "[4/4] Copied launcher"
}

# Create shortcuts
$WshShell = New-Object -comObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
$startMenu = [System.Environment]::GetFolderPath('StartMenu')

# Desktop shortcut
$shortcut = $WshShell.CreateShortcut("$desktop\Foundation.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\Foundation-Launcher.ps1`""
$shortcut.Save()

# Start Menu shortcut
$programsDir = "$startMenu\Programs\Foundation"
New-Item -ItemType Directory -Path $programsDir -Force | Out-Null
$shortcut2 = $WshShell.CreateShortcut("$programsDir\Foundation.lnk")
$shortcut2.TargetPath = "powershell.exe"
$shortcut2.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\Foundation-Launcher.ps1`""
$shortcut2.Save()

Write-Output ""
Write-Output "========================================"
Write-Output "  Installation Complete!"
Write-Output "========================================"
Write-Output "Shortcuts created on desktop and Start Menu."
Write-Output ""
Write-Output "⚠️  Remember: You need keys/master.key to decrypt scripts."
Write-Output "   Place it in: $InstallDir\keys\master.key"
