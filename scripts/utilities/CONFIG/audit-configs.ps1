param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$configDir = Join-Path $ROOT 'config'
$searchDirs = @(
  'scripts', 'apps', '.github', 'docs', 'config'
)
$log = @{ used = @{}; unused = @{} }

# Build list of config names
$allConfigs = Get-ChildItem -Path $configDir -Filter '*.json' | Select-Object -ExpandProperty Name
$allNames = $allConfigs | ForEach-Object { [regex]::Escape($_) }
$pattern = $allNames -join '|'

# Search all dirs at once — single Select-String pass per dir
$refMap = @{}
foreach ($dir in $searchDirs) {
  $path = Join-Path $ROOT $dir
  if (-not (Test-Path $path)) { continue }
  $matches = Select-String -Path (Get-ChildItem -Path $path -Recurse -Include '*.ps1', '*.ts', '*.tsx', '*.js', '*.md', '*.yml', '*.yaml', '*.json' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName) -Pattern $pattern -List -ErrorAction SilentlyContinue
  if ($matches) { $matches | ForEach-Object { $refMap[$_.Pattern] = $dir } }
}

# Classify each config
foreach ($name in $allConfigs) {
  $escaped = [regex]::Escape($name)
  $foundDir = $refMap[$escaped]
  if (-not $foundDir) { $log.unused[$name] = 'no references found' }
  elseif ($foundDir -eq 'config') { $log.unused[$name] = 'only self-referenced' }
  else { $log.used[$name] = $foundDir }
}

if (-not $Quiet) {
  Write-Host "=== Config Audit Report ===" -ForegroundColor Cyan
  Write-Host "Total configs: $($log.used.Count + $log.unused.Count)" -ForegroundColor Gray
  Write-Host ""

  if ($log.used.Count -gt 0) {
    Write-Host "Referenced configs ($($log.used.Count)):" -ForegroundColor Green
    $log.used.Keys | Sort-Object | ForEach-Object { Write-Host "  ✅ $_ ($($log.used[$_]) locations)" -ForegroundColor Gray }
    Write-Host ""
  }

  if ($log.unused.Count -gt 0) {
    Write-Host "UNREFERENCED configs ($($log.unused.Count)) — candidates for archival:" -ForegroundColor Yellow
    $log.unused.Keys | Sort-Object | ForEach-Object { Write-Host "  ⚠️  $_ — $($log.unused[$_])" -ForegroundColor Yellow }
    Write-Host ""
  }

  Write-Host "Recommendation:" -ForegroundColor Cyan
  if ($log.unused.Count -eq 0) {
    Write-Host "  All configs are referenced. No action needed." -ForegroundColor Green
  } else {
    Write-Host "  Review $($log.unused.Count) unreferenced configs. Consider:" -ForegroundColor White
    Write-Host "  1. Archive to deprecated/config/ if no longer needed" -ForegroundColor Gray
    Write-Host "  2. Add references if they should be used" -ForegroundColor Gray
    Write-Host "  3. Keep if loaded dynamically at runtime" -ForegroundColor Gray
  }
}

return $log
