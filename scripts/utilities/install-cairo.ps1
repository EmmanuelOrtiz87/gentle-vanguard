<#
.SYNOPSIS
    Install Cairo native library for Windows (required by cairosvg/PNG export).
.DESCRIPTION
    Downloads and installs GTK3 Runtime which includes libcairo-2.dll and
    other GDK-Pixbuf libraries needed by cairosvg to export SVG to PNG.
    
    This script:
    1. Downloads GTK3 Runtime installer from github.com/tschoonj
    2. Installs it silently
    3. Configures PATH and GDK_PIXBUF_MODULEDIR
    4. Verifies cairosvg can import and render PNG
    
    Prerequisites: Python 3.10+, pip (cairosvg + cairocffi installed via pip)
.PARAMETER Force
    Reinstall even if Cairo is already available.
.EXAMPLE
    .\install-cairo.ps1
    .\install-cairo.ps1 -Force
#>
param(
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

function Write-Step { param([string]$Msg) Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

Write-Step 'Cairo Installation for Windows'

# Check if already working
if (-not $Force) {
    try {
        $testPng = Join-Path $env:TEMP 'cairosvg-verify.png'
        $testSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><rect width="100" height="100" fill="red"/></svg>'
        & python -c "import cairosvg; cairosvg.svg2png(bytestring=r'$testSvg'.encode(), write_to=r'$testPng')" 2>$null
        if (Test-Path $testPng) {
            Remove-Item $testPng -Force -ErrorAction SilentlyContinue
            Write-OK 'cairosvg PNG export funciona - no se necesita instalacion'
            exit 0
        }
    } catch { }
    Write-Warn 'cairosvg no puede exportar PNG - se necesita la libreria Cairo nativa'
} else {
    Write-Step 'Forzando reinstalacion...'
}

# Detect architecture
$arch = if ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }
$gtkInstallDir = Join-Path ${env:ProgramFiles} 'GTK3-Runtime'
$installerPath = Join-Path $env:TEMP 'gtk3-runtime-installer.exe'

# GTK3 Runtime installer URL (tschoonj/GTK-for-Windows-Runtime-Environment-Installer)
$gtkUrl = 'https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer/releases/download/2022-01-04/gtk3-runtime-3.24.31-2022-01-04-ts-win64.exe'

# Step 1: Try winget first (fastest)
Write-Step 'Metodo 1: winget'

$wingetAvailable = $false
try {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -ne $wingetCmd) {
        $wingetAvailable = $true
        Write-Host 'winget disponible, intentando...' -ForegroundColor Gray
        & winget install tschoonj.GTK --accept-package-agreements --accept-source-agreements 2>$null
        if (Test-Path $gtkInstallDir) {
            Write-OK 'GTK3 Runtime instalado via winget'
        }
    }
} catch { }

