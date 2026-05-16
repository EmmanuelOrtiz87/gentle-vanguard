#!/usr/bin/env pwsh
param(
    [string]$ProjectName = 'workspace_gentle_vanguard'
)

$ErrorActionPreference = 'SilentlyContinue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$engramSafe = Join-Path $repoRoot 'scripts\utilities\engram-safe.ps1'
if (Test-Path $engramSafe) {
    . $engramSafe
}

if (-not (Get-Command Invoke-Gentle-VanguardEngram -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Engram helper unavailable. Context restore skipped (non-critical)." -ForegroundColor Cyan
    exit 0
}

$result = Invoke-Gentle-VanguardEngram -RepoRoot $repoRoot -Arguments @('context', $ProjectName)

if ($result.Success) {
    Write-Host "[OK] Engram context restored for project: $ProjectName" -ForegroundColor Green
    if ($result.Output) {
        $result.Output | ForEach-Object { Write-Host $_ }
    }
    exit 0
}

Write-Host "[WARN] Engram context restore skipped (non-critical): $($result.Output -join ' | ')" -ForegroundColor Yellow
exit 0
