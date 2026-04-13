# update-suite.ps1
# Gentleman Foundation Suite - Complete Update Script
# Delegates to update-tools.ps1 for the actual tool updates.
#
# To update all tools (gga, engram, gentle-ai) run:
#   .\scripts\utilities\wf.ps1 update-tools
# Or directly:
#   .\scripts\utilities\update-tools.ps1
#
# NOTE: brew is NOT required on Windows. All tools install via:
#   gga       -> bash install.sh (Git Bash, gentleman-guardian-angel repo)
#   engram    -> go install github.com/Gentleman-Programming/engram/cmd/engram@latest
#   gentle-ai -> go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest

param(
    [switch]$DryRun,
    [switch]$Force
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "Gentleman Foundation Suite - Update" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$updateToolsScript = Join-Path $scriptDir 'update-tools.ps1'
if (-not (Test-Path $updateToolsScript)) {
    Write-Host "[ERROR] update-tools.ps1 not found at: $updateToolsScript" -ForegroundColor Red
    exit 1
}

if ($DryRun -and $Force) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateToolsScript -DryRun -Force
} elseif ($DryRun) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateToolsScript -DryRun
} elseif ($Force) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateToolsScript -Force
} else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateToolsScript
}
exit $LASTEXITCODE
