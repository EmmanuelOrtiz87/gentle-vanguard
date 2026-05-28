param([switch]$Quiet)
$changed = git diff --name-only HEAD~1 HEAD 2>$null
if (-not $changed) { exit 0 }
$lines = $changed -split "`n"
foreach ($path in $lines) {
    $p = $path.Trim()
    if ($p -and (Test-Path $p -ErrorAction SilentlyContinue)) {
        & "$PSScriptRoot\hashline.ps1" -Action update -Path $p -Quiet:$Quiet
    }
}