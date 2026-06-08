$lefthook = Get-Command lefthook -ErrorAction SilentlyContinue
if (-not $lefthook) {
    Write-Host "lefthook is not installed — hooks will not run" -ForegroundColor Yellow
    exit 0
}
$version = & lefthook version 2>$null
if (-not $version) {
    Write-Host "lefthook binary found but failed to run" -ForegroundColor Yellow
    exit 0
}
$repoRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$config = $null
if (Test-Path -LiteralPath (Join-Path $repoRoot "lefthook.json")) {
    $config = "lefthook.json"
} elseif (Test-Path -LiteralPath (Join-Path $repoRoot ".lefthook.yml")) {
    $config = ".lefthook.yml"
} elseif (Test-Path -LiteralPath (Join-Path $repoRoot ".lefthook.yaml")) {
    $config = ".lefthook.yaml"
}
if (-not $config) {
    Write-Host "lefthook is installed but no config file found in repo root" -ForegroundColor Yellow
    exit 0
}
Write-Host "lefthook $version — $config found" -ForegroundColor Green
exit 0
