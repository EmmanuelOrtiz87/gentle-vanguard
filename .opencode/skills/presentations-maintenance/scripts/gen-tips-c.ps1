# gen-tips-c.ps1 — Genera claves tip_c_* en i18n.js desde el contenido traducido de i18n-content.js
#
# Para cada info-trigger con data-i18n-title="tip_c_XXX" en las páginas, crea la clave
# tip_c_XXX: { en: <c_XXX.en>, es: <c_XXX.es>, "pt-BR": <c_XXX.pt-BR> } en los 3 bloques de i18n.js.
# Así los modales muestran el texto traducido al idioma activo (no el fallback en inglés).
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/gen-tips-c.ps1
#     [-DocsDir <docs/presentations>] [-ContentJs <i18n-content.js>] [-JsPath <i18n.js>] [-DryRun]
#
# Idempotente por bloque: si tip_c_health_5 ya existe en el bloque en, se omite (no duplica).

param(
  [string]$DocsDir = (Join-Path (Get-Location) "docs/presentations"),
  [string]$ContentJs = (Join-Path (Get-Location) "docs/presentations/assets/js/i18n-content.js"),
  [string]$JsPath = (Join-Path (Get-Location) "docs/presentations/assets/js/i18n.js"),
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $JsPath)) { throw "i18n.js no encontrado: $JsPath" }
if (-not (Test-Path -LiteralPath $ContentJs)) { throw "i18n-content.js no encontrado: $ContentJs" }

# 1. Recolectar claves tip_c_* usadas por triggers en las páginas
$tipKeys = @{}
Get-ChildItem -LiteralPath $DocsDir -Filter "*.html" | ForEach-Object {
  $html = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
  foreach ($m in [regex]::Matches($html, 'data-i18n-title="(tip_c_[a-zA-Z0-9_]+)"')) {
    $tipKeys[$m.Groups[1].Value] = $true
  }
}
Write-Output "Claves tip_c_* requeridas por triggers: $($tipKeys.Count)"

# 2. Extraer bloques en/es/pt-BR de i18n-content.js
$contentRaw = [System.IO.File]::ReadAllText($ContentJs, [System.Text.Encoding]::UTF8)
function Get-ContentBlock($raw, $name) {
  $start = $raw.IndexOf("__GV_CONTENT.$name = {")
  if ($start -lt 0) { $start = $raw.IndexOf("__GV_CONTENT['$name'] = {") }
  if ($start -lt 0) { return $null }
  $start = $raw.IndexOf('{', $start)
  # encontrar cierre balanceado de llaves
  $depth = 0; $i = $start
  do {
    $ch = $raw[$i]
    if ($ch -eq '{') { $depth++ }
    elseif ($ch -eq '}') { $depth-- }
    $i++
  } while ($depth -gt 0 -and $i -lt $raw.Length)
  return $raw.Substring($start, $i - $start)
}
$blocks = @{
  'en'    = Get-ContentBlock $contentRaw 'en'
  'es'    = Get-ContentBlock $contentRaw 'es'
  'pt-BR' = Get-ContentBlock $contentRaw 'pt-BR'
}
foreach ($k in $blocks.Keys) { if (-not $blocks[$k]) { throw "bloque $k no encontrado en i18n-content.js" } }

# Parsear "key": "value" de cada bloque
function Get-Dict($block) {
  $d = @{}
  foreach ($m in [regex]::Matches($block, '"([a-zA-Z0-9_]+)":\s*"((?:[^"\\]|\\.)*)"')) {
    $d[$m.Groups[1].Value] = $m.Groups[2].Value -replace '\\n', ' ' -replace '\s+', ' ' -replace '\\"', '"' -replace '\\\\', '\\'
  }
  return $d
}
$dict = @{ 'en' = (Get-Dict $blocks['en']); 'es' = (Get-Dict $blocks['es']); 'pt-BR' = (Get-Dict $blocks['pt-BR']) }
Write-Output "Diccionarios: en=$($dict['en'].Count) es=$($dict['es'].Count) pt-BR=$($dict['pt-BR'].Count)"

# 3. Construir entradas tip_c_* por idioma
$entries = @{ 'en' = @{}; 'es' = @{}; 'pt-BR' = @{} }
$missing = 0
foreach ($tipKey in $tipKeys.Keys) {
  $cKey = $tipKey.Substring(4)   # tip_c_health_5 -> c_health_5
  $ok = $true
  foreach ($lang in @('en', 'es', 'pt-BR')) {
    if ($dict[$lang].ContainsKey($cKey)) {
      $entries[$lang][$tipKey] = $dict[$lang][$cKey]
    } else {
      $ok = $false
    }
  }
  if (-not $ok) { $missing++ }
}
Write-Output "Entradas tip_c_* generadas: $($entries['en'].Count) (faltan claves c_* en diccionario: $missing)"

# 4. Insertar en i18n.js por bloque (idempotente por bloque)
$t = [System.IO.File]::ReadAllText($JsPath, [System.Text.Encoding]::UTF8)
$sections = @(
  @{ lang = 'en';    marker = "status_unknown: 'Unknown'" },
  @{ lang = 'es';    marker = "status_unknown: 'Desconocido'" },
  @{ lang = 'pt-BR'; marker = "status_unknown: 'Desconhecido'" }
)
$inserted = 0
foreach ($sec in $sections) {
  $lang = $sec.lang
  $marker = $sec.marker
  $m = [regex]::Match($t, [regex]::Escape($marker) + "([\s\S]*?)`r?`n    \},")
  if (-not $m.Success) { Write-Output "${lang}: marker no encontrado"; continue }
  $block = $m.Groups[1].Value

  $toInsert = @()
  foreach ($tipKey in ($entries[$lang].Keys | Sort-Object)) {
    if ($block -match [regex]::Escape("$tipKey`:")) { continue }  # ya existe en este bloque
    $text = $entries[$lang][$tipKey] -replace "'", "\'"
    $toInsert += "      $tipKey`: '$text',"
  }
  if ($toInsert.Count -eq 0) { Write-Output "${lang}: 0 nuevas (todas ya presentes)"; continue }

  $insertion = "`n" + ($toInsert -join "`n")
  $pos = $t.IndexOf($marker)
  $pos = $t.IndexOf("`n", $pos)
  if (-not $DryRun) { $t = $t.Insert($pos + 1, $insertion) }
  $inserted += $toInsert.Count
  Write-Output "${lang}: $($toInsert.Count) claves insertadas"
}

if ($DryRun) {
  Write-Output "DRY-RUN: $inserted claves tip_c_* listas (sin escribir)"
} else {
  [System.IO.File]::WriteAllText($JsPath, $t, $utf8)
  Write-Output "DONE - i18n.js actualizado ($inserted claves)"
}
