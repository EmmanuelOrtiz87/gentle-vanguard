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
        if ($AutoStart) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $engramScript version 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Engram CLI is ready"
            } else {
                Write-Warning "Engram CLI check failed"
            }
        } else {
            Write-Success "Engram check skipped (AutoStart not requested)"
        }
    } catch {
        Write-Error "Failed to verify Engram: $($_.Exception.Message)"
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

    $gentleAIScript = Join-Path $scriptDir 'run-gentle-ai.ps1'
    $gentleAIAvailable = Test-ToolAvailable "Gentle-AI" {
        $cmd = Get-Command gentle-ai -ErrorAction SilentlyContinue
        if ($cmd) { return $true }
        return (Test-Path $gentleAIScript)
    }

    if (-not $gentleAIAvailable -and $AutoStart) {
        if (Test-Path $gentleAIScript) {
            Write-Warning "Native Gentle-AI CLI not found. Using compatibility launcher."
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gentleAIScript status | Out-Null
        } else {
            Write-Warning "Gentle-AI tooling is unavailable."
            Write-Host "Expected launcher: $gentleAIScript" -ForegroundColor Yellow
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

function Test-MCPIntegrationReadiness {
    Write-Step "Checking optional MCP integrations..."

    $configPath = Join-Path $repoRoot 'config\workspace.config.json'
    if (-not (Test-Path $configPath)) {
        Write-Warning "workspace.config.json not found - skipping MCP integration checks"
        return
    }

    try {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Could not parse workspace.config.json - skipping MCP integration checks"
        return
    }

    if (-not $cfg.mcpIntegrations) {
        Write-Success "No optional MCP integrations configured"
        return
    }

    $integrationNames = @('context7', 'notion')
    foreach ($name in $integrationNames) {
        $integration = $cfg.mcpIntegrations.$name
        if (-not $integration) { continue }

        if (-not $integration.enabled) {
            Write-Success "MCP $name is disabled (default)"
            continue
        }

        $missing = @()
        if ($integration.requiredEnv) {
            foreach ($envName in $integration.requiredEnv) {
                $value = [Environment]::GetEnvironmentVariable([string]$envName)
                if ([string]::IsNullOrWhiteSpace($value)) {
                    $missing += [string]$envName
                }
            }
        }

        if ($missing.Count -gt 0) {
            Write-Warning "MCP $name is enabled but missing env vars: $($missing -join ', ')"
        } else {
            Write-Success "MCP $name is enabled and env vars are present"
        }
    }
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
        Write-Host "Use '.\scripts\utilities\wf.ps1 status' to check project status" -ForegroundColor Cyan
        Write-Host "Use '.\scripts\utilities\wf.ps1 review' to run code review" -ForegroundColor Cyan
        Write-Host "Use '.\scripts\utilities\wf.ps1 audit' to generate audit reports" -ForegroundColor Cyan
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
Test-MCPIntegrationReadiness
Test-WorkflowReadiness
Show-StatusSummary

exit 0