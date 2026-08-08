# homologate-pages.ps1 — Homologa info-triggers en TODAS las páginas de docs/presentations/
#
# Convierte cada <td data-i18n="c_XXX">Texto</td> (que aún no tenga .info-trigger) en:
#   <td><span data-i18n="c_XXX">Texto</span><span class="info-trigger"
#       data-i18n-title="tip_XXX" title="<texto EN de la clave>">i</span></td>
#
# El title fallback se toma del diccionario i18n-content.js (contenido EN), de modo que el modal
# funcione incluso antes de añadir claves tip_* al diccionario i18n.js. Para traducción completa de
# los modales, insertar después las claves tip_* con insert-tips.ps1.
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/homologate-pages.ps1
#     [-DocsDir <docs/presentations>] [-ContentJs <ruta a i18n-content.js>] [-DryRun] [-Page <file.html>]
#
# Idempotente: solo transforma tds que no contienen ya un .info-trigger.

param(
  [string]$DocsDir = (Join-Path (Get-Location) "docs/presentations"),
  [string]$ContentJs = (Join-Path (Get-Location) "docs/presentations/assets/js/i18n-content.js"),
  [string]$Page = "",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $DocsDir)) { throw "docs/presentations no encontrado: $DocsDir" }
if (-not (Test-Path -LiteralPath $ContentJs)) { throw "i18n-content.js no encontrado: $ContentJs" }

# Cargar diccionario EN para title fallback: "c_health_5": "Dashboard WS server, ..."
$contentRaw = [System.IO.File]::ReadAllText($ContentJs, [System.Text.Encoding]::UTF8)
$enDict = @{}
# Extraer SOLO el bloque en: entre "__GV_CONTENT.en = {" y el siguiente bloque (__GV_CONTENT.es)
$enStart = $contentRaw.IndexOf("__GV_CONTENT.en = {")
$enEnd = $contentRaw.IndexOf("__GV_CONTENT.es = {", $enStart)
if ($enStart -lt 0 -or $enEnd -lt 0) { throw "bloque en de i18n-content.js no encontrado" }
$enBlock = $contentRaw.Substring($enStart, $enEnd - $enStart)
foreach ($m in [regex]::Matches($enBlock, '"([c_][a-zA-Z0-9_]+)":\s*"((?:[^"\\]|\\.)*)"')) {
  $enDict[$m.Groups[1].Value] = $m.Groups[2].Value -replace '\\"', '"' -replace '\\\\', '\\'
}

$files = if ($Page) { @($Page) } else { (Get-ChildItem -LiteralPath $DocsDir -Filter "*.html" | Select-Object -ExpandProperty Name) }
$totalChanged = 0

foreach ($f in $files) {
  $path = Join-Path $DocsDir $f
  if (-not (Test-Path -LiteralPath $path)) { Write-Warning "no existe: $f"; continue }
  $t = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

  $changed = 0
  # Iterar sobre tds data-i18n que NO contienen info-trigger dentro
  foreach ($m in [regex]::Matches($t, '<td data-i18n="([c_][a-zA-Z0-9_]+)">([\s\S]*?)</td>')) {
    $key = $m.Groups[1].Value
    $inner = $m.Groups[2].Value
    if ($inner -match 'info-trigger') { continue }   # idempotencia
    if ($inner -match '<') { continue }               # td con hijos complejos: no tocar

    $tipKey = 'tip_' + $key
    $fallback = $enDict[$key]
    $titleAttr = ''
    if ($fallback) {
      $titleAttr = ' title="' + ($fallback -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;') + '"'
    }
    $plain = $inner.Trim()
    $replacement = '<td><span data-i18n="' + $key + '">' + $plain + '</span><span class="info-trigger" data-i18n-title="' + $tipKey + '"' + $titleAttr + '>i</span></td>'
    $t = $t.Replace($m.Value, $replacement)
    $changed++
  }

  if ($changed -gt 0 -and -not $DryRun) {
    [System.IO.File]::WriteAllText($path, $t, $utf8)
  }
  $totalChanged += $changed
  Write-Output ("{0}: {1} tds transformados" -f $f, $changed)
}

if ($DryRun) { Write-Output "DRY-RUN: $totalChanged tds listos en total (sin escribir)" }
else { Write-Output "DONE: $totalChanged tds transformados" }
