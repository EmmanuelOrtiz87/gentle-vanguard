#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Encryption Manager - AES-256 Encryption for Engram Packs
    
.DESCRIPTION
    Manages encryption and decryption of sensitive data using AES-256
    
.PARAMETER Action
    Action: encrypt, decrypt, generate-key, validate
    
.PARAMETER Data
    Data to encrypt/decrypt
    
.PARAMETER KeyPath
    Path to encryption key
    
.EXAMPLE
    .\encryption-manager.ps1 -Action encrypt -Data "sensitive" -KeyPath ".\keys\master.key"
#>

param(
    [ValidateSet('encrypt', 'decrypt', 'generate-key', 'validate')]
    [string]$Action = 'validate',
    [string]$Data,
    [string]$KeyPath = ".\keys\master.key",
    [string]$LogLevel = 'info'
)

$EncryptionVersion = "1.0.0"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$keysDir = ".\keys"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Initialize-KeyDirectory {
    Write-Log "Initializing key directory..." "info"
    
    if (-not (Test-Path $keysDir)) {
        New-Item -ItemType Directory -Path $keysDir -Force | Out-Null
        Write-Log "Key directory created: $keysDir" "info"
    }
}

function Generate-EncryptionKey {
    Write-Log "Generating AES-256 encryption key..." "info"
    
    Initialize-KeyDirectory
    
    $key = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($key)
    
    $keyBase64 = [Convert]::ToBase64String($key)
    Set-Content -Path $KeyPath -Value $keyBase64 -Force
    
    Write-Log "Encryption key generated: $KeyPath" "info"
    return $key
}

function Get-EncryptionKey {
    Write-Log "Loading encryption key..." "info"
    
    if (-not (Test-Path $KeyPath)) {
        Write-Log "Key not found, generating new key..." "warn"
        return Generate-EncryptionKey
    }
    
    $keyBase64 = Get-Content -Path $KeyPath
    $key = [Convert]::FromBase64String($keyBase64)
    
    if ($key.Length -ne 32) {
        Write-Log "Invalid key length: $($key.Length)" "error"
        throw "Invalid encryption key"
    }
    
    Write-Log "Encryption key loaded successfully" "info"
    return $key
}

function Encrypt-Data {
    param([string]$PlainText)
    
    Write-Log "Encrypting data..." "info"
    
    if ([string]::IsNullOrEmpty($PlainText)) {
        Write-Log "Cannot encrypt empty data" "error"
        throw "Data cannot be empty"
    }
    
    $key = Get-EncryptionKey
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    
    $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)
    $memoryStream = New-Object System.IO.MemoryStream
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    
    $streamWriter = New-Object System.IO.StreamWriter($cryptoStream)
    $streamWriter.Write($PlainText)
    $streamWriter.Close()
    $cryptoStream.Close()
    
    $encryptedData = $memoryStream.ToArray()
    $iv = $aes.IV
    
    $result = @{
        iv = [Convert]::ToBase64String($iv)
        data = [Convert]::ToBase64String($encryptedData)
        timestamp = (Get-Date -Format "o")
        algorithm = "AES-256"
    }
    
    Write-Log "Data encrypted successfully" "info"
    return $result | ConvertTo-Json
}

function Decrypt-Data {
    param([string]$EncryptedJson)
    
    Write-Log "Decrypting data..." "info"
    
    if ([string]::IsNullOrEmpty($EncryptedJson)) {
        Write-Log "Cannot decrypt empty data" "error"
        throw "Data cannot be empty"
    }
    
    $encrypted = $EncryptedJson | ConvertFrom-Json
    $key = Get-EncryptionKey
    
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.IV = [Convert]::FromBase64String($encrypted.iv)
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    
    $decryptor = $aes.CreateDecryptor($aes.Key, $aes.IV)
    $encryptedData = [Convert]::FromBase64String($encrypted.data)
    $memoryStream = New-Object System.IO.MemoryStream(, $encryptedData)
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
    
    $streamReader = New-Object System.IO.StreamReader($cryptoStream)
    $plainText = $streamReader.ReadToEnd()
    $streamReader.Close()
    $cryptoStream.Close()
    
    Write-Log "Data decrypted successfully" "info"
    return $plainText
}

function Validate-Encryption {
    Write-Log "Validating encryption setup..." "info"
    
    $validation = @{
        keyExists = Test-Path $KeyPath
        keyValid = $false
{
  "prompt_tokens": 88670,
  "prompt_unit_price": "0",
  "prompt_price_unit": "0",
  "prompt_price": "0",
  "completion_tokens": 8096,
  "completion_unit_price": "0",
  "completion_price_unit": "0",
  "completion_price": "0",
  "total_tokens": 96766,
  "total_price": "0",
  "currency": "USD",
  "latency": 43.834,
  "time_to_first_token": 3.578,
  "time_to_generate": 40.256
}