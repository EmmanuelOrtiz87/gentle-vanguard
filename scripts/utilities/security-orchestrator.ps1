# security-orchestrator.ps1
# Security Orchestrator - initializes and manages security settings

param(
    [string]$Action = "init",
    [switch]$AsJson
)

$ErrorActionPreference = "Continue"
$configPath = Join-Path $PSScriptRoot "..\config"
$securityPolicy = Join-Path $configPath "security-policy.json"
$securityPrivacy = Join-Path $configPath "security-privacy.json"

function Write-Log {
    param([string]$Message)
    if (-not $AsJson) {
        Write-Host "[SECURITY] $Message" -ForegroundColor Cyan
    }
}

function Get-SecurityStatus {
    $status = @{
        policy = if (Test-Path $securityPolicy) { "loaded" } else { "missing" }
        privacy = if (Test-Path $securityPrivacy) { "loaded" } else { "missing" }
        mode = "enforced"
    }
    return $status
}

if ($Action -eq "init") {
    Write-Log "Initializing Security Orchestrator..."
    
    if (-not (Test-Path $securityPolicy)) {
        Write-Log "Security policy not found: $securityPolicy"
        if ($AsJson) { @{ error = "policy_missing" } | ConvertTo-Json; exit 1 }
        exit 1
    }
    
    if (-not (Test-Path $securityPrivacy)) {
        Write-Log "Security privacy not found: $securityPrivacy"
        if ($AsJson) { @{ error = "privacy_missing" } | ConvertTo-Json; exit 1 }
        exit 1
    }
    
    $status = Get-SecurityStatus
    if ($AsJson) {
        $status | ConvertTo-Json
    } else {
        Write-Log "Security Orchestrator initialized successfully"
        Write-Log "Policy: $($status.policy)"
        Write-Log "Privacy: $($status.privacy)"
        Write-Log "Mode: $($status.mode)"
    }
    exit 0
}

if ($Action -eq "status") {
    $status = Get-SecurityStatus
    if ($AsJson) {
        $status | ConvertTo-Json
    } else {
        Write-Log "Security Status:"
        Write-Log "  Policy: $($status.policy)"
        Write-Log "  Privacy: $($status.privacy)"
        Write-Log "  Mode: $($status.mode)"
    }
    exit 0
}

Write-Log "Unknown action: $Action"
if ($AsJson) { @{ error = "unknown_action"; action = $Action } | ConvertTo-Json }
exit 1
