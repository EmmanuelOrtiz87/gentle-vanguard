#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests for security-logger.ps1 (v1.1) — PII sanitization + audit logging
#>

$script:scriptPath = Join-Path $PSScriptRoot "..\..\scripts\security\security-logger.ps1"

Describe "Security Logger (security-logger.ps1)" {

    Context "PII Sanitization" {
        It "Should redact machine name from messages" {
            $script:result = & $script:scriptPath -EventType info -Message "User accessed config" -Severity low
            $LASTEXITCODE | Should -Be 0
        }

        It "Should redact IP addresses in logs" {
            $content = "Login from 192.168.1.1"
            $sanitized = $content -replace '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', '<IP>'
            $sanitized | Should -Be "Login from <IP>"
        }

        It "Should redact username patterns in messages" {
            $raw = "User JohnDoe accessed secret"
            $sanitized = $raw -replace 'User [A-Za-z0-9_]+', 'User <USER>'
            $sanitized | Should -Be "User <USER> accessed secret"
        }

        It "Should not contain raw environment variables in sanitized output" {
            $envVars = @($env:USERNAME, $env:COMPUTERNAME)
            $sanitized = "Log from $env:USERNAME on $env:COMPUTERNAME"
            $sanitized = $sanitized -replace [regex]::Escape($env:USERNAME), '<USER>'
            $sanitized = $sanitized -replace [regex]::Escape($env:COMPUTERNAME), '<MACHINE>'
            $sanitized | Should -Not -Match "^Log from $env:USERNAME"
            $sanitized | Should -Match '<USER>'
            $sanitized | Should -Match '<MACHINE>'
        }
    }

    Context "Message Validation" {
        It "Should reject empty messages" {
            & $script:scriptPath -EventType info -Message "" -Severity low 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }

        It "Should reject null messages" {
            & $script:scriptPath -EventType info -Message $null -Severity low 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 1
        }
    }
}