# Step 2: If not installed, download installer
if (-not (Test-Path $gtkInstallDir)) {
    Write-Step 'Metodo 2: Descarga manual'

    try {
        Write-Host "Descargando GTK3 Runtime ($arch bit)..." -ForegroundColor Gray
        Write-Host "URL: $gtkUrl" -ForegroundColor DarkGray

        Invoke-WebRequest -Uri $gtkUrl -OutFile $installerPath -UseBasicParsing -MaximumRetryCount 3

        if (Test-Path $installerPath) {
            $size = (Get-Item $installerPath).Length / 1MB
            Write-OK "Descargado: $([math]::Round($size, 1)) MB"

            Write-Step 'Instalando GTK3 Runtime (silencioso)'
            $proc = Start-Process -FilePath $installerPath -ArgumentList '/S /D=C:\Program Files\GTK3-Runtime' -Wait -PassThru -NoNewWindow 2>$null
            if ($proc.ExitCode -eq 0) {
                Write-OK 'GTK3 Runtime instalado'
            } else {
                Write-Warn "El instalador puede haber requerido interaccion (codigo: $($proc.ExitCode))"
                Write-Host 'Si se abrio un asistente, completalo manualmente.' -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
        } else {
            Write-Err 'Descarga fallo'
        }
    } catch {
        Write-Err "Error descargando: $($_.Exception.Message)"
        Write-Host @'
Descarga manual:
  1. Ir a: https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer/releases
  2. Descargar gtk3-runtime-*-win64.exe
  3. Ejecutar el instalador
  4. Re-ejecutar este script para verificar
'@ -ForegroundColor Yellow
    }
}

# Clean up installer
if (Test-Path $installerPath) {
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
}

# Step 3: Configure PATH and environment
if (Test-Path $gtkInstallDir) {
    Write-Step 'Configurando entorno'

    $gtkBin = Join-Path $gtkInstallDir 'bin'
    if (Test-Path $gtkBin) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -notlike "*$gtkBin*") {
            [Environment]::SetEnvironmentVariable('Path', "$userPath;$gtkBin", 'User')
            $env:Path += ";$gtkBin"
            Write-OK "Agregado al PATH: $gtkBin"
        } else {
            Write-OK "$gtkBin ya esta en PATH"
        }

        # GDK_PIXBUF_MODULEDIR
        $loadersDir = Join-Path $gtkInstallDir 'lib\gdk-pixbuf-2.0\2.10.0\loaders'
        if (Test-Path $loadersDir) {
            [Environment]::SetEnvironmentVariable('GDK_PIXBUF_MODULEDIR', $loadersDir, 'User')
            $env:GDK_PIXBUF_MODULEDIR = $loadersDir
            Write-OK "GDK_PIXBUF_MODULEDIR configurado"
        }

        # GTK3_RUNTIME
        [Environment]::SetEnvironmentVariable('GTK3_RUNTIME', $gtkInstallDir, 'User')
        $env:GTK3_RUNTIME = $gtkInstallDir

        # Verify libcairo-2.dll exists
        $cairoDll = Join-Path $gtkBin 'libcairo-2.dll'
        if (Test-Path $cairoDll) {
            Write-OK "libcairo-2.dll encontrado: $cairoDll"
        } else {
            Write-Warn "libcairo-2.dll no encontrado en $gtkBin"
        }
    }
} else {
    Write-Err 'GTK3 Runtime no se instalo correctamente'
}

# Step 4: Verify
Write-Step 'Verificando instalacion'

# Refresh PATH for current session
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

# Also add GTK bin to ptron Python's PATH if not there
if (Test-Path $gtkInstallDir) {
    $gtkBin = Join-Path $gtkInstallDir 'bin'
    if ($env:Path -notlike "*$gtkBin*") {
        $env:Path += ";$gtkBin"
    }
}

try {
    $testOut = Join-Path $env:TEMP 'cairosvg-verify.png'
    & python -c @"
import cairosvg
svg = '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\"><rect width=\"100\" height=\"100\" fill=\"red\"/></svg>'
cairosvg.svg2png(bytestring=svg.encode(), write_to=r'$testOut')
print('OK')
"@ 2>&1
    if (Test-Path $testOut) {
        $size = (Get-Item $testOut).Length
        Remove-Item $testOut -Force -ErrorAction SilentlyContinue
        Write-OK "cairosvg PNG export funciona! ($size bytes generados)"
    } else {
        Write-Err 'cairosvg PNG export sigue fallando'
        Write-Host @'
Posibles soluciones:
  1. Reiniciar la terminal y re-ejecutar este script
  2. Instalar GTK3 Runtime manualmente desde:
     https://github.com/tschoonj/GTK-for-Windows-Runtime-Environment-Installer/releases
  3. Alternativa: instalar MSYS2 + pacman -S mingw-w64-x86_64-cairo
'@ -ForegroundColor Yellow
    }
} catch {
    Write-Err "Error en verificacion: $($_.Exception.Message)"
}

Write-Step 'Resumen'
if (Test-Path $gtkInstallDir) {
    Write-Host @'
GTK3 Runtime instalado. Reinicia la terminal para que los cambios surtan efecto.

Uso con fireworks-tech-graph:
  - diagramas SVG: directo (sin Cairo)
  - export PNG:  cairosvg usa libcairo-2.dll de GTK3 Runtime
  - el skill detecta automaticamente si PNG esta disponible

Comandos utiles:
  python -c "import cairosvg; print('OK')"
  python -c "import cairo; print(cairo.cairo_version_string())"
'@ -ForegroundColor White
}