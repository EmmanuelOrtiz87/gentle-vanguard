#Requires -Version 7.0
<#
.SYNOPSIS
    Data Encryption Utility for Sensitive Metrics
.DESCRIPTION
    Encrypts and decrypts sensitive data in JSON files using AES encryption.
.NOTES
    Version: 1.0.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('encrypt', 'decrypt')]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [string]$KeyFile = ".runtime/.encryption-key"
)

$ErrorActionPreference = 'Stop'

function Get-OrCreateEncryptionKey {
    param($KeyFile)
    
    if (Test-Path $KeyFile) {
        $keyBytes = Get-Content $KeyFile -Encoding Byte -Raw
        return $keyBytes
    }
    
    # Generate new key
    $keyBytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($keyBytes)
    
    # Ensure directory exists
    $dir = Split-Path -Parent $KeyFile
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    # Save key (in production, use secure key management)
    Set-Content $KeyFile -Value $keyBytes -Encoding Byte
    Write-Host "New encryption key generated at: $KeyFile" -ForegroundColor Yellow
    
    return $keyBytes
}

function Protect-Data {
    param($Data, $Key)
    
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.GenerateIV()
    
    $encryptor = $aes.CreateEncryptor()
    $encryptedBytes = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
    
    # Combine IV + encrypted data
    $result = $aes.IV + $encryptedBytes
    
    return [Convert]::ToBase64String($result)
}

function Unprotect-Data {
    param($EncryptedData, $Key)
    
    $encryptedBytes = [Convert]::FromBase64String($EncryptedData)
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    
    # Extract IV (first 16 bytes)
    $aes.IV = $encryptedBytes[0..15]
    $cipherText = $encryptedBytes[16..($encryptedBytes.Length - 1)]
    
    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($cipherText, 0, $cipherText.Length)
    
    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

# Main execution
$key = Get-OrCreateEncryptionKey -KeyFile $KeyFile

switch ($Action) {
    'encrypt' {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        $content = Get-Content $FilePath -Raw
        $encrypted = Protect-Data -Data $content -Key $key
        
        $outputPath = "$FilePath.encrypted"
        Set-Content $outputPath -Value $encrypted
        
        Write-Host "Encrypted: $outputPath" -ForegroundColor Green
    }
    
    'decrypt' {
        $encryptedPath = "$FilePath.encrypted"
        if (-not (Test-Path $encryptedPath)) {
            throw "Encrypted file not found: $encryptedPath"
        }
        
        $encrypted = Get-Content $encryptedPath -Raw
        $decrypted = Unprotect-Data -EncryptedData $encrypted -Key $key
        
        Set-Content $FilePath -Value $decrypted
        Write-Host "Decrypted: $FilePath" -ForegroundColor Green
    }
}
