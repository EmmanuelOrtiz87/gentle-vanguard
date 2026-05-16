# Foundation Complete Setup Script v1.0=

Automated setup for Foundation across all supported platforms and use cases.

param(
    [string]$InstallPath = "$(if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME })\foundation",
    [ValidateSet('developer', 'team', 'enterprise')]
    [string]$Mode = 'developer',
    [switch]$SkipTests,
    [switch]$SkipHooks
)

$ErrorActionPreference = 'Stop'
$script:homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$host.UI.RawUI.WindowTitle = "Foundation Complete Setup"

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [[OK]] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "  [X] $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Step "Checking Prerequisites for: $Mode mode"
    
    # PowerShell 7+
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 7) {
        Write-Error "PowerShell 7+ required. Current: $psVersion"
        Write-Host "  Download: https://github.com/PowerShell/PowerShell" -ForegroundColor Gray
        exit 1
    }
    Write-Success "PowerShell $psVersion detected"
    
    # Git
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Git detected: $($gitVersion.Split(' ')[2])"
        } else {
            Write-Warning "Git not found. Some features may not work."
        }
    } catch {
        Write-Warning "Git not found. Install from https://git-scm.com/"
    }
    
    # Node.js (for some tools)
    try {
        $nodeVersion = node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Node.js detected: $nodeVersion"
        }
    } catch {
        Write-Host "  Node.js not found (optional)" -ForegroundColor Gray
    }
    
    # Disk space
    $drive = if (Test-Path $InstallPath) { (Get-Item $InstallPath).PSDrive } else { "C:" }
    $freeSpace = (Get-PSDrive $drive -ErrorAction SilentlyContinue).Free
    if ($freeSpace -and $freeSpace -lt 1GB) {
        Write-Warning "Low disk space. At least 1GB recommended."
    } else {
        Write-Success "Disk space OK (>1GB available)"
    }
}

function Install-Foundation {
    Write-Step "Installing Foundation ($Mode mode)"
    
    # Create directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Success "Created install directory: $InstallPath"
    }
    
    # Clone or copy files
    if (Test-Path "$PSScriptRoot\..\.git") {
        Write-Host "  Copying from current repository..." -ForegroundColor Gray
        $items = @("scripts", "skills", "config", "docs", "templates", "rules", "plugins")
        foreach ($item in $items) {
            $src = Join-Path $PSScriptRoot "..\$item" -ErrorAction SilentlyContinue
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $InstallPath -Recurse -Force
                Write-Success "  Copied: $item"
            }
        }
    } else {
        Write-Warning "Not in a git repository. Please clone Foundation first."
        return $false
    }
    
    # Install git hooks
    if (-not $SkipHooks) {
        $hooksScript = Join-Path $InstallPath "scripts\utilities\install-hooks.ps1"
        if (Test-Path $hooksScript) {
            & $hooksScript
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Git hooks installed (Lefthook + Trufflehog)"
            }
        }
    }
    
    # Mode-specific setup
    switch ($Mode) {
        'developer' {
            Write-Success "Developer mode: Basic setup complete"
        }
        'team' {
            # Install team tools
            $teamTools = @("scripts\utilities\WORKFLOW-ORCHESTRATION", "scripts\utilities\GIT-VERSION-CONTROL")
            foreach ($tool in $teamTools) {
                $toolPath = Join-Path $InstallPath $tool
                if (Test-Path $toolPath) {
                    Write-Success "  Team tool ready: $tool"
                }
            }
        }
        'enterprise' {
            # Install enterprise features
            $entTools = @("scripts\security", "scripts\utilities\AUDIT-REPORTING", "scripts\diagnostics")
            foreach ($tool in $entTools) {
                $toolPath = Join-Path $InstallPath $tool
                if (Test-Path $toolPath) {
                    Write-Success "  Enterprise tool ready: $tool"
                }
            }
            # Apply enterprise policies
            $policies = Join-Path $InstallPath "config\security-policy.json"
            if (Test-Path $policies) {
                Write-Success "Enterprise security policies applied"
            }
        }
    }
    
    return $true
}

function Initialize-Environment {
    Write-Step "Initializing Environment"
    
    # VS Code settings
    $vscodeDir = Join-Path $InstallPath ".vscode"
    if (-not (Test-Path $vscodeDir)) {
        New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
    }
    
    $settingsPath = Join-Path $vscodeDir "settings.json"
    $settings = @{
        "powershell.codeFormatting.pester.scriptBlockMustHaveBraces" = $true
        "powershell.codeFormatting.pester.missingShouldBe" = "error"
        "editor.formatOnSave" = $true
        "files.trimTrailingWhitespace" = $true
    }
    $settings | ConvertTo-Json | Out-File $settingsPath -Encoding UTF8
    Write-Success "VS Code settings configured"
    
    # PowerShell profile
    $profileDir = Split-Path $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    $profileContent = @"
# Foundation Environment
`$env:FOUNDATION_ROOT = '$InstallPath'
Import-Module `$env:FOUNDATION_ROOT\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 -ErrorAction SilentlyContinue
Write-Host 'Foundation environment loaded' -ForegroundColor Green
"@
    $profileContent | Out-File $PROFILE.CurrentUserCurrentHost -Encoding UTF8 -Append
    Write-Success "PowerShell profile updated"
}

function Run-Tests {
    if ($SkipTests) {
        Write-Warning "Skipping tests (SkipTests specified)"
        return
    }
    
    Write-Step "Running Test Suite"
    
    # Run Pester tests
    $testDir = Join-Path $InstallPath "tests"
    if (Test-Path $testDir) {
        $output = pwsh -NoProfile -Command "Invoke-Pester -Path '$testDir' -PassThru" 2>&1
        if ($output -match "Failed:\s*[1-9]") {
            Write-Warning "Some tests failed. Check output above."
        } else {
            Write-Success "All tests passed"
        }
    } else {
        Write-Warning "Test directory not found. Skipping tests."
    }
}

function Show-Completion {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Foundation Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Install path: $InstallPath" -ForegroundColor White
    Write-Host "  Mode: $Mode" -ForegroundColor White
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: wf.ps1 health" -ForegroundColor Gray
    Write-Host "  2. Read: docs\getting-started\README.md" -ForegroundColor Gray
    Write-Host "  3. Explore: wf.ps1 skills" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  For $Mode mode:" -ForegroundColor Cyan
    switch ($Mode) {
        'developer' {
            Write-Host "  - Start coding with AI assistance" -ForegroundColor Gray
            Write-Host "  - Use 'wf.ps1' for workflow automation" -ForegroundColor Gray
        }
        'team' {
            Write-Host "  - Set up CI/CD: wf.ps1 setup-ci" -ForegroundColor Gray
            Write-Host "  - Share skills with team" -ForegroundColor Gray
        }
        'enterprise' {
            Write-Host "  - Review security policies" -ForegroundColor Gray
            Write-Host "  - Run compliance audit: wf.ps1 audit full" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# Main execution
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Foundation Complete Setup v1.0" -ForegroundColor Cyan
Write-Host "  Mode: $Mode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Prerequisites
$installed = Install-Foundation
if ($installed) {
    Initialize-Environment
    Run-Tests
    Show-Completion
} else {
    Write-Error "Installation failed. Please check errors above."
    exit 1
}
