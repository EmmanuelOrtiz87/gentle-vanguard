# update-tools.ps1
# Updates GGA, Engram, and Gentle-AI on the local machine.
#
# How each tool is installed on Windows:
#   gga         - bash install.sh from gentleman-guardian-angel repo (Git Bash required)
#   engram      - go install github.com/Gentleman-Programming/engram/cmd/engram@latest
#   gentle-ai   - go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest
#
# brew is NOT required. brew is macOS/Linuxbrew only.
# All tools work on Windows via Git Bash + Go.

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

# ── Prerequisites ─────────────────────────────────────────────────────────────

function Test-Go {
    $go = Get-Command go -ErrorAction SilentlyContinue
    if ($go) { Write-Ok "Go found: $($go.Source)"; return $true }
    Write-Err "Go not found. Install from https://go.dev/dl/"
    return $false
}

function Test-GitBash {
    $gitBash = 'C:\Program Files\Git\bin\bash.exe'
    if (Test-Path $gitBash) { Write-Ok "Git Bash found: $gitBash"; return $gitBash }
    $alt = Get-Command bash -ErrorAction SilentlyContinue
    if ($alt) { Write-Ok "bash found: $($alt.Source)"; return $alt.Source }
    Write-Err "Git Bash not found. Install Git for Windows: https://git-scm.com/download/win"
    return $null
}

# ── Tool: GGA (Gentleman Guardian Angel) ──────────────────────────────────────
# Installed via bash install.sh from the gentleman-guardian-angel repo.
# The installed binary is a bash script placed in $HOME/bin/gga.

function Update-Gga {
    param([string]$BashPath)

    Write-Step "Updating GGA (Gentleman Guardian Angel)"

    # Find the local repo
    $ggaRepo = $null
    $candidates = @(
        (Join-Path $repoRoot '..\gentleman-guardian-angel'),
        (Join-Path $env:USERPROFILE 'Workspace_local\gentleman-guardian-angel'),
        'C:\Workspace_local\gentleman-guardian-angel'
    )
    foreach ($c in $candidates) {
        $resolved = if (Test-Path $c) { (Resolve-Path $c).Path } else { $null }
        if ($resolved -and (Test-Path (Join-Path $resolved 'install.sh'))) {
            $ggaRepo = $resolved
            break
        }
    }

    if (-not $ggaRepo) {
        Write-Warn "gentleman-guardian-angel repo not found in known locations."
        Write-Info "Clone it manually:"
        Write-Host "  git clone https://github.com/Gentleman-Programming/gentleman-guardian-angel.git" -ForegroundColor White
        return $false
    }

    Write-Info "Repo: $ggaRepo"

    # Pull latest
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would run: git pull --ff-only origin main"
    } else {
        Push-Location $ggaRepo
        try {
            git pull --ff-only origin main 2>&1 | ForEach-Object { Write-Host "  $_" }
        } finally {
            Pop-Location
        }
    }

    # Install/reinstall binary
    if ($DryRun) {
        Write-Info "[DRY-RUN] Would run: bash install.sh (non-interactive)"
        return $true
    }

    # Non-interactive install: copy files and patch LIB_DIR manually
    $installDir = "$env:USERPROFILE\bin" -replace '\\', '/'
    $installDir = $installDir -replace '^C:', '/c'
    $libDir     = "$installDir/lib/gga"

    $binSrc  = Join-Path $ggaRepo 'bin\gga'
    $binDest = Join-Path $env:USERPROFILE 'bin\gga'

    if (-not (Test-Path (Split-Path $binDest))) {
        New-Item -ItemType Directory -Path (Split-Path $binDest) -Force | Out-Null
    }

    Copy-Item $binSrc $binDest -Force

    # Copy lib files
    $winLibDir = Join-Path $env:USERPROFILE 'bin\lib\gga'
    New-Item -ItemType Directory -Path $winLibDir -Force | Out-Null
    foreach ($lib in @('providers.sh', 'cache.sh', 'pr_mode.sh')) {
        $src = Join-Path $ggaRepo "lib\$lib"
        if (Test-Path $src) { Copy-Item $src (Join-Path $winLibDir $lib) -Force }
    }

    # Patch LIB_DIR and VERSION in the installed script
    $gitTag = & git -C $ggaRepo describe --tags --abbrev=0 2>$null
    if ($gitTag) { $version = $gitTag -replace '^v', '' } else { $version = 'dev' }

    $content = Get-Content $binDest -Raw -Encoding UTF8
    $content = $content -replace 'LIB_DIR=.*', "LIB_DIR=`"$libDir`""
    $content = $content -replace 'VERSION="\${GGA_VERSION:-dev}"', "VERSION=`"$version`""
    # Use UTF-8 without BOM to avoid breaking the shebang in Git Bash.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($binDest, $content, $utf8NoBom)

    # Verify
    $result = & $BashPath -c "$($installDir -replace ' ', '\ ')/gga --version" 2>&1
    if ($result -match 'gga') {
        Write-Ok "GGA updated: $result"
        return $true
    } else {
        Write-Warn "GGA installed but version check inconclusive: $result"
        return $true
    }
}

