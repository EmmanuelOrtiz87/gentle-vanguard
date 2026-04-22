# orchestrator-status.ps1
# Verifica el estado del Project Orchestrator y la integracin con Engram.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path $scriptDir
if ($projectRoot.Path -like '*\utilities') {
    $projectRoot = Resolve-Path (Join-Path $projectRoot '..\..')
} else {
    $projectRoot = Resolve-Path (Join-Path $projectRoot '..')
}

$activationFile = Join-Path $projectRoot '.orchestrator-active'
$configFile = Join-Path $projectRoot 'config\orchestrator.json'
$skillCandidates = @(
    Join-Path $projectRoot '.skills\project-orchestrator-skill'
    Join-Path $projectRoot '.workspace-foundation\skills\project-orchestrator-skill'
    Join-Path $projectRoot 'skills\project-orchestrator-skill'
)
$skillDir = $skillCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $skillDir) { $skillDir = $skillCandidates[0] }
$engramData = Join-Path $projectRoot '.engram-data'
$runEngramScript = Join-Path $projectRoot 'scripts\utilities\run-engram.ps1'
$customRulesScript = Join-Path $projectRoot 'scripts\utilities\custom-rules.ps1'

function Write-Step { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor DarkCyan }

function Get-TokenGuardDefaults {
    return @{
        enabled = $true
        require_engram = $true
        daily_budget_tokens = 120000
        soft_threshold_pct = 70
        hard_threshold_pct = 90
    }
}

function Get-TodayTokenUsage {
    param([string]$ProjectRoot)

    $usageFile = Join-Path $ProjectRoot 'docs\sessions\metrics\token-guard-usage.csv'
    if (-not (Test-Path $usageFile)) {
        return 0
    }

    $rows = Import-Csv -Path $usageFile -ErrorAction SilentlyContinue
    if (-not $rows) {
        return 0
    }

    $today = Get-Date -Format 'yyyy-MM-dd'
    $sum = 0
    foreach ($row in $rows) {
        if ($row.date -ne $today) {
            continue
        }

        $tokens = 0
        if ([int]::TryParse([string]$row.estimated_tokens, [ref]$tokens)) {
            $sum += $tokens
        }
    }

    return $sum
}

function Show-TokenGuardExecutiveSummary {
    param(
        [object]$Config,
        [string]$ProjectRoot,
        [bool]$EngramInstalled
    )

    Write-Step 'Token Guard Executive Summary'

    $defaults = Get-TokenGuardDefaults
    $guard = @{}
    foreach ($key in @($defaults.Keys)) {
        $guard[$key] = $defaults[$key]
    }

    if ($Config -and $Config.PSObject.Properties.Name -contains 'subagent_orchestration' -and $Config.subagent_orchestration -and $Config.subagent_orchestration.PSObject.Properties.Name -contains 'token_budget_guard' -and $Config.subagent_orchestration.token_budget_guard) {
        $custom = $Config.subagent_orchestration.token_budget_guard
        foreach ($key in @($defaults.Keys)) {
            if ($custom.PSObject.Properties.Name -contains $key) {
                $guard[$key] = $custom.$key
            }
        }
    }

    if (-not $guard.enabled) {
        Write-Warning 'Token budget guard is disabled.'
        return
    }

    $usedToday = Get-TodayTokenUsage -ProjectRoot $ProjectRoot
    $budget = [int]$guard.daily_budget_tokens
    $pct = if ($budget -gt 0) { [Math]::Round(($usedToday / $budget) * 100, 2) } else { 0 }
    $soft = [double]$guard.soft_threshold_pct
    $hard = [double]$guard.hard_threshold_pct

    Write-Host "  guard_enabled: $($guard.enabled)" -ForegroundColor White
    Write-Host "  require_engram: $($guard.require_engram)" -ForegroundColor White
    Write-Host "  used_today_tokens: $usedToday" -ForegroundColor White
    Write-Host "  daily_budget_tokens: $budget" -ForegroundColor White
    Write-Host "  projected_pct_today: $pct" -ForegroundColor White
    Write-Host "  thresholds: soft=$soft% hard=$hard%" -ForegroundColor White

    if ($guard.require_engram -and -not $EngramInstalled) {
        Write-Warning 'Continuity risk: Engram required by policy but not installed in PATH.'
        Write-Host '  Alternative 1: .\scripts\utilities\wf.ps1 install-engram' -ForegroundColor Yellow
        Write-Host '  Alternative 2: .\scripts\utilities\run-engram.ps1 --help' -ForegroundColor Yellow
        return
    }

    if ($pct -ge $hard) {
        Write-Warning 'Hard token threshold reached: use compact flow and finish with closure-safe path.'
        Write-Host '  Alternative 1: .\scripts\utilities\wf.ps1 response-mode simple' -ForegroundColor Yellow
        Write-Host '  Alternative 2: .\scripts\utilities\wf.ps1 response-mode ultra' -ForegroundColor Yellow
        Write-Host '  Alternative 3: .\scripts\utilities\wf.ps1 context-pack "<objective>"' -ForegroundColor Yellow
        Write-Host '  Alternative 4: .\scripts\utilities\wf.ps1 end-session "<task>" -SkipReview -SkipTests -Force' -ForegroundColor Yellow
        return
    }

    if ($pct -ge $soft) {
        Write-Warning 'Soft token threshold reached: reduce context size and split work into smaller slices.'
        Write-Host '  Recommendation: run .\scripts\utilities\wf.ps1 compact-start "<objective>" before continuing' -ForegroundColor Yellow
        return
    }

    Write-Success 'Token budget posture is healthy.'
}

