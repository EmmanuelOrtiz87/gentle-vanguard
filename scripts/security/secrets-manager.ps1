#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Secrets Manager - Secure Secrets Management (DPAPI Vault)

.DESCRIPTION
    Manages secrets using DPAPI-encrypted vault. Replaces legacy env-var storage.
    Delegates to secret-vault.ps1 for all CRUD operations.
    Compliance: SOC2 CC6.1, GDPR Art.32

.PARAMETER Action
    Action: get, set, delete, list, rotate, validate

.PARAMETER SecretName
    Name of the secret (UPPER_SNAKE_CASE)

.PARAMETER SecretValue
    Value of the secret (only for set action)

.PARAMETER Reason
    Justification for access (mandatory for get/delete operations)

.EXAMPLE
    .\secrets-manager.ps1 -Action set -SecretName GITHUB_TOKEN -SecretValue ghp_xxxx
    .\secrets-manager.ps1 -Action get -SecretName GITHUB_TOKEN -Reason "CI pipeline"
    .\secrets-manager.ps1 -Action validate
#>

param(
    [ValidateSet('get', 'set', 'delete', 'list', 'rotate', 'validate')]
    [string]$Action = 'validate',
    [string]$SecretName,
    [string]$SecretValue,
    [string]$Reason,
    [string]$LogLevel = 'info'
)

$SecretsVersion = "2.0.0"
$scriptDir = Split-Path -Parent $PSCommandPath
$vaultScript = Join-Path $scriptDir "secret-vault.ps1"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Get-Secret {
    param([string]$Name)
    Write-Log "Retrieving secret: $Name" "info"

    if (-not (Test-Path $vaultScript)) {
        throw "secret-vault.ps1 not found. Install vault for DPAPI encryption (run setup-secure.ps1)."
    }

    $result = & $vaultScript -Subcommand get -Name $Name -Reason $Reason 2>&1
    if ($LASTEXITCODE -eq 0) { return $result } else { return $null }
}

function Set-Secret {
    param([string]$Name, [string]$Value)
    Write-Log "Setting secret: $Name" "info"

    if ([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($Value)) {
        Write-Log "Secret name and value cannot be empty" "error"
        return $false
    }

    if (-not (Test-Path $vaultScript)) {
        throw "secret-vault.ps1 not found. Install vault for DPAPI encryption (run setup-secure.ps1)."
    }

    & $vaultScript -Subcommand create -Name $Name -Value $Value
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Secret stored in encrypted vault: $Name" "info"
        return $true
    }

    throw "Failed to store secret in vault: $Name"
}

function Delete-Secret {
    param([string]$Name)
    Write-Log "Removing secret: $Name" "info"

    if (-not (Test-Path $vaultScript)) {
        throw "secret-vault.ps1 not found. Install vault for DPAPI encryption (run setup-secure.ps1)."
    }

    & $vaultScript -Subcommand breach-response -CompromisedSecret $Name -Reason $Reason
    if ($LASTEXITCODE -eq 0) { return $true }

    throw "Failed to delete secret from vault: $Name"
}

function List-Secrets {
    Write-Log "Listing secrets..." "info"

    if (Test-Path $vaultScript) {
        & $vaultScript -Subcommand list
        return $true
    }

    Write-Log "No vault found. No secrets enumerated." "warn"
    return $true
}

function Rotate-Secrets {
    Write-Log "Rotating secrets..." "info"

    if (Test-Path $vaultScript) {
        & $vaultScript -Subcommand rotate -Name $SecretName
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Secret rotated in vault: $SecretName" "info"
            return $true
        }
        Write-Log "Vault rotation failed" "error"
        return $false
    }

    Write-Log "No vault — rotation requires secret-vault.ps1" "error"
    return $false
}

function Validate-Secrets {
    Write-Log "Validating secrets configuration..." "info"

    if (Test-Path $vaultScript) {
        & $vaultScript -Subcommand validate-compliance
        return ($LASTEXITCODE -eq 0)
    }

    Write-Log "Vault not found — limited validation" "warn"
    $validation = @{
        timestamp = (Get-Date -Format "o")
        version = $SecretsVersion
        vault = "not-available"
        checks = @(
            @{ check = "vault-present"; status = "WARN"; message = "secret-vault.ps1 not found. Install vault for DPAPI encryption." }
        )
    }
    Write-Output ($validation | ConvertTo-Json -Depth 3)
    return $true
}

function Main {
    Write-Log "Secrets Manager v$SecretsVersion (DPAPI vault)" "info"
    Write-Log "Action: $Action" "info"

    if (($Action -in @('get', 'delete')) -and [string]::IsNullOrEmpty($Reason)) {
        Write-Log "Reason is mandatory for $Action operation. Pass -Reason '<justification>'." "error"
        return 1
    }

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
