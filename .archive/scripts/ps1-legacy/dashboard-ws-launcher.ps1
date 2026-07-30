# Dashboard WS Launcher Wrapper for Autoheal
# This script launches the dashboard WS server and ensures it stays running
# Called by maintenance-watchtower.ts during autoheal

param(
    [Parameter(Mandatory=$false)]
    [switch]$Quiet,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkingDirectory = "."
)

$ErrorActionPreference = "Continue"

# Change to working directory
Set-Location -Path $WorkingDirectory

# Check if already running on port 8080
$existingProcess = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | 
    Where-Object { $_.OwningProcess -gt 0 } | 
    Select-Object -First 1

if ($existingProcess) {
    $proc = Get-Process -Id $existingProcess.OwningProcess -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -eq "node") {
        if (-not $Quiet) {
            Write-Output "Dashboard WS already running on PID $($proc.Id)"
        }
        exit 0
    }
}

# Launch the dashboard WS server using Start-Process for proper Windows process management
# This creates a truly detached process that survives the autoheal
# Use cmd.exe /c start to properly detach on Windows

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = "cmd.exe"
$startInfo.Arguments = "/c start /b npx tsx src/dashboard-ws-autostart.ts --quiet"
$startInfo.WorkingDirectory = $WorkingDirectory
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true

# Start the process
$proc = [System.Diagnostics.Process]::Start($startInfo)

if ($null -eq $proc) {
    Write-Error "Failed to start process"
    exit 1
}

if (-not $Quiet) {
    Write-Output "Dashboard WS launched"
}

# Small delay to let it start
Start-Sleep -Milliseconds 500

exit 0
