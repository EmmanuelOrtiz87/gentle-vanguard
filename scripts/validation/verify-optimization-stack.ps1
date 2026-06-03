#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Verifica las 8 reglas del Stack de Optimización de Tokens y Costos
.DESCRIPTION
  Valida que todas las optimizaciones (compresión, cache, modelo, tracking, etc.)
  estén activas y funcionando. Exit code = número de reglas falladas (0 = todo OK).
.PARAMETER Quiet
  Solo muestra fallos, no successes
.PARAMETER AsJson
  Salida en JSON para consumo por CI/herramientas
.EXAMPLE
  ./verify-optimization-stack.ps1
  ./verify-optimization-stack.ps1 -Quiet
  ./verify-optimization-stack.ps1 -AsJson
#>
param(
  [switch]$Quiet,
  [switch]$AsJson
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$results = @()
$exitCode = 0

function Write-Check {
  param([string]$Name, [bool]$Passed, [string]$Detail)
  $results += @{ name = $Name; passed = $Passed; detail = $Detail }
  if (-not $Quiet -or -not $Passed) {
    $icon = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "$icon $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
  }
  if (-not $Passed) { $exitCode++ }
}

# === R1: CLAUDE.md comprimido ≤ 65 líneas ===
$claudePath = Join-Path $root "CLAUDE.md"
if (Test-Path $claudePath) {
  $lines = (Get-Content $claudePath).Count
  Write-Check "R1: CLAUDE.md <= 65 lines" ($lines -le 65) "$lines lines (max 65)"
} else {
  Write-Check "R1: CLAUDE.md exists" $false
}

# === R2: Response cache SHA256 activo ===
$cacheFile = Join-Path $root ".session/preprocess-response-cache.json"
$ppPath = Join-Path $root "scripts/utilities/pre-process-input.ps1"
$hasCache = (Test-Path $ppPath) -and ((Get-Content $ppPath -Raw) -match "preprocess-response-cache")
if ($hasCache -and (Test-Path $cacheFile)) {
  $cacheSize = [math]::Round((Get-Item $cacheFile).Length / 1KB, 1)
  Write-Check "R2: Response cache SHA256 activo" $true "${cacheSize}KB"
} elseif ($hasCache) {
  Write-Check "R2: Response cache SHA256 configurado" $true "Cache file not yet created"
} else {
  Write-Check "R2: Response cache SHA256 configurado" $false "pre-process-input.ps1 missing cache"
}

# === R3: Modelo óptimo (0 ocurrencias glm-5 premium) ===
$ocPath = Join-Path $root "opencode.json"
if (Test-Path $ocPath) {
  $glmCount = (Select-String -Path $ocPath -Pattern "glm-5" -SimpleMatch).Count
  $qwenCount = (Select-String -Path $ocPath -Pattern "qwen-3.6-plus" -SimpleMatch).Count
  Write-Check "R3: Modelo economico en uso" ($glmCount -eq 0 -and $qwenCount -ge 3) "glm-5:$glmCount qwen-3.6-plus:$qwenCount"
} else {
  Write-Check "R3: opencode.json exists" $false
}

# === R4: Pre-task compression activa ===
$compressPath = Join-Path $root "scripts/hooks/pre-task-compress.ps1"
if (Test-Path $compressPath) {
  $result = & $compressPath -PromptText "test verify compression" -DryRun 2>&1 | Out-String
  $hasCompress = $result -match "COMPRESS:"
  Write-Check "R4: Pre-task compression activa" $hasCompress
} else {
  Write-Check "R4: pre-task-compress.ps1 exists" $false
}

# === R5: Token tracking funcional ===
$tuPath = Join-Path $root ".session/token-usage.json"
if (Test-Path $tuPath) {
  $tu = Get-Content $tuPath -Raw | ConvertFrom-Json
  $hasSessions = ($tu.PSObject.Properties.Name | Measure-Object).Count -gt 0
  Write-Check "R5: Token tracking funcional" $hasSessions
} else {
  Write-Check "R5: token-usage.json exists" $false
}

# === R6: Pre-compact hook sin hardcoded ===
$pchPath = Join-Path $root "scripts/utilities/PERFORMANCE-OPTIMIZATION/pre-compact-hook.ps1"

if (Test-Path $pchPath) {
  $pchContent = Get-Content $pchPath -Raw
  $hasHardcode = $pchContent -match "16000" -and $pchContent -notmatch "token-usage"
  Write-Check "R6: Pre-compact hook usa metricas reales" (-not $hasHardcode)
} elseif (Test-Path "$root/scripts/utilities/pre-compact-hook.ps1") {
  $pchContent = Get-Content "$root/scripts/utilities/pre-compact-hook.ps1" -Raw
  $hasMetricRead = $pchContent -match "token-usage"
  Write-Check "R6: Pre-compact hook forwarder funcional" $hasMetricRead
} else {
  Write-Check "R6: pre-compact-hook.ps1 exists" $false
}

# === R7: Notificaciones de tokens ===
$notifPath = Join-Path $root ".session/token-display-config.json"
if (Test-Path $notifPath) {
  $notif = Get-Content $notifPath -Raw | ConvertFrom-Json
  Write-Check "R7: Notificaciones configuradas" $true "enabled:$($notif.enabled)"
} else {
  Write-Check "R7: token-display-config.json exists" $false
}

# === R8: Cache < 5MB ===
$cacheLimitPath = Join-Path $root ".session/preprocess-response-cache.json"
if (Test-Path $cacheLimitPath) {
  $sizeKB = [math]::Round((Get-Item $cacheLimitPath).Length / 1KB, 1)
  Write-Check "R8: Cache < 5MB" ($sizeKB -lt 5120) "${sizeKB}KB / 5120KB max"
} else {
  Write-Check "R8: Cache exists (check size)" $true "No cache file yet"
}

if ($AsJson) {
  Write-Output ($results | ConvertTo-Json)
  exit $exitCode
}

Write-Host "`n=== Optimization Stack Verification ===" -ForegroundColor Cyan
Write-Host "Status: $(if($exitCode -eq 0){'ALL PASS'}else{"$exitCode FAILURES"})" -ForegroundColor $(if($exitCode -eq 0){'Green'}else{'Red'})
exit $exitCode
