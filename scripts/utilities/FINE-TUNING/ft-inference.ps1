param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [ValidateSet("BA","SAD","DEV","QA")]
    [string]$Domain = "",
    [int]$TopN = 3,
    [switch]$UseFT,
    [switch]$FallbackToTFIDF,
    [string]$RegistryPath = "",
    [string]$MLRouterPath = ""
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
if (-not $RegistryPath) { $RegistryPath = Join-Path (Join-Path $ProjectRoot ".ft") "registry.json" }
if (-not $MLRouterPath) { $MLRouterPath = Join-Path $ProjectRoot "scripts" "utilities" "AUTO-DELEGATION" "ml-router.ps1" }

function Get-FTAdapter {
    param([string]$Domain)
    if (-not (Test-Path $RegistryPath)) { return $null }
    try {
        $reg = Get-Content $RegistryPath -Raw | ConvertFrom-Json
        return $reg.adapters | Where-Object { $_.domain -eq $Domain -and $_.active } | Select-Object -First 1
    } catch { return $null }
}

function Invoke-BaselineRouter {
    param([string]$Query, [int]$TopN)
    if (Test-Path $MLRouterPath) {
        $result = & $MLRouterPath -Query $Query -TopN $TopN -Raw
        return $result
    }
    return $null
}

Write-Host "=== FT Inference ===" -ForegroundColor Cyan
Write-Host "Query: $Query"
Write-Host ""

$result = @{
    query = $Query
    domain = $Domain
    mode = "baseline"
    adapter = $null
    matches = @()
    timestamp = (Get-Date -Format "o")
}

if ($UseFT -and $Domain) {
    $adapter = Get-FTAdapter -Domain $Domain
    if ($adapter) {
        Write-Host "[FT-INF] Using LoRA adapter for $Domain" -ForegroundColor Green
        Write-Host "[FT-INF] Model: $($adapter.model) v$($adapter.version)"
        $result.mode = "fine-tuned"
        $result.adapter = $adapter
    } else {
        Write-Host "[FT-INF] No adapter found for $Domain" -ForegroundColor Yellow
        if ($FallbackToTFIDF) {
            Write-Host "[FT-INF] Falling back to TF-IDF baseline..." -ForegroundColor Gray
        }
    }
}

if ($result.mode -eq "baseline" -or $FallbackToTFIDF) {
    Write-Host "[FT-INF] Using TF-IDF baseline router..." -ForegroundColor Gray
    if (Test-Path $MLRouterPath) {
        $routerResult = Invoke-BaselineRouter -Query $Query -TopN $TopN
        $result.matches = $routerResult
        if ($routerResult) {
            $count = @($routerResult).Count
            Write-Host "[FT-INF] TF-IDF returned $count results" -ForegroundColor Green
        }
    } else {
        Write-Host "[FT-INF] ML Router not found at $MLRouterPath" -ForegroundColor Yellow
    }
}

$result | ConvertTo-Json -Depth 3
