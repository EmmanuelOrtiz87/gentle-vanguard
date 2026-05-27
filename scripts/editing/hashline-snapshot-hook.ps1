param([switch]$Quiet)
$changed = git diff --name-only HEAD~1 HEAD 2>$null
if (-not $changed) { exit 0 }
$changed | ForEach-Object {
    $path = $_
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        & "$PSScriptRoot\hashline.ps1" -Action update -Path $path -Quiet:$Quiet
    }
}