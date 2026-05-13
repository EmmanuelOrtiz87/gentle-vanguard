# lockfile-lint-pre-commit.ps1
# Validate package-lock.json structure and integrity
# Prevents corrupted lockfiles from being committed

param(
    [string]$LockfilePath = "package-lock.json",
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

# Check if lockfile is staged
$stagedFiles = git diff --cached --name-only 2>$null
if ($stagedFiles -notcontains $LockfilePath) {
    if ($Verbose) {
        Write-Host "[lockfile-lint] $LockfilePath not staged, skipping validation" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path $LockfilePath)) {
    Write-Host "[lockfile-lint] $LockfilePath not found, skipping validation" -ForegroundColor Yellow
    exit 0
}

Write-Host "[lockfile-lint] Validating $LockfilePath..." -ForegroundColor Cyan

# 1. Validate JSON structure
try {
    $lockContent = Get-Content $LockfilePath -Raw
    $lock = $lockContent | ConvertFrom-Json -ErrorAction Stop
    Write-Host "[OK] JSON structure valid" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Invalid JSON in lockfile: $_" -ForegroundColor Red
    Write-Host "`nTo fix:" -ForegroundColor Yellow
    Write-Host "  1. Inspect the file: code $LockfilePath" -ForegroundColor White
    Write-Host "  2. Fix JSON syntax errors" -ForegroundColor White
    Write-Host "  3. Regenerate if corrupted: rm $LockfilePath && npm install" -ForegroundColor White
    exit 1
}

# 2. Validate required fields
$requiredFields = @("lockfileVersion", "requires", "packages")
$missingFields = @()

foreach ($field in $requiredFields) {
    if (-not (Get-Member -InputObject $lock -Name $field -ErrorAction SilentlyContinue)) {
        $missingFields += $field
    }
}

if ($missingFields.Count -gt 0) {
    Write-Host "[ERROR] Missing required fields: $($missingFields -join ', ')" -ForegroundColor Red
    Write-Host "`nTo fix:" -ForegroundColor Yellow
    Write-Host "  Run: npm install  (to regenerate valid lockfile)" -ForegroundColor White
    exit 1
}

Write-Host "[OK] Required fields present (lockfileVersion=$($lock.lockfileVersion))" -ForegroundColor Green

# 3. Validate packages object not empty
if ($lock.packages.PSObject.Properties.Count -eq 0) {
    Write-Host "[WARNING] packages object is empty" -ForegroundColor Yellow
    Write-Host "  This might indicate a corrupted lockfile" -ForegroundColor Yellow
}

# 4. Check for common corruption patterns
$issues = @()

# Check for invalid version formats
$invalidVersions = $lock.packages.PSObject.Properties | Where-Object {
    $_.Value.version -and $_.Value.version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$'
}

if ($invalidVersions) {
    $issues += "Invalid version format detected"
}

# Check for missing integrity hashes (can indicate corruption)
$missingIntegrity = $lock.packages.PSObject.Properties | Where-Object {
    $_.Value.resolved -and -not $_.Value.integrity
} | Measure-Object | Select-Object -ExpandProperty Count

if ($missingIntegrity -gt 0) {
    $issues += "$missingIntegrity packages missing integrity hashes"
}

if ($issues.Count -gt 0) {
    Write-Host "[WARNING] Potential lockfile issues detected:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
    Write-Host "`nConsider regenerating: npm ci && npm install --save-exact" -ForegroundColor Yellow
}

# 5. Validate lockfile version compatibility
$lockfileVersion = $lock.lockfileVersion
if ($lockfileVersion -lt 2) {
    Write-Host "[WARNING] lockfileVersion $lockfileVersion is outdated" -ForegroundColor Yellow
    Write-Host "  Recommend updating to v3+: npm install" -ForegroundColor Yellow
}

Write-Host "[OK] Lockfile validation passed" -ForegroundColor Green
exit 0
