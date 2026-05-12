#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sync changes from private repo to public repo.
.DESCRIPTION
    Copies ONLY public-safe files:
    - Bootstrap scripts (plain text - needed for onboarding)
    - Public documentation (README, LICENSE, docs/, demos/)
    - Example configs (no secrets)
    - Pre-built encrypted artifacts (protected/)
    - Public skill stubs (public/)
    - Compiled launcher and installer (.exe)
    
    Does NOT copy:
    - Plain-text scripts, configs, or skills (should be encrypted in protected/)
    - Internal documentation
.PARAMETER privateRepo
    Path to private repo root. Default: $env:PRIVATE_REPO or ..\..\..\..
.PARAMETER publicRepo
    Path to public repo root. Default: $env:PUBLIC_REPO or ..\..\..\foundation-public
.PARAMETER skipPush
    If set, skips git commit and push (useful for CI dry-runs).
.EXAMPLE
    .\sync-to-public.ps1
    .\sync-to-public.ps1 -skipPush
#>

param(
    [string]$privateRepo = '',
    [string]$publicRepo = '',
    [string]$publicRepoSlug = "$(if ($env:PUBLIC_REPO_SLUG) { $env:PUBLIC_REPO_SLUG } else { 'EmmanuelOrtiz87/foundation-public' })",
    [switch]$skipPush
)

$ErrorActionPreference = "Stop"

if ($env:FOUNDATION_BASE_DIR) {
    $resolvedRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $resolvedRoot = $searchDir
}

if ([string]::IsNullOrEmpty($privateRepo)) { $privateRepo = if ($env:PRIVATE_REPO) { $env:PRIVATE_REPO } else { $resolvedRoot } }
if ([string]::IsNullOrEmpty($publicRepo)) { $publicRepo = if ($env:PUBLIC_REPO) { $env:PUBLIC_REPO } else { Join-Path (Split-Path -Parent (Split-Path -Parent $resolvedRoot)) 'foundation-public' } }

$buildDir = Join-Path $privateRepo 'build'
$distDir = Join-Path $privateRepo 'dist'

Write-Output "=== Syncing Private -> Public Repo ==="
Write-Output ""

# ============================================================================
# 0. Bootstrap scripts (plain text - needed for user onboarding)
# ============================================================================
Write-Output "[BOOTSTRAP] Syncing bootstrap scripts..."
$bootstrapDir = "$publicRepo\scripts\foundation"
New-Item -ItemType Directory -Path $bootstrapDir -Force | Out-Null
Copy-Item "$privateRepo\scripts\foundation\bootstrap.ps1" "$bootstrapDir\bootstrap.ps1" -Force
Copy-Item "$privateRepo\scripts\foundation\bootstrap-machine.ps1" "$bootstrapDir\bootstrap-machine.ps1" -Force
Copy-Item "$privateRepo\scripts\foundation\setup-multi-machine.ps1" "$bootstrapDir\setup-multi-machine.ps1" -Force

# ============================================================================
# 1. Public documentation (root files)
# ============================================================================
Write-Output " Syncing public docs..."
Copy-Item "$privateRepo\README.md" "$publicRepo\README.md" -Force
Copy-Item "$privateRepo\LICENSE" "$publicRepo\LICENSE" -Force
Copy-Item "$privateRepo\CONTRIBUTING.md" "$publicRepo\CONTRIBUTING.md" -Force
Copy-Item "$privateRepo\SECURITY.md" "$publicRepo\SECURITY.md" -Force
Copy-Item "$privateRepo\CHANGELOG.md" "$publicRepo\CHANGELOG.md" -Force
Copy-Item "$privateRepo\BUILD-README.md" "$publicRepo\BUILD-README.md" -Force -ErrorAction SilentlyContinue

# ============================================================================
# 2. Documentation directory (ONLY public-safe docs, no internal IP)
# ============================================================================
Write-Output " Syncing public-safe docs..."
if (Test-Path "$publicRepo\docs") {
    Remove-Item "$publicRepo\docs" -Recurse -Force -ErrorAction SilentlyContinue
}

# Root-level public docs
$publicRootDocs = @(
    'docs/README.md'
)
foreach ($f in $publicRootDocs) {
    $src = "$privateRepo\$f"
    $dst = "$publicRepo\$f"
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    if (Test-Path $src) { Copy-Item $src $dst -Force }
}

