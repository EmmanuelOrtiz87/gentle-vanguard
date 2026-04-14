# auto-init-dev-environment.ps1
# Automatic development environment initialization
# Run this when starting a new session or creating a new project

param(
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'

function Write-Step {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n=== $Message ===" -ForegroundColor Cyan
    }
}

function Write-Success {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[OK] $Message" -ForegroundColor Green
    }
}

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[INFO] $Message" -ForegroundColor Blue
    }
}

function Write-Warning {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    }
}

function Invoke-LocalPowerShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    & $ScriptPath @ScriptArgs
}

# Check if we're in a Gentleman Foundation project
$currentDir = Get-Location
$projectRoot = $null
$checkPaths = @(
    (Join-Path $currentDir '.gentleman'),
    (Join-Path $currentDir 'SKILL.md'),
    (Join-Path $currentDir 'scripts/utilities/wf.ps1')
)

foreach ($path in $checkPaths) {
    if (Test-Path $path) {
        $projectRoot = $currentDir
        break
    }
}

if (-not $projectRoot) {
    # Look up the directory tree
    $candidate = Split-Path -Parent $currentDir
    while ($candidate) {
        foreach ($path in $checkPaths) {
            $fullPath = Join-Path $candidate (Split-Path -Leaf $path)
            if (Test-Path $fullPath) {
                $projectRoot = $candidate
                break
            }
        }
        if ($projectRoot) { break }
        $parent = Split-Path -Parent $candidate
        if (-not $parent -or $parent -eq $candidate) { break }
        $candidate = $parent
    }
}

if (-not $Quiet) {
    Write-Host "Gentleman Foundation - Auto Environment Init" -ForegroundColor Magenta
    Write-Host "Ensuring development environment is ready..." -ForegroundColor White
    Write-Host ""
}

if ($projectRoot) {
    Write-Info "Detected Gentleman Foundation project at: $projectRoot"
    Set-Location $projectRoot

    $detectScript = Join-Path $projectRoot 'scripts/utilities/detect-ide-session.ps1'
    if (Test-Path $detectScript) {
        try {
            $ideDataRaw = Invoke-LocalPowerShellScript -ScriptPath $detectScript -ScriptArgs @('-AsJson')
            $ideData = $ideDataRaw | ConvertFrom-Json
            Write-Info "IDE session detection: $($ideData.ideName) (confidence=$($ideData.confidence))"
            if (-not $ideData.isIdeSession) {
                Write-Warning "No known IDE session detected. Manual activation is recommended."
                Write-Host "  Suggested: $($ideData.recommendedActivationCommand)" -ForegroundColor White
            }
        } catch {
            Write-Warning "IDE detection script failed: $($_.Exception.Message)"
        }
    }

    # Run health check and tool activation
    Write-Step "Activating Development Tools"
    $healthScript = Join-Path $projectRoot 'scripts/utilities/ensure-tools-active.ps1'
    if (Test-Path $healthScript) {
        $healthArgs = @('-Quiet', '-AutoStart')
        if ($Force) { $healthArgs += "-Force" }
        Invoke-LocalPowerShellScript -ScriptPath $healthScript -ScriptArgs $healthArgs
        Write-Success "Development tools activated"
    } else {
        Write-Warning "Health check script not found - tools may not be fully activated"
    }

    # Initialize project if needed
    Write-Step "Initializing Project"
    $initScript = Join-Path $projectRoot 'scripts/project/init-project.ps1'
    if (Test-Path $initScript) {
        Invoke-LocalPowerShellScript -ScriptPath $initScript
        Write-Success "Project initialized"
    } else {
        Write-Info "No project initialization script found - skipping"
    }

    # Check git status
    Write-Step "Checking Git Status"
    if (Test-Path (Join-Path $projectRoot '.git')) {
        $gitStatus = git status --porcelain 2>$null
        if ($gitStatus) {
            Write-Info "Git repository has uncommitted changes"
        } else {
            Write-Success "Git repository is clean"
        }
    } else {
        Write-Info "Not a git repository"
    }

} else {
    Write-Info "No Gentleman Foundation project detected in current directory tree"

    # Global environment check
    Write-Step "Checking Global Development Environment"

    $tools = @(
        @{ Name = "Node.js"; Exec = "node"; Args = @("--version") },
        @{ Name = "npm"; Exec = "npm"; Args = @("--version") },
        @{ Name = "Go"; Exec = "go"; Args = @("version") },
        @{ Name = "Git"; Exec = "git"; Args = @("--version") },
        @{ Name = "GitHub CLI"; Exec = "gh"; Args = @("--version") }
    )

    foreach ($tool in $tools) {
        try {
            & $tool.Exec @($tool.Args) 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($tool.Name) is available"
            } else {
                Write-Warning "$($tool.Name) may not be working correctly"
            }
        } catch {
            Write-Warning "$($tool.Name) is not available"
        }
    }
}

if (-not $Quiet) {
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "  Environment Ready for Development" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The Gentleman Foundation development environment is now active." -ForegroundColor White
    Write-Host "Use '.\scripts\utilities\wf.ps1 status' to check project status" -ForegroundColor Cyan
    Write-Host "Use '.\scripts\utilities\wf.ps1 health' to re-run tool activation" -ForegroundColor Cyan
    Write-Host ""
}

exit 0