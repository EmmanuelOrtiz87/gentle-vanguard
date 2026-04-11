param(
    [ValidateSet("prepare", "activate", "deactivate", "validate", "demo")]
    [string]$Action = "validate",
    [string]$ProjectPath,
    [switch]$AllowPassive,
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

$foundationRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$orchestratorSkill = Join-Path $foundationRoot "skills\project-orchestrator-skill"

if ($ProjectPath) {
    $targetProject = (Resolve-Path $ProjectPath).Path
} else {
    $targetProject = $foundationRoot.Path
}

function Ensure-Engram {
    Write-Step "Preparing tools"
    $engram = Get-Command engram -ErrorAction SilentlyContinue
    if ($engram) {
        $v = & $engram.Source version | Select-Object -First 1
        Write-Ok "Engram available: $v"
        return
    }

    $installScript = Join-Path $foundationRoot "scripts\utilities\install-engram.ps1"
    if (Test-Path $installScript) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $installScript
    }

    $engram = Get-Command engram -ErrorAction SilentlyContinue
    if (-not $engram) {
        throw "Engram is not available. Install and retry."
    }

    $v = & $engram.Source version | Select-Object -First 1
    Write-Ok "Engram available: $v"
}

function Activate-OnDemand {
    param([string]$Path)

    Write-Step "Activating on-demand orchestrator"

    $configDir = Join-Path $Path "config"
    $configFile = Join-Path $configDir "orchestrator.json"
    $marker = Join-Path $Path ".orchestrator-active"

    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    @{
        activated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        skill = "project-orchestrator"
        activation_mode = "on-demand"
        auto_active = $false
    } | ConvertTo-Json | Out-File -FilePath $marker -Encoding UTF8 -Force

    @{
        active = $true
        skill_path = $orchestratorSkill
        auto_detect = $true
        workflow_mode = "coordinated"
        memory_integration = $true
        quality_gates = $true
        session_tracking = $true
        activation_mode = "on-demand"
        activated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    } | ConvertTo-Json | Out-File -FilePath $configFile -Encoding UTF8 -Force

    Write-Ok "On-demand orchestrator active in: $Path"
}

function Deactivate-OnDemand {
    param([string]$Path)

    Write-Step "Deactivating orchestrator"

    $configFile = Join-Path $Path "config\orchestrator.json"
    $marker = Join-Path $Path ".orchestrator-active"

    if (Test-Path $marker) {
        Remove-Item $marker -Force
        Write-Ok "Removed marker: $marker"
    } else {
        Write-Warn "Marker not found: $marker"
    }

    if (Test-Path $configFile) {
        $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        $cfg.active = $false
        if ($cfg.PSObject.Properties.Name -contains "deactivated_at") {
            $cfg.deactivated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        } else {
            $cfg | Add-Member -NotePropertyName deactivated_at -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        ($cfg | ConvertTo-Json -Depth 5) | Out-File -FilePath $configFile -Encoding UTF8 -Force
        Write-Ok "Set active=false in: $configFile"
    }
}

function Validate-Stack {
    Write-Step "Validating stack state"

    $validator = Join-Path $foundationRoot "scripts\utilities\orchestrator-status.ps1"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validator

    $sessionValidator = "C:\Workspace_local\tools\validate-session-stack.ps1"
    if (Test-Path $sessionValidator) {
        $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $sessionValidator)
        if ($Detailed) { $args += "-Detailed" }
        if ($AllowPassive) { $args += "-AllowPassive" }
        & powershell @args
    } else {
        Write-Warn "Workspace validator not found: $sessionValidator"
    }

    Write-Ok "Validation complete"
}

function Run-Demo {
    Write-Step "Demo"
    Write-Host "1. Activate on-demand orchestrator" -ForegroundColor White
    Write-Host "2. Run implementation task" -ForegroundColor White
    Write-Host "3. Run session validator" -ForegroundColor White
    Write-Host "4. Run closeout template" -ForegroundColor White
    Write-Host "5. Deactivate orchestrator" -ForegroundColor White
    Write-Ok "Demo flow printed"
}

switch ($Action) {
    "prepare" { Ensure-Engram }
    "activate" { Ensure-Engram; Activate-OnDemand -Path $targetProject }
    "deactivate" { Deactivate-OnDemand -Path $targetProject }
    "validate" { Validate-Stack }
    "demo" { Run-Demo }
}

Write-Step "Completed"
Write-Host "Action=$Action ProjectPath=$targetProject" -ForegroundColor Cyan
