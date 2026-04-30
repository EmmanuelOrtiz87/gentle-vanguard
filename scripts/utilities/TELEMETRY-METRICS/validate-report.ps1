# validate-report.ps1
# Simple validation of management report

$reportFile = "C:\Workspace_local\workspace-foundation\reports\MANAGEMENT-REPORT-2026-04.csv"

if (-not (Test-Path $reportFile)) {
    Write-Host "ERROR: Report file not found: $reportFile"
    exit 1
}

$csv = Import-Csv $reportFile

Write-Host "=== VALIDATION DE REPORTE ==="
Write-Host "Ubicación: $reportFile"
Write-Host ""

Write-Host "Total sesiones: $($csv.Count)"
Write-Host "Columnas: $($csv[0].PSObject.Properties.Name.Count)"
Write-Host ""

Write-Host "Datos por columna:"
Write-Host "- SessionID: $(($csv | Where-Object { $_.SessionID -ne '' }).Count) con datos"
Write-Host "- TokensIn: $(($csv | Where-Object { [int]$_.TokensIn -gt 0 }).Count) con valores > 0"
Write-Host "- SkillsUsed: $(($csv | Where-Object { $_.SkillsUsed -ne '' }).Count) con datos"
Write-Host "- ActionsPerformed: $(($csv | Where-Object { $_.ActionsPerformed -ne '' }).Count) con datos"

$minDuration = ($csv | Measure-Object -Property 'Duration(min)' -Minimum).Minimum
$maxDuration = ($csv | Measure-Object -Property 'Duration(min)' -Maximum).Maximum
Write-Host "- Duration(min): Min=$minDuration, Max=$maxDuration"

Write-Host ""
Write-Host "Primeras 3 filas:"
$csv | Select-Object -First 3 | Format-Table

Write-Host ""
Write-Host "=== RESUMEN ==="
if ($csv.Count -ge 10) {
    Write-Host "✅ Report has $($csv.Count) sessions"
} else {
    Write-Host "⚠️ Report has only $($csv.Count) sessions (expected 10+)"
}

if (($csv | Where-Object { $_.SkillsUsed -ne '' }).Count -gt 0) {
    Write-Host "✅ SkillsUsed column has data"
} else {
    Write-Host "⚠️ SkillsUsed column is empty (Engram integration needed)"
}

if (($csv | Where-Object { $_.ActionsPerformed -ne '' }).Count -gt 0) {
    Write-Host "✅ ActionsPerformed column has data"
} else {
    Write-Host "⚠️ ActionsPerformed column is empty (Engram integration needed)"
}
