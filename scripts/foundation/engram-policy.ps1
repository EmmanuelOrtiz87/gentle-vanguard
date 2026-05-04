# engram-policy.ps1
# Política de disponibilidad de engram: siempre instalado, activo y disponible
# desde el inicio de sesión hasta el cierre de sesión

param(
    [ValidateSet('check', 'enforce', 'repair', 'install', 'start', 'status')]
    [string]$Action = 'status',
    
    [string]$EngramPath = "$HOME\bin\engram.exe",
    [string]$ToolsPath = ".\workspace-foundation\tools\engram.exe",
    [string]$GoPath = "$HOME\go\bin\engram.exe"
)

$ErrorActionPreference = "Continue"

function Write-PolicyStatus {
    param([string]$Message)
    Write-Host "[ENGRAM-POLICY] $Message" -ForegroundColor Cyan
}

function Write-PolicyWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-PolicyError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-PolicySuccess {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Verificar instalación
function Test-EngramInstalled {
    $locations = @($EngramPath, $ToolsPath, $GoPath)
    $found = @()
    
    foreach ($loc in $locations) {
        if (Test-Path $loc) {
            $found += $loc
            $version = & $loc --version 2>&1 | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches.Value }
            Write-PolicyStatus "Found: $loc (v$version)"
        }
    }
    
    return $found
}

# Verificar si engram está corriendo
function Test-EngramRunning {
    $process = Get-Process -Name "engram" -ErrorAction SilentlyContinue
    if ($process) {
        Write-PolicySuccess "Engram running (PID: $($process.Id))"
        return $true
    } else {
        Write-PolicyWarning "Engram not running"
        return $false
    }
}

# Iniciar engram
function Start-Engram {
    $installed = Test-EngramInstalled
    if ($installed.Count -eq 0) {
        Write-PolicyError "Engram not installed. Run with -Action install"
        return $false
    }
    
    $binary = $installed[0]
    Start-Process -FilePath $binary -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    
    if (Test-EngramRunning) {
        Write-PolicySuccess "Engram started successfully"
        return $true
    } else {
        Write-PolicyError "Failed to start engram"
        return $false
    }
}

# Instalar/actualizar engram
function Install-Engram {
    Write-PolicyStatus "Installing/updating engram..."
    
    # Detener proceso si está corriendo
    $process = Get-Process -Name "engram" -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Id $process.Id -Force
        Start-Sleep -Seconds 1
    }
    
    # Instalar via go install
    try {
        go install github.com/workspace-foundation/engram/cmd/engram@latest
        Write-PolicySuccess "Engram installed via go install"
    } catch {
        Write-PolicyError "go install failed: $_"
        return $false
    }
    
    # Copiar a ubicaciones estándar
    if (Test-Path $GoPath) {
        Copy-Item $GoPath $EngramPath -Force
        Copy-Item $GoPath $ToolsPath -Force
        Write-PolicySuccess "Binaries copied to standard locations"
    }
    
    # Ejecutar setup
    & $EngramPath setup opencode 2>&1 | Out-Null
    Write-PolicySuccess "Engram configured for opencode"
    
    return $true
}

# Reparar instalación
function Repair-Engram {
    Write-PolicyStatus "Repairing engram installation..."
    
    $installed = Test-EngramInstalled
    if ($installed.Count -eq 0) {
        Write-PolicyWarning "No installation found, installing..."
        return Install-Engram
    }
    
    # Verificar integridad
    foreach ($loc in $installed) {
        $size = (Get-Item $loc).Length
        if ($size -lt 1000000) {  # Menos de 1MB probablemente está corrupto
            Write-PolicyWarning "$loc appears corrupted (size: $size bytes)"
            return Install-Engram
        }
    }
    
    # Asegurar que esté en todas las ubicaciones
    $source = $installed[0]
    Copy-Item $source $EngramPath -Force -ErrorAction SilentlyContinue
    Copy-Item $source $ToolsPath -Force -ErrorActionSilentlyContinue
    
    Write-PolicySuccess "Repair completed"
    return $true
}

# Ejecutar acción
switch ($Action) {
    'status' {
        Write-PolicyStatus "=== Engram Policy Status ==="
        $installed = Test-EngramInstalled
        if ($installed.Count -eq 0) {
            Write-PolicyError "Engram NOT installed"
        }
        $running = Test-EngramRunning
        if (-not $running) {
            Write-PolicyWarning "Engram NOT running"
        }
        break
    }
    'check' {
        $installed = Test-EngramInstalled
        $running = Test-EngramRunning
        if ($installed.Count -gt 0 -and $running) {
            Write-PolicySuccess "Engram policy: COMPLIANT"
            exit 0
        } else {
            Write-PolicyError "Engram policy: NON-COMPLIANT"
            exit 1
        }
        break
    }
    'enforce' {
        $installed = Test-EngramInstalled
        if ($installed.Count -eq 0) {
            Install-Engram
        }
        $running = Test-EngramRunning
        if (-not $running) {
            Start-Engram
        }
        Write-PolicySuccess "Engram policy enforced"
        break
    }
    'repair' {
        Repair-Engram
        Start-Engram
        break
    }
    'install' {
        Install-Engram
        Start-Engram
        break
    }
    'start' {
        Start-Engram
        break
    }
}

Write-PolicyStatus "=== Policy check complete ==="