function Resolve-ConfigText {
    param(
        [string]$Text,
        [hashtable]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    $resolved = $Text
    foreach ($key in $Context.Keys) {
        $resolved = $resolved.Replace("{$key}", [string]$Context[$key])
    }

    return $resolved
}

function Resolve-WorkspacePath {
    param(
        [string]$Path,
        [string]$WorkspaceRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $Path))
}

Write-Step "Orchestrator Status Check"

if (Test-Path $activationFile) {
    Write-Success "Orchestrator activation file found"
    $activation = Get-Content $activationFile | ConvertFrom-Json
    Write-Host "  skill: $($activation.skill)" -ForegroundColor White
    Write-Host "  project: $($activation.project)" -ForegroundColor White
    Write-Host "  auto_active: $($activation.auto_active)" -ForegroundColor White
} else {
    Write-Warning "Orchestrator activation file not found: $activationFile"
}

if (Test-Path $configFile) {
    Write-Success "Orchestrator config found"
    $config = Get-Content $configFile | ConvertFrom-Json
    $configContext = @{
        workspaceRoot = $projectRoot
        dataRoot = (Join-Path $projectRoot '.engram-data')
        toolsRoot = (Join-Path $projectRoot 'tools')
        projectsRoot = (Join-Path $projectRoot 'projects')
    }
    if ($config.PSObject.Properties.Name -contains 'dataRoot' -and $config.dataRoot) {
        $engramData = Resolve-WorkspacePath -Path (Resolve-ConfigText -Text $config.dataRoot -Context $configContext) -WorkspaceRoot $projectRoot
    }
    Write-Host "  active: $($config.active)" -ForegroundColor White
    Write-Host "  workflow_mode: $($config.workflow_mode)" -ForegroundColor White
    $responseMode = if ($config.PSObject.Properties.Name -contains 'communication_response_mode') { $config.communication_response_mode } else { 'executive (default)' }
    $languageMode = if ($config.PSObject.Properties.Name -contains 'communication_language') { $config.communication_language } else { 'es (default)' }
    $compressionProfile = if ($config.PSObject.Properties.Name -contains 'response_profiles' -and $config.response_profiles -and $config.response_profiles.active) { $config.response_profiles.active } else { 'lite (default)' }
    $defaultPreset = if ($config.PSObject.Properties.Name -contains 'communication_presets' -and $config.communication_presets -and $config.communication_presets.default) { $config.communication_presets.default } else { 'bugfix (default)' }
    $autoApplyPreset = if ($config.PSObject.Properties.Name -contains 'communication_presets' -and $config.communication_presets -and $config.communication_presets.PSObject.Properties.Name -contains 'auto_apply_on_session_start') { $config.communication_presets.auto_apply_on_session_start } else { $true }
    $autoApplyRisk = if ($config.PSObject.Properties.Name -contains 'communication_presets' -and $config.communication_presets -and $config.communication_presets.PSObject.Properties.Name -contains 'auto_apply_default_risk') { $config.communication_presets.auto_apply_default_risk } else { 'medium' }
    Write-Host "  communication_language: $languageMode" -ForegroundColor White
    Write-Host "  communication_response_mode: $responseMode" -ForegroundColor White
    Write-Host "  response_profile: $compressionProfile" -ForegroundColor White
    Write-Host "  communication_preset_default: $defaultPreset" -ForegroundColor White
    Write-Host "  communication_preset_auto_apply: $autoApplyPreset" -ForegroundColor White
    Write-Host "  communication_preset_auto_risk: $autoApplyRisk" -ForegroundColor White
    Write-Host "  memory_integration: $($config.memory_integration)" -ForegroundColor White
    Write-Host "  auto_detect: $($config.auto_detect)" -ForegroundColor White
} else {
    Write-Warning "Orchestrator config not found: $configFile"
}

