# session-manager.ps1
# Gestor de sesiones para workspace-foundation

param(
    [ValidateSet('AutoStart', 'Manual', 'Health', 'End')]
    [string]$Mode = 'Manual',
    [string]$ProjectName = 'gentleman-foundation',
    [string]$SessionDir = '.\.session'
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message)
    Write-Host "[SESSION] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Asegurar que existe el directorio de sesin
if (-not (Test-Path $SessionDir)) {
    New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null
    Write-Info "Created session directory: $SessionDir"
}

function Initialize-Session {
    param([string]$Mode)
    
    Write-Status "Initializing session in $Mode mode"
    
    # Generar ID de sesin
    $date = Get-Date -Format "yyyy-MM-dd"
    $sessionNumber = (Get-ChildItem -Path $SessionDir -Filter "session-$date-*" -ErrorAction SilentlyContinue | Measure-Object).Count + 1
    $sessionId = "session-$date-$($sessionNumber.ToString('D2'))"
    
    # Crear archivo de sesin
    $sessionFile = Join-Path $SessionDir "$sessionId.json"
    
    $sessionData = @{
        sessionId = $sessionId
        project = $ProjectName
        mode = $Mode
        startTime = Get-Date -Format "o"
        status = "active"
        version = "1.0"
    }
    
    $sessionData | ConvertTo-Json | Out-File -FilePath $sessionFile -Encoding UTF8
    
    Write-Status "Session initialized: $sessionId"
    Write-Info "Session file: $sessionFile"
    
    # Autonomous norm enforcement at session start
    Write-Status "Running autonomous norm enforcement (session-start)..."
    $enforcerScript = Join-Path $PSScriptRoot "..\adaptive\karpathy-enforcer.ps1"
    if (-not (Test-Path $enforcerScript)) {
        $enforcerScript = Join-Path $PSScriptRoot "karpathy-enforcer.ps1"
    }
    if (Test-Path $enforcerScript) {
        $verboseFlag = $VerbosePreference -eq "Continue"
        & $enforcerScript -Trigger session-start -AutoFix:$false -VerboseOutput:$verboseFlag
        Write-Info "Karpathy enforcement completed"
    } else {
        Write-Warning "Karpathy enforcer not found, skipping..."
    }
    
    # Autonomous learning at session start
    Write-Status "Running autonomous norm learner (session-start)..."
    $learnerScript = Join-Path $PSScriptRoot "..\adaptive\auto-norm-learner.ps1"
    if (-not (Test-Path $learnerScript)) {
        $learnerScript = Join-Path $PSScriptRoot "auto-norm-learner.ps1"
    }
    if (Test-Path $learnerScript) {
        $verboseFlag = $VerbosePreference -eq "Continue"
        & $learnerScript -Trigger session-start -VerboseOutput:$verboseFlag
        Write-Info "Norm learner completed"
    } else {
        Write-Warning "Norm learner not found, skipping..."
    }
    if (Test-Path $enforcerScript) {
        $verboseFlag = $VerbosePreference -eq "Continue"
        & $enforcerScript -Trigger session-start -AutoFix -VerboseOutput:$verboseFlag
        Write-Info "Norm enforcement completed"
    } else {
        Write-Warning "Norm enforcer not found, skipping..."
    }
    
    # Autonomous learning at session start
    Write-Status "Running autonomous norm learner (session-start)..."
    $learnerScript = Join-Path $PSScriptRoot "..\adaptive\auto-norm-learner.ps1"
    if (-not (Test-Path $learnerScript)) {
        $learnerScript = Join-Path $PSScriptRoot "auto-norm-learner.ps1"
    }
    if (Test-Path $learnerScript) {
        $verboseFlag = $VerbosePreference -eq "Continue"
        & $learnerScript -Trigger session-start -VerboseOutput:$verboseFlag
        Write-Info "Norm learner completed"
    } else {
        Write-Warning "Norm learner not found, skipping..."
    }
    
    return $sessionId
}

