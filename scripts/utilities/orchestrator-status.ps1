# orchestrator-status.ps1
# Verifica el estado del Project Orchestrator y la integración con Engram.

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
