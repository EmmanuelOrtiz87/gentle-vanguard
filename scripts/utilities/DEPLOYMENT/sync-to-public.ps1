#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sync changes from private repo to public repo.
.DESCRIPTION
    Copies skills (public stubs for protected ones), configs, installer,
    compiled launcher, and docs from private to public repo, then commits
    and pushes. Supports both local and CI (GitHub Actions) execution.
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
    [string]$privateRepo = "$(if ($env:PRIVATE_REPO) { $env:PRIVATE_REPO } else { Resolve-Path "$PSScriptRoot\..\..\.." })",
    [string]$publicRepo = "$(if ($env:PUBLIC_REPO) { $env:PUBLIC_REPO } else { Resolve-Path "$PSScriptRoot\..\..\..\..\foundation-public" })",
    [string]$publicRepoSlug = "$(if ($env:PUBLIC_REPO_SLUG) { $env:PUBLIC_REPO_SLUG } else { 'EmmanuelOrtiz87/foundation-public' })",
    [switch]$skipPush
)

$ErrorActionPreference = "Stop"
$buildDir = "$privateRepo\build"

Write-Output "=== Syncing Private → Public Repo ==="
Write-Output ""

# 0. Sync public bootstrap bundle
Write-Output "[BOOTSTRAP] Syncing public bootstrap bundle..."
New-Item -ItemType Directory -Path "$publicRepo\scripts\foundation" -Force | Out-Null
New-Item -ItemType Directory -Path "$publicRepo\scripts\utilities\DEPLOYMENT" -Force | Out-Null
Copy-Item "$privateRepo\scripts\foundation\bootstrap.ps1" "$publicRepo\scripts\foundation\bootstrap.ps1" -Force
Copy-Item "$privateRepo\scripts\foundation\bootstrap-machine.ps1" "$publicRepo\scripts\foundation\bootstrap-machine.ps1" -Force
Copy-Item "$privateRepo\scripts\foundation\setup-multi-machine.ps1" "$publicRepo\scripts\foundation\setup-multi-machine.ps1" -Force
Copy-Item "$privateRepo\scripts\utilities\DEPLOYMENT\setup-wizard.ps1" "$publicRepo\scripts\utilities\DEPLOYMENT\setup-wizard.ps1" -Force
Copy-Item "$privateRepo\scripts\utilities\DEPLOYMENT\install-github-runner.ps1" "$publicRepo\scripts\utilities\DEPLOYMENT\install-github-runner.ps1" -Force

# 1. Update public docs
Write-Output "📄 Syncing public docs..."
Copy-Item "$privateRepo\README.md" "$publicRepo\README.md" -Force
Copy-Item "$privateRepo\LICENSE" "$publicRepo\LICENSE" -Force
Copy-Item "$privateRepo\CONTRIBUTING.md" "$publicRepo\CONTRIBUTING.md" -Force
Copy-Item "$privateRepo\SECURITY.md" "$publicRepo\SECURITY.md" -Force
Copy-Item "$privateRepo\CHANGELOG.md" "$publicRepo\CHANGELOG.md" -Force
Copy-Item "$privateRepo\docs" "$publicRepo\" -Recurse -Force
Copy-Item "$privateRepo\BUILD-README.md" "$publicRepo\BUILD-README.md" -Force -ErrorAction SilentlyContinue

