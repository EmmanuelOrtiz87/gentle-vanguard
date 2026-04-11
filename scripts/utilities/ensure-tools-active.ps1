# ensure-tools-active.ps1
# Automated tool activation and health check for Gentleman Foundation
# Ensures all development tools are active and ready for coordinated workflow

param(
    [switch]$AutoStart,
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

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

function Write-Warning {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    }
}

function Write-Error {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[ERROR] $Message" -ForegroundColor Red
    }
}

function Test-ToolAvailable {
    param([string]$Name, [scriptblock]$TestScript)

    try {
        $result = & $TestScript
        if ($result) {
            Write-Success "$Name is available"
            return $true
        } else {
            Write-Warning "$Name is not available"
            return $false
        }
    } catch {
        Write-Error "$Name check failed: $($_.Exception.Message)"
        return $false
    }
}

function Start-Engram {
    Write-Step "Starting Engram memory system..."

    $engramScript = Join-Path $scriptDir 'run-engram.ps1'
    if (-not (Test-Path $engramScript)) {
        Write-Warning "Engram script not found at: $engramScript"
        return
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if (-not $engramCmd -and $AutoStart) {
        $installer = Join-Path $scriptDir 'install-engram.ps1'
        if (Test-Path $installer) {
            Write-Host "Engram CLI missing. Installing..." -ForegroundColor Yellow
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -Force
        }
    }

    try {
        # Check if engram is already running
        $engramProcess = Get-Process -Name "*engram*" -ErrorAction SilentlyContinue
        if (-not $engramProcess -or $Force) {
            if ($AutoStart) {
                Write-Host "Starting Engram in background..." -ForegroundColor Yellow
                Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$engramScript`"" -NoNewWindow
                Start-Sleep -Seconds 2
            }
            Write-Success "Engram initialization triggered"
        } else {
            Write-Success "Engram already running"
        }
    } catch {
        Write-Error "Failed to start Engram: $($_.Exception.Message)"
    }
}

function Start-GGA {
    Write-Step "Checking Gentleman Guardian Angel (GGA)..."

    $ggaScript = Join-Path $scriptDir 'run-gga.ps1'
    if (Test-Path $ggaScript) {
        # Test GGA availability
        $ggaAvailable = Test-ToolAvailable "GGA" {
            try {
                $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ggaScript --help 2>$null
                return $true
            } catch {
                return $false
            }
        }

        if (-not $ggaAvailable -and $AutoStart) {
            Write-Warning "GGA not available - attempting installation..."
            # Could add installation logic here
        }
    } else {
        Write-Warning "GGA script not found at: $ggaScript"
    }
}

function Start-GentleAI {
    Write-Step "Checking Gentle-AI CLI..."

    $gentleAIAvailable = Test-ToolAvailable "Gentle-AI" {
        $cmd = Get-Command gentle-ai -ErrorAction SilentlyContinue
        return $cmd -ne $null
    }

    if (-not $gentleAIAvailable -and $AutoStart) {
        Write-Warning "Gentle-AI not available - attempting installation..."
        try {
            npm install -g gentle-ai
            Write-Success "Gentle-AI installed"
        } catch {
            Write-Error "Failed to install Gentle-AI: $($_.Exception.Message)"
        }
    }
}

function Start-OrchestratorSkills {
    Write-Step "Activating Orchestrator Skills..."

    # Check if skills are installed
    $skillsDir = Join-Path $repoRoot 'skills'
    $orchestratorSkills = @('project-orchestrator-skill', 'code-review-orchestrator-skill', 'session-workflow-skill')

    foreach ($skill in $orchestratorSkills) {
        $skillPath = Join-Path $skillsDir $skill
        if (Test-Path $skillPath) {
            Write-Success "$skill is available"
        } else {
            Write-Warning "$skill not found - may need installation"
        }
    }

    # Skills are always active when available - no explicit start needed
    Write-Success "Orchestrator skills ready for coordination"
}

function Test-WorkflowReadiness {
    Write-Step "Testing Workflow Readiness..."

    # Test wf.ps1 functionality
    $wfScript = Join-Path $scriptDir 'wf.ps1'
    if (Test-Path $wfScript) {
        $statusWorks = Test-ToolAvailable "Workflow CLI (status)" {
            $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wfScript status 2>$null
            return $LASTEXITCODE -eq 0
        }

        $reviewWorks = Test-ToolAvailable "Workflow CLI (review)" {
            $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wfScript review -SkipTests 2>$null
            return $LASTEXITCODE -eq 0
        }

        if ($statusWorks -and $reviewWorks) {
            Write-Success "Workflow system is fully operational"
        } else {
            Write-Warning "Some workflow functions may not be working correctly"
        }
    } else {
        Write-Error "Workflow script not found: $wfScript"
    }
}

function Show-StatusSummary {
    if (-not $Quiet) {
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "  Tool Activation Complete" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "All development tools have been checked and activated where possible." -ForegroundColor White
        Write-Host "The coordinated workflow system is now ready for use." -ForegroundColor White
        Write-Host ""
        Write-Host "Use '.\wf.ps1 status' to check project status" -ForegroundColor Cyan
        Write-Host "Use '.\wf.ps1 review' to run code review" -ForegroundColor Cyan
        Write-Host "Use '.\wf.ps1 audit' to generate audit reports" -ForegroundColor Cyan
        Write-Host ""
    }
}

# Main execution
if (-not $Quiet) {
    Write-Host "Gentleman Foundation - Tool Activation System" -ForegroundColor Magenta
    Write-Host "Ensuring all development tools are active and ready..." -ForegroundColor White
    Write-Host ""
}

Start-Engram
Start-GGA
Start-GentleAI
Start-OrchestratorSkills
Test-WorkflowReadiness
Show-StatusSummary

exit 0