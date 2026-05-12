<#
.SYNOPSIS
    Session Authentication - Validates owner before restricted operations
.DESCRIPTION
    Flow:
    1. Check if already authenticated in this session
    2. If not, check lockout status (rate limiting)
    3. Require API key OR security questions
    4. If API key correct -> authenticate session
    5. If API key wrong -> log failed attempt, offer security questions
    6. Security questions -> 3/3 correct required, then reveal API key
    7. If anything wrong -> DENIED
    8. Integrity check on owner-auth.json (SHA256 hash validation)
    9. Supports DPAPI encryption via secure-auth.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [switch]$UseSecurityQuestions,

    [Parameter(Mandatory=$false)]
    [ValidateSet('status', 'encrypt', 'decrypt')]
    [string]$ManageAuth = '',

    [switch]$AsJson
)

$ErrorActionPreference = "Stop"

$repoRoot = if ($env:FOUNDATION_BASE_DIR) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$authPath = Join-Path $repoRoot "config\owner-auth.json"
$sessionAuthFile = Join-Path $repoRoot ".workspace\config\session-auth.json"
$lockFile = Join-Path $repoRoot "config\owner-auth.json.lock"
$integrityFile = Join-Path $repoRoot "config\owner-auth.json.integrity"
$secureAuthScript = Join-Path $repoRoot "scripts\security\secure-auth.ps1"
$auditLogFile = Join-Path $repoRoot ".runtime\security-auth-audit.log"

function Write-AuthJson {
    param([hashtable]$Data)
    $Data | ConvertTo-Json -Depth 5 | Write-Output
}

function Get-FileHashSHA256 {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $hashBytes = $hash.ComputeHash($bytes)
    $hash.Dispose()
    return [Convert]::ToBase64String($hashBytes)
}

function Initialize-Integrity {
    if (-not (Test-Path $authPath)) {
        Write-Host "[ERROR] owner-auth.json not found at: $authPath" -ForegroundColor Red
        return $false
    }
    $currentHash = Get-FileHashSHA256 -FilePath $authPath
    $integrityData = @{
        hash = $currentHash
        computedAt = (Get-Date).ToString("o")
        file = $authPath
    }
    $dir = Split-Path -Parent $integrityFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $integrityData | ConvertTo-Json | Set-Content $integrityFile -Encoding UTF8
    return $true
}

function Test-Integrity {
    if (-not (Test-Path $integrityFile)) {
        Write-Host "[WARN] Integrity file missing, initializing..." -ForegroundColor Yellow
        return (Initialize-Integrity)
    }
    if (-not (Test-Path $authPath)) { return $false }

    $stored = Get-Content $integrityFile -Raw | ConvertFrom-Json
    $currentHash = Get-FileHashSHA256 -FilePath $authPath

    if ($stored.hash -ne $currentHash) {
        Write-Host "[CRITICAL] owner-auth.json integrity check FAILED" -ForegroundColor Red
        Write-Host " Expected: $($stored.hash)" -ForegroundColor Red
        Write-Host " Actual:   $currentHash" -ForegroundColor Red
        Write-Host " The file may have been tampered with." -ForegroundColor Red
        return $false
    }
    return $true
}

function Write-AuditLog {
    param(
        [string]$Action,
        [string]$Result,
        [string]$Detail = ''
    )
    $logDir = Split-Path -Parent $auditLogFile
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $entry = @{
        timestamp = (Get-Date).ToString("o")
        action = $Action
        result = $Result
        detail = $Detail
    } | ConvertTo-Json -Compress
    Add-Content -Path $auditLogFile -Value $entry -Encoding UTF8
}

function Get-SessionAuth {
    if (Test-Path $sessionAuthFile) {
        $session = Get-Content $sessionAuthFile -Raw | ConvertFrom-Json
        if ($session.authenticated -and $session.expiresAt) {
            $expiry = [DateTime]::Parse($session.expiresAt)
            if ($expiry -gt (Get-Date)) {
                return $true
            } else {
                Remove-Item $sessionAuthFile -Force -ErrorAction SilentlyContinue
                Write-Host "[INFO] Previous session expired" -ForegroundColor Yellow
            }
        }
    }
    return $false
}

