#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Checks if a user is in the trusted users list and can bypass authentication.
.DESCRIPTION
    Verifies if the current user or machine is in the trusted users policy file
    and can bypass authentication for certain operations.
.PARAMETER Username
    Username to check (defaults to current user)
.PARAMETER MachineId
    Machine ID to check (defaults to current machine)
.PARAMETER Operation
    Specific operation to check exemption for
.OUTPUTS
    Returns JSON with trusted status and exemptions
#>

param(
    [string]$Username = $env:USERNAME,
    [string]$MachineId = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($env:COMPUTERNAME)) | ForEach-Object {$_.ToString("x2")} | Join-String -Separator "",
    [string]$Operation
)

$ErrorActionPreference = "Stop"

# Paths
$repoRoot = if ($env:GV_BASE_DIR) { $env:GV_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$trustedUsersPolicyPath = Join-Path $repoRoot "config\trusted-users-policy.json"

function Write-TrustedUserJson {
    param([hashtable]$Data)
    $Data | ConvertTo-Json -Depth 5 | Write-Output
}

# Check if trusted users policy exists
if (-not (Test-Path $trustedUsersPolicyPath)) {
    Write-TrustedUserJson @{
        isTrusted = $false
        reason = "Trusted users policy file not found"
        exemptions = @()
    }
    exit 0
}

try {
    $policy = Get-Content $trustedUsersPolicyPath -Raw | ConvertFrom-Json
    
    # Check if user is in trusted list (by username, MD5 machineId, or literal hostname)
    $trustedUser = $policy.trustedUsers | Where-Object {
        ($_.username -eq $Username) -or
        ($_.machineId -eq $MachineId) -or
        ($_.hostname -and $_.hostname -eq $env:COMPUTERNAME)
    }
    
    if ($trustedUser) {
        $exemptions = if ($Operation) {
            # Check if specific operation is exempted
            $isExempt = $trustedUser.exemptOperations -contains $Operation -or 
                       $policy.exemptFromCriticalChecks -contains $Operation
            @{
                isTrusted = $true
                isOperationExempt = $isExempt
                operation = $Operation
                exemptions = $trustedUser.exemptOperations
                allowedOperations = $trustedUser.allowedOperations
                reason = "User $Username is trusted"
            }
        } else {
            # Return general trusted status
            @{
                isTrusted = $true
                exemptions = $trustedUser.exemptOperations
                allowedOperations = $trustedUser.allowedOperations
                reason = "User $Username is trusted"
            }
        }
        
        Write-TrustedUserJson $exemptions
        exit 0
    } else {
        Write-TrustedUserJson @{
            isTrusted = $false
            reason = "User $Username not found in trusted users list"
            exemptions = @()
        }
        exit 0
    }
} catch {
    Write-TrustedUserJson @{
        isTrusted = $false
        reason = "Error reading trusted users policy: $($_.Exception.Message)"
        exemptions = @()
    }
    exit 1
}