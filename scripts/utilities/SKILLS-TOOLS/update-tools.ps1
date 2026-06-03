# update-tools.ps1
# Updates all gentle-vanguard tools on the local machine.
#
# Tool installation:
#   engram           - go install github.com/gentle-vanguard/engram/cmd/engram@latest
#   opencode         - installer script, package manager, npm, or manual binary install

param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { (Get-Location).Path }

function Write-Step  { param([string]$m) if (-not $Quiet) { Write-Host "`n=== $m ===" -ForegroundColor Cyan } }
function Write-Ok    { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn  { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err   { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }
function Write-Info  { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Cyan }

function Get-CurrentPlatform {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) { return 'windows' }
        if ($IsMacOS) { return 'macos' }
        if ($IsLinux) { return 'linux' }
    }
    try {
        $os = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription.ToLowerInvariant()
        if ($os -like '*windows*') { return 'windows' }
        if ($os -like '*darwin*' -or $os -like '*mac*') { return 'macos' }
        if ($os -like '*linux*') { return 'linux' }
    } catch {}
    return 'windows'
}

function Get-HomePath {
    if ((Get-CurrentPlatform) -eq 'windows') { return $env:USERPROFILE }
    return $HOME
}

function Convert-ToBashPath {
    param([string]$Path)
    if ((Get-CurrentPlatform) -ne 'windows') { return $Path }
    $normalized = $Path -replace '\\', '/'
    if ($normalized -match '^([A-Za-z]):(.*)$') {
        $drive = $Matches[1].ToLowerInvariant()
        $rest = $Matches[2]
        return "/$drive$rest"
    }
    return $normalized
}

function Get-BashPath {
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if ($bash) { return $bash.Source }
    if ((Get-CurrentPlatform) -eq 'windows') {
        $gitBash = 'C:\Program Files\Git\bin\bash.exe'
        if (Test-Path $gitBash) { return $gitBash }
    }
    return $null
}

#  Prerequisites 

function Get-GoBinDir {
    if ($env:GOBIN)  { return $env:GOBIN }
    if ($env:GOPATH) { return Join-Path $env:GOPATH 'bin' }
    return Join-Path (Join-Path (Get-HomePath) 'go') 'bin'
}

function Get-ToolsRoot {
    $cfgPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (Test-Path $cfgPath) {
        $c = Get-Content $cfgPath -Raw | ConvertFrom-Json
        if ($c.toolsRoot) { return Join-Path $repoRoot $c.toolsRoot }
    }
    return Join-Path $repoRoot 'tools'
}

function Test-Go {
    $go = Get-Command go -ErrorAction SilentlyContinue
    if ($go) { Write-Ok "Go found: $($go.Source)"; return $true }
    Write-Err "Go not found. Install from https://go.dev/dl/"
    return $false
}

#  Version comparison helpers 

# Fetches the latest release tag from a GitHub repo (e.g. "gentle-vanguard/engram")
function Get-GitHubLatestVersion {
    param([string]$Repo)
    try {
        $url  = "https://api.github.com/repos/$Repo/releases/latest"
        $resp = Invoke-RestMethod -Uri $url -Headers @{ 'User-Agent' = 'gentle-vanguard-updater' } -ErrorAction Stop
        return ($resp.tag_name -replace '^v', '')
    } catch {
        return $null
    }
}

# Compares two semantic version strings. Returns -1, 0, or 1.
function Compare-Version {
    param([string]$A, [string]$B)
    try {
        $va = [Version]($A -replace '[^0-9.]', '')
        $vb = [Version]($B -replace '[^0-9.]', '')
        return $va.CompareTo($vb)
    } catch {
        return 0
    }
}

# Gets the installed version of a Go binary (first number-containing line of --version output)
function Get-InstalledVersion {
    param([string]$BinaryPath)
    if (-not (Test-Path $BinaryPath)) { return $null }
    try {
        $raw = & $BinaryPath --version 2>&1 | Select-Object -First 2
        foreach ($line in $raw) {
            if ($line -match '(\d+\.\d+[\.\d]*)') { return $Matches[1] }
        }
    } catch {}
    return $null
}

#  Tool: Engram 
# Installed via: go install github.com/gentle-vanguard/engram/cmd/engram@latest
# Binary lands in $GOPATH/bin/engram.exe

function Update-Engram {
    Write-Step "Updating Engram"

    $goBin     = Get-GoBinDir
    $engramExe = Join-Path $goBin 'engram.exe'
    if (-not (Test-Path $engramExe)) { $engramExe = Join-Path $goBin 'engram' }

    $installed = Get-InstalledVersion -BinaryPath $engramExe
    $latest    = Get-GitHubLatestVersion -Repo 'gentle-vanguard/engram'

    if ($installed) {
        Write-Info "Engram installed: v$installed"
        if ($latest) {
            Write-Info "Engram latest:    v$latest"
            $cmp = Compare-Version -A $installed -B $latest
            if ($cmp -ge 0) {
                Write-Ok "Engram is up to date (v$installed)"
                return $true
            }
            Write-Info "Upgrade available: v$installed  v$latest"
        }
    } else {
        Write-Info "Engram not installed; installing latest"
    }

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would run: go install github.com/gentle-vanguard/engram/cmd/engram@latest"
        return $true
    }

    Write-Info "Running: go install github.com/gentle-vanguard/engram/cmd/engram@latest"
    # -mod=mod ensures Go fetches the latest even if module cache has an older version
    $env:GOFLAGS = '-mod=mod'
    go install github.com/gentle-vanguard/engram/cmd/engram@latest 2>&1 | ForEach-Object { Write-Host "  $_" }
    $env:GOFLAGS = $null

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Engram update failed (exit $LASTEXITCODE)"
        return $false
    }

    $engramExe = Join-Path $goBin 'engram.exe'
    if (-not (Test-Path $engramExe)) { $engramExe = Join-Path $goBin 'engram' }

    if (Test-Path $engramExe) {
        $ver = & $engramExe --version 2>&1 | Select-Object -First 1
        Write-Ok "Engram updated: $ver"
        return $true
    }

    Write-Ok "Engram installed. Ensure $goBin is in your PATH."
    return $true
}

