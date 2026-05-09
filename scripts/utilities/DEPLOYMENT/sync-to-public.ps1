#!/usr/bin/env pwsh
# Sync changes from private repo to public repo - v2.1
# Includes skills, configs, installer, public stubs, and docs

$privateRepo = "C:\Workspace_local\workspace-foundation"
$publicRepo = "C:\Workspace_local\foundation-public"
$buildDir = "$privateRepo\build"

Write-Output "=== Syncing Private → Public Repo ==="
Write-Output ""

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

# 6. Copy compiled launcher
Write-Output "🚀 Syncing compiled launcher..."
Copy-Item "$buildDir\compiled\Foundation-Launcher.exe" "$publicRepo\Foundation-Launcher.exe" -Force

# 7. Commit and push to public repo
Push-Location $publicRepo
git add .
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$commitMsg = "sync: automated sync from private repo - $timestamp"
git commit -m $commitMsg 2>&1 | Out-Null
git push origin master 2>&1 | Select-Object -First 10
Pop-Location

Write-Output ""
Write-Output "=== Sync Complete ==="
