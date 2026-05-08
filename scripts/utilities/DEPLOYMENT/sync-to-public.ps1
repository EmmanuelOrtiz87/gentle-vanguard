#!/usr/bin/env pwsh
# Sync changes from private repo to public repo

$privateRepo = "C:\Workspace_local\workspace-foundation"
$publicRepo = "C:\Workspace_local\foundation-public"
$buildDir = "$privateRepo\build"

Write-Output "=== Syncing Private → Public Repo ==="
Write-Output ""

# 1. Update public docs
Write-Output "📄 Syncing public docs..."
Copy-Item "$privateRepo\README.md" "$publicRepo\README.md" -Force
Copy-Item "$privateRepo\LICENSE" "$publicRepo\LICENSE" -Force
Copy-Item "$privateRepo\docs" "$publicRepo\" -Recurse -Force
Copy-Item "$privateRepo\CONTRIBUTING.md" "$publicRepo\CONTRIBUTING.md" -Force
Copy-Item "$privateRepo\SECURITY.md" "$publicRepo\SECURITY.md" -Force
Copy-Item "$privateRepo\CHANGELOG.md" "$publicRepo\CHANGELOG.md" -Force

# 2. Copy protected stubs (not encrypted files)
if (Test-Path "$buildDir\public") {
    Write-Output "📦 Copying public stubs..."
    Copy-Item "$buildDir\public\*" "$publicRepo\protected\" -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Rebuild installer if NSIS available
$makensis = Get-Command makensis -ErrorAction SilentlyContinue
if ($makensis) {
    Write-Output "🔨 Rebuilding installer..."
    & makensis "$buildDir\foundation-installer.nsi" 2>&1 | Out-Null
    if (Test-Path "$buildDir\Foundation-Setup.exe") {
        Copy-Item "$buildDir\Foundation-Setup.exe" "$publicRepo\Foundation-Setup.exe" -Force
        Write-Output "✅ Installer updated"
    }
} else {
    Write-Output "⚠️  NSIS not found, skipping installer rebuild"
}

# 4. Commit and push to public repo
cd $publicRepo
git add .
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "sync: automated sync from private repo - $timestamp" 2>&1 | Out-Null
git push origin master 2>&1 | Select-Object -First 10

Write-Output ""
Write-Output "=== Sync Complete ==="
