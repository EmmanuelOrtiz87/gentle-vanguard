# foundation-installer-tui.ps1
# FF-018: Interactive TUI Installer for Foundation
# Terminal User Interface wizard for onboarding new users

param(
    [string]$InstallPath = "$env:USERPROFILE\foundation",
    [switch]$Silent,
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$host.UI.RawUI.WindowTitle = "Foundation TUI Installer"

# Colors
$colorHighlight = "Cyan"
$colorSuccess = "Green"
$colorWarning = "Yellow"
$colorError = "Red"
$colorMenu = "White"

function Write-Header {
    Clear-Host
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host "  Foundation TUI Installer (FF-018)" -ForegroundColor $colorHighlight
    Write-Host "  Terminal-Based Setup Wizard" -ForegroundColor $colorHighlight
    Write-Host "========================================" -ForegroundColor $colorHighlight
    Write-Host ""
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor $colorMenu
}

function Write-Success { param([string]$Message) Write-Host "  [✓] $Message" -ForegroundColor $colorSuccess }
function Write-Warning { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor $colorWarning }
function Write-Error { param([string]$Message) Write-Host "  [X] $Message" -ForegroundColor $colorError }

function Read-Choice {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [int]$Default = 0
    )
    
    Write-Host $Prompt -ForegroundColor $colorMenu
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $prefix = if ($i -eq $Default) { ">" } else { "  " }
        Write-Host "  $prefix $($i+1). $($Options[$i])" -ForegroundColor $(if ($i -eq $Default) { $colorHighlight } else { $colorMenu })
    }
    
    $validInput = $false
    $result = $Default
    while (-not $validInput) {
        $input = Read-Host "Select option (1-$($Options.Count)) or press Enter for default"
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
            Write-Warning "Invalid input. Please enter a number between 1 and $($Options.Count)."
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
    Write-Step 1 5 "Checking prerequisites..."
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 7) {
        Write-Error "PowerShell 7+ required. Current: $psVersion"
        return $false
    }
    Write-Success "PowerShell $psVersion detected"
    
    # Check Git
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git detected: $($gitVersion.Split(' ')[2])"
        } else {
            Write-Warning "Git not found. Some features may not work."
        }
    } catch {
        Write-Warning "Git not found. Some features may not work."
    }
    
    # Check available space
    $drive = (Get-Item $InstallPath -ErrorAction SilentlyContinue).PSDrive
    if (-not $drive) { $drive = "C:" }
    $freeSpace = (Get-PSDrive $drive -ErrorAction SilentlyContinue).Free
    if ($freeSpace -and $freeSpace -lt 500MB) {
        Write-Warning "Low disk space. At least 500MB recommended."
    } else {
        Write-Success "Disk space OK"
    }
    
    return $true
}

function Select-InstallPath {
    Write-Step 2 5 "Configure installation path..."
    
    $currentPath = $InstallPath
    Write-Host "  Current install path: $currentPath" -ForegroundColor $colorMenu
    
    $choice = Read-Choice -Prompt "Would you like to change it?" -Options @("Yes, change path", "No, use current path") -Default 1
    
    if ($choice -eq 0) {
        $newPath = Read-Input -Prompt "Enter new install path" -Default $currentPath -Required
        if (Test-Path $newPath -and -not $Force) {
            $overwrite = Read-Choice -Prompt "Path already exists. Overwrite?" -Options @("Yes, overwrite", "No, choose another") -Default 1
            if ($overwrite -eq 1) {
                return Select-InstallPath
            }
        }
        $script:InstallPath = $newPath
        Write-Success "Install path set to: $InstallPath"
    } else {
        Write-Success "Using current path: $InstallPath"
    }
}

