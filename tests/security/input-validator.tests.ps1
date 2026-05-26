#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests for input-validator.ps1 — type validation, sanitization, injection prevention
#>

$script:scriptPath = Join-Path $PSScriptRoot "..\..\scripts\security\input-validator.ps1"

Describe "Input Validator (input-validator.ps1)" {

    Context "Integer Validation" {
        It "Should accept valid integer within range" {
            & $script:scriptPath -Input "42" -Type integer
            $LASTEXITCODE | Should Be 0
        }

        It "Should accept zero" {
            & $script:scriptPath -Input "0" -Type integer
            $LASTEXITCODE | Should Be 0
        }

        It "Should accept max range value" {
            & $script:scriptPath -Input "10000" -Type integer
            $LASTEXITCODE | Should Be 0
        }

        It "Should reject negative values" {
            & $script:scriptPath -Input "-5" -Type integer
            $LASTEXITCODE | Should Be 1
        }

        It "Should reject values above range" {
            & $script:scriptPath -Input "10001" -Type integer
            $LASTEXITCODE | Should Be 1
        }

        It "Should reject non-numeric strings" {
            & $script:scriptPath -Input "abc" -Type integer
            $LASTEXITCODE | Should Be 1
        }

        It "Should reject empty strings" {
            & $script:scriptPath -Input "" -Type integer
            $LASTEXITCODE | Should Be 1
        }
    }

    Context "String Validation" {
        It "Should accept valid strings" {
            & $script:scriptPath -Input "test-data" -Type string
            $LASTEXITCODE | Should Be 0
        }

        It "Should reject null strings" {
            & $script:scriptPath -Input "" -Type string
            $LASTEXITCODE | Should Be 1
        }
    }

    Context "Path Validation" {
        It "Should reject path traversal" {
            & $script:scriptPath -Input "..\..\etc\passwd" -Type path
            $LASTEXITCODE | Should Be 1
        }

        It "Should reject absolute paths" {
            & $script:scriptPath -Input "C:\Windows\System32" -Type path
            $LASTEXITCODE | Should Be 1
        }
    }

    Context "Command Injection" {
        It "Should reject command chaining with &&" {
            & $script:scriptPath -Input "dir && rm -rf /" -Type command
            $LASTEXITCODE | Should Be 1
        }

        It "Should reject pipe operators" {
            & $script:scriptPath -Input "dir | format" -Type command
            $LASTEXITCODE | Should Be 1
        }

        It "Should reject semicolons" {
            & $script:scriptPath -Input "dir; rm -rf" -Type command
            $LASTEXITCODE | Should Be 1
        }
    }

    Context "Email Validation" {
        It "Should accept valid emails" {
            & $script:scriptPath -Input "user@example.com" -Type email
            $LASTEXITCODE | Should Be 0
        }

        It "Should reject invalid emails" {
            & $script:scriptPath -Input "not-an-email" -Type email
            $LASTEXITCODE | Should Be 1
        }
    }
}
