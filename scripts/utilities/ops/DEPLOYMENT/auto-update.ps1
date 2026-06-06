<#
.SYNOPSIS
    Auto-update launcher for Gentle-Vanguard
.DESCRIPTION
    Checks for updates, downloads, and applies them automatically.
    Supports rollback on failure.
.PARAMETER Check
    Check for available updates
.PARAMETER Apply
    Apply available update
.PARAMETER Schedule
    Schedule automatic checks
.EXAMPLE
    .\auto-update.ps1 -Check
    .\auto-update.ps1 -Apply
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Apply,
    [switch]$Schedule,
    [string]$Channel = "stable",  # stable, beta, alpha
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$script:VersionUrl = "https://api.github.com/repos/EmmanuelOrtiz87/gentle-vanguard/releases/latest"
$script:UpdateDir = Join-Path $PSScriptRoot "..\..\..\.updates"
$script:CurrentVersion = "2.30.0"
$script:BackupDir = Join-Path $PSScriptRoot "..\..\..\.backups"

function Write-Log {
    param([string]$Level, [string]$Message)
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Get-LatestVersion {
    try {
        $response = Invoke-RestMethod -Uri $script:VersionUrl -Method Get
        return @{
            version = $response.tag_name -replace "v", ""
            url = $response.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 -ExpandProperty browser_download_url
            notes = $response.body
            published = $response.published_at
        }
    } catch {
        Write-Log "ERROR" "Failed to check for updates: $_"
        return $null
    }
}

function Compare-Versions {
    param([string]$Current, [string]$Latest)
    
    $currentParts = $Current.Split(".")
    $latestParts = $Latest.Split(".")
    
    for ($i = 0; $i -lt [Math]::Max($currentParts.Length, $latestParts.Length); $i++) {
        $c = if ($i -lt $currentParts.Length) { [int]$currentParts[$i] } else { 0 }
        $l = if ($i -lt $latestParts.Length) { [int]$latestParts[$i] } else { 0 }
        
        if ($l -gt $c) { return 1 }
        if ($l -lt $c) { return -1 }
    }
    
    return 0
}

function Backup-Current {
    if (-not (Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $script:BackupDir "backup-$timestamp.zip"
    
    $projectRoot = Join-Path $PSScriptRoot "..\..\.."
    Compress-Archive -Path "$projectRoot\*" -DestinationPath $backupPath -Force
    
    Write-Log "SUCCESS" "Backup created: $backupPath"
    return $backupPath
}

function Download-Update {
    param([string]$Url, [string]$Version)
    
    if (-not (Test-Path $script:UpdateDir)) {
        New-Item -ItemType Directory -Path $script:UpdateDir -Force | Out-Null
    }
    
    $updateFile = Join-Path $script:UpdateDir "update-$Version.zip"
    
    Write-Log "INFO" "Downloading update..."
    Invoke-WebRequest -Uri $Url -OutFile $updateFile
    
    Write-Log "SUCCESS" "Downloaded: $updateFile"
    return $updateFile
}

function Apply-Update {
    param([string]$UpdateFile)
    
    Write-Log "INFO" "Applying update..."
    
    $extractDir = Join-Path $script:UpdateDir "extracted"
    if (Test-Path $extractDir) {
        Remove-Item -Path $extractDir -Recurse -Force
    }
    
    Expand-Archive -Path $UpdateFile -DestinationPath $extractDir
    
    # Copy files (preserving user config)
    $projectRoot = Join-Path $PSScriptRoot "..\..\.."
    $exclude = @("config\orchestrator.json", ".session", ".logs", ".engram-data")
    
    Get-ChildItem -Path $extractDir -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($extractDir.Length + 1)
        $shouldExclude = $false
        
        foreach ($ex in $exclude) {
            if ($relativePath -like "*$ex*") {
                $shouldExclude = $true
                break
            }
        }
        
        if (-not $shouldExclude -and -not $_.PSIsContainer) {
            $targetPath = Join-Path $projectRoot $relativePath
            $targetDir = Split-Path -Parent $targetPath
            
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            Copy-Item $_.FullName $targetPath -Force
        }
    }
    
    Write-Log "SUCCESS" "Update applied successfully"
}

function Test-UpdateHealth {
    Write-Log "INFO" "Testing update health..."
    
    # Run validation scripts
    $validators = @(
        "scripts\utilities\VALIDATE\validate-configs.ps1"
        "scripts\utilities\WORKFLOW-ORCHESTRATION\validate-system-health.ps1"
    )
    
    foreach ($validator in $validators) {
        $path = Join-Path $PSScriptRoot "..\..\.." $validator
        if (Test-Path $path) {
            try {
                & $path
                Write-Log "SUCCESS" "Validation passed: $validator"
            } catch {
                Write-Log "ERROR" "Validation failed: $validator"
                return $false
            }
        }
    }
    
    return $true
}

function Rollback-Update {
    param([string]$BackupPath)
    
    Write-Log "WARN" "Rolling back update..."
    
    $projectRoot = Join-Path $PSScriptRoot "..\..\.."
    
    # Restore from backup
    Expand-Archive -Path $BackupPath -DestinationPath $projectRoot -Force
    
    Write-Log "SUCCESS" "Rollback complete"
}

# Main execution
if ($Check) {
    Write-Log "INFO" "Checking for updates..."
    Write-Log "INFO" "Current version: $script:CurrentVersion"
    Write-Log "INFO" "Channel: $Channel"
    
    $latest = Get-LatestVersion
    
    if ($latest) {
        Write-Log "INFO" "Latest version: $($latest.version)"
        
        $comparison = Compare-Versions -Current $script:CurrentVersion -Latest $latest.version
        
        if ($comparison -lt 0) {
            Write-Log "SUCCESS" "Update available: $($latest.version)"
            Write-Log "INFO" "Published: $($latest.published)"
            Write-Log "INFO" "Use -Apply to install"
            
            return @{
                available = $true
                version = $latest.version
                url = $latest.url
                notes = $latest.notes
            } | ConvertTo-Json
        } else {
            Write-Log "SUCCESS" "Already up to date"
        }
    }
}

if ($Apply) {
    Write-Log "INFO" "Applying update..."
    
    $latest = Get-LatestVersion
    if (-not $latest) {
        Write-Log "ERROR" "Could not get latest version"
        exit 1
    }
    
    # Backup current
    $backupPath = Backup-Current
    
    try {
        # Download
        $updateFile = Download-Update -Url $latest.url -Version $latest.version
        
        # Apply
        Apply-Update -UpdateFile $updateFile
        
        # Test
        if (-not (Test-UpdateHealth)) {
            throw "Update health check failed"
        }
        
        Write-Log "SUCCESS" "Update to $($latest.version) complete!"
    }
    catch {
        Write-Log "ERROR" "Update failed: $_"
        
        if ($backupPath -and (Test-Path $backupPath)) {
            Rollback-Update -BackupPath $backupPath
        }
        
        exit 1
    }
}

if ($Schedule) {
    Write-Log "INFO" "Scheduling automatic updates..."
    
    # Create scheduled task for weekly checks
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSScriptRoot\auto-update.ps1`" -Check"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "2:00 AM"
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    Register-ScheduledTask -TaskName "GentleVanguard-AutoUpdate" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    
    Write-Log "SUCCESS" "Scheduled task created: GentleVanguard-AutoUpdate"
}
