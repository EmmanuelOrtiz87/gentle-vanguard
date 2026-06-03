#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Git Hooks Setup - Configures automated testing hooks
    
.DESCRIPTION
    Sets up pre-commit and pre-push hooks for automated testing
    
.EXAMPLE
    .\git-hooks-setup.ps1
#>

$HooksVersion = "1.0.0"
$gitHooksDir = ".git/hooks"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Create-PreCommitHook {
    Write-Log "Creating pre-commit hook..." "info"
    
    $hookContent = @'
#!/bin/bash
# Pre-commit hook - Run unit tests before commit

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [info] Running pre-commit tests..."

# Run unit tests
pwsh -NoProfile -ExecutionPolicy Bypass -File "scripts/testing/run-tests.ps1" -TestType unit

if ($LASTEXITCODE -ne 0) {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [error] Pre-commit tests failed"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [info] Pre-commit tests passed"
exit 0
'@
    
    $hookPath = "$gitHooksDir/pre-commit"
    Set-Content -Path $hookPath -Value $hookContent -Encoding UTF8
    
    # Make executable on Unix
    if ($PSVersionTable.Platform -eq "Unix") {
        chmod +x $hookPath
    }
    
    Write-Log "Pre-commit hook created: $hookPath" "info"
}

function Create-PrePushHook {
    Write-Log "Creating pre-push hook..." "info"
    
    $hookContent = @'
#!/bin/bash
# Pre-push hook - Run all tests before push

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [info] Running pre-push tests..."

# Run all tests
pwsh -NoProfile -ExecutionPolicy Bypass -File "scripts/testing/run-tests.ps1" -TestType all -GenerateReport

if ($LASTEXITCODE -ne 0) {
    echo
{
  "prompt_tokens": 102866,
  "prompt_unit_price": "0",
  "prompt_price_unit": "0",
  "prompt_price": "0",
  "completion_tokens": 8096,
  "completion_unit_price": "0",
  "completion_price_unit": "0",
  "completion_price": "0",
  "total_tokens": 110962,
  "total_price": "0",
  "currency": "USD",
  "latency": 40.893,
  "time_to_first_token": 2.516,
  "time_to_generate": 38.377
}