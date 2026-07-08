<#
.SYNOPSIS
  Federation Auth — cross-org authentication via challenge-response handshake.
.DESCRIPTION
  Manages trust between organizations. Uses asymmetric key pairs for identity.
  Supports handshake, verify, token generation/validation, and key management.
.PARAMETER Action
  handshake — initiate or respond to a cross-org authentication
  verify    — verify a signed message from another org
  token     — generate or validate a delegation token
  keys      — manage local key pair (generate/export/rotate)
.PARAMETER TargetOrg
  Target org ID (for handshake).
.PARAMETER Message
  Message or token to verify.
.PARAMETER Signature
  Signature to verify against message.
.PARAMETER PublicKey
  Public key of the signing org (PEM format).
.PARAMETER Duration
  Token validity in minutes (default: from config).
.EXAMPLE
  .\federation-auth.ps1 -Action handshake -TargetOrg "acme-corp"
  .\federation-auth.ps1 -Action verify -Message "hello" -Signature "signed-data" -PublicKey "pub-key"
  .\federation-auth.ps1 -Action token -Duration 120
#>

param(
  [ValidateSet("handshake", "verify", "token", "keys")]
  [string]$Action = "keys",
  [string]$TargetOrg = "",
  [string]$Message = "",
  [string]$Signature = "",
  [string]$PublicKey = "",
  [int]$Duration = 0
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
  $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
  if (-not $root) { $root = (Get-Location).Path }
  $root
}

$configPath = Join-Path $repoRoot "config\federation-config.json"
if (-not (Test-Path $configPath)) { Write-Error "federation-config.json not found"; exit 1 }
$config = Get-Content $configPath -Raw | ConvertFrom-Json

$federationDir = Join-Path $repoRoot ".session\federation"
$null = New-Item -ItemType Directory -Path $federationDir -Force

$localKeyPath = Join-Path $repoRoot $config.localOrg.keyPath
$localKeyDir = Split-Path -Parent $localKeyPath
$null = New-Item -ItemType Directory -Path $localKeyDir -Force

function Get-LocalKeyPair {
  $keyFile = $localKeyPath
  if (-not (Test-Path $keyFile)) {
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $keyFile) -Force
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    $privateKey = $rsa.ToXmlString($true)
    Set-Content $keyFile $privateKey -Encoding utf8
  } else {
    $privateKey = Get-Content $keyFile -Raw
  }
  $rsa = [System.Security.Cryptography.RSA]::Create()
  $rsa.FromXmlString($privateKey)
  return $rsa
}

