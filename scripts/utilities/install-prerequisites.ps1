# install-prerequisites.ps1
# Instala automticamente las herramientas requeridas para Foundation
# Ejecucin: .\scripts\utilities\install-prerequisites.ps1

param(
    [switch]$Force,
    [switch]$Silent,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    return ($null -ne $command)
}

function Test-Installed {
    param([string]$Name, [string]$Type)
    
    switch ($Type) {
        "npm" {
            $result = npm list -g --depth=0 2>$null | Out-String
            return ($result -imatch $Name)
        }
        "choco" {
            $result = choco list --local-only $Name 2>$null
            return ($result -imatch $Name)
        }
        "pip" {
            $result = pip show $Name 2>$null
            return ($LASTEXITCODE -eq 0)
        }
        default {
            return Test-Command $Name
        }
    }
}

function Install-Tool {
    param(
        [string]$Name,
        [string]$InstallCommand,
        [string]$Type,
        [string]$Description
    )
    
    if (-not $Silent) {
        Write-Step "Installing $Name..."
    }
    
    try {
        if ($Type -eq "npm") {
            Invoke-Expression $InstallCommand
        } elseif ($Type -eq "choco") {
            Invoke-Expression "choco install $Name -y"
        } elseif ($Type -eq "pip") {
            Invoke-Expression $InstallCommand
        } elseif ($Type -eq "git") {
            Invoke-Expression $InstallCommand
        } else {
            Invoke-Expression $InstallCommand
        }
        
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            if (-not $Silent) { Write-Ok "$Name installed" }
            return $true
        }
    } catch {
        $errorMsg = $_.Exception.Message
        if (-not $Silent) { Write-Warn "$Name : $errorMsg" }
    }
    
    return $false
}

Write-Host ""
Write-Host "=== Foundation Prerequisites Installer ===" -ForegroundColor Cyan
Write-Host ""

$prerequisites = @(
    @{
        Name = "Node.js"
        Type = "command"
        Command = "node"
        Description = "JavaScript runtime"
        Required = $true
    },
    @{
        Name = "npm"
        Type = "command"
        Command = "npm"
        Description = "Node package manager"
        Required = $true
    },
    @{
        Name = "Git"
        Type = "command"
        Command = "git"
        Description = "Version control"
        Required = $true
    },
    @{
        Name = "PowerShell"
        Type = "command"
        Command = "pwsh"
        Description = "PowerShell Core"
        Required = $false
    },
    @{
        Name = "lefthook"
        Type = "npm"
        InstallCommand = "npm install -g lefthook"
        Description = "Git hooks management"
        Required = $false
    },
    @{
        Name = "prettier"
        Type = "npm"
        InstallCommand = "npm install -g prettier"
        Description = "Code formatting"
        Required = $false
    },
    @{
        Name = "commitlint"
        Type = "npm"
        InstallCommand = "npm install -g @commitlint/cli @commitlint/config-conventional"
        Description = "Commit message validation"
        Required = $false
    },
    @{
        Name = "trufflehog"
        Type = "manual"
        InstallCommand = "choco install trufflehog"
        Description = "Secrets detection"
        Required = $false
        ManualHint = "choco install trufflehog"
        AlternativeCheck = { $null -ne (Get-Command trufflehog -ErrorAction SilentlyContinue) }
    },
    @{
        Name = "Python"
        Type = "command"
        Command = "python"
        Description = "Python runtime (optional)"
        Required = $false
    },
    @{
        Name = "pip"
        Type = "command"
        Command = "pip"
        Description = "Python package manager (optional)"
        Required = $false
    }
)

$missing = @()
$installed = @()

if ($CheckOnly) {
    Write-Step "Checking prerequisites..."
    Write-Host ""
}

foreach ($tool in $prerequisites) {
    $isInstalled = $false
    
    if ($tool.Type -eq "command") {
        $isInstalled = Test-Command $tool.Command
    } elseif ($tool.Type -eq "npm") {
        $isInstalled = Test-Installed $tool.Name "npm"
    } elseif ($tool.Type -eq "choco") {
        $isInstalled = Test-Installed $tool.Name "choco"
    } elseif ($tool.Type -eq "pip") {
        $isInstalled = Test-Installed $tool.Name "pip"
    } elseif ($tool.Type -eq "manual" -and $tool.AlternativeCheck) {
        $isInstalled = & $tool.AlternativeCheck
    }
    
    if ($isInstalled) {
        $installed += $tool.Name
        if (-not $Silent) {
            Write-Ok "$($tool.Name) - $($tool.Description)"
        }
    } else {
        if ($tool.Required) {
            $missing += $tool
            Write-Warn "$($tool.Name) (REQUIRED) - $($tool.Description)"
        } else {
            if (-not $Silent) {
                Write-Warn "$($tool.Name) - $($tool.Description) [optional]"
            }
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Installed: $($installed.Count)" -ForegroundColor Green
Write-Host "Missing: $($missing.Count)" -ForegroundColor $(if ($missing.Count -gt 0) { "Yellow" } else { "Green" })

if ($missing.Count -gt 0 -and -not $CheckOnly) {
    Write-Host ""
    Write-Step "Installing missing tools..."
    
    foreach ($tool in $missing) {
        if ($tool.Name -eq "lefthook") {
            Install-Tool -Name $tool.Name -InstallCommand "npm install -g lefthook" -Type npm -Description $tool.Description
        } elseif ($tool.Name -eq "prettier") {
            Install-Tool -Name $tool.Name -InstallCommand "npm install -g prettier" -Type npm -Description $tool.Description
        } elseif ($tool.Name -eq "commitlint") {
            Install-Tool -Name $tool.Name -InstallCommand "npm install -g @commitlint/cli @commitlint/config-conventional" -Type npm -Description $tool.Description
        } else {
            Write-Warn "$($tool.Name): Manual install required - $($tool.Description)"
        }
    }
}

Write-Host ""
Write-Host "=== Installed Tools ===" -ForegroundColor Cyan
foreach ($tool in $installed) {
    Write-Host "  - $tool" -ForegroundColor Gray
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Tools Requiring Manual Install ===" -ForegroundColor Yellow
    foreach ($tool in $missing) {
        $hint = switch ($tool.Name) {
            "trufflehog" { "choco install trufflehog" }
            default { "See tool documentation" }
        }
        Write-Host "  - $($tool.Name): $hint" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "For more info: docs/getting-started/PREREQUISITES.md" -ForegroundColor Gray
Write-Host ""

exit 0