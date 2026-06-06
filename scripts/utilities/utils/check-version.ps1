<#
.SYNOPSIS
    Check for new versions of Gentle-Vanguard on GitHub.
.DESCRIPTION
    Reads local version from VERSION file and compares it against the latest
    release on GitHub. Returns structured output for use by auto-update.ps1.
.PARAMETER Quiet
    Suppress console output; use exit code only (0=up-to-date, 1=update, 2=error).
.PARAMETER PreRelease
    Include pre-release versions when checking for updates.
#>
[CmdletBinding()]
param(
    [switch]$Quiet,
    [switch]$PreRelease
)

function Get-SemverParts {
    param([string]$Version)
    $parts = $Version -split '\.'
    return @{
        Major = [int]$parts[0]
        Minor = [int]$parts[1]
        Patch = [int]$parts[2]
    }
}

function Compare-Semver {
    param([string]$Local, [string]$Remote)
    $a = Get-SemverParts $Local
    $b = Get-SemverParts $Remote
    if ($a.Major -ne $b.Major) { return $a.Major - $b.Major }
    if ($a.Minor -ne $b.Minor) { return $a.Minor - $b.Minor }
    return $a.Patch - $b.Patch
}

$scriptPath = Split-Path -Parent $PSScriptRoot
$projectRoot = Split-Path -Parent $scriptPath
$versionFile = Join-Path $projectRoot "VERSION"

try {
    if (-not (Test-Path $versionFile)) {
        throw "VERSION file not found at $versionFile"
    }

    $localVersion = (Get-Content $versionFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($localVersion)) {
        throw "VERSION file is empty"
    }

    if (-not $Quiet) {
        Write-Host "Checking for updates..." -ForegroundColor Cyan
        Write-Host "Local version: v$localVersion" -ForegroundColor Gray
    }

    $apiUrl = "https://api.github.com/repos/EmmanuelOrtiz87/gentle-vanguard/releases/latest"
    if ($PreRelease) {
        $apiUrl = "https://api.github.com/repos/EmmanuelOrtiz87/gentle-vanguard/releases"
    }

    $release = Invoke-RestMethod -Uri $apiUrl -Method Get -ErrorAction Stop

    $latestVersion = ""
    $downloadUrl = ""

    if ($PreRelease) {
        $latest = $release | Sort-Object { [version]($_.tag_name -replace '^v', '') } -Descending | Select-Object -First 1
        if (-not $latest) { throw "No releases found" }
        $latestVersion = $latest.tag_name -replace '^v', ''
        $downloadUrl = $latest.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1 -ExpandProperty browser_download_url
    } else {
        $latestVersion = $release.tag_name -replace '^v', ''
        $downloadUrl = $release.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1 -ExpandProperty browser_download_url
    }

    if ([string]::IsNullOrWhiteSpace($latestVersion)) {
        throw "Could not determine latest version from GitHub response"
    }

    if (-not $Quiet) {
        Write-Host "Latest version: v$latestVersion" -ForegroundColor Gray
    }

    $comparison = Compare-Semver $localVersion $latestVersion

    if ($comparison -lt 0) {
        if (-not $Quiet) {
            Write-Host "Update available: v$localVersion -> v$latestVersion" -ForegroundColor Green
        }
        Write-Output "UPDATE_AVAILABLE|$localVersion|$latestVersion|$downloadUrl"
        exit 1
    } else {
        if (-not $Quiet) {
            Write-Host "You are on the latest version (v$localVersion)" -ForegroundColor Green
        }
        Write-Output "UP_TO_DATE|$localVersion"
        exit 0
    }
} catch {
    $errorMsg = $_.Exception.Message -replace '\|', '-'
    if (-not $Quiet) {
        Write-Host "Version check failed: $errorMsg" -ForegroundColor Red
    }
    Write-Output "CHECK_FAILED|$errorMsg"
    exit 2
}
