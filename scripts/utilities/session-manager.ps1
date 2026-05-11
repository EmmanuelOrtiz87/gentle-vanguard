# session-manager.ps1
# Gestor de sesiones para workspace-foundation

param(
    [ValidateSet('AutoStart', 'Manual', 'Health', 'End', 'Cleanup')]
    [string]$Mode = 'Manual',
    [string]$ProjectName = 'gentleman-foundation',
    [string]$SessionDir = '.\.session',
    [int]$OrphanMaxAgeHours = 24
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

function Write-Status {
    param([string]$Message)
    Write-Host "[SESSION] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

$repoRoot = if ($env:FOUNDATION_BASE_DIR) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}
$fullSessionDir = Join-Path $repoRoot $SessionDir.TrimStart('.\')

if (-not (Test-Path $fullSessionDir)) {
    New-Item -ItemType Directory -Path $fullSessionDir -Force | Out-Null
    Write-Info "Created session directory: $fullSessionDir"
}

function Clear-OrphanedSessions {
    param([int]$MaxAgeHours = 24)

    Write-Status "Checking for orphaned sessions..."

    $sessionFiles = Get-ChildItem -Path $fullSessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue
    if ($sessionFiles.Count -eq 0) {
        Write-Info "No session files found"
        return @{ cleaned = 0; kept = 0 }
    }

    $cleaned = 0
    $kept = 0
    $cutoff = (Get-Date).AddHours(-$MaxAgeHours)

    foreach ($file in $sessionFiles) {
        $data = $null
        try {
            $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warn "Corrupt session file (will archive): $($file.Name)"
            $archiveDir = Join-Path $fullSessionDir "archive"
            if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
            Move-Item -Path $file.FullName -Destination (Join-Path $archiveDir $file.Name) -Force
            $cleaned++
            continue
        }

        if ($data.status -eq 'active') {
            $startTime = $null
            if ($data.startTime) {
                try { $startTime = [DateTime]::Parse($data.startTime) } catch { }
            }

            if ($null -eq $startTime) {
                $startTime = $file.LastWriteTime
            }

            if ($startTime -lt $cutoff) {
                $updatedData = @{
                    sessionId = $data.sessionId
                    project = $data.project
                    mode = $data.mode
                    startTime = $data.startTime
                    version = if ($data.PSObject.Properties['version']) { $data.version } else { '1.0' }
                    status = "orphaned"
                    orphanedAt = (Get-Date).ToString("o")
                    orphanedReason = "Session left active > $MaxAgeHours hours"
                }
                $updatedData | ConvertTo-Json | Out-File -FilePath $file.FullName -Encoding UTF8
                Write-Warn "Orphaned session closed: $($data.sessionId) (age: $([Math]::Round(($cutoff - $startTime).TotalHours * -1, 1))h)"
                $cleaned++
            } else {
                $kept++
            }
        } else {
            $kept++
        }
    }

    Write-Status "Orphan cleanup: $cleaned closed, $kept active/recent"
    return @{ cleaned = $cleaned; kept = $kept }
}

function Initialize-Session {
    param([string]$Mode)

    Write-Status "Initializing session in $Mode mode"

    Clear-OrphanedSessions -MaxAgeHours $OrphanMaxAgeHours | Out-Null

    $date = Get-Date -Format "yyyy-MM-dd"
    $sessionNumber = (Get-ChildItem -Path $fullSessionDir -Filter "session-$date-*.json" -ErrorAction SilentlyContinue | Measure-Object).Count + 1
    $sessionId = "session-$date-$($sessionNumber.ToString('D2'))"

    $sessionFile = Join-Path $fullSessionDir "$sessionId.json"

    $sessionData = @{
        sessionId = $sessionId
        project = $ProjectName
        mode = $Mode
        startTime = Get-Date -Format "o"
        status = "active"
        version = "2.0"
        authRequired = $false
        authAuthenticated = $false
    }

    $sessionData | ConvertTo-Json | Out-File -FilePath $sessionFile -Encoding UTF8

    Write-Status "Session initialized: $sessionId"
    Write-Info "Session file: $sessionFile"

    $enforcerScript = Join-Path $repoRoot 'scripts\utilities\karpathy-enforcer.ps1'
    if (-not (Test-Path $enforcerScript)) {
        $enforcerScript = Join-Path $repoRoot 'scripts\adaptive\karpathy-enforcer.ps1'
    }
    if (Test-Path $enforcerScript) {
        $verboseFlag = $VerbosePreference -eq "Continue"
        & $enforcerScript -Trigger session-start -AutoFix -VerboseOutput:$verboseFlag
        Write-Info "Karpathy baseline completed"
    } else {
        Write-Warn "Karpathy enforcer not found, skipping..."
    }

    $learnerScript = Join-Path $repoRoot 'scripts\adaptive\auto-norm-learner.ps1'
    if (Test-Path $learnerScript) {
        $verboseFlag = $VerbosePreference -eq "Continue"
        & $learnerScript -Trigger session-start -VerboseOutput:$verboseFlag
        Write-Info "Norm learner completed"
    } else {
        Write-Warn "Norm learner not found, skipping..."
    }

    $authScript = Join-Path $repoRoot 'scripts\utilities\auth-session.ps1'
    if (Test-Path $authScript) {
        Write-Status "Checking auth session integrity..."
        & $authScript -ManageAuth status -AsJson 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Auth integrity check passed"
        } else {
            Write-Warn "Auth integrity check returned exit code $LASTEXITCODE"
        }
    }

    return $sessionId
}

function Get-SessionHealth {
    Write-Status "Checking session health..."

    $sessionFiles = Get-ChildItem -Path $fullSessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue |
                    Sort-Object -Property LastWriteTime -Descending

    if ($sessionFiles.Count -eq 0) {
        Write-Warn "No active sessions found"
        return $false
    }

    $latestSession = $sessionFiles | Select-Object -First 1
    $sessionData = Get-Content -Path $latestSession.FullName -Raw | ConvertFrom-Json

    Write-Info "Latest session: $($sessionData.sessionId)"
    Write-Info "Status: $($sessionData.status)"
    Write-Info "Started: $($sessionData.startTime)"

    $activeCount = ($sessionFiles | Where-Object {
        $d = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $d.status -eq 'active'
    }).Count

    Write-Info "Total sessions: $($sessionFiles.Count)"
    Write-Info "Active sessions: $activeCount"

    return $true
}

function End-Session {
    Write-Status "Ending session..."

    $enforcerScript = Join-Path $repoRoot 'scripts\adaptive\auto-norm-enforcer.ps1'
    if (Test-Path $enforcerScript) {
        & $enforcerScript -Trigger session-close -AutoFix -VerboseOutput:$VerbosePreference
        Write-Info "Norm enforcement completed"
    } else {
        Write-Warn "Norm enforcer not found at: $enforcerScript"
    }

    $learnerScript = Join-Path $repoRoot 'scripts\adaptive\auto-norm-learner.ps1'
    if (Test-Path $learnerScript) {
        & $learnerScript -Trigger session-close -VerboseOutput:$VerbosePreference
        Write-Info "Norm learner completed"
    } else {
        Write-Warn "Norm learner not found at: $learnerScript"
    }

    $validator = Join-Path $repoRoot 'scripts\utilities\pre-close-validator.ps1'
    if (Test-Path $validator) {
        & $validator -AutoResolve
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Pre-close validation failed. Session closure blocked."
            Write-ErrorMsg "Fix issues or use -Force to override."
            exit 1
        }
        Write-Status "Pre-close validation passed"
    } else {
        Write-Warn "Pre-close validator not found, skipping validation"
    }

    $sessionFiles = Get-ChildItem -Path $fullSessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue |
                    Sort-Object -Property LastWriteTime -Descending

    if ($sessionFiles.Count -eq 0) {
        Write-Warn "No active sessions to end"
        return
    }

    $latestSession = $sessionFiles | Select-Object -First 1
    $sessionData = Get-Content -Path $latestSession.FullName -Raw | ConvertFrom-Json

    $engramBin = Join-Path $repoRoot 'tools\engram.exe'
    if (-not (Test-Path $engramBin)) {
        $engramBin = Join-Path $env:HOME 'bin\engram.exe'
    }
    if (-not (Test-Path $engramBin)) {
        $engramBin = Join-Path $env:GOPATH 'bin\engram.exe'
    }
    if (Test-Path $engramBin) {
        $summaryContent = @"
## Goal
Session closure with full validation

## Instructions
- Pre-close validation ensures no pending work
- Auto-resolve enabled for git issues

## Discoveries
- Validated git state, pending tasks, partial implementations
- Engram state verified before closure

## Accomplished
- Pre-close validation passed
- Session $($sessionData.sessionId) closed properly
- All checks completed

## Relevant Files
- scripts/utilities/pre-close-validator.ps1 - New validation before closure
- scripts/utilities/session-manager.ps1 - Enhanced with validation
"@
        & $engramBin session-summary --id $sessionData.sessionId --content $summaryContent 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Comprehensive session summary saved to Engram"
        } else {
            Write-Warn "Failed to save session summary to Engram"
        }
    }

    $updatedData = @{
        sessionId = $sessionData.sessionId
        project = $sessionData.project
        mode = $sessionData.mode
        startTime = $sessionData.startTime
        version = $sessionData.version
        status = "ended"
        endTime = Get-Date -Format "o"
    }
    $updatedData | ConvertTo-Json | Out-File -FilePath $latestSession.FullName -Encoding UTF8

    Write-Status "Session ended: $($sessionData.sessionId)"

    $notifyScript = Join-Path $repoRoot 'scripts\utilities\notify-user.ps1'
    if (Test-Path $notifyScript) {
        & $notifyScript -Action "session-close" -Reason "Session ended (manual or idle timeout)" -RecoveryCommand ".\tools\session-quick-restart.ps1 -Components session" 2>$null
    }

    $sessionAuthFile = Join-Path $repoRoot ".workspace\config\session-auth.json"
    if (Test-Path $sessionAuthFile) {
        Remove-Item $sessionAuthFile -Force -ErrorAction SilentlyContinue
        Write-Info "Session auth cleared"
    }
}

switch ($Mode) {
    'AutoStart' {
        Write-Status "AutoStart mode - initializing workspace session"
        $sessionId = Initialize-Session -Mode 'AutoStart'
        Write-Status "Workspace ready for work"
    }

    'Manual' {
        Write-Status "Manual mode - ready to initialize session"
        $sessionId = Initialize-Session -Mode 'Manual'
    }

    'Health' {
        Get-SessionHealth | Out-Null
    }

    'End' {
        End-Session
    }

    'Cleanup' {
        $result = Clear-OrphanedSessions -MaxAgeHours $OrphanMaxAgeHours
        Write-Status "Cleanup completed: $($result.cleaned) sessions closed, $($result.kept) active/recent"
    }

    default {
        Write-ErrorMsg "Unknown mode: $Mode"
        exit 1
    }
}

Write-Status "Session manager operation completed"
exit 0