#  Show current status 

#  Tool: OpenCode 
# Installed via: official installer, package manager, npm, or manual binary install
# NOTE: The installer downloads and executes a remote script.
#       Auto-install requires explicit -Force flag to avoid unintended network calls.

function Check-Opencode {
    Write-Step "Checking OpenCode"

    function Get-OpencodeVersion {
        try {
            $v = (& opencode --version 2>$null | Select-Object -First 1)
            if (-not [string]::IsNullOrWhiteSpace($v)) { return $v }
        } catch {}
        return $null
    }

    $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
    if ($opencodeCmd) {
        $ver = Get-OpencodeVersion
        if ([string]::IsNullOrWhiteSpace($ver)) { $ver = 'installed' }
        Write-Ok "opencode: $ver"
        return $true
    }

    Write-Warn "opencode not found"
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would run: irm https://opencode.ai/install | iex"
        return $true
    }
    if ($Force) {
        Write-Info "Running opencode installer (requires network)..."
        try {
            $installerScript = Invoke-RestMethod -Uri 'https://opencode.ai/install' -ErrorAction Stop
            Invoke-Expression $installerScript 2>&1 | Out-Null
            $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
            if ($opencodeCmd) { Write-Ok "opencode installed"; return $true }
            Write-Warn "opencode installer ran but binary not found; restart terminal"
            return $false
        } catch {
            $msg = $_.Exception.Message
            if ($_.Exception.Response.StatusCode.value__ -eq 403 -or $msg -like '*403*' -or $msg -like '*Prohibido*' -or $msg -like '*Forbidden*') {
                Write-Warn "opencode: install blocked by network restriction (HTTP 403)"
                Write-Info "  This tool is optional. Alternative install options:"
                Write-Info "  1. GitHub releases: https://github.com/sst/opencode/releases"
                Write-Info "  2. package manager: install from your OS package manager"
                Write-Info "  3. npm:             npm install -g opencode"
                Write-Info "  4. Manual:          download binary from GitHub and add to PATH"
            } else {
                Write-Err "opencode install failed: $msg"
            }
            return $false
        }
    } else {
        Write-Host "  Install via the official installer, your package manager, npm, or a manual binary download." -ForegroundColor Gray
        Write-Host "  Or run: .\scripts\utilities\gv.ps1 update-tools -Force" -ForegroundColor Gray
        return $false
    }
}

function Show-ToolStatus {
    Write-Step "Current Tool Status"

    $goBin = Get-GoBinDir

    # Engram
    $engramExe = Join-Path $goBin 'engram'
    if (-not (Test-Path $engramExe)) { $engramExe = Join-Path $goBin 'engram.exe' }
    if (Test-Path $engramExe) {
        $ver = & $engramExe --version 2>&1 | Select-Object -First 1
        Write-Ok "engram: $ver"
    } else {
        Write-Warn "engram: not installed (expected at $engramExe)"
    }

    # OpenCode
    $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
    if ($opencodeCmd) {
        $ver = $null
        try {
            $ver = (& opencode --version 2>$null | Select-Object -First 1)
        } catch {}
        if ([string]::IsNullOrWhiteSpace($ver)) { $ver = 'installed' }
        Write-Ok "opencode: $ver"
    } else {
        Write-Warn "opencode: not installed"
    }

    Write-Host ""
    Write-Host "Install commands:" -ForegroundColor Gray
    Write-Host "  engram    : go install github.com/gentle-vanguard/engram/cmd/engram@latest" -ForegroundColor Gray
    Write-Host "  opencode  : official installer, package manager, npm, or manual binary (or gv.ps1 update-tools -Force)" -ForegroundColor Gray
}

#  Main 

Write-Host ""
Write-Host "Gentle-Vanguard - Tool Updater" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN MODE]" -ForegroundColor Yellow }
Write-Host ""

Show-ToolStatus

$hasGo   = Test-Go
$bashExe = Test-GitBash

$results = @{}

if ($hasGo) {
    $results['engram'] = Update-Engram
} else {
    Write-Warn "Skipping engram (Go not found)"
    $results['engram'] = $false
}

$results['opencode'] = Check-Opencode

# Summary
Write-Step "Update Summary"
$ok = 0; $fail = 0
foreach ($tool in $results.Keys) {
    if ($results[$tool]) {
        Write-Ok $tool
        $ok++
    } else {
        Write-Warn "$tool - skipped or failed"
        $fail++
    }
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "All tools updated successfully." -ForegroundColor Green
} else {
    Write-Host "$ok updated, $fail skipped/failed. Check warnings above." -ForegroundColor Yellow
}
Write-Host ""

