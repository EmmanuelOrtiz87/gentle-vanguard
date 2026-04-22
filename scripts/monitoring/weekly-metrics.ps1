#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Genera mtricas semanales del workspace usando Engram.

.DESCRIPTION
    Recopila estadsticas de uso, sesiones, y estado del proyecto
    usando Engram y otras herramientas del workspace.

.PARAMETER ProjectName
    Nombre del proyecto. Por defecto: workspace_local

.PARAMETER OutputPath
    Ruta del archivo de reporte. Por defecto: logs/weekly-metrics-{date}.md

.PARAMETER Email
    Enviar reporte por email (requiere configuracin SMTP)

.EXAMPLE
    .\weekly-metrics.ps1
    Genera reporte de mtricas semanales

.EXAMPLE
    .\weekly-metrics.ps1 -ProjectName "workspace_local" -Email
    Genera reporte y lo enva por email
#>

param(
    [string]$ProjectName = "workspace_local",
    [string]$OutputPath = "",
    [switch]$Email
)

$ErrorActionPreference = "Continue"

if ([string]::IsNullOrEmpty($OutputPath)) {
    $date = Get-Date -Format "yyyy-MM-dd"
    $OutputPath = "logs/weekly-metrics-$date.md"
}

function Write-Section {
    param([string]$Title, [string]$Content = "")
    
    $output = "`n## $Title`n"
    if ($Content) {
        $output += "`n$Content`n"
    }
    return $output
}

function Get-EngramStats {
    param([string]$Project)
    
    Write-Host "Obteniendo estadisticas de Engram..." -ForegroundColor Yellow
    
    try {
        $stats = & engram stats --project $Project 2>&1
        return $stats -join "`n"
    }
    catch {
        return "Error al obtener estadisticas de Engram: $_"
    }
}

function Get-SessionStats {
    Write-Host "Analizando sesiones..." -ForegroundColor Yellow
    
    $sessionDocs = "workspace-foundation\docs\sessions"
    if (-not (Test-Path $sessionDocs)) {
        return "No se encontraron documentos de sesion"
    }
    
    $sessions = Get-ChildItem -Path $sessionDocs -Filter "*.md" -Recurse
    $lastWeek = (Get-Date).AddDays(-7)
    $recentSessions = $sessions | Where-Object { $_.LastWriteTime -gt $lastWeek }
    
    $stats = @"
- **Total de sesiones (historico)**: $($sessions.Count)
- **Sesiones ultima semana**: $($recentSessions.Count)
- **Promedio diario**: $([math]::Round($recentSessions.Count / 7, 2))
"@
    
    return $stats
}

function Get-CodeStats {
    Write-Host "Analizando codigo..." -ForegroundColor Yellow
    
    $stats = @()
    
    # PowerShell scripts
    $ps1Files = Get-ChildItem -Path . -Filter "*.ps1" -Recurse -File | Where-Object { $_.FullName -notmatch "(node_modules|\.git|bin|obj)" }
    $ps1Lines = 0
    foreach ($file in $ps1Files) {
        $ps1Lines += (Get-Content $file.FullName).Count
    }
    
    # Bash scripts
    $shFiles = Get-ChildItem -Path . -Filter "*.sh" -Recurse -File | Where-Object { $_.FullName -notmatch "(node_modules|\.git|bin|obj)" }
    $shLines = 0
    foreach ($file in $shFiles) {
        $shLines += (Get-Content $file.FullName).Count
    }
    
    # Markdown docs
    $mdFiles = Get-ChildItem -Path . -Filter "*.md" -Recurse -File | Where-Object { $_.FullName -notmatch "(node_modules|\.git)" }
    $mdLines = 0
    foreach ($file in $mdFiles) {
        $mdLines += (Get-Content $file.FullName).Count
    }
    
    $stats = @"
- **Scripts PowerShell**: $($ps1Files.Count) archivos, $ps1Lines lineas
- **Scripts Bash**: $($shFiles.Count) archivos, $shLines lineas
- **Documentacion Markdown**: $($mdFiles.Count) archivos, $mdLines lineas
- **Total lineas de codigo**: $($ps1Lines + $shLines) lineas
- **Total lineas de documentacion**: $mdLines lineas
"@
    
    return $stats
}

function Get-GitStats {
    Write-Host "Analizando Git..." -ForegroundColor Yellow
    
    try {
        $lastWeek = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
        $commits = & git log --since="$lastWeek" --oneline 2>&1
        $commitCount = if ($commits) { ($commits | Measure-Object).Count } else { 0 }
        
        $authors = & git log --since="$lastWeek" --format="%an" 2>&1 | Sort-Object -Unique
        $authorCount = if ($authors) { ($authors | Measure-Object).Count } else { 0 }
        
        $stats = @"
- **Commits ultima semana**: $commitCount
- **Contribuidores activos**: $authorCount
- **Branch actual**: $(git branch --show-current 2>&1)
"@
        
        return $stats
    }
    catch {
        return "Git no disponible o no es un repositorio Git"
    }
}

function Get-HealthStatus {
    Write-Host "Verificando salud del workspace..." -ForegroundColor Yellow
    
    try {
        $health = & ".\scripts\utilities\wf.ps1" health 2>&1
        return $health -join "`n"
    }
    catch {
        return "Error al verificar salud del workspace"
    }
}

function Generate-MetricsReport {
    Write-Host "`n=== Generando Reporte de Metricas Semanales ===" -ForegroundColor Cyan
    
    $reportDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $weekStart = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
    $weekEnd = Get-Date -Format "yyyy-MM-dd"
    
    $report = @"
# Metricas Semanales del Workspace

**Proyecto**: $ProjectName
**Periodo**: $weekStart a $weekEnd
**Generado**: $timestamp

---

"@
    
    # Engram Stats
    $report += Write-Section "Estadisticas de Engram" (Get-EngramStats -Project $ProjectName)
    
    # Session Stats
    $report += Write-Section "Estadisticas de Sesiones" (Get-SessionStats)
    
    # Code Stats
    $report += Write-Section "Estadisticas de Codigo" (Get-CodeStats)
    
    # Git Stats
    $report += Write-Section "Estadisticas de Git" (Get-GitStats)
    
    # Health Status
    $report += Write-Section "Estado de Salud del Workspace" (Get-HealthStatus)
    
    # Recommendations
    $report += Write-Section "Recomendaciones" @"
- Revisar sesiones con bajo rendimiento
- Actualizar documentacion obsoleta
- Ejecutar auditorias de codigo periodicamente
- Mantener Engram sincronizado con backups
"@
    
    # Save report
    Set-Content -Path $OutputPath -Value $report -Encoding UTF8
    
    Write-Host "`nReporte generado exitosamente:" -ForegroundColor Green
    Write-Host "  $OutputPath" -ForegroundColor Cyan
    
    return $OutputPath
}

# Generate report
$reportPath = Generate-MetricsReport

# Email if requested
if ($Email) {
    Write-Host "`nFuncionalidad de email no implementada aun" -ForegroundColor Yellow
    Write-Host "Configurar SMTP en config/email-settings.json" -ForegroundColor Gray
}

Write-Host "`nMetricas semanales completadas" -ForegroundColor Green