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
Write-Output "[INFO] privateRepo=$privateRepo"
Write-Output "[INFO] publicRepo=$publicRepo"
Write-Output ""

# ============================================================================
# Sync function — runs file-by-file copy operations for one branch
# Called once per branch inside the push loop (section 11)
# ============================================================================
function Sync-FilesToBranch {
    param([string]$targetDir)

    Write-Output "  ── populating $targetDir ──"

    # 0. Bootstrap scripts
    $bootstrapDir = "$targetDir\scripts\gentle-vanguard"
    New-Item -ItemType Directory -Path $bootstrapDir -Force | Out-Null
    Copy-Item "$privateRepo\scripts\core\bootstrap.ps1" "$bootstrapDir\bootstrap.ps1" -Force
    Copy-Item "$privateRepo\scripts\core\bootstrap-machine.ps1" "$bootstrapDir\bootstrap-machine.ps1" -Force
    Copy-Item "$privateRepo\scripts\core\setup-multi-machine.ps1" "$bootstrapDir\setup-multi-machine.ps1" -Force

    # 1. Public root docs
    if (Test-Path "$privateRepo\README-PUBLIC.md") {
        Copy-Item "$privateRepo\README-PUBLIC.md" "$targetDir\README.md" -Force
    }
    Copy-Item "$privateRepo\LICENSE" "$targetDir\LICENSE" -Force
    Copy-Item "$privateRepo\CONTRIBUTING.md" "$targetDir\CONTRIBUTING.md" -Force
    if (Test-Path "$privateRepo\SECURITY.md") {
        Copy-Item "$privateRepo\SECURITY.md" "$targetDir\SECURITY.md" -Force
    } elseif (Test-Path "$privateRepo\docs\SECURITY.md") {
        Copy-Item "$privateRepo\docs\SECURITY.md" "$targetDir\SECURITY.md" -Force
    }
    Copy-Item "$privateRepo\CHANGELOG.md" "$targetDir\CHANGELOG.md" -Force
    Copy-Item "$privateRepo\BUILD-README.md" "$targetDir\BUILD-README.md" -Force -ErrorAction SilentlyContinue
    if (Test-Path "$privateRepo\INSTALLATION.md") {
        Copy-Item "$privateRepo\INSTALLATION.md" "$targetDir\INSTALLATION.md" -Force
    }

    # 2. Public docs dir
    Remove-Item "$targetDir\docs" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "$targetDir\docs" -Force | Out-Null
    foreach ($dir in @('docs/getting-started','docs/guides','docs/marketing','docs/supplementary')) {
        $src = "$privateRepo\$dir"
        if (Test-Path $src) {
            $dstParent = "$targetDir\$(Split-Path $dir -Parent)"
            if (-not (Test-Path $dstParent)) { New-Item -ItemType Directory -Path $dstParent -Force | Out-Null }
            Copy-Item $src "$targetDir\$dir" -Recurse -Force
        }
    }
    $refDir = "$targetDir\docs\reference"
    New-Item -ItemType Directory -Path $refDir -Force | Out-Null
    foreach ($f in @('docs/reference/ARCHITECTURE.md','docs/ROADMAP.md','docs/reference/SKILL-ORGANIZATION.md','docs/reference/SKILL-RESOLVER-PROTOCOL.md','docs/reference/SUBAGENT-ARCHITECTURE.md','docs/reference/PLUGIN-ARCHITECTURE.md','docs/reference/REAL-TOKEN-TRACKING.md')) {
        $src = "$privateRepo\$f"
        if (Test-Path $src) { Copy-Item $src "$refDir\" -Force }
    }
    if (Test-Path "$privateRepo\docs\architecture\README.md") {
        New-Item -ItemType Directory -Path "$targetDir\docs\architecture" -Force | Out-Null
        Copy-Item "$privateRepo\docs\architecture\README.md" "$targetDir\docs\architecture\README.md" -Force
    }
    if (Test-Path "$privateRepo\docs\EXAMPLES.md") {
        Copy-Item "$privateRepo\docs\EXAMPLES.md" "$targetDir\docs\EXAMPLES.md" -Force
    }

    # 3. Example configs
    $exampleDir = "$targetDir\config"
    Remove-Item "$exampleDir" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $exampleDir -Force | Out-Null
    foreach ($example in @('workspace.example.json','workspace.portable.example.json','github-runner.example.json','ai-review.example.json')) {
        $src = "$privateRepo\config\$example"
        if (Test-Path $src) { Copy-Item $src "$exampleDir\$example" -Force }
    }
    if (Test-Path "$privateRepo\config\README.md") {
        Copy-Item "$privateRepo\config\README.md" "$exampleDir\README.md" -Force
    }

    # 4. Encrypted protected/
    if (Test-Path "$buildDir\protected") {
        Remove-Item "$targetDir\protected" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$buildDir\protected" "$targetDir\" -Recurse -Force
    }

    # 5. Public skill stubs
    if (Test-Path "$buildDir\public") {
        Remove-Item "$targetDir\public" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$buildDir\public" "$targetDir\" -Recurse -Force
    }

    # 6. Demos
    if (Test-Path "$privateRepo\demos") {
        Remove-Item "$targetDir\demos" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$privateRepo\demos" "$targetDir\" -Recurse -Force
    }

    # 6b. Presentation
    if (Test-Path "$privateRepo\gentle-vanguard-presentation.html") {
        Copy-Item "$privateRepo\gentle-vanguard-presentation.html" "$targetDir\gentle-vanguard-presentation.html" -Force
    }

    # 7. Installer exe
    if (Test-Path "$distDir\Gentle-Vanguard.exe") {
        @("$targetDir\Gentle-Vanguard-Launcher.exe", "$targetDir\Gentle-Vanguard-Setup.exe") | ForEach-Object {
            if (Test-Path $_) { Remove-Item $_ -Force }
        }
        Copy-Item "$distDir\Gentle-Vanguard.exe" "$targetDir\Gentle-Vanguard.exe" -Force
    }

    # 8. Root infra files
    foreach ($f in @('docker-compose.yml','docker-compose.test.yml','Dockerfile')) {
        $src = "$privateRepo\$f"
        if (Test-Path $src) { Copy-Item $src "$targetDir\$f" -Force }
    }

    # 9. Cleanup plain-text artifacts
    foreach ($dir in @("$targetDir\scripts\utilities","$targetDir\scripts\monitoring","$targetDir\scripts\security","$targetDir\scripts\git-hooks","$targetDir\scripts\validation","$targetDir\scripts\project","$targetDir\scripts\diagnostics","$targetDir\scripts\docs","$targetDir\scripts\testing","$targetDir\scripts\sre","$targetDir\scripts\core")) {
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem "$targetDir\scripts" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'run-tests-simple.ps1' } | ForEach-Object {
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    }
    Remove-Item "$targetDir\skills" -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem "$targetDir\config" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*.example.*" -and $_.Name -ne "README.md" -and $_.Name -ne "PSScriptAnalyzerSettings.psd1" } | ForEach-Object {
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # 10. CI scripts
    $ciScripts = @(
        'scripts\utilities\WORKFLOW-ORCHESTRATION\comprehensive-validation.ps1',
        'scripts\run-tests-simple.ps1',
        'scripts\diagnostics\validate-script-governance.ps1',
        'scripts\sre\enforce-error-budget.ps1',
        'scripts\testing\check-performance-baselines.ps1',
        'scripts\testing\check-accessibility.ps1',
        'scripts\testing\check-i18n.ps1',
        'scripts\monitoring\cross-workspace-validator.ps1',
        'scripts\utilities\SKILLS-TOOLS\plugins-discovery.ps1',
        'scripts\diagnostics\validate-sdd-governance.ps1',
        'scripts\diagnostics\agent-process-alert.ps1',
        'scripts\utilities\UTILITIES\gentle-vanguard-sync.ps1',
        'scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1',
        'scripts\monitoring\aggregate-logs.ps1'
    )
    foreach ($rel in $ciScripts) {
        $src = Join-Path $privateRepo $rel
        $dst = Join-Path $targetDir $rel
        if (Test-Path $src) {
            $dstDirp = Split-Path $dst -Parent
            if (-not (Test-Path $dstDirp)) { New-Item -ItemType Directory -Path $dstDirp -Force | Out-Null }
            Copy-Item $src $dst -Force
        }
    }

    # 10b. CI root files
    foreach ($f in @('.gitleaks.toml','package.json','.prettierrc','.prettierignore','VERSION','INSTALLATION.md')) {
        $src = Join-Path $privateRepo $f
        $dst = Join-Path $targetDir $f
        if (Test-Path $src) { Copy-Item $src $dst -Force }
    }
    # Adapters
    if (Test-Path "$privateRepo\adapters") {
        Remove-Item "$targetDir\adapters" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$privateRepo\adapters" "$targetDir\adapters" -Recurse -Force
    }
    $pssaSrc = Join-Path $privateRepo 'config\PSScriptAnalyzerSettings.psd1'
    $pssaDst = Join-Path $targetDir 'config\PSScriptAnalyzerSettings.psd1'
    if (Test-Path $pssaSrc) {
        if (-not (Test-Path (Split-Path $pssaDst -Parent))) { New-Item -ItemType Directory -Path (Split-Path $pssaDst -Parent) -Force | Out-Null }
        Copy-Item $pssaSrc $pssaDst -Force
    }

    # 10c. CI test files
    foreach ($td in @('tests\unit','tests\smoke')) {
        if (Test-Path "$privateRepo\$td") {
            Remove-Item "$targetDir\$td" -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item "$privateRepo\$td" "$targetDir\$td" -Recurse -Force
        }
    }

    # 10d. CI workflows (adapted)
    $workflowSrcDir = Join-Path $privateRepo '.github\workflows'
    $workflowDstDir = Join-Path $targetDir '.github\workflows'
    New-Item -ItemType Directory -Path $workflowDstDir -Force | Out-Null
    foreach ($wf in @('autonomous-validation.yml','cross-platform-tests.yml','dashboard-auto-refresh.yml','format-check.yml','gentle-vanguard-quality-gate.yml','gitleaks.yml','labeler.yml','ps-lint.yml','script-governance.yml','security-scan.yml','test-suite.yml','workflow-lint.yml')) {
        $src = Join-Path $workflowSrcDir $wf
        $dst = Join-Path $workflowDstDir $wf
        if (Test-Path $src) {
            $content = Get-Content $src -Raw
            $adapted = $content -replace "branches:\s*\[\s*develop\s*\]", "branches: [main]"
            $adapted = $adapted -replace "branches:\s*\[(.*?develop.*?)\]", "branches: [main]"
            Set-Content $dst $adapted -Force
        }
    }
}

# ============================================================================
# 11. Commit and push to ALL remote branches
# ============================================================================
if (-not $skipPush) {
    Push-Location $publicRepo

    git fetch origin --prune 2>&1 | Out-Null
    $remoteBranches = git branch -r 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^origin/(\S+)' -and $_ -notmatch '->' } | ForEach-Object { $_ -replace '^origin/', '' }
    if (-not $remoteBranches) { $remoteBranches = @('main') }
    Write-Output "[DETECT] Remote branches: $($remoteBranches -join ', ')"

    $priorBranch = git branch --show-current

    foreach ($branch in $remoteBranches) {
        Write-Output "[BRANCH] Syncing to '$branch'..."

        $localBranch = git branch --list $branch 2>$null
        if ([string]::IsNullOrWhiteSpace($localBranch)) {
            git checkout -B $branch "origin/$branch" 2>&1 | Out-Null
        } else {
            git checkout $branch 2>&1 | Out-Null
        }

        # Reset to remote state, then apply sync files
        git reset --hard "origin/$branch" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[WARN] Could not reset to origin/$branch — skipping"
            continue
        }

        # Run the file sync on this branch's working tree
        Sync-FilesToBranch -targetDir $publicRepo

        git add .
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        $commitMsg = "sync: automated sync from private repo - $timestamp"
        git commit -m $commitMsg 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[OK] Committed to '$branch': $commitMsg"
            $pushResult = git push origin $branch 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Output "[OK] Pushed to origin/$branch"
            } else {
                Write-Output "[FAIL] Push to $branch failed: $pushResult"
            }
        } else {
            Write-Output "i  Nothing to commit on '$branch' — up to date"
        }
    }

    git checkout $priorBranch 2>&1 | Out-Null
    Pop-Location
} else {
    Write-Output "i  skipPush enabled - commit/push skipped"
}

Write-Output ""
Write-Output "=== Sync Complete ==="

