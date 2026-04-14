# update-tools.ps1
# Updates all foundation tools on the local machine.
#
# Tool installation on Windows:
#   gga              - bash install.sh (Git Bash required, gentleman-guardian-angel repo)
#   engram           - go install github.com/Gentleman-Programming/engram/cmd/engram@latest
#   gentle-ai        - go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest
#   gentleman-skills - git clone / pull https://github.com/Gentleman-Programming/Gentleman-Skills.git
#   opencode         - irm https://opencode.ai/install | iex  (requires -Force to auto-run)
#
# brew is NOT required on Windows. All Go tools install via go install.

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

function Get-GoBinDir {
    if ($env:GOBIN)  { return $env:GOBIN }
    if ($env:GOPATH) { return Join-Path $env:GOPATH 'bin' }
    return Join-Path $env:USERPROFILE 'go\bin'
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

# ── Tool: Gentleman-Skills ────────────────────────────────────────────────────
# Installed via: git clone https://github.com/Gentleman-Programming/Gentleman-Skills.git {toolsRoot}/Gentleman-Skills
# Update via: git pull --ff-only

function Update-GentlemanSkills {
    Write-Step "Updating Gentleman-Skills"

    $toolsRoot = Get-ToolsRoot
    $skillsDir = Join-Path $toolsRoot 'Gentleman-Skills'
    $repoUrl   = 'https://github.com/Gentleman-Programming/Gentleman-Skills.git'

    if (Test-Path $skillsDir) {
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would run: git pull --ff-only in $skillsDir"
            return $true
        }
        Write-Info "Pulling latest Gentleman-Skills..."
        Push-Location $skillsDir
        try {
            git pull --ff-only origin main 2>&1 | ForEach-Object { Write-Host "  $_" }
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Gentleman-Skills up to date"
                return $true
            } else {
                Write-Warn "Gentleman-Skills pull returned exit $LASTEXITCODE"
                return $false
            }
        } finally {
            Pop-Location
        }
    } else {
        if ($DryRun) {
            Write-Info "[DRY-RUN] Would clone: $repoUrl → $skillsDir"
            return $true
        }
        Write-Info "Cloning Gentleman-Skills..."
        $parent = Split-Path -Parent $skillsDir
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        git clone $repoUrl $skillsDir 2>&1 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Gentleman-Skills cloned"
            return $true
        } else {
            Write-Err "Gentleman-Skills clone failed"
            return $false
        }
    }
}

# ── Tool: OpenCode ─────────────────────────────────────────────────────────────
# Installed via: irm https://opencode.ai/install | iex
# NOTE: The installer downloads and executes a remote script.
#       Auto-install requires explicit -Force flag to avoid unintended network calls.

function Check-Opencode {
    Write-Step "Checking OpenCode"

    $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
    if ($opencodeCmd) {
        $ver = & $opencodeCmd.Source --version 2>&1 | Select-Object -First 1
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
            Invoke-Expression "irm https://opencode.ai/install | iex" 2>&1 | Out-Null
            $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
            if ($opencodeCmd) { Write-Ok "opencode installed"; return $true }
            Write-Warn "opencode installer ran but binary not found — restart terminal"
            return $false
        } catch {
            Write-Err "opencode install failed: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Host "  To install: irm https://opencode.ai/install | iex" -ForegroundColor Gray
        Write-Host "  Or run:     .\scripts\utilities\wf.ps1 update-tools -Force" -ForegroundColor Gray
        return $false
    }
}

function Show-ToolStatus {
    Write-Step "Current Tool Status"

    $goBin     = Get-GoBinDir
    $toolsRoot = Get-ToolsRoot
    $gitBash   = 'C:\Program Files\Git\bin\bash.exe'

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

    # Gentleman-Skills
    $skillsDir = Join-Path $toolsRoot 'Gentleman-Skills'
    if (Test-Path $skillsDir) {
        $branch = git -C $skillsDir rev-parse --abbrev-ref HEAD 2>$null
        Write-Ok "gentleman-skills: $skillsDir (branch: $branch)"
    } else {
        Write-Warn "gentleman-skills: not cloned (expected at $skillsDir)"
    }

    # OpenCode
    $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
    if ($opencodeCmd) {
        $ver = & $opencodeCmd.Source --version 2>&1 | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($ver)) { $ver = 'installed' }
        Write-Ok "opencode: $ver"
    } else {
        Write-Warn "opencode: not installed"
    }

    Write-Host ""
    Write-Host "Install commands (Windows / no brew needed):" -ForegroundColor Gray
    Write-Host "  gga       : git clone + bash install.sh (gentleman-guardian-angel repo)" -ForegroundColor Gray
    Write-Host "  engram    : go install github.com/Gentleman-Programming/engram/cmd/engram@latest" -ForegroundColor Gray
    Write-Host "  gentle-ai : go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest" -ForegroundColor Gray
    Write-Host "  gentleman-skills: git clone https://github.com/Gentleman-Programming/Gentleman-Skills.git" -ForegroundColor Gray
    Write-Host "  opencode  : irm https://opencode.ai/install | iex  (or wf.ps1 update-tools -Force)" -ForegroundColor Gray
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

$results['gentleman-skills'] = Update-GentlemanSkills
$results['opencode']         = Check-Opencode

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
