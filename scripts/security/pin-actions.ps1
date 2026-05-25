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
    "actions/checkout@v6"          = "actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd"
    "actions/upload-artifact@v7"   = "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"
    "actions/download-artifact@v8" = "actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
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
