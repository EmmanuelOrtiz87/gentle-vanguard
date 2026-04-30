<#
.SYNOPSIS
    Session Authentication - Validates owner before restricted operations
.DESCRIPTION
    Flow:
    1. Check if already authenticated in this session
    2. If not, require API key OR security questions
    3. If API key correct -> authenticate session
    4. If API key wrong -> offer security questions
    5. If anything wrong -> DENIED
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseSecurityQuestions
)

$ErrorActionPreference = "Stop"

$authPath = ".workspace\config\owner-auth.json"
$sessionAuthFile = ".workspace\config\session-auth.json"

function Get-SessionAuth {
    if (Test-Path $sessionAuthFile) {
        $session = Get-Content $sessionAuthFile | ConvertFrom-Json
        if ($session.authenticated -and $session.expiresAt -gt (Get-Date)) {
            return $true
        }
    }
    return $false
}

function Set-SessionAuth {
    $session = @{
        authenticated = $true
        authenticatedAt = (Get-Date).ToString("o")
        expiresAt = (Get-Date).AddHours(8).ToString("o")
    }
    $session | ConvertTo-Json | Set-Content $sessionAuthFile
}

function Test-ApiKey {
    param([string]$Key)
    
    $auth = Get-Content $authPath | ConvertFrom-Json
    return ($Key -eq $auth.apiKey)
}

function Test-SecurityQuestions {
    param([string[]]$Answers)
    
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $auth = Get-Content $authPath | ConvertFrom-Json
    
    $correct = 0
    for ($i = 0; $i -lt 3; $i++) {
        $answer = $Answers[$i].ToLower().Trim()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($answer)
        $hashBytes = $hash.ComputeHash($bytes)
        $answerHash = "sha256:" + [Convert]::ToBase64String($hashBytes)
        
        $expected = $auth.securityQuestions.("q" + ($i + 1)).answerHash
        if ($answerHash -eq $expected) {
            $correct++
        }
    }
    
    return $correct
}

function Show-AuthRequired {
    param([string]$Context)
    
    Write-Host ""
    Write-Host "========================================= " -ForegroundColor Yellow
    Write-Host "[LOCK] AUTHENTICATION REQUIRED" -ForegroundColor Cyan
    Write-Host "========================================= " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[CONTEXT] $Context" -ForegroundColor White
    Write-Host ""
    Write-Host "Esta operacion requiere autenticacion del owner." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  1. Ingresa tu API key" -ForegroundColor White
    Write-Host "  2. Usa preguntas de seguridad (si olvidaste tu API key)" -ForegroundColor White
    Write-Host ""
}

function Show-AuthError {
    param([string]$Reason)
    
    Write-Host ""
    Write-Host "========================================= " -ForegroundColor Red
    Write-Host "[X] ACCESS DENIED" -ForegroundColor Red
    Write-Host "========================================= " -ForegroundColor Red
    Write-Host ""
    Write-Host "[REASON] $Reason" -ForegroundColor White
    Write-Host ""
    Write-Host "No tienes permisos para realizar esta operacion." -ForegroundColor Red
    Write-Host "Contacta al owner del workspace para solicitar acceso." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

function Show-AuthSuccess {
    param([string]$Message)
    
    Write-Host ""
    Write-Host "========================================= " -ForegroundColor Green
    Write-Host "[OK] AUTHENTICATED" -ForegroundColor Green
    Write-Host "========================================= " -ForegroundColor Green
    Write-Host ""
    Write-Host "$Message" -ForegroundColor Green
    Write-Host ""
}

# MAIN FLOW
# =========

# Check if already authenticated this session
if (Get-SessionAuth) {
    Write-Host "[INFO] Session already authenticated" -ForegroundColor Green
    exit 0
}

# If no API key provided and not requesting security questions
if (-not $ApiKey -and -not $UseSecurityQuestions) {
    Show-AuthRequired -Context "Restricted operation"
    Write-Host "Ingresa tu API key o usa --security-questions" -ForegroundColor Yellow
    exit 1
}

# Flow: Security Questions Recovery
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
        $answerStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($answer))
        $answers += $answerStr
        Write-Host ""
    }
    
    $correct = Test-SecurityQuestions -Answers $answers
    
    if ($correct -eq 3) {
        Show-AuthSuccess -Message "Todas las respuestas correctas!"
        
        $auth = Get-Content $authPath | ConvertFrom-Json
        Write-Host "Tu API key: $($auth.apiKey)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Quieres usar esta API key para autenticarte en esta sesion?" -ForegroundColor Yellow
        $confirm = Read-Host "[S/N]"
        
        if ($confirm -eq "S" -or $confirm -eq "s") {
            Set-SessionAuth
            Write-Host "[OK] Sesion autenticada por 8 horas" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "[INFO] Puedes usar la API key manualmente" -ForegroundColor Yellow
            exit 0
        }
    } else {
        Show-AuthError -Reason "Solo $correct/3 respuestas correctas"
    }
}

# Flow: API Key Validation
if ($ApiKey) {
    if (Test-ApiKey -Key $ApiKey) {
        Show-AuthSuccess -Message "API key valida"
        Set-SessionAuth
        Write-Host "[OK] Sesion autenticada por 8 horas" -ForegroundColor Green
        exit 0
    } else {
        Write-Host ""
        Write-Host "[X] API key invlida" -ForegroundColor Red
        Write-Host ""
        Write-Host "Olvidaste tu API key? Usa: --security-questions" -ForegroundColor Yellow
        exit 1
    }
}