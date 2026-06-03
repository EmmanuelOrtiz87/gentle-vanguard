<#
.SYNOPSIS
    Refactor orchestrator.json into modular config files
.DESCRIPTION
    Splits monolithic orchestrator.json into separate concerns:
    - orchestrator.core.json (main config)
    - orchestrator.tools.json (tool profiles)
    - orchestrator.norms.json (normative references)
    - orchestrator.agents.json (agent profiles)
    - orchestrator.response.json (response policies)
.EXAMPLE
    .\orchestrator-refactor.ps1 -Validate
    .\orchestrator-refactor.ps1 -Apply
#>
[CmdletBinding()]
param(
    [switch]$Validate,
    [switch]$Apply,
    [switch]$Backup
)

$ErrorActionPreference = "Stop"

$script:SourceFile = Join-Path $PSScriptRoot "orchestrator.json"
$script:BackupDir = Join-Path $PSScriptRoot "backups"

function Write-Log {
    param([string]$Level, [string]$Message)
    $colors = @{ "INFO" = "White"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Backup-Config {
    if (-not (Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $script:BackupDir "orchestrator-$timestamp.json"
    Copy-Item $script:SourceFile $backupPath
    Write-Log "SUCCESS" "Backup created: $backupPath"
}

function Split-OrchestratorConfig {
    $config = Get-Content $script:SourceFile | ConvertFrom-Json -AsHashtable
    
    # Core config
    $core = @{
        version = $config.orchestrator.version
        active = $config.orchestrator.active
        activation_mode = $config.orchestrator.activation_mode
        activeToolDetection = $config.orchestrator.activeToolDetection
        preProcessing = $config.orchestrator.preProcessing
        triggerDetection = $config.orchestrator.triggerDetection
        sessionStartup = $config.orchestrator.sessionStartup
        skillLoading = $config.orchestrator.skillLoading
        logging = $config.orchestrator.logging
        workspace = $config.workspace
        subagent_orchestration = $config.subagent_orchestration
    }
    
    # Tool profiles
    $tools = @{
        version = "2.6.0"
        toolProfiles = $config.toolProfiles
    }
    
    # Norms
    $norms = @{
        version = "2.6.0"
        norms = $config.norms
    }
    
    # Response policies
    $response = @{
        version = "2.6.0"
        communication_language = $config.communication_language
        allowed_languages = $config.allowed_languages
        communication_response_mode = $config.communication_response_mode
        allowed_response_modes = $config.allowed_response_modes
        chat_response = $config.chat_response
        communication_presets = $config.communication_presets
        response_profiles = $config.response_profiles
        response_policy = $config.response_policy
        governed_override_profiles = $config.governed_override_profiles
    }
    
    return @{
        core = $core
        tools = $tools
        norms = $norms
        response = $response
    }
}

function Export-ConfigFiles {
    param([hashtable]$Configs)
    
    $Configs.core | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $PSScriptRoot "orchestrator.core.json")
    $Configs.tools | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $PSScriptRoot "orchestrator.tools.json")
    $Configs.norms | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $PSScriptRoot "orchestrator.norms.json")
    $Configs.response | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $PSScriptRoot "orchestrator.response.json")
    
    Write-Log "SUCCESS" "Config files exported:"
    Write-Log "INFO" "  - orchestrator.core.json ($($Configs.core.Count) keys)"
    Write-Log "INFO" "  - orchestrator.tools.json ($($Configs.tools.Count) keys)"
    Write-Log "INFO" "  - orchestrator.norms.json ($($Configs.norms.Count) keys)"
    Write-Log "INFO" "  - orchestrator.response.json ($($Configs.response.Count) keys)"
}

function Test-ConfigIntegrity {
    param([hashtable]$Configs)
    
    $issues = @()
    
    # Check required keys
    $requiredCore = @("version", "active", "workspace")
    foreach ($key in $requiredCore) {
        if (-not $Configs.core.ContainsKey($key)) {
            $issues += "Missing core key: $key"
        }
    }
    
    # Check tool profiles
    if (-not $Configs.tools.toolProfiles) {
        $issues += "Missing toolProfiles"
    }
    
    # Check norms
    if (-not $Configs.norms.norms) {
        $issues += "Missing norms"
    }
    
    return $issues
}

# Main execution
Write-Log "INFO" "Orchestrator Config Refactor Tool"
Write-Log "INFO" "Source: $script:SourceFile"

if (-not (Test-Path $script:SourceFile)) {
    Write-Log "ERROR" "Source file not found: $script:SourceFile"
    exit 1
}

if ($Backup) {
    Backup-Config
}

Write-Log "INFO" "Splitting configuration..."
$configs = Split-OrchestratorConfig

Write-Log "INFO" "Validating integrity..."
$issues = Test-ConfigIntegrity -Configs $configs

if ($issues.Count -gt 0) {
    Write-Log "WARN" "Validation issues found:"
    foreach ($issue in $issues) {
        Write-Log "WARN" "  - $issue"
    }
} else {
    Write-Log "SUCCESS" "Validation passed"
}

if ($Apply) {
    if ($issues.Count -gt 0) {
        Write-Log "ERROR" "Cannot apply with validation issues. Fix or use -Force"
        exit 1
    }
    
    if (-not (Test-Path $script:BackupDir)) {
        Backup-Config
    }
    
    Export-ConfigFiles -Configs $configs
    Write-Log "SUCCESS" "Refactor complete!"
} else {
    Write-Log "INFO" "Use -Apply to export config files"
}
