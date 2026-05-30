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
    - Single installer executable: Gentle-Vanguard.exe (NSIS, AES-256, all-in-one)
    
    Does NOT copy:
    - Plain-text scripts, configs, or skills (should be encrypted in protected/)
    - Internal documentation
.PARAMETER privateRepo
    Path to private repo root. Default: $env:PRIVATE_REPO or ..\..\..\..
.PARAMETER publicRepo
    Path to public repo root. Default: $env:PUBLIC_REPO or ..\..\..\gentle-vanguard-public
.PARAMETER skipPush
    If set, skips git commit and push (useful for CI dry-runs).
.EXAMPLE
    .\sync-to-public.ps1
    .\sync-to-public.ps1 -skipPush
#>

param(
    [string]$privateRepo = '',
    [string]$publicRepo = '',
    [string]$publicRepoSlug = "$(if ($env:PUBLIC_REPO_SLUG) { $env:PUBLIC_REPO_SLUG } else { 'EmmanuelOrtiz87/gentle-vanguard-public' })",
    [switch]$skipPush
)

$ErrorActionPreference = "Stop"

if ($env:GENTLE_VANGUARD_BASE_DIR) {
    $resolvedRoot = $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $resolvedRoot = $searchDir
}

if ([string]::IsNullOrEmpty($privateRepo)) { $privateRepo = if ($env:PRIVATE_REPO) { $env:PRIVATE_REPO } else { $resolvedRoot } }
# Fix: use sibling directory of private repo (not grandparent) to resolve gentle-vanguard-public
if ([string]::IsNullOrEmpty($publicRepo)) { $publicRepo = if ($env:PUBLIC_REPO) { $env:PUBLIC_REPO } else { Join-Path (Split-Path -Parent $resolvedRoot) 'gentle-vanguard-public' } }

$buildDir = Join-Path $privateRepo 'build'
$distDir = Join-Path $privateRepo 'dist'

Write-Output "=== Syncing Private -> Public Repo ==="
Write-Output ""

# ============================================================================
# 0. Bootstrap scripts (plain text - needed for user onboarding)
# ============================================================================
Write-Output "[BOOTSTRAP] Syncing bootstrap scripts..."
$bootstrapDir = "$publicRepo\scripts\gentle-vanguard"
New-Item -ItemType Directory -Path $bootstrapDir -Force | Out-Null
$privateBootstrapDir = "$privateRepo\scripts\core"
Copy-Item "$privateBootstrapDir\bootstrap.ps1" "$bootstrapDir\bootstrap.ps1" -Force
Copy-Item "$privateBootstrapDir\bootstrap-machine.ps1" "$bootstrapDir\bootstrap-machine.ps1" -Force
Copy-Item "$privateBootstrapDir\setup-multi-machine.ps1" "$bootstrapDir\setup-multi-machine.ps1" -Force

