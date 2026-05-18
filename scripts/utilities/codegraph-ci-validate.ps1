# codegraph-ci-validate.ps1
# CI validation step: runs codegraph affected on changed files to detect impact
# Returns exit code 0 if no issues, 1 if affected tests found (configurable)

param(
    [string]$WorkspaceRoot = ".",
    [string]$BaseBranch = "develop",
    [string[]]$ChangedFiles = @(),
    [switch]$FailOnAffected = $false,
    [switch]$AsJson,
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$codegraphDir = Join-Path $repoRoot ".codegraph"
$dbPath = Join-Path $codegraphDir "codegraph.db"

function Write-Result {
    param([string]$Status, [string]$Message, [hashtable]$Data = @{})
    if ($AsJson) {
        $result = @{ status = $Status; message = $Message; timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") }
        foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
        Write-Output ($result | ConvertTo-Json -Compress)
    } else {
        $color = if ($Status -eq "OK") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
        Write-Host "[$Status] $Message" -ForegroundColor $color
    }
}

if (-not (Test-Path $dbPath)) {
    Write-Result "WARN" "CodeGraph database not found. Skipping CI validation."
    exit 0
}

if ($ChangedFiles.Count -eq 0) {
    try {
        $gitDiff = & git -C $repoRoot diff --name-only "$BaseBranch..." 2>&1
        $ChangedFiles = @($gitDiff | Where-Object { $_ -and $_.Trim() }) | ForEach-Object { $_.Trim() }
    } catch {
        $ChangedFiles = @()
    }

    if ($ChangedFiles.Count -eq 0) {
        try {
            $gitStatus = & git -C $repoRoot status --porcelain 2>&1
            $ChangedFiles = @($gitStatus | ForEach-Object {
                if ($_ -match '^\s*\S+\s+(.+)$') { $Matches[1] }
            }) | Where-Object { $_ }
        } catch {
            $ChangedFiles = @()
        }
    }
}

if ($ChangedFiles.Count -eq 0) {
    Write-Result "OK" "No changed files detected. Nothing to validate."
    exit 0
}

if ($Verbose) {
    Write-Host "[INFO] Validating $($ChangedFiles.Count) changed files against CodeGraph index..." -ForegroundColor Cyan
    foreach ($f in $ChangedFiles) {
        Write-Host "  - $f" -ForegroundColor Gray
    }
}

$affectedTests = @()
$affectedSymbols = @()

foreach ($file in $ChangedFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) { continue }

    $ext = [System.IO.Path]::GetExtension($file)
    if ($ext -in @('.ts', '.tsx', '.js', '.jsx', '.py', '.go', '.rs', '.java', '.vue', '.svelte')) {
        try {
            $affectedResult = & codegraph affected $file 2>&1
            if ($LASTEXITCODE -eq 0 -and $affectedResult) {
                $affectedTests += $affectedResult
                $affectedSymbols += @{ file = $file; affected = $affectedResult }
            }
        } catch {
            if ($Verbose) { Write-Host "  [WARN] Could not analyze: $file" -ForegroundColor Yellow }
        }
    }
}

$uniqueAffectedTests = $affectedTests | Select-Object -Unique | Where-Object { $_ }

$summary = @{
    changedFiles = $ChangedFiles.Count
    affectedTestCount = $uniqueAffectedTests.Count
    affectedTests = $uniqueAffectedTests
}

if ($uniqueAffectedTests.Count -gt 0) {
    Write-Result "WARN" "Found $($uniqueAffectedTests.Count) affected test file(s) for $($ChangedFiles.Count) changed file(s)" $summary

    if ($Verbose) {
        Write-Host ""
        Write-Host "Affected Tests:" -ForegroundColor Yellow
        foreach ($t in $uniqueAffectedTests) {
            Write-Host "  - $t" -ForegroundColor Gray
        }
    }

    if ($FailOnAffected) {
        exit 1
    }
} else {
    Write-Result "OK" "No affected tests detected for $($ChangedFiles.Count) changed file(s)" $summary
}

exit 0