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

    $cfg = $null
    if (Test-Path $configFile) {
        try {
            $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        } catch {
            $cfg = [pscustomobject]@{}
        }
    } else {
        $cfg = [pscustomobject]@{}
    }

    function Set-ConfigValue {
        param(
            [psobject]$Target,
            [string]$Name,
            $Value
        )

        if ($Target.PSObject.Properties.Name -contains $Name) {
            $Target.$Name = $Value
        } else {
            $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
        }
    }

    Set-ConfigValue -Target $cfg -Name 'active' -Value $true
    Set-ConfigValue -Target $cfg -Name 'skill_path' -Value $orchestratorSkill
    Set-ConfigValue -Target $cfg -Name 'auto_detect' -Value $true
    Set-ConfigValue -Target $cfg -Name 'workflow_mode' -Value 'coordinated'
    Set-ConfigValue -Target $cfg -Name 'memory_integration' -Value $true
    Set-ConfigValue -Target $cfg -Name 'quality_gates' -Value $true
    Set-ConfigValue -Target $cfg -Name 'session_tracking' -Value $true
    Set-ConfigValue -Target $cfg -Name 'activation_mode' -Value 'on-demand'
    Set-ConfigValue -Target $cfg -Name 'activated_at' -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    if (-not ($cfg.PSObject.Properties.Name -contains 'communication_response_mode')) {
        Set-ConfigValue -Target $cfg -Name 'communication_response_mode' -Value 'simple'
    }
    if (-not ($cfg.PSObject.Properties.Name -contains 'allowed_response_modes')) {
        Set-ConfigValue -Target $cfg -Name 'allowed_response_modes' -Value @('simple', 'executive', 'expanded')
    }
    if (-not ($cfg.PSObject.Properties.Name -contains 'response_profiles') -or -not $cfg.response_profiles) {
        Set-ConfigValue -Target $cfg -Name 'response_profiles' -Value ([pscustomobject]@{
            active = 'ultra'
            allow = @('lite', 'lleno', 'ultra')
        })
    }
    if (-not ($cfg.PSObject.Properties.Name -contains 'chat_response') -or -not $cfg.chat_response) {
        Set-ConfigValue -Target $cfg -Name 'chat_response' -Value ([pscustomobject]@{
            default_level = 'chat-compact'
            enforce_on_session_start = $true
            allow = @('chat-compact', 'chat-balanced', 'chat-detailed')
            decision = [pscustomobject]@{
                kind = 'architecture'
                title = 'startup-chat-baseline'
                rationale = 'Initialize sessions with minimal chat verbosity for token efficiency and closure-first operation.'
            }
        })
    }

    if (-not ($cfg.PSObject.Properties.Name -contains 'response_policy') -or -not $cfg.response_policy) {
        Set-ConfigValue -Target $cfg -Name 'response_policy' -Value ([pscustomobject]@{
            strict_mode = $true
            enforce_baseline = $true
            baseline_detail = 'simple'
            baseline_profile = 'ultra'
            baseline_chat_level = 'chat-compact'
            allow_overrides = $false
            require_override_reason = $true
        })
    }

    if (-not ($cfg.PSObject.Properties.Name -contains 'workflow_optimization') -or -not $cfg.workflow_optimization) {
        Set-ConfigValue -Target $cfg -Name 'workflow_optimization' -Value ([pscustomobject]@{
            auto_escalation = [pscustomobject]@{
                enabled = $true
                file_change_threshold = 8
                risk_trigger = 'high'
                target_detail = 'expanded'
                target_profile = 'lleno'
            }
            kpi_tracking = [pscustomobject]@{
                enabled = $true
                cadence = 'weekly'
                script = './scripts/utilities/aggregate-metrics.ps1'
                metrics = @('tokens_per_task', 'time_per_task', 'rework_rate', 'post_change_defects')
            }
        })
    }

    if (-not ($cfg.PSObject.Properties.Name -contains 'runtime_preference') -or -not $cfg.runtime_preference) {
        Set-ConfigValue -Target $cfg -Name 'runtime_preference' -Value ([pscustomobject]@{
            primary = 'stack-cli'
            fallback = 'gentle-ai'
            auto_start_primary = $true
            fallback_on_primary_failure = $true
            require_primary_for_guidance = $false
        })
    }

    ($cfg | ConvertTo-Json -Depth 30) | Out-File -FilePath $configFile -Encoding UTF8 -Force

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
        $validatorArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $sessionValidator)
        if ($Detailed) { $validatorArgs += "-Detailed" }
        if ($AllowPassive) { $validatorArgs += "-AllowPassive" }
        & powershell @validatorArgs
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
