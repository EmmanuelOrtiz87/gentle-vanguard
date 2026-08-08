# insert-tips.ps1 — Inserta claves tip_* desde un JSON en i18n.js (bloques en/es/pt-BR)
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/insert-tips.ps1
#     -JsonPath <ruta a tips.json> -JsPath <ruta a i18n.js> [-MarkerKey tip_auto_loop]
#
# Idempotente POR BLOQUE de idioma (gotcha #3): comprueba la existencia de MarkerKey dentro de
# cada sección de idioma por separado, no globalmente.
#
# JSON esperado:
# {
#   "tip_mi_clave": { "en": "...", "es": "...", "pt-BR": "..." },
#   ...
# }

param(
  [string]$JsonPath = (Join-Path $PSScriptRoot "tips-new.json"),
  [string]$JsPath = (Join-Path (Get-Location) "docs/presentations/assets/js/i18n.js"),
  [string]$MarkerKey = "tip_auto_loop",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $JsonPath)) { throw "JSON no encontrado: $JsonPath" }
if (-not (Test-Path -LiteralPath $JsPath)) { throw "i18n.js no encontrado: $JsPath" }

$tips = Get-Content -Raw -LiteralPath $JsonPath | ConvertFrom-Json
$t = [System.IO.File]::ReadAllText($JsPath, [System.Text.Encoding]::UTF8)

# Anclas únicas de cierre de cada bloque de idioma (ajustar si cambian en i18n.js)
$sections = @(
  @{ lang = 'en';    marker = "status_unknown: 'Unknown'" },
  @{ lang = 'es';    marker = "status_unknown: 'Desconocido'" },
  @{ lang = 'pt-BR'; marker = "status_unknown: 'Desconhecido'" }
)

$totalInserted = 0
foreach ($sec in $sections) {
  $lang = $sec.lang
  $marker = $sec.marker

  $m = [regex]::Match($t, [regex]::Escape($marker) + "([\s\S]*?)`r?`n    \},")
  if (-not $m.Success) { Write-Output "${lang}: marker no encontrado"; continue }

  $block = $m.Groups[1].Value

  # Idempotencia POR BLOQUE
  if ($block -match [regex]::Escape("$MarkerKey`:")) {
    Write-Output "${lang}: claves ya presentes en esta seccion (omitir)"
    continue
  }

  $props = $tips.PSObject.Properties | Sort-Object Name
  $blockLines = @()
  foreach ($p in $props) {
    $text = [string]$p.Value.$lang
    $text = $text -replace "'", "\'"
    $blockLines += "      $($p.Name): '$text',"
  }

  $insertion = "`n" + ($blockLines -join "`n")
  $pos = $t.IndexOf($marker)
  $pos = $t.IndexOf("`n", $pos)
  if (-not $DryRun) { $t = $t.Insert($pos + 1, $insertion) }
  $totalInserted += $blockLines.Count
  Write-Output "${lang}: $($blockLines.Count) claves insertadas"
}

if ($DryRun) {
  Write-Output "DRY-RUN: $totalInserted claves listas (sin escribir)"
} else {
  [System.IO.File]::WriteAllText($JsPath, $t, $utf8)
  Write-Output "DONE - i18n.js actualizado ($totalInserted claves)"
}