# ============================================================================
# 1. Public documentation (root files)
# ============================================================================
Write-Output " Syncing public docs..."
# README-PUBLIC.md is the canonical public-facing README — it is the single source of truth
# for the public repo's README.md. Changes to README-PUBLIC.md in private repo automatically
# flow to the public repo. The public repo MUST NOT modify README.md directly.
if (Test-Path "$privateRepo\README-PUBLIC.md") {
    Copy-Item "$privateRepo\README-PUBLIC.md" "$publicRepo\README.md" -Force
    Write-Output "  [OK] README-PUBLIC.md -> README.md (public-facing)"
} else {
    Write-Output "  [WARN] README-PUBLIC.md not found — public README.md not updated"
}
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
    'docs/sdd',
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
# 4. Encrypted artifacts (pre-built by protect-gentle-vanguard.ps1)
# ============================================================================
Write-Output " Syncing encrypted protected/..."
if (Test-Path "$buildDir\protected") {
    if (Test-Path "$publicRepo\protected") {
        Remove-Item "$publicRepo\protected" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$buildDir\protected" "$publicRepo\" -Recurse -Force
    Write-Output "  [OK] protected/"
} else {
    Write-Output "  [WARN]  build/protected/ not found - run protect-gentle-vanguard.ps1 first"
}

# ============================================================================
# 5. Public skill stubs (pre-built by protect-gentle-vanguard.ps1)
# ============================================================================
Write-Output " Syncing public skill stubs..."
if (Test-Path "$buildDir\public") {
    if (Test-Path "$publicRepo\public") {
        Remove-Item "$publicRepo\public" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item "$buildDir\public" "$publicRepo\" -Recurse -Force
    Write-Output "  [OK] public/"
} else {
    Write-Output "  [WARN]  build/public/ not found - run protect-gentle-vanguard.ps1 first"
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
# 6b. Presentation — gentle-vanguard-presentation.html
# ============================================================================
Write-Output " Syncing presentation..."
if (Test-Path "$privateRepo\gentle-vanguard-presentation.html") {
    Copy-Item "$privateRepo\gentle-vanguard-presentation.html" "$publicRepo\gentle-vanguard-presentation.html" -Force
    Write-Output "  [OK] gentle-vanguard-presentation.html"
} else {
    Write-Output "  [WARN] gentle-vanguard-presentation.html not found"
}

# ============================================================================
# 7. Single executable — Gentle-Vanguard.exe (NSIS installer, all-in-one)
# ============================================================================
Write-Output " Syncing installer executable..."

$installerExe = "$distDir\Gentle-Vanguard.exe"
if (Test-Path $installerExe) {
    # Remove legacy exes if they exist (deprecated)
    @("$publicRepo\Gentle-Vanguard-Launcher.exe", "$publicRepo\Gentle-Vanguard-Setup.exe") | ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Force; Write-Output "  [DEPRECATED] removed $($_ | Split-Path -Leaf)" }
    }
    Copy-Item $installerExe "$publicRepo\Gentle-Vanguard.exe" -Force
    Write-Output "  [OK] Gentle-Vanguard.exe (NSIS installer, AES-256, all-in-one)"
} else {
    Write-Output "  [WARN]  dist/Gentle-Vanguard.exe not found — run build/create-installer.ps1 first"
}

# ============================================================================
# 8. INSTALLATION.md (manually maintained in public repo)
# ============================================================================
# INSTALLATION.md should exist already in gentle-vanguard-public from the installer.
# If missing, create a basic version.
if (-not (Test-Path "$publicRepo\INSTALLATION.md")) {
    Write-Output "  [WARN]  INSTALLATION.md missing - keeping existing if any"
}

# ============================================================================
# 9. Cleanup FIRST: remove plain-text artifacts that shouldn't be in public repo
#     (MUST run BEFORE CI scripts copy to avoid deleting just-copied files)
# ============================================================================
Write-Output "[CLEANUP] Removing plain-text artifacts..."

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
    "$publicRepo\scripts\testing",
    "$publicRepo\scripts\sre",
    "$publicRepo\scripts\core"
)
foreach ($dir in $strayScriptDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "    Removed: $dir"
    }
}

# Remove stray plain-text script files at scripts/ root level (except bootstrap dir and run-tests-simple.ps1)
Get-ChildItem "$publicRepo\scripts" -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -ne 'run-tests-simple.ps1'
} | ForEach-Object {
    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    Write-Output "    Removed: scripts/$($_.Name)"
}

# Remove plain-text skills root (should only exist in protected/ and public/)
$plainSkills = "$publicRepo\skills"
if (Test-Path $plainSkills) {
    Remove-Item $plainSkills -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "    Removed: skills/ (plain text - use protected/skills/ or public/skills/)"
}

# Remove plain-text config files that are NOT examples (actual routing/IP)
Get-ChildItem "$publicRepo\config" -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notlike "*.example.*" -and $_.Name -ne "README.md" -and $_.Name -ne "PSScriptAnalyzerSettings.psd1"
} | ForEach-Object {
    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    Write-Output "    Removed: config/$($_.Name)"
}

Write-Output ""

# ============================================================================
# 10. CI-required scripts (minimal set for workflows to pass)
#     Runs AFTER cleanup so these files are preserved
# ============================================================================
Write-Output "[CI] Syncing CI-required scripts..."

