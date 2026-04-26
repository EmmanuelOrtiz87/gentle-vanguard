# session-manager.ps1
# Gestor de sesiones para workspace-foundation

param(
    [ValidateSet('AutoStart', 'Manual', 'Health', 'End')]
    [string]$Mode = 'Manual',
    [string]$ProjectName = 'workspace_local',
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

# Asegurar que existe el directorio de sesión
if (-not (Test-Path $SessionDir)) {
    New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null
    Write-Info "Created session directory: $SessionDir"
}

function Initialize-Session {
    param([string]$Mode)
    
    Write-Status "Initializing session in $Mode mode"
    
    # Generar ID de sesión
    $date = Get-Date -Format "yyyy-MM-dd"
    $sessionNumber = (Get-ChildItem -Path $SessionDir -Filter "session-$date-*" -ErrorAction SilentlyContinue | Measure-Object).Count + 1
    $sessionId = "session-$date-$($sessionNumber.ToString('D2'))"
    
    # Crear archivo de sesión
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
    
    $sessionFiles = Get-ChildItem -Path $SessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                    Sort-Object -Property LastWriteTime -Descending
    
    if ($sessionFiles.Count -eq 0) {
        Write-Warning "No active sessions to end"
        return
    }
    
    $latestSession = $sessionFiles | Select-Object -First 1
    $sessionData = Get-Content -Path $latestSession.FullName -Raw | ConvertFrom-Json
    
    $sessionData | Add-Member -NotePropertyName "endTime" -NotePropertyValue (Get-Date -Format "o") -PassThru | 
    ForEach-Object { $_.endTime = Get-Date -Format "o" }
    
    $sessionData.status = "ended"
    $sessionData.endTime = Get-Date -Format "o"
    
    $sessionData | ConvertTo-Json | Out-File -FilePath $latestSession.FullName -Encoding UTF8
    
    Write-Status "Session ended: $($sessionData.sessionId)"
}

# Ejecutar según el modo
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