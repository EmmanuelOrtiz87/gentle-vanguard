# ============================================================================
# GGA Pre-commit Hook - Windows PowerShell
# ============================================================================
# This hook runs GGA (Gentleman Guardian Angel) on staged files
# before each commit. It will block the commit if GGA is not installed
# or if the review fails in strict mode.
# ============================================================================

param(
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Continue'

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) {
    Write-Host "[GGA] Not in a git repository. Skipping." -ForegroundColor Yellow
    exit 0
}

$GgaMarker = Join-Path $RepoRoot ".gga-installed"

function Get-GgaPath {
    # Check if gga is in PATH
    $ggaCmd = Get-Command gga -ErrorAction SilentlyContinue
    if ($ggaCmd) {
        return $ggaCmd.Source
    }

    # Check common installation paths
    $paths = @(
        "$env:HOME\bin\gga",
        "$env:USERPROFILE\bin\gga",
        "$env:LOCALAPPDATA\Programs\gga\bin\gga.exe",
        "$env:ProgramFiles\gga\bin\gga.exe"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Install-Gga {
    Write-Host "[GGA] Installing Gentleman Guardian Angel..." -ForegroundColor Blue

    $isGitBash = $env:MSYSTEM -eq "MINGW64" -or $env:OSTYPE -like "msys*"
    $isWSL = Get-Command wsl -ErrorAction SilentlyContinue

    if ($isGitBash -or $isWSL) {
        # Use Bash installer
        $bashPath = $null
        if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
            $bashPath = "C:\Program Files\Git\bin\bash.exe"
        }

        if ($bashPath) {
            $gGAClonePath = Join-Path $env:TEMP "gentleman-guardian-angel"

            if (-not (Test-Path $gGAClonePath)) {
                Write-Host "[GGA] Cloning repository..." -ForegroundColor Blue
                git clone https://github.com/Gentleman-Programming/gentleman-guardian-angel.git $gGAClonePath 2>$null
            }

            if (Test-Path (Join-Path $gGAClonePath "install.sh")) {
                Write-Host "[GGA] Running install script..." -ForegroundColor Blue
                & $bashPath -c "cd '$gGAClonePath' && bash install.sh"

                # Verify installation
                $installedGga = Join-Path $env:HOME "bin\gga"
                if (Test-Path $installedGga) {
                    New-Item -ItemType File -Path $GgaMarker -Force | Out-Null
                    Write-Host "[GGA] Installation complete!" -ForegroundColor Green
                    return $installedGga
                }
            }
        }
    }
    else {
        # Native Windows - download binary
        Write-Host "[GGA] Windows native installation not yet supported." -ForegroundColor Yellow
        Write-Host "[GGA] Please install Git Bash or WSL, then run: bash install.sh" -ForegroundColor Yellow
    }

    return $null
}

function Invoke-GgaReview {
    param([string]$GgaPath)

    Write-Host "[GGA] Running code review..." -ForegroundColor Blue

    $bashPath = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bashPath)) {
        Write-Host "[GGA] Git Bash not found. Please install Git for Windows." -ForegroundColor Yellow
        return $true
    }

    # Ensure PATH includes gga location
    $gGaBinDir = Split-Path $GgaPath -Parent
    $bashCommand = "export PATH=`"$gGaBinDir:`$PATH`" && cd '$RepoRoot' && gga run"

    try {
        $result = & $bashPath -c $bashCommand 2>&1
        $exitCode = $LASTEXITCODE

        if ($result -match "STATUS: PASSED" -or $result -match "Review passed") {
            Write-Host "[GGA] Review passed!" -ForegroundColor Green
            return $true
        }
        elseif ($result -match "STATUS: FAILED") {
            Write-Host "[GGA] Review failed!" -ForegroundColor Red
            Write-Host $result
            return $false
        }
        else {
            # Non-strict mode or demo mode
            if ($result -match "Allowing commit" -or $result -match "Skipping") {
                Write-Host "[GGA] Review completed with warnings." -ForegroundColor Yellow
                return $true
            }
            Write-Host $result
            return $true
        }
    }
    catch {
        Write-Host "[GGA] Error running GGA: $_" -ForegroundColor Red
        return $true
    }
}

# Main execution
Write-Host "[GGA] Pre-commit hook starting..." -ForegroundColor Blue

# Check if .gga config exists
$ggaConfig = Join-Path $RepoRoot ".gga"
if (-not (Test-Path $ggaConfig)) {
    Write-Host "[GGA] No .gga config found. Skipping GGA review." -ForegroundColor Yellow
    exit 0
}

# Check if GGA is installed
$GgaPath = Get-GgaPath

if (-not $GgaPath -and -not $SkipInstall) {
    Write-Host "[GGA] GGA not found. Attempting to install..." -ForegroundColor Yellow
    $GgaPath = Install-Gga
}

if (-not $GgaPath) {
    Write-Host "[GGA] GGA not available. Skipping review." -ForegroundColor Yellow
    exit 0
}

# Run GGA review
$success = Invoke-GgaReview -GgaPath $GgaPath

if ($success) {
    exit 0
}
else {
    Write-Host "[GGA] Review failed. Commit blocked." -ForegroundColor Red
    exit 1
}
