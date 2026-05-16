param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
if ($env:GV_BASE_DIR) {
    $repoRoot = $env:GV_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
Set-Location $repoRoot

$gitHooksDir = Join-Path $repoRoot '.git/hooks'
$preCommitHook = Join-Path $gitHooksDir 'pre-commit'
$prePushHook = Join-Path $gitHooksDir 'pre-push'

function Install-Hooks {
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
    }
    
    $preCommitContent = @'
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\scripts\hooks\pre-commit-normalization.ps1'"
exit $?
'@
    
    $prePushContent = @'
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\scripts\hooks\pre-push-normalization.ps1'"
exit $?
'@
    
    $preCommitContent | Out-File -FilePath $preCommitHook -Encoding UTF8 -NoNewline
    $prePushContent | Out-File -FilePath $prePushHook -Encoding UTF8 -NoNewline
    
    if ($PSVersionTable.Platform -ne 'Win32NT') {
        chmod +x $preCommitHook
        chmod +x $prePushHook
    }
    
    Write-Host "Normalization hooks installed successfully" -ForegroundColor Green
}

function Uninstall-Hooks {
    if (Test-Path $preCommitHook) {
        Remove-Item $preCommitHook -Force
    }
    if (Test-Path $prePushHook) {
        Remove-Item $prePushHook -Force
    }
    
    Write-Host "Normalization hooks uninstalled" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Script Normalization Hooks Setup" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

if ($Uninstall) {
    Uninstall-Hooks
} else {
    Install-Hooks
    Write-Host ""
    Write-Host "Hooks installed:" -ForegroundColor Cyan
    Write-Host "  - Pre-commit: Validates script normalization" -ForegroundColor White
    Write-Host "  - Pre-push: Validates script compliance" -ForegroundColor White
    Write-Host ""
}

exit 0
