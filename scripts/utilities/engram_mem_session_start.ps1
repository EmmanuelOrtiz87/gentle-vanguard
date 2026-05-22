#!/usr/bin/env pwsh
param(
    [string]$ProjectName = 'workspace_gentle_vanguard',
    [string]$SessionId = ''
)

$ErrorActionPreference = 'Continue'

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

if ([string]::IsNullOrWhiteSpace($SessionId)) {
    $sessionIdScript = Join-Path $repoRoot 'scripts\utilities\get-session-id.ps1'
    if (Test-Path $sessionIdScript) {
        $SessionId = (& $sessionIdScript | Select-Object -First 1).Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($SessionId)) {
    $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
}

if (-not (Get-Command Invoke-Gentle-VanguardEngram -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Engram helper unavailable. Session marker skipped (non-critical)." -ForegroundColor Cyan
    exit 0
}

$title = "Session start: $SessionId"
$content = "Session $SessionId registered manually for project $ProjectName."
$result = Invoke-Gentle-VanguardEngram -RepoRoot $repoRoot -Arguments @('save', $title, $content, '--project', $ProjectName, '--type', 'session')

if ($result.Success) {
    Write-Host "[OK] Engram session registered: $SessionId" -ForegroundColor Green
    exit 0
}

Write-Host "[WARN] Engram session registration skipped (non-critical): $($result.Output -join ' | ')" -ForegroundColor Yellow
exit 0
