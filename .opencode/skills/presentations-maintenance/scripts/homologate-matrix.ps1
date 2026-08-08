# homologate-matrix.ps1 — Homologa info-triggers en la Feature Matrix de index.html
#
# Convierte cada <td data-i18n="c_index_XX">Texto</td> en:
#   <td><span data-i18n="c_index_XX">Texto</span><span class="info-trigger"
#       data-i18n-title="tip_fm_XX" title="...">i</span></td>
#
# Idempotente: si el td ya contiene un .info-trigger, lo deja intacto.
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/homologate-matrix.ps1
#     [-HtmlPath <ruta a index.html>] [-TipsJson <ruta a tips-fm.json>] [-DryRun]

param(
  [string]$HtmlPath = (Join-Path (Get-Location) "docs/presentations/index.html"),
  [string]$TipsJson = (Join-Path $PSScriptRoot "tips-fm.json"),
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $HtmlPath)) { throw "index.html no encontrado: $HtmlPath" }
if (-not (Test-Path -LiteralPath $TipsJson)) {
  Write-Warning "tips-fm.json no encontrado: $TipsJson — se usa solo el data-i18n-title sin title fallback"
}

$t = [System.IO.File]::ReadAllText($HtmlPath, [System.Text.Encoding]::UTF8)

# Mapa clave -> texto del tip (inglés; i18n.js traducirá via data-i18n-title)
$tips = @{}
if (Test-Path -LiteralPath $TipsJson) {
  $json = Get-Content -Raw -LiteralPath $TipsJson | ConvertFrom-Json
  foreach ($p in $json.PSObject.Properties) {
    $tips[$p.Name] = $p.Value.en
  }
}

$changed = 0
$keysInHtml = [regex]::Matches($t, 'c_index_\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique
foreach ($k in $keysInHtml) {
  $tipText = $tips[$k]
  $titleAttr = if ($tipText) { ' title="' + ($tipText -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;') + '"' } else { '' }
  $pattern = '<td data-i18n="' + $k + '">([^<]*)</td>'
  $m = [regex]::Match($t, $pattern)
  if ($m.Success) {
    $inner = $m.Groups[1].Value
    $tipKey = 'tip_fm_' + $k.Substring(8)
    $replacement = '<td><span data-i18n="' + $k + '">' + $inner + '</span><span class="info-trigger" data-i18n-title="' + $tipKey + '"' + $titleAttr + '>i</span></td>'
    $t = $t.Replace($m.Value, $replacement)
    $changed++
  }
}

if ($DryRun) {
  Write-Output "DRY-RUN: $changed filas a transformar (sin escribir)"
} else {
  [System.IO.File]::WriteAllText($HtmlPath, $t, $utf8)
  Write-Output "Filas transformadas: $changed"
}
