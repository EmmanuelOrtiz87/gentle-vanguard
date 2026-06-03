<#
.SYNOPSIS
    Create a new release for Gentle-Vanguard
.DESCRIPTION
    Automates the release process: version bump, changelog, tag, build, release notes.
.PARAMETER Version
    Version number (e.g., 3.1.0)
.PARAMETER Build
    Build the executable
.PARAMETER Release
    Create GitHub release
.EXAMPLE
    .\create-release.ps1 -Version 3.1.0 -Build -Release
#>
[CmdletBinding()]
param(
    [string]$Version = "",
    [switch]$Build,
    [switch]$Release
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Level, [string]$Message)
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Get version from VERSION file if not provided
if (-not $Version) {
    $Version = (Get-Content "VERSION" -Raw).Trim()
}

Write-Log "INFO" "Creating release v$Version"

# Stage version and changelog changes
Write-Log "INFO" "Staging version and changelog..."
git add VERSION CHANGELOG.md

# Commit version bump
Write-Log "INFO" "Committing version bump..."
git commit -m "chore: bump version to $Version" --no-verify

# Create tag
Write-Log "INFO" "Creating tag v$Version..."
git tag -a "v$Version" -m "Release v$Version"

# Build executable if requested
if ($Build) {
    Write-Log "INFO" "Building executable..."
    & "$PSScriptRoot\compile-ps2exe.ps1" -Version $Version
    
    if (Test-Path "releases\gentle-vanguard-$Version.exe") {
        Write-Log "SUCCESS" "Executable built: releases\gentle-vanguard-$Version.exe"
    } else {
        Write-Log "WARN" "Executable not found after build"
    }
}

# Push to origin
Write-Log "INFO" "Pushing to origin..."
git push origin main
git push origin "v$Version"

# Create GitHub release if requested
if ($Release) {
    Write-Log "INFO" "Creating GitHub release..."
    
    $releaseNotes = @"
## Release v$Version

### New Features
- Dashboard v4 with OpenTelemetry tracing
- Skill Marketplace with ratings and reviews
- Interactive Documentation with tutorials
- Performance optimizations with code splitting

### Download
- Windows: gentle-vanguard-$Version.exe
- Source: Source code (zip)

### Installation
1. Download the executable
2. Run gentle-vanguard-$Version.exe
3. Follow the setup wizard

### Documentation
See docs/ for full documentation.
"@
    
    # Create release using gh CLI if available
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        gh release create "v$Version" `
            --title "Release v$Version" `
            --notes "$releaseNotes" `
            --target main
        
        if ($Build -and (Test-Path "releases\gentle-vanguard-$Version.exe")) {
            gh release upload "v$Version" "releases\gentle-vanguard-$Version.exe"
        }
        
        Write-Log "SUCCESS" "GitHub release created: v$Version"
    } else {
        Write-Log "WARN" "gh CLI not found. Create release manually on GitHub."
    }
}

Write-Log "SUCCESS" "Release v$Version complete!"