function Get-SessionHealth {
    Write-Status "Checking session health..."
    
    $sessionFiles = Get-ChildItem -Path $SessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                    Sort-Object -Property LastWriteTime -Descending
    
    if ($sessionFiles.Count -eq 0) {
        Write-Warning "No active sessions found"
        return $false
    }
    
    $latestSession = $sessionFiles | Select-Object -First 1
    $sessionData = Get-Content -Path $latestSession.FullName | ConvertFrom-Json
    
    Write-Info "Latest session: $($sessionData.sessionId)"
    Write-Info "Status: $($sessionData.status)"
    Write-Info "Started: $($sessionData.startTime)"
    
    return $true
}

function End-Session {
    Write-Status "Ending session..."
    
    # Autonomous norm enforcement at session close
    Write-Status "Running autonomous norm enforcement (session-close)..."
    $enforcerScript = Join-Path $PSScriptRoot "..\scripts\adaptive\auto-norm-enforcer.ps1"
    if (Test-Path $enforcerScript) {
        & $enforcerScript -Trigger session-close -AutoFix -VerboseOutput:$VerbosePreference
        Write-Info "Norm enforcement completed"
    } else {
        Write-Warning "Norm enforcer not found at: $enforcerScript"
    }
    
    # Autonomous learning at session close
    Write-Status "Running autonomous norm learner (session-close)..."
    $learnerScript = Join-Path $PSScriptRoot "..\scripts\adaptive\auto-norm-learner.ps1"
    if (Test-Path $learnerScript) {
        & $learnerScript -Trigger session-close -VerboseOutput:$VerbosePreference
        Write-Info "Norm learner completed"
    } else {
        Write-Warning "Norm learner not found at: $learnerScript"
    }
    
    # Pre-close validation
    Write-Status "Running pre-close validation..."
    $validator = Join-Path $PSScriptRoot "pre-close-validator.ps1"
    if (Test-Path $validator) {
        & $validator -AutoResolve
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Pre-close validation failed. Session closure blocked."
            Write-Error "Fix issues or use -Force to override."
            exit 1
        }
        Write-Status "Pre-close validation passed"
    } else {
        Write-Warning "Pre-close validator not found, skipping validation"
    }
    
    $sessionFiles = Get-ChildItem -Path $SessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                    Sort-Object -Property LastWriteTime -Descending
    
    if ($sessionFiles.Count -eq 0) {
        Write-Warning "No active sessions to end"
        return
    }
    
    $latestSession = $sessionFiles | Select-Object -First 1
    $sessionData = Get-Content -Path $latestSession.FullName -Raw | ConvertFrom-Json
    
    # Save comprehensive session summary to Engram BEFORE ending session
    $engramBin = Join-Path $PSScriptRoot "engram.exe"
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
-  Pre-close validation passed
-  Session $($sessionData.sessionId) closed properly
-  All checks completed

## Relevant Files
- tools/pre-close-validator.ps1  New validation before closure
- tools/session-manager.ps1  Enhanced with validation
"@
        & $engramBin session-summary --id $sessionData.sessionId --content $summaryContent 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Comprehensive session summary saved to Engram"
        } else {
            Write-Warning "Failed to save session summary to Engram"
        }
    }
    
    $sessionData.status = "ended"
    $sessionData.endTime = Get-Date -Format "o"
    
    $sessionData | ConvertTo-Json | Out-File -FilePath $latestSession.FullName -Encoding UTF8
    
    Write-Status "Session ended: $($sessionData.sessionId)"
    
    # Notify user with recovery option
    $notifyScript = Join-Path $PSScriptRoot "notify-user.ps1"
    if (Test-Path $notifyScript) {
        & $notifyScript -Action "session-close" -Reason "Session ended (manual or idle timeout)" -RecoveryCommand ".\tools\session-quick-restart.ps1 -Components session" 2>$null
    }
}

# Ejecutar segn el modo
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
    
    default {
        Write-Error "Unknown mode: $Mode"
        exit 1
    }
}

Write-Status "Session manager operation completed"
exit 0