function Set-SessionAuth {
    $dir = Split-Path -Parent $sessionAuthFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $session = @{
        authenticated = $true
        authenticatedAt = (Get-Date).ToString("o")
        expiresAt = (Get-Date).AddHours(8).ToString("o")
    }
    $session | ConvertTo-Json | Set-Content $sessionAuthFile -Encoding UTF8
}

function Get-LockoutStatus {
    if (Test-Path $lockFile) {
        $lock = Get-Content $lockFile -Raw | ConvertFrom-Json
        if ($lock.lockoutEnd) {
            $lockoutEnd = [DateTime]::Parse($lock.lockoutEnd)
            if ($lockoutEnd -gt (Get-Date)) {
                $remaining = ($lockoutEnd - (Get-Date)).TotalMinutes
                return @{
                    locked = $true
                    attempts = $lock.attempts
                    lockoutEnd = $lock.lockoutEnd
                    remainingMinutes = [Math]::Round($remaining, 1)
                }
            } else {
                Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    return @{ locked = $false; attempts = 0 }
}

function Add-FailedAttempt {
    $status = Get-LockoutStatus
    if ($status.locked) { return $status }

    $newAttempts = $status.attempts + 1
    if ($newAttempts -ge 3) {
        $lockoutData = @{
            attempts = $newAttempts
            lockoutEnd = (Get-Date).AddMinutes(15).ToString("o")
            timestamp = (Get-Date).ToString("o")
        }
        $lockoutData | ConvertTo-Json | Set-Content $lockFile -Encoding UTF8
        Write-AuditLog -Action "lockout" -Result "activated" -Detail "3 failed attempts"
        return @{ locked = $true; attempts = $newAttempts; lockoutEnd = $lockoutData.lockoutEnd }
    }

    $tempLock = @{
        attempts = $newAttempts
        lockoutEnd = $null
    }
    $tempLock | ConvertTo-Json | Set-Content $lockFile -Encoding UTF8
    return @{ locked = $false; attempts = $newAttempts; remaining = 3 - $newAttempts }
}

function Clear-Lockout {
    if (Test-Path $lockFile) { Remove-Item $lockFile -Force }
}

function Test-ApiKey {
    param([string]$Key)
    $auth = Get-Content $authPath -Raw | ConvertFrom-Json
    return ($Key -eq $auth.apiKey)
}

function Test-SecurityQuestions {
    param([string[]]$Answers)

    $hash = [System.Security.Cryptography.SHA256]::Create()
    $auth = Get-Content $authPath -Raw | ConvertFrom-Json
    $correct = 0

    for ($i = 0; $i -lt 3; $i++) {
        $answer = $Answers[$i].ToLower().Trim()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($answer)
        $hashBytes = $hash.ComputeHash($bytes)
        $answerHash = "sha256:" + [Convert]::ToBase64String($hashBytes)
        $expected = $auth.securityQuestions.("q" + ($i + 1)).answerHash
        if ($answerHash -eq $expected) { $correct++ }
    }
    $hash.Dispose()
    return $correct
}

function Show-AuthRequired {
    param([string]$Context = "Restricted operation")
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host "[LOCK] AUTHENTICATION REQUIRED" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[CONTEXT] $Context" -ForegroundColor White
    Write-Host ""
    Write-Host "Esta operacion requiere autenticacion del owner." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  1. Ingresa tu API key:  -ApiKey <tu_key>" -ForegroundColor White
    Write-Host "  2. Preguntas de seguridad:  -UseSecurityQuestions" -ForegroundColor White
    Write-Host ""
}

function Show-AuthError {
    param([string]$Reason)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Red
    Write-Host "[X] ACCESS DENIED" -ForegroundColor Red
    Write-Host "===========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "[REASON] $Reason" -ForegroundColor White
    Write-Host ""
    Write-Host "No tienes permisos para realizar esta operacion." -ForegroundColor Red
    Write-Host "Contacta al owner del workspace para solicitar acceso." -ForegroundColor Yellow
    Write-Host ""
}

function Show-AuthSuccess {
    param([string]$Message)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "[OK] AUTHENTICATED" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "$Message" -ForegroundColor Green
    Write-Host ""
}

# ======================================================
# MANAGEMENT COMMANDS (encrypt/decrypt/status)
# ======================================================
if ($ManageAuth -eq 'status') {
    $lockout = Get-LockoutStatus
    $integOk = Test-Integrity
    $sessionOk = Get-SessionAuth
    $encFile = Join-Path $repoRoot "config\owner-auth.json.enc"
    $isEncrypted = Test-Path $encFile

    $status = @{
        sessionAuthenticated = $sessionOk
        integrityValid = $integOk
        encrypted = $isEncrypted
        lockout = $lockout
        authFile = $authPath
        integrityFile = $integrityFile
    }

    if ($AsJson) {
        Write-AuthJson $status
    } else {
        Write-Host "=== AUTH STATUS ===" -ForegroundColor Cyan
        Write-Host "Session authenticated: $sessionOk" -ForegroundColor $(if($sessionOk){'Green'}else{'Red'})
        Write-Host "Integrity valid:       $integOk" -ForegroundColor $(if($integOk){'Green'}else{'Red'})
        Write-Host "Encrypted (DPAPI):     $isEncrypted" -ForegroundColor $(if($isEncrypted){'Green'}else{'Yellow'})
        if ($lockout.locked) {
            Write-Host "Lockout:               LOCKED ($($lockout.remainingMinutes) min remaining)" -ForegroundColor Red
        } else {
            Write-Host "Lockout:               OK (attempts: $($lockout.attempts)/3)" -ForegroundColor Green
        }
    }
    exit 0
}

if ($ManageAuth -eq 'encrypt') {
    if (-not (Test-Path $secureAuthScript)) {
        Write-Host "[ERROR] secure-auth.ps1 not found at: $secureAuthScript" -ForegroundColor Red
        exit 1
    }
    & $secureAuthScript -Action encrypt -InputFile $authPath
    if ($LASTEXITCODE -eq 0) {
        Initialize-Integrity | Out-Null
        Write-Host "[OK] owner-auth.json encrypted and integrity baseline updated" -ForegroundColor Green
    }
    exit $LASTEXITCODE
}

if ($ManageAuth -eq 'decrypt') {
    $lockout = Get-LockoutStatus
    if ($lockout.locked) {
        Write-Host "[ERROR] Account locked. Wait $($lockout.remainingMinutes) minutes." -ForegroundColor Red
        exit 1
    }

    $encFile = Join-Path $repoRoot "config\owner-auth.json.enc"
    if (-not (Test-Path $encFile)) {
        Write-Host "[INFO] No encrypted file found, already decrypted" -ForegroundColor Yellow
        exit 0
    }

    if (-not (Test-Path $secureAuthScript)) {
        Write-Host "[ERROR] secure-auth.ps1 not found at: $secureAuthScript" -ForegroundColor Red
        exit 1
    }
    & $secureAuthScript -Action decrypt -InputFile $encFile -OutputFile $authPath
    if ($LASTEXITCODE -eq 0) {
        Initialize-Integrity | Out-Null
        Write-Host "[OK] owner-auth.json decrypted and integrity baseline updated" -ForegroundColor Green
    }
    exit $LASTEXITCODE
}

# ======================================================
# MAIN AUTHENTICATION FLOW
# ======================================================

$lockout = Get-LockoutStatus
if ($lockout.locked) {
    Write-Host ""
    Write-Host "[LOCKED] Account locked due to too many failed attempts." -ForegroundColor Red
    Write-Host " Try again in $($lockout.remainingMinutes) minutes." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Integrity)) {
    Show-AuthError -Reason "Integrity check failed on owner-auth.json"
    Write-AuditLog -Action "integrity_check" -Result "failed" -Detail "owner-auth.json hash mismatch"
    exit 1
}

if (Get-SessionAuth) {
    Write-Host "[INFO] Session already authenticated" -ForegroundColor Green
    exit 0
}

if (-not $ApiKey -and -not $UseSecurityQuestions) {
    Show-AuthRequired -Context "Restricted operation"
    Write-Host " Ingresa tu API key o usa -UseSecurityQuestions" -ForegroundColor Yellow
    exit 1
}

if ($UseSecurityQuestions) {
    Write-Host ""
    Write-Host "==== Security Questions Recovery ====" -ForegroundColor Cyan
    Write-Host "Responde correctamente las 3 preguntas" -ForegroundColor Yellow
    Write-Host ""

    $answers = @()
    $questions = @(
        "Nombre de tu primera mascota?",
        "Ciudad donde naciste?",
        "Nombre de tu mejor amigo de infancia?"
    )

    for ($i = 0; $i -lt 3; $i++) {
        Write-Host "Q$($i+1): $($questions[$i])" -ForegroundColor Cyan
        $answer = Read-Host "Answer" -AsSecureString
        $answerStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($answer)
        )
        $answers += $answerStr
        Write-Host ""
    }

    $correct = Test-SecurityQuestions -Answers $answers

    if ($correct -eq 3) {
        Clear-Lockout
        Show-AuthSuccess -Message "Todas las respuestas correctas!"
        Write-AuditLog -Action "security_questions" -Result "success" -Detail "3/3 correct"

        $auth = Get-Content $authPath -Raw | ConvertFrom-Json
        Write-Host "Tu API key: $($auth.apiKey)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Quieres usar esta API key para autenticarte en esta sesion?" -ForegroundColor Yellow
        $confirm = Read-Host "[S/N]"

        if ($confirm -eq "S" -or $confirm -eq "s") {
            Set-SessionAuth
            Write-Host "[OK] Sesion autenticada por 8 horas" -ForegroundColor Green
            Write-AuditLog -Action "session_auth" -Result "success" -Detail "via security questions"
        } else {
            Write-Host "[INFO] Usa la API key con: -ApiKey <key>" -ForegroundColor Yellow
        }
        exit 0
    } else {
        $attemptResult = Add-FailedAttempt
        Write-AuditLog -Action "security_questions" -Result "failed" -Detail "$correct/3 correct"
        if ($attemptResult.locked) {
            Show-AuthError -Reason "Solo $correct/3 respuestas correctas. Cuenta bloqueada por 15 minutos."
        } else {
            Show-AuthError -Reason "Solo $correct/3 respuestas correctas. Intentos restantes: $($attemptResult.remaining)"
        }
        exit 1
    }
}

if ($ApiKey) {
    if (Test-ApiKey -Key $ApiKey) {
        Clear-Lockout
        Set-SessionAuth
        Show-AuthSuccess -Message "API key valida - Sesion autenticada por 8 horas"
        Write-AuditLog -Action "api_key" -Result "success" -Detail "authenticated"
        exit 0
    } else {
        $attemptResult = Add-FailedAttempt
        Write-AuditLog -Action "api_key" -Result "failed" -Detail "invalid key"
        Write-Host ""
        Write-Host "[X] API key invalida" -ForegroundColor Red
        Write-Host ""
        if ($attemptResult.locked) {
            Write-Host "Cuenta bloqueada por 15 minutos (3 intentos fallidos)." -ForegroundColor Red
        } else {
            Write-Host "Olvidaste tu API key? Usa: -UseSecurityQuestions" -ForegroundColor Yellow
            Write-Host "Intentos restantes: $($attemptResult.remaining)" -ForegroundColor Yellow
        }
        exit 1
    }
}