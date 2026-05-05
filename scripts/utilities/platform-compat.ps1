<#
.SYNOPSIS
    Cross-platform compatibility helpers for Gentleman Foundation scripts.

.DESCRIPTION
    Dot-source this module to get platform-aware path helpers, OS detection,
    and cross-platform utilities. Compatible with PowerShell 7+ on Windows,
    Linux (Ubuntu, Debian, Fedora, Alpine), and macOS (Intel + Apple Silicon).

    Usage:
        $compat = Join-Path $PSScriptRoot '..\platform-compat.ps1'
        if (Test-Path $compat) { . $compat }

    Exported functions:
        Get-Platform          - Returns 'windows' | 'linux' | 'macos'
        Join-NativePath       - Platform-correct path join
        Get-RepoRoot          - Locate repo root from any working dir
        Invoke-NativeOpen     - Open file/URL in default app (xdg/open/start)
        Get-PwshPath          - Locate pwsh executable cross-platform
        Test-CommandAvailable - Safely test if a CLI command is in PATH
        Get-TempDir           - Platform-aware temp directory
#>

# ── Platform detection ────────────────────────────────────────────────────────
function Get-Platform {
    if ($IsWindows -or $env:OS -eq 'Windows_NT') { return 'windows' }
    if ($IsMacOS)                                  { return 'macos' }
    return 'linux'
}

# ── Path helpers ──────────────────────────────────────────────────────────────
function Join-NativePath {
    param([string[]]$Parts)
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $joined = $Parts -join $sep
    # Normalize any mixed separators
    return $joined -replace '[/\\]', [System.Text.RegularExpressions.Regex]::Escape($sep)
}

function Get-RepoRoot {
    param([string]$StartDir = $PWD.Path)
    $dir = $StartDir
    $maxSteps = 10
    for ($i = 0; $i -lt $maxSteps; $i++) {
        if (Test-Path (Join-Path $dir '.git')) { return $dir }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $StartDir
}

# ── Open file/URL cross-platform ──────────────────────────────────────────────
function Invoke-NativeOpen {
    param([string]$Path)
    $platform = Get-Platform
    switch ($platform) {
        'windows' { Start-Process $Path }
        'macos'   { & open $Path }
        default   {
            if (Get-Command xdg-open -ErrorAction SilentlyContinue) {
                & xdg-open $Path 2>$null
            } else {
                Write-Warning "No default opener found. Open manually: $Path"
            }
        }
    }
}

# ── Locate pwsh ───────────────────────────────────────────────────────────────
function Get-PwshPath {
    $candidates = @('pwsh', 'pwsh7', '/usr/bin/pwsh', '/usr/local/bin/pwsh', '/snap/bin/pwsh')
    foreach ($c in $candidates) {
        if (Get-Command $c -ErrorAction SilentlyContinue) {
            return (Get-Command $c).Source
        }
    }
    return $null
}

# ── Command availability ──────────────────────────────────────────────────────
function Test-CommandAvailable {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── Temp directory ────────────────────────────────────────────────────────────
function Get-TempDir {
    if ($env:TMPDIR)  { return $env:TMPDIR }
    if ($env:TEMP)    { return $env:TEMP }
    if ($env:TMP)     { return $env:TMP }
    $platform = Get-Platform
    if ($platform -eq 'windows') { return $env:TEMP ?? 'C:\Temp' }
    return '/tmp'
}

# ── Path separator normalizer for config JSON paths ──────────────────────────
function ConvertTo-NativePath {
    param([string]$Path)
    $sep = [System.IO.Path]::DirectorySeparatorChar
    return $Path -replace '[/\\]', [System.Text.RegularExpressions.Regex]::Escape($sep)
}

# ── Platform info string ──────────────────────────────────────────────────────
function Get-PlatformInfo {
    $platform = Get-Platform
    $psver    = $PSVersionTable.PSVersion.ToString()
    $arch     = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    return "[platform: $platform | pwsh: $psver | arch: $arch]"
}

Export-ModuleMember -Function * -ErrorAction SilentlyContinue