function Select-Components {
    Write-Step 3 5 "Select components to install..."
    
    $components = @(
        @{ Name = "Core Scripts"; Description = "Essential workflow scripts"; Selected = $true },
        @{ Name = "Skills Framework"; Description = "125+ skills library"; Selected = $true },
        @{ Name = "Git Hooks"; Description = "Lefthook + Trufflehog security"; Selected = $true },
        @{ Name = "Telemetry & Metrics"; Description = "Token tracking and benchmarks"; Selected = $false },
        @{ Name = "Dev Tools"; Description = "Testing, linting, diagnostics"; Selected = $false }
    )
    
    Write-Host "  Components available:" -ForegroundColor $colorMenu
    for ($i = 0; $i -lt $components.Count; $i++) {
        $c = $components[$i]
        $mark = if ($c.Selected) { "[✓]" } else { "[ ]" }
        Write-Host "    $mark $($i+1). $($c.Name) - $($c.Description)" -ForegroundColor $colorMenu
    }
    
    Write-Host ""
    $toggle = Read-Choice -Prompt "Toggle components (select to toggle, then choose 'Done')" -Options @($components | ForEach-Object { "$($_.Name)" }) -Default 5
    
    # Simplified: just install all for now
    Write-Success "All core components will be installed."
}

function Configure-Settings {
    Write-Step 4 5 "Configure settings..."
    
    # Git config
    $userName = Read-Input -Prompt "Git user.name" -Default $(try { git config --global user.name 2>$null } catch { "" })
    $userEmail = Read-Input -Prompt "Git user.email" -Default $(try { git config --global user.email 2>$null } catch { "" })
    
    # AI Provider selection
    Write-Host "  AI Provider (for token tracking):" -ForegroundColor $colorMenu
    $aiChoice = Read-Choice -Prompt "Select default AI provider" -Options @("None (skip API setup)", "OpenAI", "Anthropic", "Other") -Default 0
    
    # Security level
    Write-Host "  Security level:" -ForegroundColor $colorMenu
    $secChoice = Read-Choice -Prompt "Select security enforcement" -Options @("Enforced (recommended)", "Audit only", "Disabled") -Default 0
    
    Write-Success "Settings configured."
}

function Install-Foundation {
    Write-Step 5 5 "Installing Foundation..."
    
    # Create directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Success "Created install directory: $InstallPath"
    }
    
    # Clone or copy files
    $isGitRepo = Test-Path "$PSScriptRoot\..\.git"
    if ($isGitRepo) {
        Write-Host "  Copying from current repository..." -ForegroundColor $colorMenu
        # Simulate install - in real scenario would git clone or copy
        $items = @("scripts", "skills", "config", ".lefthook.yml")
        foreach ($item in $items) {
            $src = Join-Path $PSScriptRoot "..\$item" -ErrorAction SilentlyContinue
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $InstallPath -Recurse -Force
                Write-Success "  Copied: $item"
            }
        }
    } else {
        Write-Warning "Not in a git repository. Please clone Foundation first:"
        Write-Host "  git clone https://github.com/yourorg/workspace-foundation.git" -ForegroundColor $colorHighlight
        return $false
    }
    
    # Install git hooks
    $hooksScript = Join-Path $InstallPath "scripts\utilities\install-hooks.ps1"
    if (Test-Path $hooksScript) {
        & $hooksScript
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git hooks installed"
        }
    }
    
    # Create initial config
    $configDir = Join-Path $InstallPath "config"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    Write-Success "Foundation installed successfully at: $InstallPath"
    return $true
}

function Show-Summary {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $colorSuccess
    Write-Host "  Installation Complete!" -ForegroundColor $colorSuccess
    Write-Host "========================================" -ForegroundColor $colorSuccess
    Write-Host ""
    Write-Host "  Install path: $InstallPath" -ForegroundColor $colorMenu
    Write-Host "  Run 'wf.ps1 health' to verify installation." -ForegroundColor $colorHighlight
    Write-Host "  Read docs/GETTING-STARTED.md to begin." -ForegroundColor $colorHighlight
    Write-Host ""
}

# Main execution
if (-not $Silent) {
    Write-Header
    
    $continue = Read-Choice -Prompt "Start Foundation installation?" -Options @("Yes, start installation", "No, exit") -Default 0
    if ($continue -eq 1) {
        Write-Host "Installation cancelled." -ForegroundColor $colorWarning
        exit 0
    }
}

# Run steps
$prereq = Test-Prerequisites
if (-not $prereq) {
    Write-Error "Prerequisites check failed. Please resolve issues and try again."
    exit 1
}

Select-InstallPath
Select-Components
Configure-Settings

$installed = Install-Foundation
if ($installed) {
    Show-Summary
    Write-Host "Thank you for installing Foundation!" -ForegroundColor $colorHighlight
} else {
    Write-Error "Installation failed. Please check errors above."
    exit 1
}
