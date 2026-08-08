# dedupe-i18n.ps1 — Elimina claves duplicadas dentro de un bloque de idioma de i18n.js
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/dedupe-i18n.ps1
#     [-JsPath <ruta a i18n.js>] [-Block en|es|pt-BR] [-DryRun]
#
# Estado sano: 208 claves por bloque (en/es/pt-BR), 0 duplicados.

param(
  [string]$JsPath = (Join-Path (Get-Location) "docs/presentations/assets/js/i18n.js"),
  [string]$Block = "en",
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $JsPath)) { throw "i18n.js no encontrado: $JsPath" }
$t = [System.IO.File]::ReadAllText($JsPath, [System.Text.Encoding]::UTF8)

# Localizar bloque: "en: {" hasta el siguiente "es: {" / "pt-BR: {" / cierre
$order = @('en', 'es', 'pt-BR')
$idx = [Array]::IndexOf($order, $Block)
if ($idx -lt 0) { throw "Bloque inválido: $Block (en|es|pt-BR)" }

$startMarker = "${Block}`r?`n\s*\{|${Block}`:\s*\{"
$blockStart = $t.IndexOf("${Block}: {")
if ($blockStart -lt 0) { throw "Bloque '$Block' no encontrado en i18n.js" }

# Fin del bloque: el siguiente idioma en el orden, o el cierre final
$endPos = $t.Length
for ($i = $idx + 1; $i -lt $order.Count; $i++) {
  $nextIdx = $t.IndexOf("$($order[$i]): {", $blockStart + $Block.Length)
  if ($nextIdx -ge 0) { $endPos = $nextIdx; break }
}

$blockText = $t.Substring($blockStart, $endPos - $blockStart)
$lines = $blockText -split "`n"
$seen = @{}
$kept = @()
$removed = 0
foreach ($line in $lines) {
  $m = [regex]::Match($line, '^\s+([a-zA-Z0-9_]+):\s')
  if ($m.Success) {
    $key = $m.Groups[1].Value
    if ($seen.ContainsKey($key)) { $removed++; continue }
    $seen[$key] = 1
  }
  $kept += $line
}
$newBlock = $kept -join "`n"
$newT = $t.Substring(0, $blockStart) + $newBlock + $t.Substring($endPos)

if ($DryRun) {
  Write-Output "DRY-RUN bloque '$Block': $removed duplicados detectados (sin escribir). Total claves: $($seen.Count)"
} else {
  [System.IO.File]::WriteAllText($JsPath, $newT, $utf8)
  Write-Output "Duplicados eliminados del bloque '$Block': $removed. Total claves: $($seen.Count)"
}