$ciScripts = @(
    @{ Src = 'scripts\utilities\WORKFLOW-ORCHESTRATION\comprehensive-validation.ps1'; Dst = 'scripts\utilities\WORKFLOW-ORCHESTRATION\comprehensive-validation.ps1' },
    @{ Src = 'scripts\utilities\validate-configs.ps1'; Dst = 'scripts\utilities\validate-configs.ps1' },
    @{ Src = 'scripts\run-tests-simple.ps1'; Dst = 'scripts\run-tests-simple.ps1' },
    @{ Src = 'scripts\diagnostics\validate-script-governance.ps1'; Dst = 'scripts\diagnostics\validate-script-governance.ps1' },
    @{ Src = 'scripts\utilities\agent-verify.ps1'; Dst = 'scripts\utilities\agent-verify.ps1' },
    @{ Src = 'scripts\sre\enforce-error-budget.ps1'; Dst = 'scripts\sre\enforce-error-budget.ps1' },
    @{ Src = 'scripts\testing\check-performance-baselines.ps1'; Dst = 'scripts\testing\check-performance-baselines.ps1' },
    @{ Src = 'scripts\testing\check-accessibility.ps1'; Dst = 'scripts\testing\check-accessibility.ps1' },
    @{ Src = 'scripts\testing\check-i18n.ps1'; Dst = 'scripts\testing\check-i18n.ps1' },
    @{ Src = 'scripts\monitoring\cross-workspace-validator.ps1'; Dst = 'scripts\monitoring\cross-workspace-validator.ps1' },
    @{ Src = 'scripts\utilities\SKILLS-TOOLS\plugins-discovery.ps1'; Dst = 'scripts\utilities\SKILLS-TOOLS\plugins-discovery.ps1' },
    @{ Src = 'scripts\diagnostics\validate-sdd-governance.ps1'; Dst = 'scripts\diagnostics\validate-sdd-governance.ps1' },
    @{ Src = 'scripts\utilities\gv.ps1'; Dst = 'scripts\utilities\gv.ps1' },
    @{ Src = 'scripts\diagnostics\agent-process-alert.ps1'; Dst = 'scripts\diagnostics\agent-process-alert.ps1' },
    @{ Src = 'scripts\utilities\UTILITIES\gentle-vanguard-sync.ps1'; Dst = 'scripts\utilities\UTILITIES\gentle-vanguard-sync.ps1' },
    @{ Src = 'scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1'; Dst = 'scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1' }
)

foreach ($ci in $ciScripts) {
    $src = Join-Path $privateRepo $ci.Src
    $dst = Join-Path $publicRepo $ci.Dst
    if (Test-Path $src) {
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item $src $dst -Force
        Write-Output "  [OK] $($ci.Src)"
    } else {
        Write-Output "  [WARN] $($ci.Src) not found in private repo"
    }
}

# ============================================================================
# 10b. CI-required config and root files
# ============================================================================
Write-Output "[CI] Syncing CI-required config and root files..."

$ciFiles = @(
    '.gitleaks.toml',
    'package.json',
    'package-lock.json',
    '.prettierrc',
    '.prettierignore'
)

foreach ($f in $ciFiles) {
    $src = Join-Path $privateRepo $f
    $dst = Join-Path $publicRepo $f
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Write-Output "  [OK] $f"
    } else {
        Write-Output "  [WARN] $f not found in private repo"
    }
}

