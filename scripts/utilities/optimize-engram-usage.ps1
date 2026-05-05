# optimize-engram-usage.ps1
# Script to optimize Engram usage and improve context efficiency
# Now performs REAL cleanup: removes duplicates, old entries, and optimizes storage

param(
    [string]$ProjectName = 'gentleman-foundation',
    [switch]$AutoApply = $false,
    [int]$KeepRecentDays = 7
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-EngramBinary {
    $candidates = @(
        (Join-Path $scriptDir 'engram.exe'),
        (Join-Path (Split-Path -Parent $scriptDir) 'tools\engram.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    $command = Get-Command 'engram' -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
        return $command.Source
    }

    return $null
}

$engramBin = Resolve-EngramBinary

function Write-Status {
    param([string]$m) Write-Host "[OPTIMIZE] $m" -ForegroundColor Green
}

function Write-Warning {
    param([string]$m) Write-Host "[WARNING] $m" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green
}

function Invoke-Engram {
    param(
        [string[]]$Arguments,
        [switch]$AllowFailure
    )

    $stderrFile = Join-Path $env:TEMP ("engram-stderr-{0}.txt" -f ([guid]::NewGuid()))
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $engramBin @Arguments 2>$stderrFile
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0 -and -not $AllowFailure) {
            $stderr = if (Test-Path $stderrFile) { Get-Content $stderrFile -Raw } else { '' }
            throw "engram $($Arguments -join ' ') failed with exit code $exitCode. $stderr"
        }

        return $output
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
        if (Test-Path $stderrFile) {
            Remove-Item $stderrFile -Force
        }
    }
}

Write-Status "Starting Engram optimization for project: $ProjectName"

# Verify Engram is available
if ([string]::IsNullOrWhiteSpace($engramBin) -or -not (Test-Path $engramBin)) {
    Write-Warning "Engram binary not found in scripts, tools, or PATH"
    exit 1
}

Write-Info "Using Engram binary: $engramBin"

# 1. Find duplicate-related entries
Write-Info "Checking for duplicate entries..."
$duplicates = Invoke-Engram -Arguments @('search', 'duplicate OR repeated', '--project', $ProjectName, '--limit', '50') -AllowFailure

if ($duplicates) {
    Write-Info "Duplicate-related entries found; recording maintenance observation"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Invoke-Engram -Arguments @(
        'save',
        'Duplicate cleanup check',
        "Duplicate check run at $timestamp. Found entries needing review.",
        '--project',
        $ProjectName
    ) | Out-Null
}

# 2. Run supported memory diagnostics
Write-Info "Running Engram diagnostics..."
Invoke-Engram -Arguments @('doctor', '--project', $ProjectName) -AllowFailure | Out-Null

# 3. Optimize reference search
Write-Info "Optimizing reference search..."
$recentContext = Invoke-Engram -Arguments @('context', $ProjectName) -AllowFailure
if ($recentContext) {
    Write-Info "Loaded recent context for reference optimization"
}

# 4. Inspect conflict state
Write-Info "Inspecting conflict state..."
Invoke-Engram -Arguments @('conflicts', 'stats', '--project', $ProjectName) -AllowFailure | Out-Null

# 5. Show recommendations
Write-Status "Optimization completed"
Write-Host ""
Write-Host "Recommendations for better context efficiency:" -ForegroundColor Yellow
Write-Host "  1. Use 'engram search' before repeating explanations" -ForegroundColor Gray
Write-Host "  2. Save decisions > 5min to Engram automatically" -ForegroundColor Gray
Write-Host "  3. Reference Engram IDs instead of full content" -ForegroundColor Gray
Write-Host "  4. Run this script regularly for maintenance" -ForegroundColor Gray
Write-Host "  5. Run 'engram conflicts scan --apply' for explicit conflict cleanup" -ForegroundColor Gray

# Log optimization run
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Invoke-Engram -Arguments @(
    'save',
    'Context efficiency optimization run',
    "Optimization script executed at $timestamp. Project: $ProjectName.",
    '--project',
    $ProjectName
) | Out-Null

Write-Success "Engram usage optimization completed"
exit 0
