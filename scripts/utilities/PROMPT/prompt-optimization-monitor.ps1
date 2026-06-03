param(
    [string]$WorkspaceRoot = ".",
    [int]$SoftThreshold = 3000,
    [int]$HardThreshold = 5000
)
$cfgPath = Join-Path $WorkspaceRoot "config/system-prompt-optimization.json"
if (Test-Path $cfgPath) {
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($cfg.monitoring) {
        $SoftThreshold = $cfg.monitoring.alertThreshold
        $HardThreshold = $cfg.monitoring.criticalThreshold
    }
}

$claudePath = Join-Path $WorkspaceRoot "CLAUDE.md"
if (-not (Test-Path $claudePath)) { exit 0 }
$content = Get-Content $claudePath -Raw
$tokens = [Math]::Ceiling($content.Length / 4)
Write-Host "System prompt: $tokens tokens"
if ($tokens -gt $HardThreshold) { Write-Host "ALERT: Exceeds $HardThreshold tokens!" -ForegroundColor Red; exit 1 }
elseif ($tokens -gt $SoftThreshold) { Write-Host "WARNING: Approaching limit" -ForegroundColor Yellow }
else { Write-Host "OK: Within limits" -ForegroundColor Green }
