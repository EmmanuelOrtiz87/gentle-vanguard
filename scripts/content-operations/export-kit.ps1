# Export local offline kit
# Ejecutar desde la ra├¡z del repositorio en Windows.
# Genera un ZIP con el material operativo tracked del Content Operations Engine.

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outDir = Join-Path (Get-Location) '.runtime\exports'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$zip = Join-Path $outDir "gentle-vanguard-content-operations-$stamp.zip"

$items = @(
  'src\content-operations',
  'tests\unit\content-operations.test.ts',
  'content\operations',
  'config\content-operations',
  'docs\operations',
  'scripts\content-operations'
) | Where-Object { Test-Path $_ }

if ($items.Count -eq 0) { throw 'No Content Operations files found.' }

Compress-Archive -Path $items -DestinationPath $zip -Force
Write-Host "Offline kit: $zip"
