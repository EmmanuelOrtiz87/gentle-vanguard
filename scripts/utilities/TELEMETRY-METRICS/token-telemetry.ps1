param(
    [double]$CostPer1MTokens = 10,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$roots = @(
    "C:\Workspace_local\workspace-foundation",
    "C:\Workspace_local\bitbucket-dashboard"
)

$reports = @()

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }
    $usage = Join-Path $root 'docs\sessions\metrics\token-guard-usage.csv'
    if (-not (Test-Path $usage)) { continue }

    $rows = Import-Csv -Path $usage -ErrorAction SilentlyContinue
    if (-not $rows) { continue }

    $totalTokens = 0
    foreach ($row in $rows) {
        $tokens = 0
        if ($row.estimated_tokens -match '^\d+$') {
            $tokens = [int]$row.estimated_tokens
            $totalTokens += $tokens
        }
    }

    $costPerToken = $CostPer1MTokens / 1000000
    $cost = [math]::Round($totalTokens * $costPerToken, 2)

    $reports += [pscustomobject]@{
        repo = Split-Path $root -Leaf
        totalTokens = $totalTokens
        costUSD = $cost
    }
}

if ($AsJson) {
    $reports | ConvertTo-Json -Depth 3
    exit 0
}

Write-Host "Token Telemetry (Global)" -ForegroundColor Cyan
foreach ($r in $reports) {
    Write-Host "- $($r.repo): $($r.totalTokens) tokens | $($r.costUSD) USD" -ForegroundColor Gray
}