function Get-PublicKeyPem {
  $rsa = Get-LocalKeyPair
  $pubKey = [System.Security.Cryptography.RSA]::Create()
  $pubKey.ImportParameters($rsa.ExportParameters($false))
  $pubBytes = $pubKey.ExportSubjectPublicKeyInfo()
  $b64 = [Convert]::ToBase64String($pubBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
  $header = "BEGIN " + "PUBLIC KEY"
  $footer = "END " + "PUBLIC KEY"
  return "-----${header}-----`n$b64`n-----${footer}-----"
}

function New-AuthToken {
  param([string]$OrgId, [int]$ValidMinutes)
  $expiry = (Get-Date).AddMinutes($ValidMinutes).ToString("o")
  $tokenData = @{ org = $config.localOrg.id; target = $OrgId; exp = $expiry; nonce = (Get-Random -Minimum 100000 -Maximum 999999).ToString() }
  $tokenStr = ($tokenData | ConvertTo-Json -Compress)
  $rsa = Get-LocalKeyPair
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($tokenStr)
  $signed = $rsa.SignData($bytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
  $sigB64 = [Convert]::ToBase64String($signed)
  return @{ jwt = $tokenStr; signature = $sigB64; publicKey = Get-PublicKeyPem }
}

function Test-TokenValid {
  param($AuthToken)
  try {
    $tokenData = $AuthToken.jwt | ConvertFrom-Json
    $expiry = [DateTime]::Parse($tokenData.exp)
    if ($expiry -lt (Get-Date)) { return $false }
    $rsa = [System.Security.Cryptography.RSA]::Create()
    $pubBytes = [Convert]::FromBase64String(($AuthToken.publicKey -replace "-----BEGIN PUBLIC KEY-----" -replace "-----END PUBLIC KEY-----" -replace "`n" -replace "`r"))
    $rsa.ImportSubjectPublicKeyInfo($pubBytes, [ref]0)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($AuthToken.jwt)
    $sigBytes = [Convert]::FromBase64String($AuthToken.signature)
    return $rsa.VerifyData($bytes, $sigBytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
  } catch { return $false }
}

switch ($Action) {
  "handshake" {
    if (-not $TargetOrg) { Write-Error "Provide -TargetOrg"; exit 1 }
    $nonce = (Get-Random -Minimum 100000000 -Maximum 999999999).ToString()
    $challenge = @{ from = $config.localOrg.id; to = $TargetOrg; nonce = $nonce; timestamp = Get-Date -Format "o" }
    Write-Host "[FED-AUTH] Handshake with $TargetOrg..." -ForegroundColor Cyan
    Write-Host "[FED-AUTH] Challenge: $($challenge.nonce)" -ForegroundColor Gray
    Write-Host "[FED-AUTH] Ready — awaiting signed response from $TargetOrg" -ForegroundColor Yellow
    return @{ status = "challenge-sent"; challenge = $challenge; expectedNonce = $nonce }
  }

  "verify" {
    if (-not $Message) { Write-Error "Provide -Message"; exit 1 }
    if (-not $Signature) { Write-Error "Provide -Signature"; exit 1 }
    if (-not $PublicKey) { Write-Error "Provide -PublicKey"; exit 1 }
    try {
      $rsa = [System.Security.Cryptography.RSA]::Create()
      $pubBytes = [Convert]::FromBase64String(($PublicKey -replace "-----BEGIN PUBLIC KEY-----" -replace "-----END PUBLIC KEY-----" -replace "`n" -replace "`r"))
      $rsa.ImportSubjectPublicKeyInfo($pubBytes, [ref]0)
      $msgBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
      $sigBytes = [Convert]::FromBase64String($Signature)
      $valid = $rsa.VerifyData($msgBytes, $sigBytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
      Write-Host "[FED-AUTH] Signature verification: $(if($valid){'VALID'}else{'INVALID'})" -ForegroundColor $(if($valid){'Green'}else{'Red'})
      return @{ valid = $valid; message = $Message }
    } catch {
      Write-Host "[FED-AUTH] Verification error: $($_.Exception.Message)" -ForegroundColor Red
      return @{ valid = $false; error = $_.Exception.Message }
    }
  }

  "token" {
    $validMinutes = if ($Duration -gt 0) { $Duration } else { [int]$config.auth.tokenExpiryMinutes }
    if ($TargetOrg) {
      $jwt = New-AuthToken -OrgId $TargetOrg -ValidMinutes $validMinutes
      $valid = Test-TokenValid -AuthToken $jwt
      Write-Host "[FED-AUTH] Token for $TargetOrg (expires in ${validMinutes}m):" -ForegroundColor Cyan
      Write-Host "[FED-AUTH] Token valid: $valid" -ForegroundColor $(if($valid){'Green'}else{'Red'})
      return $jwt
    }
    Write-Error "Provide -TargetOrg for token generation"; exit 1
  }

  "keys" {
    $pubKey = Get-PublicKeyPem
    Write-Host "[FED-AUTH] Local org: $($config.localOrg.id)" -ForegroundColor Cyan
    Write-Host "[FED-AUTH] Key pair at: $localKeyPath" -ForegroundColor Gray
    Write-Host "[FED-AUTH] Public key:" -ForegroundColor Gray
    Write-Host $pubKey -ForegroundColor White
    return @{ orgId = $config.localOrg.id; publicKey = $pubKey; keyPath = $localKeyPath }
  }
}
