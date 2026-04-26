<#
.SYNOPSIS
    Workspace Access Control - Validates owner API key before executing restricted commands
.DESCRIPTION
    This script validates the caller's API key before allowing access to restricted operations.
    Only the workspace owner has access to skill-optimizer and administrative functions.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey
)

$ErrorActionPreference = "Stop"

# Paths
$configPath = ".workspace\config\access-control.json"
$authPath = ".workspace\config\owner-auth.json"

function Test-OwnerAccess {
    param([string]$Key)
    
    if (-not (Test-Path $authPath)) {
        Write-Host "[WARNING] No auth config found - owner access required" -ForegroundColor Yellow
        return $false
    }
    
    $auth = Get-Content $authPath | ConvertFrom-Json
    
    if ($Key -eq $auth.apiKey) {
        return $true
    }
    
    return $false
}

function Get-BlockedActions {
    $config = Get-Content $configPath | ConvertFrom-Json
    
    return $config.blockedActions.developers
}

# Main validation
$bypassCommands = @(
    "help", 
    "documentation-strategist help",
    "skill-optimizer help",
    "skill-optimizer request"
)

if ($Command -in $bypassCommands) {
    Write-Host "[INFO] Public command - access granted"
    exit 0
}

if (-not $ApiKey) {
    $blocked = Get-BlockedActions
    
    if ($Command -match $blocked.patterns -or $Command -in $blocked.commands) {
        Write-Host "[DENIED] This command requires owner authentication" -ForegroundColor Red
        Write-Host "[INFO] Use: wf.ps1 <command> -apiKey <your-api-key>" -ForegroundColor Yellow
        exit 1
    }
}

if ($ApiKey) {
    if (Test-OwnerAccess -Key $ApiKey) {
        Write-Host "[OK] Owner authenticated - access granted" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[DENIED] Invalid API key" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[OK] Command not restricted" -ForegroundColor Green
exit 0