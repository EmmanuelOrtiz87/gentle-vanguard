<#
.SYNOPSIS
    Pin/unpin GitHub Actions to commit SHAs for supply-chain security
.DESCRIPTION
    Replaces semantic version tags (@v4, @v6) with pinned commit SHAs
    across all workflow files. Supports --pin (default) and --unpin modes.
    SHA mapping is hardcoded and manually audited.
#>
param(
    [ValidateSet("pin","unpin")]
    [string]$Mode = "pin",
    [switch]$Quiet
)

$workflowDir = Join-Path $PSScriptRoot "..\..\.github\workflows"
$workflowDir = (Get-Item $workflowDir).FullName

$map = @{
    "actions/checkout@v4"          = "actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5"
    "actions/upload-artifact@v4"   = "actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02"
    "actions/download-artifact@v4" = "actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093"
    "actions/setup-node@v6"        = "actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e"
    "actions/cache@v5"             = "actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae"
    "actions/labeler@v6"           = "actions/labeler@f27b608878404679385c85cfa523b85ccb86e213"
}

if ($Mode -eq "unpin") {
    $reverse = @{}
    foreach ($k in $map.Keys) { $reverse[$map[$k]] = $k }
    $map = $reverse
}

$changed = 0
Get-ChildItem "$workflowDir\*.yml" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $original = $content
    foreach ($entry in $map.GetEnumerator()) {
        $content = $content -replace [regex]::Escape($entry.Key), $entry.Value
    }
    if ($content -ne $original) {
        Set-Content $_.FullName -Value $content -NoNewline
        $changed++
        if (-not $Quiet) { Write-Host "  [PINNED] $($_.Name)" -ForegroundColor Green }
    }
}

if (-not $Quiet) { Write-Host "Done: $changed workflow files updated ($Mode mode)" -ForegroundColor Cyan }
exit 0