# Public-safe subdirectories
$publicDocDirs = @(
    'docs/getting-started',
    'docs/guides',
    'docs/marketing',
    'docs/specs',
    'docs/supplementary'
)
foreach ($dir in $publicDocDirs) {
    $src = "$privateRepo\$dir"
    if (Test-Path $src) {
        $dstParent = "$publicRepo\$(Split-Path $dir -Parent)"
        if (-not (Test-Path $dstParent)) { New-Item -ItemType Directory -Path $dstParent -Force | Out-Null }
        Copy-Item $src "$publicRepo\$dir" -Recurse -Force
        Write-Output "  [OK] $dir"
    }
}

# Public reference docs (selected files only)
$publicRefDocs = @(
    'docs/reference/SKILL-ORGANIZATION.md',
    'docs/reference/SKILL-RESOLVER-PROTOCOL.md',
    'docs/reference/SUBAGENT-ARCHITECTURE.md',
    'docs/reference/PLUGIN-ARCHITECTURE.md',
    'docs/reference/REAL-TOKEN-TRACKING.md'
)
$refDir = "$publicRepo\docs\reference"
New-Item -ItemType Directory -Path $refDir -Force | Out-Null
foreach ($f in $publicRefDocs) {
    $src = "$privateRepo\$f"
    if (Test-Path $src) {
        Copy-Item $src "$refDir\" -Force
        Write-Output "  [OK] $f"
    }
}

# Public architecture overview (not the full ARCHITECTURE.md)
$archOverview = "$privateRepo\docs\architecture\README.md"
if (Test-Path $archOverview) {
    $archDest = "$publicRepo\docs\architecture"
    New-Item -ItemType Directory -Path $archDest -Force | Out-Null
    Copy-Item $archOverview "$archDest\README.md" -Force
    Write-Output "  [OK] docs/architecture/README.md"
}

# Public examples
$examples = "$privateRepo\docs\EXAMPLES.md"
if (Test-Path $examples) {
    Copy-Item $examples "$publicRepo\docs\EXAMPLES.md" -Force
    Write-Output "  [OK] docs/EXAMPLES.md"
}

# ============================================================================
# 3. Example configs only (no secrets)
# ============================================================================
Write-Output "[*] Syncing example configs..."
$exampleDir = "$publicRepo\config"
New-Item -ItemType Directory -Path $exampleDir -Force | Out-Null
# Remove all first, then copy only example files
Get-ChildItem "$exampleDir" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
foreach ($example in @('workspace.example.json', 'workspace.portable.example.json', 'github-runner.example.json', 'ai-review.example.json')) {
    $src = "$privateRepo\config\$example"
    if (Test-Path $src) {
        Copy-Item $src "$exampleDir\$example" -Force
        Write-Output "  [OK] config/$example"
    }
}
# Copy config README if exists
if (Test-Path "$privateRepo\config\README.md") {
    Copy-Item "$privateRepo\config\README.md" "$exampleDir\README.md" -Force
}

