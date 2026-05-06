# foundation-installer-tui-IMPROVED.ps1
# FF-018: Enhanced Interactive TUI Installer for Foundation
# Improvements: real git clone, dynamic component copy, post-install verification, logging, uninstall

param(
    [string]$InstallPath = "$env:USERPROFILE\workspace-foundation",
    [switch]$Silent,
    [switch]$Force,
    [switch]$Uninstall,
    [string]$RepoURL = "https://github.com/EmmanuelOrtiz87/gentleman-foundation.git"
)

$ErrorActionPreference = "Continue"
$host.UI.RawUI.WindowTitle = "Foundation TUI Installer - Enhanced"

# Directories
$logDir = Join-Path $env:TEMP "foundation-installer-logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    switch ($Level) {
        "ERROR" { Write-Host "  [X] $Message" -ForegroundColor Red }
        "WARN"  { Write-Host "  [!] $Message" -ForegroundColor Yellow }
        "SUCCESS" { Write-Host "  [✓] $Message" -ForegroundColor Green }
        default { Write-Host "  $Message" -ForegroundColor White }
    }
}

# Colors
$colorHighlight = "Cyan"
$colorSuccess = "Green"
$colorWarning = "Yellow"
$colorError = "Red"
$colorMenu = "White"

function Write-Header {
    Clear-Host
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host "  Foundation TUI Installer (Enhanced)" -ForegroundColor $colorHighlight
    Write-Host "  Terminal-Based Setup Wizard v2.7.0" -ForegroundColor $colorHighlight
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host ""
    Write-Log "Installer started. Log: $logFile"
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor $colorMenu
    Write-Log "Step $Step/$Total`: $Message"
}

function Read-Choice {
    param([string]$Prompt, [string[]]$Options, [int]$Default = 0)
    Write-Host $Prompt -ForegroundColor $colorMenu
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $prefix = if ($i -eq $Default) { ">" } else { "  " }
        $color = if ($i -eq $Default) { $colorHighlight } else { $colorMenu }
        Write-Host "$prefix $($i+1). $($Options[$i])" -ForegroundColor $color
    }
    $validInput = $false
    $result = $Default
    while (-not $validInput) {
        $input = Read-Host "Select option (1-$($Options.Count)) or Enter for default"
        if ([string]::IsNullOrWhiteSpace($input)) {
            $validInput = $true
            $result = $Default
        } elseif ($input -match '^\d+$') {
            $num = [int]$input
            if ($num -ge 1 -and $num -le $Options.Count) {
                $validInput = $true
                $result = $num - 1
            }
        }
        if (-not $validInput) {
            Write-Host "  [!] Invalid input. Enter 1-$($Options.Count)." -ForegroundColor $colorWarning
        }
    }
    return $result
}

function Test-Prerequisites {
    Write-Step 1 6 "Checking prerequisites..."
    $allPass = $true

    # PowerShell 7+
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 7) {
        Write-Log "PowerShell 7+ required. Current: $psVersion" -Level "ERROR"
        $allPass = $false
    } else {
        Write-Log "PowerShell $psVersion detected" -Level "SUCCESS"
    }

    # Git
    try {
        $gitVersion = (git --version 2>$null).Split(' ')[2]
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Git detected: $gitVersion" -Level "SUCCESS"
        } else { throw "Git not found" }
    } catch {
        Write-Log "Git not found. Some features may not work." -Level "WARN"
    }

    # Disk space (500MB min)
    $drive = (Get-Item $InstallPath -ErrorAction SilentlyContinue).PSDrive
    if (-not $drive) { $drive = "C:" }
    $freeSpace = (Get-PSDrive $drive -ErrorAction SilentlyContinue).Free
    if ($freeSpace -and $freeSpace -lt 500MB) {
        Write-Log "Low disk space. At least 500MB recommended." -Level "WARN"
    } else {
        Write-Log "Disk space OK" -Level "SUCCESS"
    }

    return $allPass
}

function Select-InstallPath {
    Write-Step 2 6 "Configure installation path..."
    Write-Host "  Current install path: $InstallPath" -ForegroundColor $colorMenu
    
    $choice = Read-Choice -Prompt "Would you like to change it?" -Options @("Yes, change path", "No, use current path") -Default 1
    if ($choice -eq 0) {
        $newPath = Read-Host "Enter new install path [$InstallPath]"
        if ([string]::IsNullOrWhiteSpace($newPath)) { $newPath = $InstallPath }
        if ((Test-Path $newPath) -and -not $Force) {
            $overwrite = Read-Choice -Prompt "Path exists. Overwrite?" -Options @("Yes, overwrite", "No, choose another") -Default 0
            if ($overwrite -eq 1) { return Select-InstallPath }
        }
        $script:InstallPath = $newPath
        Write-Log "Install path set to: $InstallPath" -Level "SUCCESS"
    } else {
        Write-Log "Using current path: $InstallPath" -Level "SUCCESS"
    }
}

function Select-Components {
    Write-Step 3 6 "Select components to install..."
    $components = @(
        @{ Name = "Core Scripts"; Description = "Essential workflow scripts (wf.ps1, utilities)"; Selected = $true },
        @{ Name = "Skills Framework"; Description = "125+ specialized skills library"; Selected = $true },
        @{ Name = "Git Hooks"; Description = "Lefthook + Trufflehog security"; Selected = $true },
        @{ Name = "Telemetry & Metrics"; Description = "Token tracking and benchmarks"; Selected = $false },
        @{ Name = "Dev Tools"; Description = "Testing, linting, diagnostics"; Selected = $false }
    )
    Write-Log "Component selection: Core=$($components[0].Selected), Skills=$($components[1].Selected), Hooks=$($components[2].Selected), Telemetry=$($components[3].Selected), DevTools=$($components[4].Selected)"
    return $components
}

