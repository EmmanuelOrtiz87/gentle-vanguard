#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Watchdog que monitorea una carpeta en busca de documentos nuevos y los analiza automaticamente.
.DESCRIPTION
    Usa FileSystemWatcher para detectar archivos nuevos/modificados (PDF, DOCX, XLSX, PPTX, MD, TXT)
    en la carpeta monitoreada y ejecuta invoke-document-analysis.ps1 automaticamente.
.PARAMETER WatchFolder
    Carpeta a monitorear. Default: docs/requirements/ (relativo a project root).
.PARAMETER OutputDir
    Directorio de salida para reportes. Default: docs/requirements-analysis/.
.PARAMETER Scope
    full | quick | tech-only | cost-only. Default: quick.
.PARAMETER Source
    document | all. Default: document.
.PARAMETER Daemon
    Ejecutar como daemon (loop continuo). Si no se especifica, corre una vez y sale.
.PARAMETER Interval
    Intervalo de polling en segundos para modo Daemon. Default: 30.
.PARAMETER Quiet
    Suprimir verbose output.
#>

param(
    [string]$WatchFolder = '',
    [string]$OutputDir = '',
    [string]$Scope = 'quick',
    [ValidateSet('document', 'all')]
    [string]$Source = 'document',
    [switch]$Daemon,
    [int]$Interval = 30,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ScriptDir -Parent
$InvokeScript = Join-Path $PSScriptRoot 'invoke-document-analysis.ps1'

if (-not $WatchFolder) { $WatchFolder = Join-Path $ProjectRoot 'docs' 'requirements' }
if (-not $OutputDir) { $OutputDir = Join-Path $ProjectRoot 'docs' 'requirements-analysis' }
New-Item -ItemType Directory -Path $WatchFolder -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$SupportedExtensions = @('.pdf', '.docx', '.doc', '.xlsx', '.xls', '.pptx', '.ppt', '.md', '.txt')
$ProcessedFiles = @{}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not $Quiet) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Watchdog] [$Level] $Message" -ForegroundColor $(if ($Level -eq 'ERROR') {'Red'} elseif ($Level -eq 'WARN') {'Yellow'} else {'DarkCyan'})
    }
}

function Invoke-DocumentAnalysis {
    param([string]$FilePath)
    $fileName = Split-Path $FilePath -Leaf
    if ($ProcessedFiles.ContainsKey($FilePath)) {
        $lastRun = $ProcessedFiles[$FilePath]
        $lastWrite = (Get-Item $FilePath).LastWriteTime
        if ($lastWrite -le $lastRun) { return } # Already processed this version
    }
    Write-Log "Nuevo documento detectado: $fileName"
    try {
        & $InvokeScript -DocumentPath $FilePath -Scope $Scope -Source $Source -OutputDir $OutputDir -Quiet:$Quiet
        $ProcessedFiles[$FilePath] = Get-Date
        Write-Log "Analisis completado: $fileName" 'OK'
    } catch { Write-Log "Error analizando $fileName`: $_" 'ERROR' }
}

function Start-WatchdogLoop {
    Write-Log "Monitoreando: $WatchFolder"
    Write-Log "Extensiones: $($SupportedExtensions -join ', ')"
    Write-Log "Output dir: $OutputDir"

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WatchFolder
    $watcher.Filter = '*.*'
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    $action = {
        $path = $Event.SourceEventArgs.FullPath
        $ext = [System.IO.Path]::GetExtension($path).ToLower()
        if ($ext -in $SupportedExtensions) {
            Start-Sleep -Seconds 2 # Wait for file to finish writing
            Invoke-DocumentAnalysis -FilePath $path
        }
    }

    Register-ObjectEvent $watcher "Created" -Action $action | Out-Null
    Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null

    Write-Log "Watchdog iniciado. Ctrl+C para detener."
    try { while ($true) { Start-Sleep -Seconds $Interval } }
    finally {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
        Write-Log "Watchdog detenido."
    }
}

if ($Daemon) { Start-WatchdogLoop }
else {
    Write-Log "Modo escaneo unico..."
    Get-ChildItem -Path $WatchFolder -Recurse -File | Where-Object { $_.Extension.ToLower() -in $SupportedExtensions } | ForEach-Object {
        Invoke-DocumentAnalysis -FilePath $_.FullName
    }
    Write-Log "Escaneo completado."
}
