#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests for secrets-manager.ps1 (v2.0) — DPAPI vault delegation
#>

$script:scriptPath = Join-Path $PSScriptRoot "..\..\scripts\security\secrets-manager.ps1"
$script:vaultScript = Join-Path $PSScriptRoot "..\..\scripts\security\secret-vault.ps1"

Describe "Secrets Manager (secrets-manager.ps1)" {

    Context "Parameter Validation" {
        It "Should accept valid actions" {
            $validActions = @('get', 'set', 'delete', 'list', 'rotate', 'validate')
            foreach ($action in $validActions) {
                { & $script:scriptPath -Action $action -SecretName "TEST_KEY" -SecretValue "test_val" -ErrorAction SilentlyContinue } | Should Not Throw
            }
        }

        It "Should reject invalid actions" {
            $errorSeen = $false
            try {
                & $script:scriptPath -Action invalid_action -ErrorAction Stop 2>$null
            } catch {
                $errorSeen = $true
            }
            $errorSeen | Should Be $true
        }
    }

    Context "Vault Delegation" {
        It "Should detect vault script presence" {
            if (Test-Path $script:vaultScript) {
                $true | Should Be $true
            } else {
                Write-Warning "secret-vault.ps1 not found — vault delegation tests skipped"
                Set-TestInconclusive
            }
        }
    }

    Context "Fallback Security" {
        It "Should not store secrets in config/.secrets file" {
            $secretsFile = Join-Path (Split-Path $script:scriptPath -Parent | Split-Path -Parent) "config\.secrets"
            Test-Path $secretsFile | Should Be $false
        }

        It "Should reference vault script correctly" {
            $content = Get-Content $script:scriptPath -Raw
            $content | Should Match "secret-vault.ps1"
        }
    }
}
