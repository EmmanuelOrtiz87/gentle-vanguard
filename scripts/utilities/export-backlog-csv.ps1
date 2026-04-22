# Exporta el backlog oficial a CSV para gobernanza y reportes
# Uso: .\scripts\utilities\export-backlog-csv.ps1 [-Output <ruta>]

param(
    [string]$Output = "..\docs\backlog\backlog-export.csv"
)

$backlogPath = "..\docs\backlog\items.json"
if (!(Test-Path $backlogPath)) {
    Write-Error "No se encontr el archivo de backlog: $backlogPath"
    exit 1
}

$items = Get-Content $backlogPath | ConvertFrom-Json

$items | Select-Object \
    id, title, description, priority, status, owner, created_at, trigger | \
    Export-Csv -Path $Output -NoTypeInformation -Encoding UTF8

Write-Host "Backlog exportado a $Output"
