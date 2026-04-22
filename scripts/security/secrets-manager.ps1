#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Secrets Manager - Secure Secrets Management
    
.DESCRIPTION
    Manages secrets using environment variables and secure storage
    
.PARAMETER Action
    Action: get, set, delete, list, rotate
    
.PARAMETER SecretName
    Name of the secret
    
.PARAMETER SecretValue
    Value of the secret
    
.EXAMPLE
    .\secrets-manager.ps1 -Action set -SecretName "API_KEY" -SecretValue "secret123"
#>

param(
    [ValidateSet('get', 'set', 'delete', 'list', 'rotate', 'validate')]
    [string]$Action = 'validate',
    [string]$SecretName,
    [string]$SecretValue,
    [string]$LogLevel = 'info'
)

$SecretsVersion = "1.0.0"
$secretsFile = ".\config\.secrets"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Get-Secret {
    param([string]$Name)
    
    Write-Log "Retrieving secret: $Name" "info"
    
    $secret = [Environment]::GetEnvironmentVariable($Name, "User")
    
    if ([string]::IsNullOrEmpty($secret)) {
        Write-Log "Secret not found: $Name" "warn"
        return $null
    }
    
    Write-Log "Secret retrieved successfully" "info"
    return $secret
}

function Set-Secret {
    param([string]$Name, [string]$Value)
    
    Write-Log "Setting secret: $Name" "info"
    
    if ([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($Value)) {
        Write-Log "Secret name and value cannot be empty" "error"
        return $false
    }
    
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    
    Write-Log "Secret set successfully: $Name" "info"
    return $true
}

function Delete-Secret {
    param([string]$Name)
    
    Write-Log "Deleting secret: $Name" "info"
    
    [Environment]::SetEnvironmentVariable($Name, $null, "User")
    
    Write-Log "Secret deleted successfully: $Name" "info"
    return $true
}

function List-Secrets {
    Write-Log "Listing secrets..." "info"
    
    $secrets = @(
        "API_KEY",
        "DATABASE_PASSWORD",
        "ENCRYPTION_KEY",
        "JWT_SECRET",
        "OAUTH_TOKEN"
    )
    
    $secretsList = @()
    foreach ($secret in $secrets) {
        $value = [Environment]::GetEnvironmentVariable($secret, "User")
        if (-not [string]::IsNullOrEmpty($value)) {
            $secretsList += @{
                name = $secret
                set = $true
                lastModified = (Get-Date -Format "o")
            }
        }
    }
    
    Write-Log "Found $($secretsList.Count) secrets" "info"
    return $secretsList | ConvertTo-Json
}

function Rotate-Secrets {
    Write-Log "Rotating secrets..." "info"
    
    $secretsToRotate = @("API_KEY", "JWT_SECRET", "OAUTH_TOKEN")
    
    foreach ($secret in $secretsToRotate) {
        $oldValue = [Environment]::GetEnvironmentVariable($secret, "User")
        
        if (-not [string]::IsNullOrEmpty($oldValue)) {
            $newValue = [System.Guid]::NewGuid().ToString()
            [Environment]::SetEnvironmentVariable($secret, $newValue, "User")
            
            Write-Log "Rotated secret: $secret" "info"
        }
    }
    
    Write-Log "Secrets rotated successfully" "info"
    return $true
}

function Validate-Secrets {
    Write-Log "Validating secrets configuration..." "info"
    
    $validation = @{
        timestamp = Get-Date -Format "o"
        version = $SecretsVersion
        checks = @()
    }
    
    $requiredSecrets = @("API_KEY", "ENCRYPTION_KEY")
    
    foreach ($secret in $requiredSecrets) {
        $value = [Environment]::GetEnvironmentVariable($secret, "User")
        $check = @{
            secret = $secret
            configured = -not [string]::IsNullOrEmpty($value)
            status = if ([string]::IsNullOrEmpty($value)) { "MISSING" } else { "OK" }
        }
        $validation.checks += $check
    }
    
    Write-Log "Secrets validation completed" "info"
    return $validation | ConvertTo-Json
}

function Main {
    Write-Log "Secrets Manager v$SecretsVersion" "info"
    Write-Log "Action: $Action" "info"
    
    $result = switch ($Action) {
        'get' { Get-Secret -Name $SecretName }
        'set' { Set-Secret -Name $SecretName -Value $SecretValue }
        'delete' { Delete-Secret -Name $SecretName }
        'list' { List-Secrets }
        'rotate' { Rotate-Secrets }
        'validate' { Validate-Secrets }
        default { Write-Log "Unknown action: $Action" "error"; return 1 }
    }
    
    if ($result) {
        Write-Log "Operation completed successfully" "info"
        return 0
    }
    else {
        Write-Log "Operation failed" "error"
        return 1
    }
}

exit (Main)