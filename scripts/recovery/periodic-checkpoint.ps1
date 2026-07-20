param([int]$IntervalHours = 24, [switch]$Quiet)

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$timestamp = Get-Date -Format 'yyyyMMddTHHmmss'

while ($true) {
    $rpDir = "$root\.session\restore-points"
    New-Item -ItemType Directory -Path $rpDir -Force | Out-Null
    $rp = @{
        id = "checkpoint-$timestamp"
        timestamp = $timestamp
        type = 'scheduled-checkpoint'
        intervalHours = $IntervalHours
    }
    $rp | ConvertTo-Json | Set-Content "$rpDir\$timestamp.json"
    if (-not $Quiet) { Write-Host "[CHECKPOINT] Creado: checkpoint-$timestamp" -ForegroundColor Green }
    Start-Sleep -Seconds ($IntervalHours * 3600)
}