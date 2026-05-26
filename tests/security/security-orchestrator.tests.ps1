#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Tests for security-orchestrator.ps1 — sanitization, blocking, auth
#>

$script:scriptPath = Join-Path $PSScriptRoot "..\..\scripts\security\security-orchestrator.ps1"

Describe "Security Orchestrator (security-orchestrator.ps1)" {

    Context "Initialization" {
        It "Should return status without errors" {
            $result = & $script:scriptPath -Action status -AsJson | ConvertFrom-Json
            $result.status | Should Be "OK"
        }

        It "Should have security enabled by default" {
            $result = & $script:scriptPath -Action status -AsJson | ConvertFrom-Json
            $result.enabled | Should Be $true
        }
    }

    Context "Sanitization" {
        It "Should sanitize machine names" {
            $content = "Server: $env:COMPUTERNAME is running"
            $result = & $script:scriptPath -Action sanitize -Content $content -Mode prompt -AsJson | ConvertFrom-Json
            $result.status | Should Be "OK"
            $result.sanitized | Should Match '<MACHINE>'
        }

        It "Should sanitize usernames" {
            $content = "User: $env:USERNAME logged in"
            $result = & $script:scriptPath -Action sanitize -Content $content -Mode log -AsJson | ConvertFrom-Json
            $result.status | Should Be "OK"
            $result.sanitized | Should Match '<USER>'
        }
    }

    Context "Critical Pattern Blocking" {
        It "Should block AWS access keys" {
            $content = "AWS key: AKIAIOSFODNN7EXAMPLE"
            $result = & $script:scriptPath -Action block -Content $content -AsJson | ConvertFrom-Json
            $result.status | Should Be "BLOCKED"
        }

        It "Should block GitHub tokens" {
            $content = "ghp_A0B1C2D3E4F5G6H7I8J9K0L1M2N3O4P5Q6R7S8T9U0V1"
            $result = & $script:scriptPath -Action block -Content $content -AsJson | ConvertFrom-Json
            $result.status | Should Be "BLOCKED"
        }

        It "Should allow safe content" {
            $content = "This is a safe message without secrets"
            $result = & $script:scriptPath -Action block -Content $content -AsJson | ConvertFrom-Json
            $result.status | Should Be "OK"
        }
    }

    Context "Scan" {
        It "Should scan for critical patterns without errors" {
            $result = & $script:scriptPath -Action scan -Targets @(".") -AsJson | ConvertFrom-Json
            $result.status | Should Be "OK"
        }
    }
}