# 2. Sync skills (public stubs only — protected skills get placeholder SKILL.md)
Write-Output "🧩 Syncing public skill stubs..."
if (Test-Path "$publicRepo\skills") {
    Remove-Item "$publicRepo\skills" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path "$publicRepo\skills" -Force | Out-Null

$protectedSkills = @(
    'business-telemetry-skill', 'finance-financial-analyst', 'hr-talent-acquisition',
    'legal-compliance-officer', 'marketing-content-writer', 'marketing-growth-hacker',
    'sales-account-executive', 'sales-outbound-strategist'
)

Get-ChildItem "$privateRepo\skills" -Directory | ForEach-Object {
    $skillName = $_.Name
    $skillDir = $_.FullName
    $targetDir = "$publicRepo\skills\$skillName"

    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

    if ($skillName -in $protectedSkills) {
        # Write protected stub
        $stub = @"
# ---

**This skill is protected intellectual property.**

## Overview
This skill provides specialized AI-assisted development capabilities for $($skillName -replace '-', ' ').

## Public Documentation
- Theory and concepts: See \`docs/guides/\`
- Usage examples: See \`docs/examples/\`
- Implementation: **Protected** (encrypted)

## Legal Notice
This skill's implementation is protected by EULA. Unauthorized reverse engineering is prohibited.
"@
        Set-Content -Path "$targetDir\SKILL.md" -Value $stub -Encoding UTF8
    } else {
        Copy-Item "$skillDir\SKILL.md" "$targetDir\SKILL.md" -Force
    }
}

# Also sync SKILL_INDEX.md
Copy-Item "$privateRepo\skills\SKILL_INDEX.md" "$publicRepo\skills\SKILL_INDEX.md" -Force

# 3. Sync config files (redacted for public)
Write-Output "⚙️ Syncing public configs..."
if (Test-Path "$publicRepo\config") {
    Remove-Item "$publicRepo\config" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path "$publicRepo\config" -Force | Out-Null
Copy-Item "$privateRepo\config\auto-delegation.json" "$publicRepo\config\auto-delegation.json" -Force
Copy-Item "$privateRepo\config\workspace.example.json" "$publicRepo\config\workspace.example.json" -Force
Copy-Item "$privateRepo\config\workspace.portable.example.json" "$publicRepo\config\workspace.portable.example.json" -Force
Copy-Item "$privateRepo\config\github-runner.example.json" "$publicRepo\config\github-runner.example.json" -Force

# 4. Copy public stubs (pre-built public artifacts)
if (Test-Path "$buildDir\public") {
    Write-Output "📦 Copying public stubs..."
    Copy-Item "$buildDir\public\*" "$publicRepo\protected\" -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Rebuild installer if NSIS available
$makensisPaths = @(
    "C:\Program Files (x86)\NSIS\makensis.exe",
    "C:\Program Files\NSIS\makensis.exe"
)
$makensis = $null
foreach ($p in $makensisPaths) {
    if (Test-Path $p) { $makensis = $p; break }
}
if (-not $makensis) { $makensis = Get-Command makensis -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }

if ($makensis) {
    Write-Output "🔨 Rebuilding installer..."
    & $makensis "$buildDir\foundation-installer.nsi" 2>&1 | Out-Null
    $installerSource = "$privateRepo\dist\Foundation-Setup.exe"
    if (Test-Path $installerSource) {
        Copy-Item $installerSource "$publicRepo\Foundation-Setup.exe" -Force
        Write-Output "✅ Installer updated"
    }
} else {
    Write-Output "⚠️  NSIS not found, skipping installer rebuild"
}

# 6. Copy compiled launcher (optional — may not exist if build step hasn't run)
$launcherSource = "$buildDir\compiled\Foundation-Launcher.exe"
if (Test-Path $launcherSource) {
    Write-Output "🚀 Syncing compiled launcher..."
    Copy-Item $launcherSource "$publicRepo\Foundation-Launcher.exe" -Force
} else {
    Write-Output "⚠️  Compiled launcher not found at $launcherSource, skipping"
}

# 7. Commit and push to public repo
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
        Write-Output "❌ Remote default branch '$defaultBranch' not found in $publicRepoSlug"
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
        Write-Output "❌ Could not rebase local $defaultBranch with origin/$defaultBranch"
        Pop-Location
        exit 1
    }

    git add .
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $commitMsg = "sync: automated sync from private repo - $timestamp"
    git commit -m $commitMsg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Committed: $commitMsg"
        $pushResult = git push origin $defaultBranch 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Output "✅ Pushed to origin/$defaultBranch"
        } else {
            Write-Output "❌ Push failed: $pushResult"
        }
    } else {
        Write-Output "ℹ️  Nothing to commit — public repo is up to date"
    }
    Pop-Location
} else {
    Write-Output "ℹ️  skipPush enabled — commit/push skipped"
}

Write-Output ""
Write-Output "=== Sync Complete ==="
