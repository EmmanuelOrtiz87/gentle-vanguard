# gentle-vanguard-installer-tui.ps1
# FF-018: Interactive TUI Installer for Gentle-Vanguard
# Terminal-Based Setup Wizard with Logo, Help, and Quit support

param(
    [string]$InstallPath = "$(if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME })\gentle-vanguard",
    [switch]$Silent,
    [switch]$Force,
    [switch]$Uninstall,
    [string]$RepoURL = "https://github.com/EmmanuelOrtiz87/gentle-vanguard.git"
)

$ErrorActionPreference = "Continue"
$script:homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$host.UI.RawUI.WindowTitle = "Gentle-Vanguard TUI Installer - Enhanced"

# Directories
$logDir = Join-Path $env:TEMP "gentle-vanguard-installer-logs"
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
        "SUCCESS" { Write-Host "  [[OK]] $Message" -ForegroundColor Green }
        default { Write-Host "  $Message" -ForegroundColor White }
    }
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    if ($env:GENTLE_VANGUARD_VERBOSE -ne "1") { return }
    Write-Host "[$Step/$Total] $Message" -ForegroundColor $colorMenu
    Write-Log "Step $Step/$Total`: $Message"
}

# Colors
$colorHighlight = "Cyan"
$colorSuccess = "Green"
$colorWarning = "Yellow"
$colorError = "Red"
$colorMenu = "White"

function Write-Header {
    Clear-Host
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host ""
    Write-Host " ██████╗ ███████╗███╗   ██╗████████╗██╗     ███████╗    ██╗   ██╗ █████╗ ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ " -ForegroundColor Cyan
    Write-Host "██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██║     ██╔════╝    ██║   ██║██╔══██╗████╗  ██║██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗" -ForegroundColor Cyan
    Write-Host "██║  ███╗█████╗  ██╔██╗ ██║   ██║   ██║     █████╗      ██║   ██║███████║██╔██╗ ██║██║  ███╗██║   ██║███████║██████╔╝██║  ██║" -ForegroundColor Cyan
    Write-Host "██║   ██║██╔══╝  ██║╚██╗██║   ██║   ██║     ██╔══╝      ╚██╗ ██╔╝██╔══██║██║╚██╗██║██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║" -ForegroundColor Cyan
    Write-Host "╚██████╔╝███████╗██║  ████║   ██║   ██║███████╗███████╗   ╚████╔╝ ██║  ██║██║  ████║╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝" -ForegroundColor Cyan
    Write-Host " ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚══════╝╚══════╝    ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "           -- NATIVE AI COGNITIVE DEVELOPMENT ECOSYSTEM --" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "            Terminal-Based Setup Wizard" -ForegroundColor White
    Write-Host "                  v2.8.0" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host "  [Q] Quit anytime | [H] Help/Commands" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host ""
}

# Write-Step is defined earlier in the file (around line 60)

function Show-Help {
    Write-Header
    Write-Host "  AVAILABLE COMMANDS & SHORTCUTS" -ForegroundColor $colorHighlight
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host "  [Q] [q]       - Quit installer immediately" -ForegroundColor Yellow
    Write-Host "  [H] [h]       - Show this help screen" -ForegroundColor Yellow
    Write-Host "  [Enter]        - Accept default option" -ForegroundColor White
    Write-Host "  1,2,3...       - Select menu option by number" -ForegroundColor White
    Write-Host ""
    Write-Host "  NAVIGATION" -ForegroundColor $colorHighlight
    Write-Host "  - Every menu allows 'Q' to quit" -ForegroundColor Gray
    Write-Host "  - 'H' shows help from any prompt" -ForegroundColor Gray
    Write-Host "  - Enter accepts the default (>) option" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  INSTALLATION PATHS" -ForegroundColor $colorHighlight
    Write-Host "  - Default: $script:homePath\gentle-vanguard" -ForegroundColor Gray
    Write-Host "  - Change it in Step 2 of installer" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  LOGS" -ForegroundColor $colorHighlight
    Write-Host "  - Location: $logDir" -ForegroundColor Gray
    Write-Host "  - Current: $(Split-Path $logFile -Leaf)" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

function Read-Choice {
    param([string]$Prompt, [string[]]$Options, [int]$Default = 0, [switch]$AllowQuit)
    Write-Host $Prompt -ForegroundColor $colorMenu
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $prefix = if ($i -eq $Default) { ">" } else { "  " }
        $color = if ($i -eq $Default) { $colorHighlight } else { $colorMenu }
        Write-Host "$prefix $($i+1). $($Options[$i])" -ForegroundColor $color
    }
    if ($AllowQuit) {
        Write-Host "  0. Quit / Exit" -ForegroundColor Red
    } else {
        Write-Host "  [Q] Quit | [H] Help" -ForegroundColor Yellow
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
            if ($num -eq 0 -and $AllowQuit) { exit 0 }
            if ($num -ge 1 -and $num -le $Options.Count) {
                $validInput = $true
                $result = $num - 1
            }
        } elseif ($input -match '^[Qq]$') {
            Write-Host "  [!] Quitting Gentle-Vanguard TUI..." -ForegroundColor Yellow
            exit 0
        } elseif ($input -match '^[Hh]$') {
            Show-Help
            return Read-Choice -Prompt $Prompt -Options $Options -Default $Default -AllowQuit:$AllowQuit
        }
        if (-not $validInput) {
            Write-Host "  [!] Invalid input. Enter 1-$($Options.Count), Q=Quit, H=Help." -ForegroundColor $colorWarning
        }
    }
    return $result
}