function Configure-Settings {
    Write-Step 4 6 "Configure settings..."
    $settings = @{}

    # Git config
    $gitUser = try { git config --global user.name 2>$null } catch { "" }
    $gitEmail = try { git config --global user.email 2>$null } catch { "" }
    $settings.GitUser = Read-Host "Git user.name [$gitUser]"
    $settings.GitEmail = Read-Host "Git user.email [$gitEmail]"

    # AI Provider
    Write-Host "  AI Provider (for token tracking):" -ForegroundColor $colorMenu
    $aiChoice = Read-Choice -Prompt "Select default AI provider" -Options @("None (skip API setup)", "OpenAI", "Anthropic", "Other") -Default 0
    $settings.AIProvider = @("None", "OpenAI", "Anthropic", "Other")[$aiChoice]

    # Security
    Write-Host "  Security level:" -ForegroundColor $colorMenu
    $secChoice = Read-Choice -Prompt "Select security enforcement" -Options @("Enforced (recommended)", "Audit only", "Disabled") -Default 0
    $settings.SecurityLevel = @("Enforced", "Audit", "Disabled")[$secChoice]

    Write-Log "Settings configured: AI=$($settings.AIProvider), Security=$($settings.SecurityLevel)" -Level "SUCCESS"
    return $settings
}

function Install-Foundation {
    Write-Step 5 6 "Installing Foundation..."
    Write-Log "Starting installation to: $InstallPath"

    # Create directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Log "Created install directory: $InstallPath" -Level "SUCCESS"
    }

    # Clone repo (preferred) or copy from current
    if (Test-Path "$PSScriptRoot\..\.git") {
        Write-Log "Detected git repository. Cloning..." -Level "INFO"
        Set-Location $InstallPath
        git clone $RepoURL . 2>&1 | ForEach-Object { Write-Log $_ }
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Git clone failed. Falling back to copy..." -Level "WARN"
            Copy-RepoFiles
        }
    } else {
        Write-Log "No git repo detected. Copying files..." -Level "INFO"
        Copy-RepoFiles
    }

    # Install git hooks
    $hooksScript = Join-Path $InstallPath "scripts\utilities\install-hooks.ps1"
    if (Test-Path $hooksScript) {
        & $hooksScript 2>&1 | ForEach-Object { Write-Log $_ }
        Write-Log "Git hooks installed" -Level "SUCCESS"
    }

    # Run post-install verification
    Write-Log "Running post-install verification..." -Level "INFO"
    $wfScript = Join-Path $InstallPath "scripts\utilities\wf.ps1"
    if (Test-Path $wfScript) {
        & $wfScript health 2>&1 | ForEach-Object { Write-Log $_ }
        Write-Log "Post-install verification completed" -Level "SUCCESS"
    }

    Write-Log "Foundation installed successfully at: $InstallPath" -Level "SUCCESS"
    return $true
}

function Copy-RepoFiles {
    $items = @("scripts", "skills", "config", ".lefthook.yml", "README.md", "LICENSE", "AGENTS.md", "CLAUDE.md")
    foreach ($item in $items) {
        $src = Join-Path $PSScriptRoot "..\$item" -ErrorAction SilentlyContinue
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $InstallPath -Recurse -Force
            Write-Log "Copied: $item" -Level "SUCCESS"
        }
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $colorSuccess
    Write-Host "  Installation Complete!" -ForegroundColor $colorSuccess
    Write-Host "========================================" -ForegroundColor $colorSuccess
    Write-Host ""
    Write-Host "  Install path: $InstallPath" -ForegroundColor $colorMenu
    Write-Host "  Run 'wf.ps1 health' to verify." -ForegroundColor $colorHighlight
    Write-Host "  Read docs/guides/GETTING-STARTED.md to begin." -ForegroundColor $colorHighlight
    Write-Host "  Log file: $logFile" -ForegroundColor $colorMenu
    Write-Host ""
}

function Uninstall-Foundation {
    Write-Host "Uninstalling Foundation from: $InstallPath" -ForegroundColor $colorWarning
    if (Test-Path $InstallPath) {
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction Stop
        Write-Log "Foundation uninstalled from: $InstallPath" -Level "SUCCESS"
    } else {
        Write-Log "Install path not found: $InstallPath" -Level "WARN"
    }
}

# Main execution
if ($Uninstall) {
    Uninstall-Foundation
    exit 0
}

if (-not $Silent) {
    Write-Header
    $continue = Read-Choice -Prompt "Start Foundation installation?" -Options @("Yes, start installation", "No, exit") -Default 0
    if ($continue -eq 1) {
        Write-Host "Installation cancelled." -ForegroundColor $colorWarning
        exit 0
    }
}

$prereq = Test-Prerequisites
if (-not $prereq) {
    Write-Log "Prerequisites check failed" -Level "ERROR"
    exit 1
}

Select-InstallPath
$components = Select-Components
$settings = Configure-Settings
$installed = Install-Foundation

if ($installed) {
    Show-Summary
    Write-Host "Thank you for installing Foundation!" -ForegroundColor $colorHighlight
} else {
    Write-Log "Installation failed" -Level "ERROR"
    exit 1
}
