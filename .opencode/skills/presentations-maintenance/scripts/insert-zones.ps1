# insert-zones.ps1 — Inserta claves tip_hs_* de svg-zones.json en i18n.js
#
# svg-zones.json tiene estructura:
#   { "<archivo>.svg": { "<tipKey>": { "rect": [x,y,w,h], "en": "..", "es": "..", "pt-BR": ".." }, ... } }
#
# insert-tips.ps1 espera:
#   { "<tipKey>": { "en": "..", "es": "..", "pt-BR": ".." }, ... }
#
# Este script aplana svg-zones.json a un JSON temporal y delega en insert-tips.ps1
# (misma lógica probada de inserción por bloque de idioma con idempotencia).
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/insert-zones.ps1
#     [-ZonesJson <...svg-zones.json>] [-MarkerKey tip_hs_loop_detection] [-DryRun]

param(
  [string]$ZonesJson = (Join-Path $PSScriptRoot "svg-zones.json"),
  [string]$MarkerKey = "tip_hs_loop_detection",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ZonesJson)) { throw "JSON no encontrado: $ZonesJson" }
$zones = Get-Content -Raw -LiteralPath $ZonesJson | ConvertFrom-Json

# Aplanar: { archivo: { tipKey: {rect,en,es,pt-BR} } } -> { tipKey: {en,es,pt-BR} }
$flat = @{}
foreach ($file in $zones.PSObject.Properties.Name) {
  foreach ($def in $zones.($file).PSObject.Properties) {
    $tipKey = $def.Name
    $flat[$tipKey] = @{
      'en'    = [string]$def.Value.en
      'es'    = [string]$def.Value.es
      'pt-BR' = [string]$def.Value.'pt-BR'
    }
  }
}

$tmpJson = Join-Path $PSScriptRoot "svg-zones-flat.json"
$flat | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $tmpJson -Encoding UTF8
Write-Output "aplanado: $($flat.Count) claves -> $tmpJson"

$passArgs = @{
  JsonPath   = $tmpJson
  MarkerKey  = $MarkerKey
}
if ($DryRun) { $passArgs.DryRun = $true }

& (Join-Path $PSScriptRoot "insert-tips.ps1") @passArgs
$code = $LASTEXITCODE

# Limpiar SIEMPRE el temporal (también en dry-run): evitar residuos en git status
Remove-Item -LiteralPath $tmpJson -Force -ErrorAction SilentlyContinue
exit $code