# ============================================================================
# 4. Encrypted artifacts (pre-built by protect-foundation.ps1)
# ============================================================================
Write-Output " Syncing encrypted protected/..."
if (Test-Path "$buildDir\protected") {
    if (Test-Path "$publicRepo\protected") {
        Remove-Item "$publicRepo\protected" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$buildDir\protected" "$publicRepo\" -Recurse -Force
    Write-Output "  [OK] protected/"
} else {
    Write-Output "  [WARN]  build/protected/ not found - run protect-foundation.ps1 first"
}

# ============================================================================
# 5. Public skill stubs (pre-built by protect-foundation.ps1)
# ============================================================================
Write-Output " Syncing public skill stubs..."
if (Test-Path "$buildDir\public") {
    if (Test-Path "$publicRepo\public") {
        Remove-Item "$publicRepo\public" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$buildDir\public" "$publicRepo\" -Recurse -Force
    Write-Output "  [OK] public/"
} else {
    Write-Output "  [WARN]  build/public/ not found - run protect-foundation.ps1 first"
}

# ============================================================================
# 6. Public demos
# ============================================================================
Write-Output " Syncing public demos..."
if (Test-Path "$privateRepo\demos") {
    if (Test-Path "$publicRepo\demos") {
        Remove-Item "$publicRepo\demos" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$privateRepo\demos" "$publicRepo\" -Recurse -Force
    Write-Output "  [OK] demos/"
}

# ============================================================================
# 7. Compiled executables
# ============================================================================
Write-Output " Syncing executables..."

# Compiled launcher
$launcherExe = "$buildDir\compiled\Foundation-Launcher.exe"
if (Test-Path $launcherExe) {
    Copy-Item $launcherExe "$publicRepo\Foundation-Launcher.exe" -Force
    Write-Output "  [OK] Foundation-Launcher.exe"
} else {
    Write-Output "  [WARN]  compiled launcher not found"
}

# Installer
$installerExe = "$distDir\Foundation-Setup.exe"
if (Test-Path $installerExe) {
    Copy-Item $installerExe "$publicRepo\Foundation-Setup.exe" -Force
    Write-Output "  [OK] Foundation-Setup.exe"
} else {
    Write-Output "  [WARN]  installer not found at $installerExe"
}

# ============================================================================
# 8. INSTALLATION.md (manually maintained in public repo)
# ============================================================================
# INSTALLATION.md should exist already in foundation-public from the installer.
# If missing, create a basic version.
if (-not (Test-Path "$publicRepo\INSTALLATION.md")) {
    Write-Output "  [WARN]  INSTALLATION.md missing - keeping existing if any"
}

# ============================================================================
# 9. Cleanup: remove any plain-text artifacts that shouldn't be in public repo
# ============================================================================
Write-Output " Cleaning up plain-text artifacts..."

# Remove stray plain-text scripts (bootstrap dir is the only exception)
$strayScriptDirs = @(
    "$publicRepo\scripts\utilities",
    "$publicRepo\scripts\monitoring",
    "$publicRepo\scripts\security",
    "$publicRepo\scripts\git-hooks",
    "$publicRepo\scripts\validation",
    "$publicRepo\scripts\project",
    "$publicRepo\scripts\diagnostics",
    "$publicRepo\scripts\docs",
    "$publicRepo\scripts\testing"
)
foreach ($dir in $strayScriptDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "    Removed: $dir"
    }
}

# Remove plain-text skills root (should only exist in protected/ and public/)
$plainSkills = "$publicRepo\skills"
if (Test-Path $plainSkills) {
    Remove-Item $plainSkills -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "    Removed: skills/ (plain text - use protected/skills/ or public/skills/)"
}

# Remove plain-text config files that are NOT examples (actual routing/IP)
$plainConfigs = @('auto-delegation.json', 'orchestrator.json', 'model-router.json', 'workspace.config.json', 'adaptive-patterns.json', 'owner-mapping.json', 'auto-delegation*.json')
Get-ChildItem "$publicRepo\config" -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notlike "*.example.*" -and $_.Name -ne "README.md"
} | ForEach-Object {
    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    Write-Output "    Removed: config/$($_.Name)"
}

Write-Output ""

# ============================================================================
# 10. Commit and push to public repo
# ============================================================================
if (-not $skipPush) {
    Push-Location $publicRepo

    # Detect default branch from remote
    git fetch origin --prune 2>&1 | Out-Null
    git remote set-head origin -a 2>&1 | Out-Null
    $remoteBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($remoteBranch)) {
        $defaultBranch = "main"
    } else {
        $defaultBranch = $remoteBranch -replace '^refs/remotes/origin/', ''
    }

    # Ensure local branch matches remote default before committing
    $remoteBranchExists = git ls-remote --heads origin $defaultBranch 2>$null
    if ([string]::IsNullOrWhiteSpace($remoteBranchExists)) {
        Write-Output "[FAIL] Remote default branch '$defaultBranch' not found in $publicRepoSlug"
        Pop-Location
        exit 1
    }

    $localBranch = git branch --list $defaultBranch 2>$null
    if ([string]::IsNullOrWhiteSpace($localBranch)) {
        git checkout -B $defaultBranch "origin/$defaultBranch" 2>&1 | Out-Null
    } else {
        git checkout $defaultBranch 2>&1 | Out-Null
    }

    git pull --rebase origin $defaultBranch 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "[FAIL] Could not rebase local $defaultBranch with origin/$defaultBranch"
        Pop-Location
        exit 1
    }

    git add .
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $commitMsg = "sync: automated sync from private repo - $timestamp"
    git commit -m $commitMsg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[OK] Committed: $commitMsg"
        $pushResult = git push origin $defaultBranch 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[OK] Pushed to origin/$defaultBranch"
        } else {
            Write-Output "[FAIL] Push failed: $pushResult"
        }
    } else {
        Write-Output "i  Nothing to commit - public repo is up to date"
    }
    Pop-Location
} else {
    Write-Output "i  skipPush enabled - commit/push skipped"
}

Write-Output ""
Write-Output "=== Sync Complete ==="
