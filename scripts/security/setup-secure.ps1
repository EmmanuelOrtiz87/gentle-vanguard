<#
.SYNOPSIS
    Security Setup for Developers
.DESCRIPTION
    Run this when cloning the repo for the first time.
    Generates your personal API key and configures security.
#>

param(
    [switch]$Force,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

$workspaceDir = ".workspace\config"
$ownerAuthFile = Join-Path $workspaceDir "owner-auth.json"
$ownerAuthExample = Join-Path $workspaceDir "owner-auth.example.json"
$sessionAuthFile = Join-Path $workspaceDir "session-auth.json"
$deployConfig = "config\security-deploy.json"

function Write-Header {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  SECURITY SETUP FOR DEVELOPERS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}

function New-ApiKey {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(24)
    $random = -join ($bytes | ForEach-Object { '{0:x2}' -f $_ })
    return "fnd_$timestamp`_$random"
}

function Initialize-DeveloperAuth {
    # Check if already configured
    if ((Test-Path $ownerAuthFile) -and -not $Force) {
        return @{
            status = "ALREADY_CONFIGURED"
            message = "Security already configured. Use -Force to regenerate."
        }
    }
    
    # Create workspace config dir
    if (-not (Test-Path $workspaceDir)) {
        New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null
    }
    
    # Generate new API key
    $apiKey = New-ApiKey
    
    # Create owner auth file
    $auth = @{
        name = "developer"
        apiKey = $apiKey
        createdAt = (Get-Date).ToString("o")
        securityQuestions = @{
            q1 = @{
                question = "What is your favorite programming language?"
                answerHash = "sha256:placeholder"
            }
            q2 = @{
                question = "What city were you born in?"
                answerHash = "sha256:placeholder"
            }
            q3 = @{
                question = "What is your favorite food?"
                answerHash = "sha256:placeholder"
            }
        }
        permissions = @(
            "run-skill-optimizer",
            "modify-skills",
            "run-tests",
            "access-workspace-config"
        )
    }
    
    $auth | ConvertTo-Json -Depth 3 | Set-Content $ownerAuthFile -Encoding UTF8
    
    return @{
        status = "OK"
        message = "Security configured successfully"
        apiKey = $apiKey
        file = $ownerAuthFile
    }
}

# MAIN
Write-Header

Write-Host "[REPO] Environment detected" -ForegroundColor Cyan

$result = Initialize-DeveloperAuth -Force:$Force

if ($AsJson) {
    $result | ConvertTo-Json
}
else {
    Write-Host ""
    if ($result.status -eq "OK") {
        Write-Host "[OK] $($result.message)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your API Key: $($result.apiKey)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Store this key securely. You will need it for:" -ForegroundColor White
        Write-Host "  - .\scripts\security\security-orchestrator.ps1 -Action disable -ApiKey <key>" -ForegroundColor Gray
        Write-Host "  - Modify security configuration" -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host "[$($result.status)] $($result.message)" -ForegroundColor Yellow
    }
}