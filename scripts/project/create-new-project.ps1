# create-new-project.ps1
# Agnostic project scaffolder based on Workspace Foundation.

param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$foundationRoot = Resolve-Path (Join-Path $scriptDir "..")
$targetPath = Join-Path (Split-Path $foundationRoot -Parent) $Name

Write-Host ">> Creating new project: $Name..." -ForegroundColor Cyan

if (Test-Path $targetPath) {
    Write-Error "Directory '$targetPath' already exists."
    exit 1
}

# 1. Create Directory Structure
New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath "scripts") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath "scripts/git-hooks") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath "config") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath "docs/code-reviews") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath "docs/specs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetPath "docs/architecture") -Force | Out-Null

# 2. Copy Operational Logic (Agnostic & Independent)
# We copy the scripts so the new project doesn't depend on the foundation path
$filesToCopy = @(
    "scripts/validate-project.ps1",
    "scripts/finalize-session.ps1",
    "scripts/create-pull-request.ps1",
    "scripts/generate-session-review.ps1",
    "scripts/bootstrap.ps1",
    "scripts/git-hooks/pre-commit",
    "config/session-review.template.md",
    "README.md"
)

foreach ($item in $filesToCopy) {
    $src = Join-Path $foundationRoot $item
    $dest = Join-Path $targetPath $item
    $destDir = Split-Path $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    if (Test-Path $src) {
        Copy-Item $src $dest -Force
    }
}

# 3. Create Standalone Project Bootstrap
$bootstrapContent = @"
# bootstrap-project.ps1
# This script initializes the project and its local git hooks
Set-Location "`$PSScriptRoot/.."
& "./scripts/bootstrap.ps1"
git config core.hooksPath scripts/git-hooks
Write-Host "[OK] Project '$Name' initialized and local hooks configured." -ForegroundColor Green
"@
$bootstrapContent | Out-File -FilePath (Join-Path $targetPath "scripts\bootstrap-project.ps1") -Encoding UTF8

Write-Host "`n[SUCCESS] Project '$Name' created at: $targetPath" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Gray
Write-Host "1. cd '$targetPath'"
Write-Host "2. ./scripts/bootstrap-project.ps1"