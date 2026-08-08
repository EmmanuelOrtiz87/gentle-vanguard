# inject-hotspots.ps1 — Inyecta rects hotspot (zonas clicables) en los SVG del libro
#
# Lee svg-zones.json (misma carpeta): { "<archivo>.svg": { "<tipKey>": { rect: [x,y,w,h], en/es/pt-BR } } }
# y añade, justo antes de </svg>:
#   <rect class="gv-hotspot" x=".." y=".." width=".." height=".." data-i18n-title="<tipKey>"
#         role="button" tabindex="0" fill="transparent" aria-label="<en:label>" />
#
# El CSS (.gv-lightbox-svg .gv-hotspot) hace fill transparente por defecto y
# un realce púrpura al hover; el click abre el modal info vía __gvShowInfo.
#
# Uso:
#   pwsh .opencode/skills/presentations-maintenance/scripts/inject-hotspots.ps1
#     [-DiagramsDir <docs/presentations/diagrams>] [-ZonesJson <...svg-zones.json>] [-DryRun]

param(
  [string]$DiagramsDir = (Join-Path (Get-Location) "docs/presentations/diagrams"),
  [string]$ZonesJson = (Join-Path $PSScriptRoot "svg-zones.json"),
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $ZonesJson)) { throw "zones json no encontrado: $ZonesJson" }
$zones = Get-Content -LiteralPath $ZonesJson -Raw | ConvertFrom-Json
$totalRect = 0

foreach ($file in $zones.PSObject.Properties.Name) {
  $path = Join-Path $DiagramsDir $file
  if (-not (Test-Path -LiteralPath $path)) { Write-Warning "no existe: $file"; continue }
  $t = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
  if ($t -notmatch '</svg>') { Write-Warning "$file no tiene cierre </svg>"; continue }
  if ($t -match 'class="gv-hotspot"') { Write-Output "${file}: ya tiene hotspots (omitir)"; continue }

  $rects = New-Object System.Text.StringBuilder
  $defs = $zones.($file).PSObject.Properties
  foreach ($def in $defs) {
    $tipKey = $def.Name
    $r = $def.Value.rect
    $label = $def.Value.en
    if ($r.Count -lt 4) { Write-Warning "${file}/${tipKey}: rect invalido"; continue }
    [void]$rects.Append('    <rect class="gv-hotspot" x="')
    [void]$rects.Append($r[0]); [void]$rects.Append('" y="')
    [void]$rects.Append($r[1]); [void]$rects.Append('" width="')
    [void]$rects.Append($r[2]); [void]$rects.Append('" height="')
    [void]$rects.Append($r[3])
    [void]$rects.Append('" rx="6" data-i18n-title="')
    [void]$rects.Append($tipKey)
    [void]$rects.Append('" role="button" tabindex="0" fill="transparent" aria-label="')
    [void]$rects.Append($label)
    [void]$rects.Append('"/>')
    [void]$rects.Append("`n")
    $totalRect++
  }

  $comment = "  <!-- ===== HOTSPOTS INTERACTIVOS (gv-hotspot) ===== -->" + "`n"
  $insert = "`n" + $comment + $rects.ToString() + "</svg>"
  $t = $t -replace '</svg>\s*$', $insert

  if (-not $DryRun) {
    [System.IO.File]::WriteAllText($path, $t, $utf8)
  }
  Write-Output ("{0}: {1} hotspots inyectados" -f $file, $defs.Count)
}

if ($DryRun) { Write-Output "DRY-RUN: $totalRect rects listos (sin escribir)" }
else { Write-Output "DONE: $totalRect hotspots inyectados" }