# ── Tool: Engram ───────────────────────────────────────────────────────────────
# Installed via: go install github.com/Gentleman-Programming/engram/cmd/engram@latest
# Binary lands in $GOPATH/bin/engram.exe

function Update-Engram {
    Write-Step "Updating Engram"

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would run: go install github.com/Gentleman-Programming/engram/cmd/engram@latest"
        return $true
    }

    Write-Info "Running: go install github.com/Gentleman-Programming/engram/cmd/engram@latest"
    go install github.com/Gentleman-Programming/engram/cmd/engram@latest 2>&1 | ForEach-Object { Write-Host "  $_" }

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Engram update failed (exit $LASTEXITCODE)"
        return $false
    }

    # Locate binary
    $goBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) { Join-Path $env:GOPATH 'bin' } else { Join-Path $env:USERPROFILE 'go\bin' }
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

# ── Tool: Gentle-AI ───────────────────────────────────────────────────────────
# Installed via: go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest
# Binary lands in $GOPATH/bin/gentle-ai.exe

function Update-GentleAI {
    Write-Step "Updating Gentle-AI"

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would run: go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest"
        return $true
    }

    Write-Info "Running: go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest"
    go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest 2>&1 | ForEach-Object { Write-Host "  $_" }

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Gentle-AI update failed (exit $LASTEXITCODE)"
        return $false
    }

    $goBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) { Join-Path $env:GOPATH 'bin' } else { Join-Path $env:USERPROFILE 'go\bin' }
    $gentleExe = Join-Path $goBin 'gentle-ai.exe'
    if (-not (Test-Path $gentleExe)) { $gentleExe = Join-Path $goBin 'gentle-ai' }

    if (Test-Path $gentleExe) {
        $ver = & $gentleExe --version 2>&1 | Select-Object -First 1
        Write-Ok "Gentle-AI updated: $ver"
        return $true
    }

    Write-Ok "Gentle-AI installed. Ensure $goBin is in your PATH."
    return $true
}

# ── Show current status ────────────────────────────────────────────────────────

function Show-ToolStatus {
    Write-Step "Current Tool Status"

    $goBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) { Join-Path $env:GOPATH 'bin' } else { Join-Path $env:USERPROFILE 'go\bin' }
    $gitBash = 'C:\Program Files\Git\bin\bash.exe'

    # GGA
    $ggaBin = Join-Path $env:USERPROFILE 'bin\gga'
    if (Test-Path $ggaBin) {
        if (Test-Path $gitBash) {
            $ver = & $gitBash -c "/c/Users/$env:USERNAME/bin/gga --version" 2>&1 | Select-Object -First 1
            Write-Ok "gga: $ver"
        } else {
            Write-Ok "gga: installed at $ggaBin (Git Bash not found to check version)"
        }
    } else {
        Write-Warn "gga: not installed"
    }

    # Engram
    $engramExe = Join-Path $goBin 'engram.exe'
    if (Test-Path $engramExe) {
        $ver = & $engramExe --version 2>&1 | Select-Object -First 1
        Write-Ok "engram: $ver"
    } else {
        Write-Warn "engram: not installed (expected at $engramExe)"
    }

    # Gentle-AI
    $gentleExe = Join-Path $goBin 'gentle-ai.exe'
    if (Test-Path $gentleExe) {
        $ver = & $gentleExe --version 2>&1 | Select-Object -First 1
        Write-Ok "gentle-ai: $ver"
    } else {
        Write-Warn "gentle-ai: not installed (expected at $gentleExe)"
    }

    Write-Host ""
    Write-Host "Install commands (Windows / no brew needed):" -ForegroundColor Gray
    Write-Host "  gga       : git clone + bash install.sh (gentleman-guardian-angel repo)" -ForegroundColor Gray
    Write-Host "  engram    : go install github.com/Gentleman-Programming/engram/cmd/engram@latest" -ForegroundColor Gray
    Write-Host "  gentle-ai : go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest" -ForegroundColor Gray
}

# ── Main ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Gentleman Foundation - Tool Updater" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY-RUN MODE]" -ForegroundColor Yellow }
Write-Host ""

Show-ToolStatus

$hasGo   = Test-Go
$bashExe = Test-GitBash

$results = @{}

if ($hasGo) {
    $results['engram']  = Update-Engram
    $results['gentle-ai'] = Update-GentleAI
} else {
    Write-Warn "Skipping engram and gentle-ai (Go not found)"
    $results['engram'] = $false
    $results['gentle-ai'] = $false
}

if ($bashExe) {
    $results['gga'] = Update-Gga -BashPath $bashExe
} else {
    Write-Warn "Skipping gga (Git Bash not found)"
    $results['gga'] = $false
}

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
