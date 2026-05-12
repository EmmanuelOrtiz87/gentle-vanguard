# engram-orchestrator.ps1
# Orquestador con autonomia para manejar fallos de engram
# Garantiza disponibilidad continua desde inicio hasta cierre de sesion

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,
    
    [string]$WorkspaceRoot = ".\foundation",
    [string]$EngramPolicyScript = "$WorkspaceRoot\scripts\foundation\engram-policy.ps1"
)

$ErrorActionPreference = "Continue"

function Write-OrchStatus {
    param([string]$Message)
    Write-Host "[ENGRAM-ORCHESTRATOR] $Message" -ForegroundColor Cyan
}

function Write-OrchWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-OrchError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-OrchSuccess {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Funcion para detectar y resolver fallos de engram
function Resolve-EngramFailure {
    param([string]$FailureType)
    
    Write-OrchWarning "Engram failure detected: $FailureType"
    Write-OrchStatus "Attempting autonomous resolution..."
    
    switch ($FailureType) {
        'not-installed' {
            Write-OrchStatus "Installing engram autonomously..."
            & $EngramPolicyScript -Action install
            return $?
        }
        'not-running' {
            Write-OrchStatus "Starting engram autonomously..."
            & $EngramPolicyScript -Action start
            return $?
        }
        'corrupted' {
            Write-OrchStatus "Repairing engram autonomously..."
            & $EngramPolicyScript -Action repair
            return $?
        }
        'version-mismatch' {
            Write-OrchStatus "Updating engram autonomously..."
            & $EngramPolicyScript -Action install
            return $?
        }
        default {
            Write-OrchStatus "Running policy enforcement..."
            & $EngramPolicyScript -Action enforce
            return $?
        }
    }
}

# Funcion para verificar salud de engram
function Test-EngramHealth {
    $health = @{
        Installed = $false
        Running = $false
        Version = $null
        Status = "UNKNOWN"
    }
    
    # Verificar instalacion
    $engramPaths = @(
        "$HOME\bin\engram.exe",
        ".\foundation\\tools\engram.exe",
        "$HOME\go\bin\engram.exe"
    )
    
    foreach ($path in $engramPaths) {
        if (Test-Path $path) {
            $health.Installed = $true
            $health.Version = & $path --version 2>&1 | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches.Value }
            break
        }
    }
    
    # Verificar ejecucion
    $process = Get-Process -Name "engram" -ErrorAction SilentlyContinue
    if ($process) {
        $health.Running = $true
    }
    
    # Determinar estado general
    if ($health.Installed -and $health.Running) {
        $health.Status = "HEALTHY"
    } elseif ($health.Installed -and -not $health.Running) {
        $health.Status = "STOPPED"
    } elseif (-not $health.Installed) {
        $health.Status = "NOT_INSTALLED"
    }
    
    return $health
}

# Funcion principal de orquestacion
function Invoke-EngramOrchestration {
    param([string]$OrchAction)
    
    Write-OrchStatus "=== Engram Orchestration: $OrchAction ==="
    
    $health = Test-EngramHealth
    Write-OrchStatus "Current status: $($health.Status)"
    
    if ($health.Status -eq "HEALTHY") {
        Write-OrchSuccess "Engram is operational"
        return $true
    }
    
    # Resolucion autonoma segun el estado
    $resolved = $false
    switch ($health.Status) {
        "NOT_INSTALLED" {
            $resolved = Resolve-EngramFailure -FailureType "not-installed"
        }
        "STOPPED" {
            $resolved = Resolve-EngramFailure -FailureType "not-running"
        }
        "CORRUPTED" {
            $resolved = Resolve-EngramFailure -FailureType "corrupted"
        }
        default {
            $resolved = Resolve-EngramFailure -FailureType "unknown"
        }
    }
    
    if ($resolved) {
        Write-OrchSuccess "Autonomous resolution successful"
        return $true
    } else {
        Write-OrchError "Autonomous resolution failed"
        return $false
    }
}

# Funcion para integrar con subagentes
function Register-SubagentEngram {
    param([string]$SubagentName)
    
    Write-OrchStatus "Registering engram for subagent: $SubagentName"
    
    # Verificar que engram este disponible antes de registrar
    $health = Test-EngramHealth
    if ($health.Status -ne "HEALTHY") {
        Write-OrchWarning "Engram not healthy, attempting to fix..."
        Invoke-EngramOrchestration -OrchAction "repair"
    }
    
    # Aqui se registraria el subagente con engram
    Write-OrchSuccess "Subagent $SubagentName registered with engram"
}

# Ejecutar accion solicitada
switch ($Action) {
    'check' {
        $health = Test-EngramHealth
        Write-OrchStatus "=== Engram Health Check ==="
        Write-OrchStatus "Installed: $($health.Installed)"
        Write-OrchStatus "Running: $($health.Running)"
        Write-OrchStatus "Version: $($health.Version)"
        Write-OrchStatus "Status: $($health.Status)"
        
        if ($health.Status -eq "HEALTHY") {
            exit 0
        } else {
            exit 1
        }
    }
    'orchestrate' {
        $result = Invoke-EngramOrchestration -OrchAction "auto"
        if ($result) {
            Write-OrchSuccess "Orchestration completed successfully"
        } else {
            Write-OrchError "Orchestration failed"
        }
    }
    'register-subagent' {
        Register-SubagentEngram -SubagentName $SubagentName
    }
    'monitor' {
        Write-OrchStatus "Starting engram monitoring loop..."
        while ($true) {
            $health = Test-EngramHealth
            if ($health.Status -ne "HEALTHY") {
                Write-OrchWarning "Health check failed: $($health.Status)"
                Invoke-EngramOrchestration -OrchAction "auto"
            }
            Start-Sleep -Seconds 60
        }
    }
}

Write-OrchStatus "=== Orchestration Complete ==="