if (Test-Path $skillDir) {
    Write-Success "Project orchestrator skill available"
} else {
    Write-Warning "Project orchestrator skill not found: $skillDir"
}

function Resolve-EngramCommand {
    if ($env:ENGRAM_CMD) {
        return $env:ENGRAM_CMD
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) { return $engramCmd.Source }

    $pathsToCheck = @()
    if ($env:GOBIN) { $pathsToCheck += Join-Path $env:GOBIN 'engram.exe'; $pathsToCheck += Join-Path $env:GOBIN 'engram' }
    if ($env:GOPATH) { $pathsToCheck += Join-Path $env:GOPATH 'bin\engram.exe'; $pathsToCheck += Join-Path $env:GOPATH 'bin\engram' }
    if ($env:USERPROFILE) { $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram.exe'; $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram' }
    if ($env:HOME) { $pathsToCheck += Join-Path $env:HOME 'go/bin/engram' }

    foreach ($path in $pathsToCheck) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

$engramPath = Resolve-EngramCommand
$engramInstalled = [bool]$engramPath
if ($engramPath) {
    Write-Success "Engram CLI is available: $engramPath"
} else {
    Write-Warning "Engram CLI not found in PATH or configured Go bin locations"
}

if (Test-Path $engramData) {
    Write-Success "Engram data directory exists"
    $entries = Get-ChildItem -Path $engramData -Force | Select-Object -ExpandProperty Name
    Write-Host "  Entries: $($entries -join ', ')" -ForegroundColor White
} else {
    Write-Info "Engram data directory will be created on first use: $engramData"
}

if (Test-Path $runEngramScript) {
    Write-Success "Engram launcher script exists"
} else {
    Write-Warning "Engram launcher script not found: $runEngramScript"
}

if ($config) {
    Show-TokenGuardExecutiveSummary -Config $config -ProjectRoot $projectRoot -EngramInstalled:$engramInstalled
}

if (Test-Path $customRulesScript) {
    try {
        $rulesJson = & $customRulesScript -Mode status -AsJson -PassThru -Quiet
        if (-not [string]::IsNullOrWhiteSpace(($rulesJson | Out-String).Trim())) {
            $rulesStatus = $rulesJson | ConvertFrom-Json
            Write-Success "Custom rules loader is available"
            Write-Host "  enabled: $($rulesStatus.enabled)" -ForegroundColor White
            Write-Host "  root: $($rulesStatus.root)" -ForegroundColor White
            Write-Host "  files loaded: $($rulesStatus.totalFiles)" -ForegroundColor White
        } else {
            Write-Warning "Custom rules loader returned no status"
        }
    }
    catch {
        Write-Warning "Custom rules status failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Custom rules loader script not found: $customRulesScript"
}

Write-Step "Conclusion"
if ((Test-Path $activationFile) -and (Test-Path $configFile) -and (Test-Path $skillDir)) {
    Write-Success "The orchestrator is configured and active."
} else {
    Write-Warning "The orchestrator configuration is missing required elements. Review the warnings above."
}
if ($engramInstalled -and (Test-Path $runEngramScript)) {
    Write-Success "Engram is available for persistent memory sessions."
    Write-Host "To start a session with persistent memory, use: .\scripts\utilities\run-engram.ps1" -ForegroundColor Cyan
} else {
    Write-Warning "Engram is not fully available in the current environment."
}

exit 0
