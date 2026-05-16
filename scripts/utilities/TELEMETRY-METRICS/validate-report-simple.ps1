# validate-report-simple.ps1
# Simple validation of management report

$reportFile = ".\gentle-vanguard\\reports\MANAGEMENT-REPORT-2026-04.csv"

if (-not (Test-Path $reportFile)) {
    Write-Host "ERROR: Report file not found"
    exit 1
}

$csv = Import-Csv $reportFile

Write-Host "=== VALIDATION REPORT ==="
Write-Host "Ubicacion: $reportFile"
Write-Host ""
Write-Host "Total sesiones: $($csv.Count)"
Write-Host "Columnas: $($csv[0].PSObject.Properties.Name.Count)"
Write-Host ""
Write-Host "Datos por columna:"
Write-Host "- SessionID: $(($csv | Where-Object { $_.SessionID -ne '' }).Count) con datos"
Write-Host "- TokensIn > 0: $(($csv | Where-Object { [int]$_.TokensIn -gt 0 }).Count)"
Write-Host "- SkillsUsed con datos: $(($csv | Where-Object { $_.SkillsUsed -ne '' }).Count)"
Write-Host "- ActionsPerformed con datos: $(($csv | Where-Object { $_.ActionsPerformed -ne '' }).Count)"
Write-Host "- Outcome COMPLETE: $(($csv | Where-Object { $_.Outcome -eq 'COMPLETE' }).Count)"
Write-Host "- Outcome ESCALATED: $(($csv | Where-Object { $_.Outcome -eq 'ESCALATED' }).Count)"
Write-Host ""
Write-Host "Duracion:"
Write-Host "- Min: $(($csv | Measure-Object -Property 'Duration(min)' -Minimum).Minimum) min"
Write-Host "- Max: $(($csv | Measure-Object -Property 'Duration(min)' -Maximum).Maximum) min"
Write-Host ""
Write-Host "Primeras 3 sesiones:"
$csv | Select-Object -First 3 | Format-Table

