param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("mem_save", "mem_session_end", "mem_update", "session_start", "session_end", "integrity_repair", "db_restore")]
    [string]$Operation,

    [string]$Description = "",
    [switch]$Force,

    [switch]$Quiet
)

$ErrorActionPreference = "Continue"

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    if ($Quiet -and $Status -ne "WARN" -and $Status -ne "ERR") { return }
    $color = @{INFO="Cyan"; OK="Green"; WARN="Yellow"; ERR="Red"; GUARD="Magenta"}
    Write-Host "[CHANGE-GUARD::$Status] $Message" -ForegroundColor $color[$Status]
}

function Get-CriticalFileHash {
    $files = @(
        ".engram-data/engram.db",
        ".engram/manifest.json",
        ".engram/chunks/"
    )
    $hashes = @()
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    foreach ($f in $files) {
        $fullPath = Join-Path $root $f
        if (Test-Path $fullPath) {
            if ((Get-Item $fullPath).PSIsContainer) {
                $hashes += "[DIR] $f"
            } else {
                $hash = (Get-FileHash $fullPath -Algorithm SHA256).Hash
                $hashes += "$hash $f"
            }
        }
    }
    return $hashes
}

$riskLevels = @{
    "mem_save" = @{ risk = "low"; desc = "Guardar una observacion nueva en memoria" }
    "mem_session_end" = @{ risk = "low"; desc = "Finalizar sesion actual en Engram" }
    "mem_update" = @{ risk = "high"; desc = "Actualizar/modificar una observacion existente" }
    "session_start" = @{ risk = "low"; desc = "Iniciar nueva sesion" }
    "session_end" = @{ risk = "medium"; desc = "Cerrar sesion con resumen" }
    "integrity_repair" = @{ risk = "critical"; desc = "Reparar integridad de Engram (puede modificar datos)" }
    "db_restore" = @{ risk = "critical"; desc = "RESTAURAR base de datos desde backup (SOBREESCRIBE datos actuales)" }
}

$opInfo = $riskLevels[$Operation]
$risk = $opInfo.risk
$desc = $opInfo.desc
if ($Description) { $desc = $Description }

if ($Force -or $risk -eq "low") {
    if (-not $Quiet) {
        Write-Step "Operation: $Operation ($risk risk)" "GUARD"
        Write-Step "Description: $desc" "INFO"
        if ($risk -eq "low") { Write-Step "Auto-approved (low risk)" "OK" }
    }
    exit 0
}

if ($risk -eq "medium") {
    Write-Step "Operation: $Operation ($risk risk)" "GUARD"
    Write-Step "Description: $desc" "INFO"
    $preHash = Get-CriticalFileHash
    Write-Step "Pre-operation snapshot taken" "OK"
    return @{ risk = $risk; preHash = $preHash }
}

if ($risk -eq "high" -or $risk -eq "critical") {
    Write-Step "[!] BLOCKED: $desc" "ERR"
    Write-Step "Risk level: $risk" "ERR"
    Write-Step "" "INFO"

    if ($risk -eq "critical") {
        Write-Step "████████████████████████████████████████████████████████████" "FATAL"
        Write-Step "█  OPERACION DE ALTO RIESGO DETECTADA                    █" "FATAL"
        Write-Step "█  Esta operacion MODIFICARA o SOBREESCRIBIRA datos      █" "FATAL"
        Write-Step "█  de Engram de forma IRREVERSIBLE.                      █" "FATAL"
        Write-Step "████████████████████████████████████████████████████████████" "FATAL"
    } else {
        Write-Step "┌─────────────────────────────────────────────────────────┐" "GUARD"
        Write-Step "│  OPERACION DE RIESGO: $Operation                         │" "GUARD"
        Write-Step "│  $desc                          │" "GUARD"
        Write-Step "└─────────────────────────────────────────────────────────┘" "GUARD"
    }

    Write-Step "" "INFO"
    Write-Step "Riesgo: $risk" "INFO"
    Write-Step ("Descripcion: {0}" -f $desc) "INFO"
    Write-Step "" "INFO"
    Write-Step "Autorizas esta operacion?" "WARN"
    Write-Step "  - Escribi 'SI' para autorizar (solo esta vez)" "INFO"
    Write-Step "  - Escribi 'SIEMPRE' para autorizar siempre esta operacion" "INFO"
    Write-Step "  - Escribi cualquier otra cosa para RECHAZAR" "INFO"

    if ($Force) {
        Write-Step "Force flag set -- bypassing guard" "WARN"
        return @{ authorized = $true; risk = $risk }
    }

    $response = Read-Host "> "
    if ($response -eq "SI") {
        Write-Step "Operacion autorizada (one-time)" "OK"
        return @{ authorized = $true; risk = $risk }
    } elseif ($response -eq "SIEMPRE") {
        Write-Step "Operacion autorizada (permanente para $Operation)" "OK"
        return @{ authorized = $true; risk = $risk; remember = $true }
    } else {
        Write-Step "OPERACION RECHAZADA por el usuario" "ERR"
        Write-Step "No se realizaron cambios en Engram" "OK"
        exit 1
    }
}

exit 0
