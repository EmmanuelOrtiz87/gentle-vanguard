<#
.SYNOPSIS
    Secure Auth Module - Encrypts/decrypts owner-auth.json using Windows DPAPI
.DESCRIPTION
    Uses Windows Data Protection API (DPAPI) to encrypt sensitive data.
    Only the current user on the current machine can decrypt.
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('encrypt', 'decrypt', 'lock', 'unlock', 'status')]
    [string]$Action,
    
    [string]$InputFile = ".workspace\config\owner-auth.json",
    [string]$OutputFile,
    
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

$authFile = $InputFile
$encryptFile = $authFile + ".enc"
$lockFile = $authFile + ".lock"

# =============================================================================
# DPAPI FUNCTIONS
# =============================================================================

function Add-Encryption {
    param([string]$FilePath, [string]$DestPath)
    
    if (-not (Test-Path $FilePath)) {
        return @{ status = 'ERROR'; message = 'File not found' }
    }
    
    $content = Get-Content $FilePath -Raw
    
    # Convert to bytes
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    
    # Encrypt using DPAPI (CurrentUser scope)
    $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    
    # Save encrypted data
    $dest = if ($DestPath) { $DestPath } else { $encryptFile }
    [System.IO.File]::WriteAllBytes($dest, $encrypted)
    
    return @{
        status = 'OK'
        message = 'Encrypted successfully'
        originalFile = $FilePath
        encryptedFile = $dest
    }
}

function Remove-Encryption {
    param([string]$FilePath, [string]$DestPath)
    
    if (-not (Test-Path $FilePath)) {
        return @{ status = 'ERROR'; message = 'Encrypted file not found' }
    }
    
    try {
        # Read encrypted data
        $encrypted = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Decrypt using DPAPI
        $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $encrypted,
            $null,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        
        # Convert to string
        $content = [System.Text.Encoding]::UTF8.GetString($decrypted)
        
        $dest = if ($DestPath) { $DestPath } else { $authFile }
        Set-Content -Path $dest -Value $content -Encoding UTF8
        
        return @{
            status = 'OK'
            message = 'Decrypted successfully'
            encryptedFile = $FilePath
            decryptedFile = $dest
        }
    }
    catch {
        return @{
            status = 'ERROR'
            message = "Decryption failed: $_"
        }
    }
}

# =============================================================================
# LOCKOUT FUNCTIONS (Rate Limiting)
# =============================================================================

function Get-LockStatus {
    if (Test-Path $lockFile) {
        $lock = Get-Content $lockFile -Raw | ConvertFrom-Json
        $lockoutEnd = [DateTime]::Parse($lock.lockoutEnd)
        
        if ($lockoutEnd -gt (Get-Date)) {
            $remaining = ($lockoutEnd - (Get-Date)).TotalMinutes
            return @{
                locked = $true
                attempts = $lock.attempts
                lockoutEnd = $lock.lockoutEnd
                remainingMinutes = [Math]::Round($remaining, 1)
            }
        }
        else {
            Remove-Item $lockFile -ErrorAction SilentlyContinue
        }
    }
    
    return @{ locked = $false; attempts = 0; lockoutEnd = $null }
}

function Set-Lockout {
    param([int]$Attempts)
    
    $lockout = @{
        attempts = $Attempts
        lockoutEnd = (Get-Date).AddMinutes(15).ToString("o")
        timestamp = (Get-Date).ToString("o")
    }
    
    $lockout | ConvertTo-Json | Set-Content $lockFile -Encoding UTF8
    
    return @{
        locked = $true
        attempts = $Attempts
        lockoutEnd = $lockout.lockoutEnd
    }
}

function Add-FailedAttempt {
    $status = Get-LockStatus
    
    if ($status.locked) {
        return $status
    }
    
    $newAttempts = $status.attempts + 1
    
    if ($newAttempts -ge 3) {
        return Set-Lockout -Attempts $newAttempts
    }
    
    $tempLock = @{
        attempts = $newAttempts
        lockoutEnd = $null
    }
    $tempLock | ConvertTo-Json | Set-Content $lockFile -Encoding UTF8
    
    return @{
        locked = $false
        attempts = $newAttempts
        remaining = 3 - $newAttempts
    }
}

function Clear-Lockout {
    if (Test-Path $lockFile) {
        Remove-Item $lockFile -Force
    }
    return @{ status = 'OK'; message = 'Lockout cleared' }
}

# =============================================================================
# MAIN
# =============================================================================

Add-Type -AssemblyName System.Security

$result = switch ($Action) {
    'encrypt' {
        Add-Encryption -FilePath $InputFile -DestPath $OutputFile
    }
    
    'decrypt' {
        Remove-Encryption -FilePath $InputFile -DestPath $OutputFile
    }
    
    'lock' {
        Set-Lockout -Attempts 3
    }
    
    'unlock' {
        Clear-Lockout
    }
    
    'status' {
        $lockStatus = Get-LockStatus
        $encrypted = Test-Path $encryptFile
        
        @{
            status = 'OK'
            encrypted = $encrypted
            lockout = $lockStatus
        }
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 3
}
else {
    switch ($Action) {
        'status' {
            Write-Host "=== SECURE AUTH STATUS ===" -ForegroundColor Cyan
            Write-Host "Encrypted: $($result.encrypted)" -ForegroundColor $(if($result.encrypted){'Yellow'}else{'Gray'})
            if ($result.lockout.locked) {
                Write-Host "Status: LOCKED" -ForegroundColor Red
                Write-Host "Remaining: $($result.lockout.remainingMinutes) min" -ForegroundColor Red
            } else {
                Write-Host "Status: OK" -ForegroundColor Green
                Write-Host "Attempts: $($result.lockout.attempts)/3" -ForegroundColor Yellow
            }
        }
        default {
            if ($result.status -eq 'OK') {
                Write-Host "[$($result.status)] $($result.message)" -ForegroundColor Green
            }
            elseif ($result.status -eq 'ERROR') {
                Write-Host "[$($result.status)] $($result.message)" -ForegroundColor Red
            }
        }
    }
}