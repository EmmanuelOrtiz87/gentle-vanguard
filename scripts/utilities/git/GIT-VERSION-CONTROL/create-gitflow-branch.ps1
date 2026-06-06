param(
    [string]$Description,
    [ValidateSet('feature', 'bugfix', 'chore', 'hotfix', 'release')]
    [string]$Type,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
if ($env:GV_BASE_DIR) {
    $repoRoot = $env:GV_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
Set-Location $repoRoot

function Write-Header {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host "$Message" -ForegroundColor Cyan
        Write-Host "========================================================" -ForegroundColor Cyan
    }
}

function Write-Info { param([string]$Message) if (-not $Quiet) { Write-Host "[INFO] $Message" -ForegroundColor Cyan } }
function Write-Success { param([string]$Message) if (-not $Quiet) { Write-Host "[OK] $Message" -ForegroundColor Green } }
function Write-Warning { param([string]$Message) if (-not $Quiet) { Write-Host "[WARN] $Message" -ForegroundColor Yellow } }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Header "GitFlow Branch Creator"

# Validate that we are in a Git repository
try {
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Write-Error "No valid Git repository detected"
        exit 1
    }
} catch {
    Write-Error "Error detecting Git repository: $_"
    exit 1
}

Write-Info "Current branch: $currentBranch"

# Request branch type if not provided
if ([string]::IsNullOrWhiteSpace($Type)) {
    Write-Host ""
    Write-Host "What type of change is this?" -ForegroundColor Cyan
    Write-Host "   1) feature  - New functionality" -ForegroundColor White
    Write-Host "   2) bugfix   - Bug fix" -ForegroundColor White
    Write-Host "   3) chore    - Maintenance/update" -ForegroundColor White
    Write-Host "   4) hotfix   - Critical production fix" -ForegroundColor Red
    Write-Host "   5) release  - Release preparation" -ForegroundColor Yellow
    
    $choice = Read-Host ""
    Write-Host "Select (1-5)"
    $typeMap = @{
        '1' = 'feature'
        '2' = 'bugfix'
        '3' = 'chore'
        '4' = 'hotfix'
        '5' = 'release'
    }
    
    if (-not $typeMap.ContainsKey($choice)) {
        Write-Error "Invalid option: $choice"
        exit 1
    }
    
    $Type = $typeMap[$choice]
}

# Display information about selected type
Write-Host ""
Write-Host "Branch type information:" -ForegroundColor Cyan
switch ($Type) {
    'feature' {
        Write-Host "   Purpose: New functionality" -ForegroundColor Green
        Write-Host "   Expected base: develop" -ForegroundColor Green
        Write-Host "   Example: feature/add-user-authentication" -ForegroundColor Green
    }
    'bugfix' {
        Write-Host "   Purpose: Bug fixes in development" -ForegroundColor Green
        Write-Host "   Expected base: develop" -ForegroundColor Green
        Write-Host "   Example: bugfix/fix-login-timeout" -ForegroundColor Green
    }
    'chore' {
        Write-Host "   Purpose: Maintenance, updates, refactoring" -ForegroundColor Green
        Write-Host "   Expected base: develop" -ForegroundColor Green
        Write-Host "   Example: chore/update-dependencies" -ForegroundColor Green
    }
    'hotfix' {
        Write-Host "   Purpose: Critical production fixes (main)" -ForegroundColor Red
        Write-Host "   Expected base: main" -ForegroundColor Red
        Write-Host "   Example: hotfix/critical-security-patch" -ForegroundColor Red
    }
    'release' {
        Write-Host "   Purpose: Release preparation" -ForegroundColor Yellow
        Write-Host "   Expected base: main" -ForegroundColor Yellow
        Write-Host "   Example: release/v1.2.0" -ForegroundColor Yellow
    }
}

# Request description if not provided
if ([string]::IsNullOrWhiteSpace($Description)) {
    Write-Host ""
    Write-Host "Briefly describe the change:" -ForegroundColor Cyan
    Write-Host "   (use hyphens to separate words, e.g: add-user-auth)" -ForegroundColor Gray
    $Description = Read-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Description)) {
        Write-Error "Description cannot be empty"
        exit 1
    }
}

# Validate and clean description
$Description = $Description.ToLower()
$Description = $Description -replace '[^a-z0-9\-]', '-' -replace '-+', '-' -replace '^-|-$', ''

if ([string]::IsNullOrWhiteSpace($Description)) {
    Write-Error "Description is empty after cleanup"
    exit 1
}

# Build branch name
$branchName = "$Type/$Description"

Write-Info "Proposed branch name: $branchName"

# Validate that branch does not exist
$branchExists = git rev-parse --verify $branchName 2>$null
if ($null -ne $branchExists) {
    Write-Error "Branch '$branchName' already exists"
    exit 1
}

# Determine expected base
$expectedBase = if ($Type -in @('feature', 'bugfix', 'chore')) { 'develop' } else { 'main' }
Write-Info "Expected PR base: $expectedBase"

# Verify that base branch exists
$baseExists = git rev-parse --verify "origin/$expectedBase" 2>$null
if ($null -eq $baseExists) {
    Write-Warning "Remote branch 'origin/$expectedBase' not found locally"
    Write-Info "Updating remote references..."
    git fetch origin --quiet
}

# Create branch from correct base
Write-Host ""
Write-Host "Creating branch..." -ForegroundColor Cyan
try {
    git checkout -b $branchName "origin/$expectedBase" 2>&1 | Out-Null
    Write-Success "Branch '$branchName' created successfully"
} catch {
    Write-Error "Error creating branch: $_"
    exit 1
}

# Display next steps
Write-Header "Next Steps"

Write-Host ""
Write-Host "1. Make your changes in the files" -ForegroundColor Cyan
Write-Host "   Edit the necessary files for your change" -ForegroundColor Gray

Write-Host ""
Write-Host "2. Stage your changes" -ForegroundColor Cyan
Write-Host "   git add ." -ForegroundColor Yellow

Write-Host ""
Write-Host "3. Create a commit" -ForegroundColor Cyan
Write-Host "   git commit -m 'clear description of change'" -ForegroundColor Yellow

Write-Host ""
Write-Host "4. Push the branch" -ForegroundColor Cyan
Write-Host "   git push -u origin $branchName" -ForegroundColor Yellow

Write-Host ""
Write-Host "5. Open a Pull Request on GitHub" -ForegroundColor Cyan
Write-Host "   Base: $expectedBase" -ForegroundColor Yellow
Write-Host "   Title: Clear description of change" -ForegroundColor Yellow
Write-Host "   Description: Explain WHAT changed and WHY" -ForegroundColor Yellow

Write-Host ""
Write-Host "Branch information:" -ForegroundColor Cyan
Write-Host "   Name: $branchName" -ForegroundColor Green
Write-Host "   Type: $Type" -ForegroundColor Green
Write-Host "   Expected base: $expectedBase" -ForegroundColor Green
Write-Host "   Status: Ready to work" -ForegroundColor Green

Write-Host ""
Write-Host "Remember:" -ForegroundColor Cyan
Write-Host "   - Commits will be validated automatically (pre-commit hook)" -ForegroundColor Gray
Write-Host "   - Push will be validated against GitFlow (pre-push hook)" -ForegroundColor Gray
Write-Host "   - PR must have the correct base: $expectedBase" -ForegroundColor Gray

Write-Host ""
exit 0