function Read-Input {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [switch]$Required
    )
    $suffix = if ($Default) { " [$Default]" } else { "" }
    $input = Read-Host "$Prompt$suffix"
    
    if ([string]::IsNullOrWhiteSpace($input) -and $Default) {
        return $Default
    }
    
    if ($Required -and [string]::IsNullOrWhiteSpace($input)) {
        Write-Warning "This field is required."
        return Read-Input -Prompt $Prompt -Default $Default -Required:$Required
    }
    
    return $input
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
        $newPath = Read-Input -Prompt "Enter new install path" -Default $InstallPath
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
        @{ Name = "Core Scripts"; Description = "Essential workflow scripts"; Selected = $true },
        @{ Name = "Skills Framework"; Description = "125+ skills library"; Selected = $true },
        @{ Name = "Git Hooks"; Description = "Lefthook + Trufflehog security"; Selected = $true },
        @{ Name = "Telemetry & Metrics"; Description = "Token tracking and benchmarks"; Selected = $false },
        @{ Name = "Dev Tools"; Description = "Testing, linting, diagnostics"; Selected = $false }
    )
    Write-Log "Component selection: Core=$($components[0].Selected), Skills=$($components[1].Selected), Hooks=$($components[2].Selected)"
    return $components
}

function Configure-Settings {
    Write-Step 4 6 "Configure settings..."
    $settings = @{}

    # Git config
    $gitUser = try { git config --global user.name 2>$null } catch { "" }
    $gitEmail = try { git config --global user.email 2>$null } catch { "" }
    $settings.GitUser = Read-Input -Prompt "Git user.name" -Default $gitUser
    $settings.GitEmail = Read-Input -Prompt "Git user.email" -Default $gitEmail

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

function Install-Gentle-Vanguard {
    Write-Step 5 6 "Installing Gentle-Vanguard..."
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

    # Optional: Install Go (needed for Engram)
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        $installGo = Read-Choice -Prompt "Install Go (required for Engram persistent memory)?" -Options @("Yes, install Go", "No, skip") -Default 1
        if ($installGo -eq 0) {
            try {
                Write-Log "Installing Go via winget..." -Level "INFO"
                & winget install GoLang.Go --accept-package-agreements --silent 2>&1 | ForEach-Object { Write-Log $_ }
                $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
                Write-Log "Go installed. You may need to restart your terminal." -Level "SUCCESS"
            } catch {
                Write-Log "Go installation failed: $($_.Exception.Message)" -Level "WARN"
                Write-Log "Install manually: winget install GoLang.Go or https://go.dev/dl/" -Level "INFO"
            }
        }
    } else {
        Write-Log "Go already installed" -Level "SUCCESS"
    }

    # Optional: Install Engram (persistent memory)
    if (-not (Get-Command engram -ErrorAction SilentlyContinue)) {
        if (Get-Command go -ErrorAction SilentlyContinue) {
            $installEngram = Read-Choice -Prompt "Install Engram (persistent memory engine)?" -Options @("Yes, install Engram", "No, skip") -Default 1
            if ($installEngram -eq 0) {
                try {
                    Write-Log "Installing Engram via go install..." -Level "INFO"
                    & go install github.com/gentle-vanguard/engram/cmd/engram@latest 2>&1 | ForEach-Object { Write-Log $_ }
                    Write-Log "Engram installed. Configure with: engram setup <agent>" -Level "SUCCESS"
                } catch {
                    Write-Log "Engram installation failed: $($_.Exception.Message)" -Level "WARN"
                }
            }
        } else {
            Write-Log "Engram requires Go. Install Go first then run: go install github.com/gentle-vanguard/engram/cmd/engram@latest" -Level "INFO"
        }
    } else {
        Write-Log "Engram already installed" -Level "SUCCESS"
    }

    # Run post-install verification
    Write-Log "Running post-install verification..." -Level "INFO"
    $wfScript = Join-Path $InstallPath "scripts\utilities\gv.ps1"
    if (Test-Path $wfScript) {
        & $wfScript health 2>&1 | ForEach-Object { Write-Log $_ }
        Write-Log "Post-install verification completed" -Level "SUCCESS"
    }

    Write-Log "Gentle-Vanguard installed successfully at: $InstallPath" -Level "SUCCESS"
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
    Write-Host "  Run 'gv.ps1 health' to verify." -ForegroundColor $colorHighlight
    Write-Host "  Read docs/guides/GETTING-STARTED.md to begin." -ForegroundColor $colorHighlight
    Write-Host "  Log file: $logFile" -ForegroundColor $colorMenu
    Write-Host ""
}

function Uninstall-Gentle-Vanguard {
    Write-Host "Uninstalling Gentle-Vanguard from: $InstallPath" -ForegroundColor $colorWarning
    if (Test-Path $InstallPath) {
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction Stop
        Write-Log "Gentle-Vanguard uninstalled from: $InstallPath" -Level "SUCCESS"
    } else {
        Write-Log "Install path not found: $InstallPath" -Level "WARN"
    }
}

# Main execution
if ($Uninstall) {
    Uninstall-Gentle-Vanguard
    exit 0
}

if (-not $Silent) {
    Write-Header
    $continue = Read-Choice -Prompt "Start Gentle-Vanguard installation?" -Options @("Yes, start installation", "No, exit") -Default 0 -AllowQuit
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
$installed = Install-Gentle-Vanguard

if ($installed) {
    Show-Summary
    Write-Host "Thank you for installing Gentle-Vanguard!" -ForegroundColor $colorHighlight
} else {
    Write-Log "Installation failed" -Level "ERROR"
    exit 1
}

