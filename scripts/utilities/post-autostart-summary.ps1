param(
    [string]$TimeZone,
    [int]$PeakStart,
    [int]$PeakEnd,
    [string]$Region
)

if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path -LiteralPath "$env:GENTLE_VANGUARD_BASE_DIR\config\orchestrator.json")) {
    $repoRoot = $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $repoRoot = $PSScriptRoot
    while ($repoRoot -and -not (Test-Path -LiteralPath "$repoRoot\config\orchestrator.json")) {
        $repoRoot = Split-Path -Parent $repoRoot
    }
}

if (-not $repoRoot) {
    Write-Host "ERROR: Could not locate repository root (config\orchestrator.json not found)." -ForegroundColor Red
    exit 1
}

$latestSession = Get-ChildItem -LiteralPath "$repoRoot\session" -Filter "session-*.json" | Sort-Object -Property Name -Descending | Select-Object -First 1
$sessionId = if ($latestSession) { (Get-Content -Raw -LiteralPath $latestSession.FullName | ConvertFrom-Json).sessionId } else { $null }

$timestamp = (Get-Date).ToString("o")
$branch = git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null
$lastCommit = git -C $repoRoot log -1 --format="%H" 2>$null

$summary = @{
    timestamp = $timestamp
    sessionId = $sessionId
    timezone  = $TimeZone
    peakStart = $PeakStart
    peakEnd   = $PeakEnd
    region    = $Region
    workspace = @{
        branch      = $branch
        lastCommit  = $lastCommit
    }
}

$outPath = "$repoRoot\reports\startup-summary.json"
$null = New-Item -ItemType Directory -Path "$repoRoot\reports" -Force
$summary | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $outPath -Encoding UTF8

Write-Host "Startup summary written to $outPath"
Write-Host "  timestamp : $timestamp"
Write-Host "  sessionId : $sessionId"
Write-Host "  branch    : $branch"
Write-Host "  lastCommit: $lastCommit"
Write-Host "  timezone  : $TimeZone"
Write-Host "  peakStart : $PeakStart"
Write-Host "  peakEnd   : $PeakEnd"
Write-Host "  region    : $Region"

exit 0
