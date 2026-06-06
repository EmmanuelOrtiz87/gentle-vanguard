<#
.SYNOPSIS
    Auto-update Gentle-Vanguard to the latest release.
.DESCRIPTION
    Checks for updates, prompts user, downloads and installs the new version.
.PARAMETER Force
    Skip user confirmation prompt.
.PARAMETER DryRun
    Simulate the update process without making changes.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

$checkScript = Join-Path $PSScriptRoot "check-version.ps1"

function Write-Status { param([string]$Msg, [string]$Color = "White") Write-Host "$Msg" -ForegroundColor $Color }

function Restore-Backup {
    param([string]$ExePath, [string]$BackupPath)
    if (Test-Path $BackupPath) {
        Write-Status "Restoring backup..." Yellow
        Copy-Item -LiteralPath $BackupPath -Destination $ExePath -Force
        Remove-Item -LiteralPath $BackupPath -Force
        Write-Status "Backup restored." Yellow
    }
}

try {
    $checkResult = & $checkScript -Quiet 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 2) {
        Write-Status "Version check failed: $checkResult" Red
        exit 1
    }

    if ($exitCode -eq 0) {
        Write-Status "Gentle-Vanguard is already up to date." Green
        exit 0
    }

    $parts = $checkResult -split '\|'
    if ($parts[0] -ne "UPDATE_AVAILABLE") {
        Write-Status "Unexpected check result: $checkResult" Red
        exit 1
    }

    $currentVersion = $parts[1]
    $latestVersion = $parts[2]
    $downloadUrl = $parts[3]

    Write-Status "Update v$latestVersion available (current: v$currentVersion)." Cyan

    if (-not $Force) {
        $response = Read-Host "Update v$latestVersion available. Download and install? [Y/N]"
        if ($response -notmatch '^[Yy]') {
            Write-Status "Update cancelled by user." Yellow
            exit 0
        }
    }

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $exeName = "gentle-vanguard.exe"
    $exePath = Join-Path $projectRoot $exeName

    if (-not (Test-Path $exePath)) {
        $exePath = Join-Path $projectRoot "bin\$exeName"
        if (-not (Test-Path $exePath)) {
            Write-Status "Executable not found at $exePath. Searching project root..." Yellow
            $exePath = Get-ChildItem -Path $projectRoot -Recurse -Filter $exeName -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
            if (-not $exePath) {
                throw "Could not find gentle-vanguard.exe. Ensure the project is built."
            }
        }
    }

    $backupPath = [System.IO.Path]::ChangeExtension($exePath, "backup.exe")
    $downloadPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "gentle-vanguard-$latestVersion.exe")

    Write-Status "Downloading v$latestVersion..." Cyan
    if ($DryRun) {
        Write-Status "[DRY-RUN] Would download: $downloadUrl" Yellow
        Write-Status "[DRY-RUN] Would save to: $downloadPath" Yellow
    } else {
        try {
            $null = Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -ErrorAction Stop
            Write-Status "Download complete." Green
        } catch {
            throw "Download failed: $($_.Exception.Message)"
        }

        if (-not (Test-Path $downloadPath)) {
            throw "Downloaded file not found at $downloadPath"
        }
    }

    Write-Status "Creating backup..." Cyan
    if ($DryRun) {
        Write-Status "[DRY-RUN] Would backup: $exePath -> $backupPath" Yellow
    } else {
        Copy-Item -LiteralPath $exePath -Destination $backupPath -Force
        Write-Status "Backup created: $backupPath" Green
    }

    Write-Status "Installing update..." Cyan
    if ($DryRun) {
        Write-Status "[DRY-RUN] Would replace: $exePath with $downloadPath" Yellow
    } else {
        Copy-Item -LiteralPath $downloadPath -Destination $exePath -Force
        Write-Status "Update installed." Green
    }

    Write-Status "Verifying new executable..." Cyan
    if ($DryRun) {
        Write-Status "[DRY-RUN] Would verify: $exePath -Version" Yellow
        Write-Status "[DRY-RUN] Update simulation complete. No changes were made." Green
        exit 0
    } else {
        try {
            $versionOutput = & $exePath -Version 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "New executable exited with code $LASTEXITCODE"
            }
            Write-Status "Verification passed: $versionOutput" Green
        } catch {
            Write-Status "Verification failed: $($_.Exception.Message)" Red
            Restore-Backup $exePath $backupPath
            Write-Status "Update failed. Previous version restored." Red
            exit 1
        }
    }

    Remove-Item -LiteralPath $downloadPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue

    Write-Status "Update complete. You are now running v$latestVersion." Green
    exit 0
} catch {
    Write-Status "Auto-update failed: $($_.Exception.Message)" Red
    exit 1
}
