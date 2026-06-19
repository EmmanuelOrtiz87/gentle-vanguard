#!/usr/bin/env pwsh
# engram-auto-sync.ps1
# Automatic Engram integrity maintenance script
# Runs during session start and periodic checks
# Prevents checksum desynchronization

param(
    [ValidateSet("check", "sync", "monitor")]
    [string]$Mode = "check",
    [int]$CheckIntervalMinutes = 60,
    [switch]$Quiet = $false
)

$ErrorActionPreference = "Continue"

# Detect repo root
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $PWD.Path
}

$integrityScript = Join-Path $repoRoot "scripts\utilities\memory\ENGRAM\engram-integrity-check.ps1"
$engramDataDir = Join-Path $repoRoot ".engram-data"
$dbPath = Join-Path $engramDataDir "engram.db"
$checksumPath = Join-Path $repoRoot ".engram\checksums.sha256"
$lockFile = Join-Path $repoRoot ".runtime\engram-sync.lock"
$lastCheckFile = Join-Path $repoRoot ".runtime\engram-last-sync.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Quiet) {
        $colors = @{INFO="Cyan"; OK="Green"; WARN="Yellow"; ERR="Red"}
        Write-Host "[ENGRAM-SYNC] [$Level] $Message" -ForegroundColor $colors[$Level]
    }
}

function Get-DbLastModified {
    if (Test-Path $dbPath) {
        $item = Get-Item $dbPath
        return $item.LastWriteTime
    }
    return $null
}

function Get-ChecksumLastModified {
    if (Test-Path $checksumPath) {
        $item = Get-Item $checksumPath
        return $item.LastWriteTime
    }
    return $null
}

function Check-Synchronization {
    Write-Log "Checking Engram synchronization..."
    
    if (-not (Test-Path $dbPath)) {
        Write-Log "Database not found, skipping" "WARN"
        return $true
    }
    
    $dbTime = Get-DbLastModified
    $checksumTime = Get-ChecksumLastModified
    
    if (-not $checksumTime) {
        Write-Log "Checksums not found, regenerating..." "WARN"
        return $false
    }
    
    # If DB was modified after checksums, they're out of sync
    if ($dbTime -gt $checksumTime) {
        $timeDiff = ($dbTime - $checksumTime).TotalSeconds
        Write-Log "DB modified $([math]::Round($timeDiff))s after checksums" "WARN"
        return $false
    }
    
    # Verify actual checksums match
    $checkResult = & $integrityScript -Mode check -Quiet 2>$null
    $checkExitCode = $LASTEXITCODE
    
    if ($checkExitCode -ne 0) {
        Write-Log "Integrity verification failed" "WARN"
        return $false
    }
    
    Write-Log "Synchronization OK" "OK"
    return $true
}

function Sync-Checksums {
    Write-Log "Regenerating checksums..."
    
    # Acquire lock to prevent concurrent operations
    $lockDir = Split-Path -Parent $lockFile
    if (-not (Test-Path $lockDir)) {
        New-Item -ItemType Directory -Path $lockDir -Force | Out-Null
    }
    
    # Simple lock: check if recent lock exists
    if (Test-Path $lockFile) {
        $lockAge = ((Get-Date) - (Get-Item $lockFile).LastWriteTime).TotalSeconds
        if ($lockAge -lt 30) {
            Write-Log "Another sync in progress, skipping" "WARN"
            return $false
        }
    }
    
    # Create lock
    Set-Content $lockFile -Value (Get-Date -Format "o") -Force
    
    try {
        # Run checksum regeneration
        & $integrityScript -Mode checksums -Quiet
        $syncExitCode = $LASTEXITCODE
        
        if ($syncExitCode -ne 0) {
            Write-Log "Checksum regeneration failed" "ERR"
            return $false
        }
        
        # Verify
        & $integrityScript -Mode check -Quiet 2>$null
        $verifyExitCode = $LASTEXITCODE
        
        if ($verifyExitCode -eq 0) {
            Write-Log "Checksums synchronized" "OK"
            
            # Record sync time
            $syncData = @{
                timestamp = (Get-Date -Format "o")
                status = "SUCCESS"
                dbModified = (Get-DbLastModified).ToString("o")
                checksumModified = (Get-ChecksumLastModified).ToString("o")
            }
            $syncData | ConvertTo-Json | Set-Content $lastCheckFile -Force
            
            return $true
        } else {
            Write-Log "Verification after sync failed" "ERR"
            return $false
        }
    } finally {
        # Release lock
        Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-PeriodicMonitor {
    Write-Log "Starting periodic monitor (interval: ${CheckIntervalMinutes}min)"
    
    while ($true) {
        Write-Log "Checking sync status..."
        
        if (-not (Check-Synchronization)) {
            Write-Log "Out of sync detected, auto-fixing..." "WARN"
            if (Sync-Checksums) {
                Write-Log "Auto-fix successful" "OK"
            } else {
                Write-Log "Auto-fix failed, manual intervention may be needed" "ERR"
            }
        }
        
        Write-Log "Next check in ${CheckIntervalMinutes} minutes"
        Start-Sleep -Seconds ($CheckIntervalMinutes * 60)
    }
}

# Main execution
switch ($Mode) {
    "check" {
        if (Check-Synchronization) {
            exit 0
        } else {
            exit 1
        }
    }
    
    "sync" {
        if (Sync-Checksums) {
            exit 0
        } else {
            exit 1
        }
    }
    
    "monitor" {
        Invoke-PeriodicMonitor
    }
}
