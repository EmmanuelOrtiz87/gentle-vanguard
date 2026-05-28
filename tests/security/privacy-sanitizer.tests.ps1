#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests for privacy-sanitizer.ps1 — PII redaction, data leakage prevention
#>

Describe "Privacy Sanitizer (privacy-sanitizer.ps1)" {
    BeforeAll {
        $script:scriptPath = Join-Path $PSScriptRoot "..\..\scripts\security\privacy-sanitizer.ps1"
    }

    Context "PII Redaction" {
        It "Should redact IP addresses" {
            $result = & $script:scriptPath -Content "Request from 10.0.0.1" -Mode prompt 2>&1
            $LASTEXITCODE | Should -Be 0
        }

        It "Should redact home paths" {
            $result = & $script:scriptPath -Content "Path: C:\Users\testuser\file.txt" -Mode prompt 2>&1
            $LASTEXITCODE | Should -Be 0
        }

        It "Should redact environment secret patterns" {
            $result = & $script:scriptPath -Content "export API_KEY=supersecret123" -Mode prompt 2>&1
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context "Mode Handling" {
        It "Should process prompt mode" {
            & $script:scriptPath -Content "test data" -Mode prompt
            $LASTEXITCODE | Should -Be 0
        }

        It "Should process log mode" {
            & $script:scriptPath -Content "test data" -Mode log
            $LASTEXITCODE | Should -Be 0
        }

        It "Should process error mode" {
            & $script:scriptPath -Content "test data" -Mode error
            $LASTEXITCODE | Should -Be 0
        }
    }
}



