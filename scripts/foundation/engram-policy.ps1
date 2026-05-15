# engram-policy.ps1
# Politica de disponibilidad de engram: siempre instalado, activo y disponible
# desde el inicio de sesion hasta el cierre de sesion

param(
    [ValidateSet('check', 'enforce', 'repair', 'install', 'start', 'status')]
    [string]$Action = 'status',
    
    [string]$EngramPath = "$HOME\bin\engram.exe",
    [string]$ToolsPath = "",
    [string]$GoPath = "$HOME\go\bin\engram.exe",
    [string]$DataDir = ""
)

$ErrorActionPreference = "Continue"

$script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($ToolsPath)) {
    $ToolsPath = Join-Path $script:RepoRoot 'tools\engram.exe'
}
if ([string]::IsNullOrWhiteSpace($DataDir)) {
    $DataDir = Join-Path $script:RepoRoot '.engram-data'
}

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

function Initialize-EngramDataDir {
    if (-not (Test-Path $DataDir)) {
        New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
    }

    $env:ENGRAM_DATA_DIR = (Resolve-Path $DataDir).Path
    Write-PolicyStatus "Data dir: $env:ENGRAM_DATA_DIR"
}

# Verificar instalacion
function Test-EngramInstalled {
    $locations = @($ToolsPath, $EngramPath, $GoPath)
    $found = @()
    
    foreach ($loc in $locations) {
        if (Test-Path $loc) {
            $found += $loc
            $versionOutput = & $loc version 2>&1
            $version = ($versionOutput | Select-String -Pattern 'engram\s+(\d+\.\d+\.\d+)' | Select-Object -First 1).Matches.Groups[1].Value
            if ([string]::IsNullOrWhiteSpace($version)) { $version = 'unknown' }
            Write-PolicyStatus "Found: $loc (v$version)"
        }
    }
    
    return $found
}

# Verificar si engram esta corriendo
function Test-EngramRunning {
    param([switch]$Quiet)

    $process = Get-Process -Name "engram" -ErrorAction SilentlyContinue
    if ($process) {
        Write-PolicySuccess "Engram running (PID: $($process.Id))"
        return $true
    } else {
        if (-not $Quiet) {
            Write-PolicyWarning "Engram not running"
        }
        return $false
    }
}

# Iniciar engram
function Start-Engram {
    Initialize-EngramDataDir
    $installed = Test-EngramInstalled
    if ($installed.Count -eq 0) {
        Write-PolicyError "Engram not installed. Run with -Action install"
        return $false
    }
    
    $binary = $installed[0]
    $logDir = Join-Path $script:RepoRoot 'logs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $stdoutLog = Join-Path $logDir 'engram-serve.out.log'
    $stderrLog = Join-Path $logDir 'engram-serve.err.log'
    Start-Process -FilePath $binary -ArgumentList "serve" -WorkingDirectory $script:RepoRoot -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
    Start-Sleep -Seconds 5
    
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
    Initialize-EngramDataDir
    
    # Detener proceso si esta corriendo
    $process = Get-Process -Name "engram" -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Id $process.Id -Force
        Start-Sleep -Seconds 1
    }
    
    # Instalar via go install
    try {
        go install github.com/foundation/engram/cmd/engram@latest
        Write-PolicySuccess "Engram installed via go install"
    } catch {
        Write-PolicyError "go install failed: $_"
        return $false
    }
    
    # Copiar a ubicaciones estandar
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

# Reparar instalacion
function Repair-Engram {
    Write-PolicyStatus "Repairing engram installation..."
    Initialize-EngramDataDir
    
    $installed = Test-EngramInstalled
    if ($installed.Count -eq 0) {
        Write-PolicyWarning "No installation found, installing..."
        return Install-Engram
    }
    
    # Verificar integridad
    foreach ($loc in $installed) {
        $size = (Get-Item $loc).Length
        if ($size -lt 1000000) {  # Menos de 1MB probablemente esta corrupto
            Write-PolicyWarning "$loc appears corrupted (size: $size bytes)"
            return Install-Engram
        }
    }
    
    # Asegurar que este en todas las ubicaciones
    $source = $installed[0]
    Copy-Item $source $EngramPath -Force -ErrorAction SilentlyContinue
    Copy-Item $source $ToolsPath -Force -ErrorActionSilentlyContinue
    
    Write-PolicySuccess "Repair completed"
    return $true
}

# Ejecutar accion
switch ($Action) {
    'status' {
        Write-PolicyStatus "=== Engram Policy Status ==="
        Initialize-EngramDataDir
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
        Initialize-EngramDataDir
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
        Initialize-EngramDataDir
        $installed = Test-EngramInstalled
        if ($installed.Count -eq 0) {
            if (-not (Install-Engram)) { exit 1 }
        }
        $running = Test-EngramRunning -Quiet
        if (-not $running) {
            Write-PolicyStatus "Engram service not active; starting..."
            if (-not (Start-Engram)) { exit 1 }
        }
        Write-PolicySuccess "Engram policy enforced"
        break
    }
    'repair' {
        if (-not (Repair-Engram)) { exit 1 }
        if (-not (Start-Engram)) { exit 1 }
        break
    }
    'install' {
        if (-not (Install-Engram)) { exit 1 }
        if (-not (Start-Engram)) { exit 1 }
        break
    }
    'start' {
        if (-not (Start-Engram)) { exit 1 }
        break
    }
}

Write-PolicyStatus "=== Policy check complete ==="
