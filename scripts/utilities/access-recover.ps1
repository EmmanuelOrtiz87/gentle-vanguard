<#
.SYNOPSIS
    Recover or reset API key using security questions
.DESCRIPTION
    If the owner forgets their API key, they can recover it by answering 3 security questions correctly.
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Reset,
    
    [Parameter(Mandatory=$false)]
    [string]$NewApiKey
)

$ErrorActionPreference = "Stop"

$authPath = ".workspace\config\owner-auth.json"

if (-not (Test-Path $authPath)) {
    Write-Host "[ERROR] Auth configuration not found" -ForegroundColor Red
    exit 1
}

$auth = Get-Content $authPath | ConvertFrom-Json

if ($Reset) {
    if (-not $NewApiKey) {
        Write-Host "[ERROR] New API key required for reset" -ForegroundColor Red
        Write-Host "[INFO] Usage: .\access-recover.ps1 -Reset -NewApiKey <new-key>" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "=== Security Questions Recovery ===" -ForegroundColor Cyan
    Write-Host "You must answer all 3 questions correctly to reset your API key" -ForegroundColor Yellow
    Write-Host ""
    
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $correct = 0
    
    $questions = @(
        @{ id = "q1"; q = $auth.securityQuestions.q1.question },
        @{ id = "q2"; q = $auth.securityQuestions.q2.question },
        @{ id = "q3"; q = $auth.securityQuestions.q3.question }
    )
    
    foreach ($q in $questions) {
        Write-Host "Q: $($q.q)" -ForegroundColor Cyan
        $answer = Read-Host "Answer" -AsSecureString
        
        $answerStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($answer))
        $answerStr = $answerStr.ToLower().Trim()
        
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($answerStr)
        $hashBytes = $hash.ComputeHash($bytes)
        $answerHash = "sha256:" + [Convert]::ToBase64String($hashBytes)
        
        $expected = $auth.securityQuestions[$q.id].answerHash
        
        if ($answerHash -eq $expected) {
            Write-Host "[OK] Correct!" -ForegroundColor Green
            $correct++
        } else {
            Write-Host "[X] Incorrect" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($correct -eq 3) {
        Write-Host "[SUCCESS] All answers correct! Resetting API key..." -ForegroundColor Green
        
        $auth.apiKey = $NewApiKey
        $auth | ConvertTo-Json -Depth 10 | Set-Content $authPath
        
        Write-Host "[DONE] API key reset to: $NewApiKey" -ForegroundColor Green
        Write-Host "[IMPORTANT] Update your scripts with the new key!" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Only $correct/3 correct - access denied" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "=== API Key Recovery ===" -ForegroundColor Cyan
    Write-Host "Answer all 3 security questions to recover your API key" -ForegroundColor Yellow
    Write-Host ""
    
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $correct = 0
    
    $questions = @(
        @{ id = "q1"; q = $auth.securityQuestions.q1.question },
        @{ id = "q2"; q = $auth.securityQuestions.q2.question },
        @{ id = "q3"; q = $auth.securityQuestions.q3.question }
    )
    
    foreach ($q in $questions) {
        Write-Host "Q: $($q.q)" -ForegroundColor Cyan
        $answer = Read-Host "Answer" -AsSecureString
        
        $answerStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($answer))
        $answerStr = $answerStr.ToLower().Trim()
        
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($answerStr)
        $hashBytes = $hash.ComputeHash($bytes)
        $answerHash = "sha256:" + [Convert]::ToBase64String($hashBytes)
        
        $expected = $auth.securityQuestions[$q.id].answerHash
        
        if ($answerHash -eq $expected) {
            Write-Host "[OK] Correct!" -ForegroundColor Green
            $correct++
        } else {
            Write-Host "[X] Incorrect" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($correct -eq 3) {
        Write-Host "[SUCCESS] All answers correct!" -ForegroundColor Green
        Write-Host "Your API key: $($auth.apiKey)" -ForegroundColor Cyan
    } else {
        Write-Host "[ERROR] Only $correct/3 correct - access denied" -ForegroundColor Red
        Write-Host "[INFO] Use -Reset to generate a new key" -ForegroundColor Yellow
        exit 1
    }
}