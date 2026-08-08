# homologate-svg.ps1 — Convierte gv-node en hotspots clicables (gv-hotspot) en los SVG
#
# Añade a cada <g class="gv-node" data-group="XXX"> :
#   - clase adicional "gv-hotspot" (mantiene gv-node para highlight/dim de initDiagrams)
#   - atributo data-i18n-title="tip_hs_<group>" (abre el modal info multi-idioma)
#   - role="button" + tabindex="0" (accesibilidad)
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/homologate-svg.ps1
#     [-DiagramsDir <docs/presentations/diagrams>] [-File <architecture-layers.svg>] [-DryRun]
#
# Idempotente: si el gv-node ya tiene gv-hotspot, se omite.

param(
  [string]$DiagramsDir = (Join-Path (Get-Location) "docs/presentations/diagrams"),
  [string]$File = "",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $DiagramsDir)) { throw "diagrams no encontrado: $DiagramsDir" }
$files = if ($File) { @($File) } else { (Get-ChildItem -LiteralPath $DiagramsDir -Filter "*.svg" | Select-Object -ExpandProperty Name) }
$totalChanged = 0

foreach ($f in $files) {
  $path = Join-Path $DiagramsDir $f
  if (-not (Test-Path -LiteralPath $path)) { Write-Warning "no existe: $f"; continue }
  $t = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  $changed = 0

  foreach ($m in [regex]::Matches($t, '<g class="gv-node"([^>]*)>')) {
    $attrs = $m.Groups[1].Value
    if ($attrs -match 'gv-hotspot') { continue }   # ya convertido
    $group = [regex]::Match($attrs, 'data-group="([^"]+)"').Groups[1].Value
    if (-not $group) { Write-Warning "${f}: gv-node sin data-group, omitido"; continue }
    $tipKey = 'tip_hs_' + $group
    # Añadir clase gv-hotspot + data-i18n-title + accesibilidad al tag <g>
    $newAttrs = ' class="gv-node gv-hotspot" data-group="' + $group + '" data-i18n-title="' + $tipKey + '" role="button" tabindex="0"' + $attrs.Substring(0, 0)
    # Reconstruir: quitar class y data-group originales del substring de attrs
    $clean = $attrs
    $clean = [regex]::Replace($clean, 'class="gv-node"', '')
    $clean = [regex]::Replace($clean, 'data-group="[^"]*"', '')
    $clean = $clean -replace '^\s+', ''
    $newTag = '<g class="gv-node gv-hotspot" data-group="' + $group + '" data-i18n-title="' + $tipKey + '" role="button" tabindex="0"' + $(if ($clean) { ' ' + $clean } else { '' }) + '>'
    $t = $t.Replace($m.Value, $newTag)
    $changed++
  }

  if ($changed -gt 0 -and -not $DryRun) {
    [System.IO.File]::WriteAllText($path, $t, $utf8)
  }
  $totalChanged += $changed
  Write-Output ("{0}: {1} gv-node convertidos a hotspots" -f $f, $changed)
}

if ($DryRun) { Write-Output "DRY-RUN: $totalChanged hotspots listos (sin escribir)" }
else { Write-Output "DONE: $totalChanged hotspots" }
