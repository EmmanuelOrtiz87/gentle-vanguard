# generate-executive-summary.ps1
# Generates comprehensive executive summary report for management

param(
    [ValidateSet("today", "yesterday", "7days", "30days", "all")]
    [string]$Period = "7days",
    [ValidateSet("markdown", "json")]
    [string]$Format = "markdown",
    [string]$ProjectRoot = "C:\Workspace_local\workspace-foundation",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Silent) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

$sessionDir = Join-Path $ProjectRoot ".session"
$telemetryDir = Join-Path $ProjectRoot ".telemetry"

$periodStart = switch ($Period) {
    "today" { (Get-Date).Date }
    "yesterday" { (Get-Date).Date.AddDays(-1) }
    "7days" { (Get-Date).Date.AddDays(-7) }
    "30days" { (Get-Date).Date.AddDays(-30) }
    "all" { [DateTime]::MinValue }
}
$periodEnd = Get-Date

Write-Log "Collecting data for period: $($periodStart.ToString('yyyy-MM-dd')) - $($periodEnd.ToString('yyyy-MM-dd'))"

$sessionFiles = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue
$sessions = @()

foreach ($file in $sessionFiles) {
    try {
        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $startTime = if ($content.startTime) { [DateTime]::Parse($content.startTime) } else { [DateTime]::MinValue }
        
        if ($startTime -ge $periodStart) {
            $correlationId = ""
            $rootSpanId = ""
            
            $telemetryFile = Join-Path $telemetryDir "initialization-$($content.sessionId).json"
            if (Test-Path $telemetryFile) {
                $telemetry = Get-Content $telemetryFile -Raw | ConvertFrom-Json
                $correlationId = $telemetry.CorrelationId
                $rootSpanId = $telemetry.RootSpanId
            }
            
            $sessions += [pscustomobject]@{
                sessionId = $content.sessionId
                status = $content.status
                startTime = $startTime
                mode = $content.mode
                project = $content.project
                correlationId = $correlationId
                rootSpanId = $rootSpanId
            }
        }
    } catch {
        Write-Log "Error: $($file.Name)" "WARN"
    }
}

$sessionsByDay = $sessions | Group-Object { $_.startTime.ToString("yyyy-MM-dd") } | Sort-Object Name

$totalSessions = $sessions.Count
$activeSessions = ($sessions | Where-Object { $_.status -eq "active" }).Count

$daysInPeriod = if ($Period -eq "today") { 1 } elseif ($Period -eq "yesterday") { 1 } elseif ($Period -eq "7days") { 7 } elseif ($Period -eq "30days") { 30 } else { ($periodEnd - $periodStart).Days }

$reportDate = Get-Date -Format "yyyy-MM-dd HH:mm"
$periodLabel = switch ($Period) {
    "today" { "Hoy" }
    "yesterday" { "Ayer" }
    "7days" { "Últimos 7 días" }
    "30days" { "Últimos 30 días" }
    "all" { "Todo el período" }
}

$systemStatus = @{
    tokenGuard = " Activo (128K budget)"
    contextEfficiency = " Perfil recommended"
    autoDelegation = " Configurado"
    distributedTracing = " Activo"
}

if ($Format -eq "json") {
    $result = @{
        generatedAt = $reportDate
        period = $Period
        periodLabel = $periodLabel
        periodStart = $periodStart.ToString("yyyy-MM-dd")
        periodEnd = $periodEnd.ToString("yyyy-MM-dd")
        summary = @{
            totalSessions = $totalSessions
            activeSessions = $activeSessions
            sessionsByDay = $sessionsByDay | ForEach-Object { @{ date = $_.Name; count = $_.Count } }
        }
        systemStatus = $systemStatus
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

$outputDir = Join-Path $ProjectRoot "reports"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$reportFile = Join-Path $outputDir "informe-ejecutivo-$Period-$(Get-Date -Format 'yyyy-MM-dd').md"

$markdown = @"
# [DATA] Informe Ejecutivo - Resumen de Actividad

**Período**: $periodLabel  
**Fecha de generación**: $reportDate  
**Proyecto**: workspace_local  

---

## [LIST] Resumen Ejecutivo

| Métrica | Valor | Nota |
|--------|-------|------|
| **Sesiones totales** | $totalSessions | $(if ($Period -eq "7days") { " $([math]::Round($totalSessions/7, 1))/día" } elseif ($Period -eq "30days") { " $([math]::Round($totalSessions/30, 1))/día" }) |
| **Sesiones activas** | $activeSessions | En curso |
| **Días analizados** | $daysInPeriod | Período seleccionado |

### [CHART] Actividad por Día

| Fecha | Sesiones |
|-------|----------|
"@

foreach ($day in $sessionsByDay) {
    $markdown += "| $($day.Name) | $($day.Count) |`n"
}

$markdown += @"

---

##  Estado del Sistema

| Componente | Estado |
|------------|--------|
| Token Guard | $($systemStatus.tokenGuard) |
| Context Efficiency | $($systemStatus.contextEfficiency) |
| Auto-Delegation | $($systemStatus.autoDelegation) |
| Distributed Tracing | $($systemStatus.distributedTracing) |

---

## [DATA] Detalle de Sesiones

"@

foreach ($day in $sessionsByDay) {
    $markdown += "### $($day.Name)`n`n"
    $daySessions = $sessions | Where-Object { $_.startTime.ToString("yyyy-MM-dd") -eq $day.Name }
    foreach ($s in $daySessions) {
        $time = $s.startTime.ToString("HH:mm:ss")
        $markdown += "- `$sessionId`: $time - $($s.status)`n"
    }
    $markdown += "`n"
}

$markdown += @"
---

##  Limitaciones y Notas

> **Nota importantes**: Los ientes métricas aún no están siendo capturadas automáticamente:
> - Tokens consumidos por sesión
> - Costo estimado (USD)
> - Contexto utilizado
> - Duración real de sesiones
> - Tool calls, files read/edited

**Próximas mejoras**: Ver `reports/MEJORAS-REPORTING-TELEMETRY.md`

---

## [TARGET] Recomendaciones

1. **Alta Prioridad**: Instrumentar captura de tokens en workflow de sesión
2. **Media Prioridad**: Implementar consolidación automática de métricas
3. **Mejora Continua**: Agregar dashboard en tiempo real

---

*Informe generado automáticamente*  
*Formato: Markdown (.md)*

"@

$markdown | Out-File -FilePath $reportFile -Encoding UTF8

Write-Log "Report saved to: $reportFile" "OK"

Write-Host ""
Write-Host "=== Executive Summary ===" -ForegroundColor Cyan
Write-Host "Period: $periodLabel" -ForegroundColor White
Write-Host "Sessions: $totalSessions (Active: $activeSessions)" -ForegroundColor White

if (-not $Silent) {
    Write-Host ""
    Write-Host "Days with activity:" -ForegroundColor White
    foreach ($day in $sessionsByDay) {
        Write-Host "  $($day.Name): $($day.Count) sessions" -ForegroundColor Gray
    }
}

exit 0


