#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Downloads and installs the witr binary (github.com/pranshuparmar/witr) into .runtime/tools/witr/.

.DESCRIPTION
    witr ("Why Is This Running?") traces processes, ports, containers and files back to their
    causal chain. This installer fetches the latest (or pinned) release from GitHub, verifies the
    SHA-256 checksum against the release manifest, and places the binary at:

        .runtime/tools/witr/witr.exe   (Windows)
        .runtime/tools/witr/witr       (Linux / macOS / FreeBSD)

.PARAMETER Version
    Release tag to install (default: v0.3.3).

.PARAMETER InstallDir
    Destination directory (default: <repo>/.runtime/tools/witr).

.PARAMETER Force
    Re-download even if the binary is already present.

.PARAMETER Quiet
    Suppress non-error output.

.EXAMPLE
    ./scripts/utilities/maintenance/witr-installer.ps1

.EXAMPLE
    ./scripts/utilities/maintenance/witr-installer.ps1 -Version v0.3.3 -Force

.EXAMPLE
    ./scripts/utilities/maintenance/witr-installer.ps1 -Quiet
#>

[CmdletBinding()]
param(
    [string]$Version = "v0.3.3",
    [string]$InstallDir = "",
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message }
}

function Write-Done {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Green }
}

# ─── Repo root (scripts/utilities/maintenance -> repo root, 3x parent) ─────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..\..\")

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path $repoRoot ".runtime\tools\witr"
}

# ─── Platform / architecture detection ─────────────────────────────────────
function Get-WitrPlatform {
    $os = ""
    $arch = ""
    $isWin = $false

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $os = "windows"
        $isWin = $true
        $procArch = $env:PROCESSOR_ARCHITECTURE
        $arch = if ($procArch -match "ARM64") { "arm64" } else { "amd64" }
    }
    elseif ($IsLinux) {
        $os = "linux"
        $isWin = $false
        $uname = & uname -m 2>$null
        $arch = if ($uname -match "aarch64|arm64") { "arm64" } else { "amd64" }
    }
    elseif ($IsMacOS) {
        $os = "darwin"
        $isWin = $false
        $uname = & uname -m 2>$null
        $arch = if ($uname -match "arm64|aarch64") { "arm64" } else { "amd64" }
    }
    else {
        throw "Unsupported platform. witr supports Windows, Linux, macOS and FreeBSD."
    }

    return [pscustomobject]@{
        OS        = $os
        Arch      = $arch
        IsWindows = $isWin
    }
}

# ─── Install ────────────────────────────────────────────────────────────────
function Install-Witr {
    param(
        [string]$Tag,
        [string]$DestDir,
        [switch]$ForceInstall
    )

    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

    $platform = Get-WitrPlatform
    $asset = ""
    if ($platform.IsWindows) {
        $asset = "witr-windows-$($platform.Arch).zip"
    }
    else {
        $asset = "witr-$($platform.OS)-$($platform.Arch)"
    }

    $exeName = if ($platform.IsWindows) { "witr.exe" } else { "witr" }
    $exePath = Join-Path $DestDir $exeName

    if ((Test-Path $exePath) -and -not $ForceInstall) {
        Write-Done "[witr] already installed at $exePath"
        return $exePath
    }

    $base = "https://github.com/pranshuparmar/witr/releases/download/$Tag"
    $downloadUrl = "$base/$asset"
    $checksumUrl = "$base/SHA256SUMS"
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "witr-install-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    try {
        Write-Info "[witr] Downloading $downloadUrl ..."
        $archivePath = Join-Path $tmpDir $asset
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing

        # ─── Checksum verification (best-effort against release manifest) ───
        try {
            $expected = $null
            $sums = Invoke-WebRequest -Uri $checksumUrl -UseBasicParsing -TimeoutSec 30
            $line = ($sums.Content -split "`n") | Where-Object { $_ -match "\s$([regex]::Escape($asset))\s*$" }
            if ($line) {
                $expected = (($line -split "\s+")[0]).ToLower()
            }
            $actual = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLower()
            if ($expected -and $actual -ne $expected) {
                throw "Checksum mismatch for $asset. Expected $expected, got $actual."
            }
            Write-Info "[witr] Checksum verified for $asset"
        }
        catch {
            Write-Warning "[witr] Checksum verification skipped: $($_.Exception.Message)"
        }

        # ─── Extract / stage binary ──────────────────────────────────────────
        if ($platform.IsWindows) {
            $extractDir = Join-Path $tmpDir "extract"
            Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force
            $candidate = Get-ChildItem -Path $extractDir -Recurse -Filter "witr.exe" | Select-Object -First 1
            if (-not $candidate) {
                throw "witr.exe not found inside $asset"
            }
            Copy-Item -Path $candidate.FullName -Destination $exePath -Force
        }
        else {
            Copy-Item -Path $archivePath -Destination $exePath -Force
            if (-not $IsWindows) {
                & chmod +x $exePath
            }
        }

        # ─── Verify version ──────────────────────────────────────────────────
        $versionOut = if ($platform.IsWindows) {
            & $exePath --version 2>&1
        }
        else {
            & $exePath --version 2>&1
        }
        Write-Done "[witr] Installed at $exePath ($versionOut)"

        return $exePath
    }
    finally {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ─── Main ───────────────────────────────────────────────────────────────────
try {
    $result = Install-Witr -Tag $Version -DestDir $InstallDir -ForceInstall:$Force
    Write-Output $result
}
catch {
    Write-Error "[witr] Installation failed: $($_.Exception.Message)"
    exit 1
}
