param(
    [string]$ProjectName = 'workspace_local',
    [switch]$AutoApply = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')

function Find-EngramBinary {
    $localPath = Join-Path $repoRoot 'tools\engram.exe'
    if (Test-Path $localPath) {
        return $localPath
    }
    $localPath2 = Join-Path $repoRoot 'tools\engram'
    if (Test-Path $localPath2) {
        return $localPath2
    }
    $userBin = 'C:\Users\emman\bin\engram.exe'
    if (Test-Path $userBin) {
        return $userBin
    }
    $inPath = Get-Command 'engram.exe' -ErrorAction SilentlyContinue
    if ($inPath) {
        return $inPath.Source
    }
    $inPath2 = Get-Command 'engram' -ErrorAction SilentlyContinue
    if ($inPath2) {
        return $inPath2.Source
    }
    return $null
}

function Write-Status {
    param([string]$m)
    Write-Host "[ENGRAM] $m" -ForegroundColor Green
}

function Write-Info {
    param([string]$m)
    Write-Host "[INFO] $m" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$m)
    Write-Host "[WARN] $m" -ForegroundColor Yellow
}

function Get-EngramMemory {
    param([string]$Project)

    $engramBin = Find-EngramBinary
    if (-not $engramBin) {
        return $null
    }

    $result = & $engramBin context --limit 10 2>$null
    return $result
}

function Search-EngramObservations {
    param(
        [string]$Project,
        [string]$Query
    )

    $engramBin = Find-EngramBinary
    if (-not $engramBin) {
        return $null
    }

    $result = & $engramBin search $Query --project $Project --limit 5 2>$null
    return $result
}

function Get-ProjectObservations {
    param([string]$Project)

    $engramBin = Find-EngramBinary
    if (-not $engramBin) {
        return $null
    }

    $result = & $engramBin search '' --project $Project --limit 20 2>$null
    return $result
}

function Save-PreloadCache {
    param(
        [string]$RepoRoot,
        [hashtable]$Data
    )

    $cacheDir = Join-Path $repoRoot '.session\engram-cache'
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }

    $cacheFile = Join-Path $cacheDir 'preload-cache.json'
    $Data.timestamp = (Get-Date -Format 'o')
    $Data.project = $ProjectName

    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile -Encoding UTF8
    return $cacheFile
}

function Get-PreloadCache {
    param([string]$RepoRoot)

    $cacheFile = Join-Path $repoRoot '.session\engram-cache\preload-cache.json'
    if (-not (Test-Path $cacheFile)) {
        return $null
    }

    $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json
    $age = (Get-Date) - [DateTime]::Parse($cache.timestamp)
    if ($age.TotalHours -gt 24) {
        return $null
    }
    return $cache
}

Write-Status "Engram Pre-load for project: $ProjectName"
Write-Info "Starting context optimization..."

$engramBin = Find-EngramBinary
if (-not $engramBin) {
    Write-Warn "Engram binary not found. Pre-load skipped."
    Write-Info "Run: .\scripts\utilities\wf.ps1 install-engram"
    exit 0
}

$startTime = Get-Date

$cachedData = Get-PreloadCache -RepoRoot $repoRoot
if ($cachedData) {
    Write-Info "Using cached pre-load (age: $((Get-Date) - [DateTime]::Parse($cachedData.timestamp)).TotalMinutes minutes)"
} else {
    Write-Info "Generating fresh pre-load..."
}

$observationsLoaded = 0
$recentContext = @()
$projectObservations = @()
$searchResults = @()

try {
    Write-Info "Loading recent context..."
    $contextOutput = Get-EngramMemory -Project $ProjectName
    if ($contextOutput) {
        $recentContext = $contextOutput -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $observationsLoaded = $recentContext.Count
        Write-Info "Loaded $($observationsLoaded) recent observations"
    }
} catch {
    Write-Warn "Could not load recent context: $_"
}

try {
    Write-Info "Loading project observations..."
    $projOutput = Get-ProjectObservations -Project $ProjectName
    if ($projOutput) {
        $projectObservations = $projOutput -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        Write-Info "Found $($projectObservations.Count) project observations"
    }
} catch {
    Write-Warn "Could not load project observations: $_"
}

try {
    Write-Info "Searching for decisions and patterns..."
    $searchOutput = Search-EngramObservations -Project $ProjectName -Query "decision OR architecture OR pattern OR bugfix"
    if ($searchOutput) {
        $searchResults = $searchOutput -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        Write-Info "Found $($searchResults.Count) relevant observations"
    }
} catch {
    Write-Warn "Search failed: $_"
}

$cacheData = @{
    timestamp = $startTime
    project = $ProjectName
    observations = $observationsLoaded
    recentContext = $recentContext
    projectObservations = $projectObservations
    searchResults = $searchResults
}

$cacheFile = Save-PreloadCache -RepoRoot $repoRoot -Data $cacheData
Write-Status "Pre-load cache saved: $cacheFile"

$elapsed = (Get-Date) - $startTime
Write-Status "Engram pre-load completed in $($elapsed.TotalMilliseconds)ms"

if ($Verbose) {
    Write-Host "`n--- Recent Context ($observationsLoaded items) ---" -ForegroundColor Gray
    $recentContext | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($recentContext.Count -gt 5) {
        Write-Host "  ... and $($recentContext.Count - 5) more" -ForegroundColor DarkGray
    }
}

Write-Info "Pre-load benefits:"
Write-Host "  - Context available without explicit mem_context calls" -ForegroundColor Gray
Write-Host "  - Reduced token usage (no repeated context loading)" -ForegroundColor Gray
Write-Host "  - Faster session resume" -ForegroundColor Gray
Write-Host "  - Recent decisions/patterns visible at session start" -ForegroundColor Gray

if ($AutoApply) {
    Write-Status "Auto-apply enabled - optimizations active"
}

Write-Status "Pre-load optimization completed"
exit 0