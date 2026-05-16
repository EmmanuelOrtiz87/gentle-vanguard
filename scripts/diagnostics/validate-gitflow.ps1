param(
    [switch]$Quiet,
    [switch]$EnforcePrBase,
    [string]$PrBase,
    [switch]$Interactive
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

function Write-Ok { param([string]$Message) if (-not $Quiet) { Write-Host "[OK] $Message" -ForegroundColor Green } }
function Write-Warn { param([string]$Message) if (-not $Quiet) { Write-Host "[WARN] $Message" -ForegroundColor Yellow } }
function Write-Fail { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Info { param([string]$Message) if (-not $Quiet) { Write-Host "[INFO] $Message" -ForegroundColor Cyan } }

function Show-GitFlowHelp {
    param([string]$CurrentBranch, [string]$Kind, [string]$ExpectedBase)
    
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "GitFlow Validation Guide - Gentle-Vanguard" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "QUICK SOLUTION:" -ForegroundColor Green
    Write-Host "1. Create a working branch:" -ForegroundColor White
    Write-Host "   .\scripts\utilities\create-gitflow-branch.ps1" -ForegroundColor Yellow
    Write-Host "   (Or manually: git checkout -b feature/your-description)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "2. Make your changes and commits" -ForegroundColor White
    Write-Host "3. Push the branch:" -ForegroundColor White
    Write-Host "   git push -u origin $CurrentBranch" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "4. Open a Pull Request on GitHub" -ForegroundColor White
    Write-Host "   Base: $ExpectedBase" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "ALLOWED BRANCH TYPES:" -ForegroundColor Cyan
    Write-Host "  feature/*  - New functionality - PR base: develop" -ForegroundColor Green
    Write-Host "  bugfix/*   - Bug fixes - PR base: develop" -ForegroundColor Green
    Write-Host "  chore/*    - Maintenance - PR base: develop" -ForegroundColor Green
    Write-Host "  hotfix/*   - Critical fixes - PR base: main" -ForegroundColor Red
    Write-Host "  release/*  - Release prep - PR base: main" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "VALID BRANCH NAME EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  feature/add-user-authentication" -ForegroundColor Green
    Write-Host "  bugfix/fix-login-timeout" -ForegroundColor Green
    Write-Host "  chore/update-dependencies" -ForegroundColor Green
    Write-Host "  hotfix/critical-security-patch" -ForegroundColor Red
    Write-Host ""
}

Write-Header "GitFlow Validation"

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ([string]::IsNullOrWhiteSpace($branch)) {
    Write-Fail "Unable to detect current git branch."
    exit 1
}

Write-Info "Current branch: $branch"

# Direct pushes to protected branches are disallowed unless explicitly overridden.
$allowProtectedPush = ($env:GITFLOW_ALLOW_PROTECTED_PUSH -eq '1')
if (($branch -eq 'main' -or $branch -eq 'develop') -and -not $allowProtectedPush) {
    Write-Fail "Direct push from protected branch '$branch' is blocked by GitFlow policy."
    Show-GitFlowHelp -CurrentBranch $branch -Kind 'protected' -ExpectedBase 'N/A'
    exit 1
}

$kind = 'unknown'
if ($branch -match '^feature/.+') { $kind = 'feature' }
elseif ($branch -match '^bugfix/.+') { $kind = 'bugfix' }
elseif ($branch -match '^chore/.+') { $kind = 'chore' }
elseif ($branch -match '^hotfix/.+') { $kind = 'hotfix' }
elseif ($branch -match '^release/.+') { $kind = 'release' }
elseif ($branch -eq 'main' -or $branch -eq 'develop') { $kind = 'protected' }

if ($kind -eq 'unknown') {
    Write-Fail "Branch '$branch' does not match allowed GitFlow naming."
    Write-Host ""
    Write-Host "INVALID BRANCH NAME" -ForegroundColor Red
    Write-Host "Your branch must start with one of these prefixes:" -ForegroundColor White
    Write-Host "  feature/  - for new functionality" -ForegroundColor Green
    Write-Host "  bugfix/   - for bug fixes" -ForegroundColor Green
    Write-Host "  chore/    - for maintenance" -ForegroundColor Green
    Write-Host "  hotfix/   - for critical fixes" -ForegroundColor Red
    Write-Host "  release/  - for release preparation" -ForegroundColor Yellow
    
    if ($Interactive) {
        Write-Host ""
        Write-Host "Do you want to create a valid branch now? (Y/n)" -ForegroundColor Cyan
        $response = Read-Host ""
        if ($response -ne 'n' -and $response -ne 'N') {
            & "$repoRoot\scripts\utilities\create-gitflow-branch.ps1"
            exit 0
        }
    }
    
    Show-GitFlowHelp -CurrentBranch $branch -Kind 'unknown' -ExpectedBase 'N/A'
    exit 1
}

$expectedBase = if ($kind -in @('feature', 'bugfix', 'chore')) { 'develop' } elseif ($kind -in @('hotfix', 'release')) { 'main' } else { $branch }
Write-Ok "Branch '$branch' classified as '$kind' (expected PR base: $expectedBase)."

if ($EnforcePrBase) {
    if ([string]::IsNullOrWhiteSpace($PrBase)) {
        Write-Fail "PR base validation requested but PrBase was not provided."
        exit 1
    }

    if ($PrBase -ne $expectedBase) {
        Write-Fail "PR base '$PrBase' violates GitFlow for branch '$branch'. Expected base: '$expectedBase'."
        Show-GitFlowHelp -CurrentBranch $branch -Kind $kind -ExpectedBase $expectedBase
        exit 1
    }

    Write-Ok "PR base '$PrBase' matches GitFlow expectation."
}

if ($allowProtectedPush -and ($branch -eq 'main' -or $branch -eq 'develop')) {
    Write-Warn "Protected branch override active via GITFLOW_ALLOW_PROTECTED_PUSH=1."
}

Write-Ok "GitFlow validation passed"
exit 0