# PSScriptAnalyzerSettings.psd1 lives in config/ in the private repo
$pssaSrc = Join-Path $privateRepo 'config\PSScriptAnalyzerSettings.psd1'
$pssaDst = Join-Path $publicRepo 'config\PSScriptAnalyzerSettings.psd1'
if (Test-Path $pssaSrc) {
    if (-not (Test-Path (Split-Path $pssaDst -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $pssaDst -Parent) -Force | Out-Null
    }
    Copy-Item $pssaSrc $pssaDst -Force
    Write-Output "  [OK] config/PSScriptAnalyzerSettings.psd1"
} elseif (Test-Path (Join-Path $privateRepo 'PSScriptAnalyzerSettings.psd1')) {
    Copy-Item (Join-Path $privateRepo 'PSScriptAnalyzerSettings.psd1') $pssaDst -Force
    Write-Output "  [OK] PSScriptAnalyzerSettings.psd1 (from root)"
} else {
    Write-Output "  [WARN] PSScriptAnalyzerSettings.psd1 not found"
}

# ============================================================================
# 10c. CI-required test files (minimal set for cross-platform tests)
# ============================================================================
Write-Output "[CI] Syncing CI-required test files..."

$ciTestDirs = @(
    'tests\unit'
)
foreach ($dir in $ciTestDirs) {
    $src = Join-Path $privateRepo $dir
    $dst = Join-Path $publicRepo $dir
    if (Test-Path $src) {
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item $src "$publicRepo\$dir" -Recurse -Force
        Write-Output "  [OK] $dir"
    } else {
        Write-Output "  [WARN] $dir not found in private repo"
    }
}

# ============================================================================
# 10d. CI-required workflows (adapted for public repo: develop → main)
# ============================================================================
Write-Output "[CI] Syncing CI-required workflows (branch: develop → main)..."

$ciWorkflows = @(
    'autonomous-validation.yml',
    'cross-platform-tests.yml',
    'dashboard-auto-refresh.yml',
    'format-check.yml',
    'gentle-vanguard-quality-gate.yml',
    'gitleaks.yml',
    'labeler.yml',
    'ps-lint.yml',
    'script-governance.yml',
    'security-scan.yml',
    'test-suite.yml',
    'workflow-lint.yml'
)

$workflowSrcDir = Join-Path $privateRepo '.github\workflows'
$workflowDstDir = Join-Path $publicRepo '.github\workflows'
if (-not (Test-Path $workflowDstDir)) { New-Item -ItemType Directory -Path $workflowDstDir -Force | Out-Null }

foreach ($wf in $ciWorkflows) {
    $src = Join-Path $workflowSrcDir $wf
    $dst = Join-Path $workflowDstDir $wf
    if (Test-Path $src) {
        $content = Get-Content $src -Raw
        # Adapt branch triggers for public repo: develop → main
        $adapted = $content -replace "branches:\s*\[\s*develop\s*\]", "branches: [main]"
        $adapted = $adapted -replace "branches:\s*\[\s*main,\s*develop\s*\]", "branches: [main]"
        $adapted = $adapted -replace "branches:\s*\[\s*develop,\s*main\s*\]", "branches: [main]"
        $adapted = $adapted -replace "branches:\s*\[\s*'main',\s*'develop'\s*\]", "branches: ['main']"
        $adapted = $adapted -replace "branches:\s*\[\s*'develop',\s*'main'\s*\]", "branches: ['main']"
        $adapted = $adapted -replace "branches:\s*\[\s*'develop'\s*\]", "branches: ['main']"
        $adapted = $adapted -replace "branches:\s*\[\s*'main',\s*'develop'\s*\]", "branches: ['main']"
        # Remove sync-public workflow trigger (not applicable in public repo)
        $adapted = $adapted -replace "branches:\s*\[\s*'develop'\s*\]", "branches: ['main']"
        Set-Content $dst $adapted -Force
        Write-Output "  [OK] .github/workflows/$wf (adapted)"
    } else {
        Write-Output "  [WARN] .github/workflows/$wf not found in private repo"
    }
}

Write-Output ""

# ============================================================================
# 11. Commit and push to public repo
# ============================================================================
if (-not $skipPush) {
    Push-Location $publicRepo

    # Detect default branch from remote HEAD (more robust than local symref)
    git fetch origin --prune 2>&1 | Out-Null
    $remoteHead = (git ls-remote --symref origin HEAD 2>$null) -join "`n"
    $headMatch = [regex]::Match($remoteHead, 'ref: refs/heads/(\S+)')
    $defaultBranch = if ($headMatch.Success) {
        $headMatch.Groups[1].Value
    } else {
        "main"
    }
    Write-Output "[DETECT] Remote HEAD points to '$defaultBranch'"

    $localBranch = git branch --list $defaultBranch 2>$null
    if ([string]::IsNullOrWhiteSpace($localBranch)) {
        git checkout -B $defaultBranch "origin/$defaultBranch" 2>&1 | Out-Null
    } else {
        git checkout $defaultBranch 2>&1 | Out-Null
    }

    # Fix: stash any working-tree changes before rebase (files may have been copied above)
    $hasChanges = (git status --porcelain 2>$null) -ne ''
    if ($hasChanges) { git stash push -u -m 'sync-pre-rebase' 2>&1 | Out-Null }

    git pull --rebase origin $defaultBranch 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        if ($hasChanges) { git stash pop 2>&1 | Out-Null }
        Write-Output "[FAIL] Could not rebase local $defaultBranch with origin/$defaultBranch"
        Pop-Location
        exit 1
    }

    # Restore synced files on top of rebased state
    if ($hasChanges) { git stash pop 2>&1 | Out-Null }

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

