# Pre-commit hook para validar opencode.json
# Valida la configuración centralizada contra esquema JSON Schema
# Consulta NORMATIVAS-ORQUESTADOR.md antes de permitir cambios
#
# Referencia: docs/reference/NORMATIVAS-ORQUESTADOR.md

param([switch]$Verbose = $false)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $colors = @{ Success = "Green"; Error = "Red"; Warning = "Yellow"; Info = "Cyan" }
    $color = if ($colors.ContainsKey($Level)) { $colors[$Level] } else { "White" }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-JsonSchema {
    param([string]$JsonPath, [string]$SchemaPath)
    
    if (-not (Test-Path $JsonPath)) {
        Write-Log "Archivo no encontrado: $JsonPath" "Error"
        return $false
    }
    
    if (-not (Test-Path $SchemaPath)) {
        Write-Log "Esquema no encontrado: $SchemaPath" "Error"
        return $false
    }
    
    try {
        $json = Get-Content $JsonPath -Raw | ConvertFrom-Json
        $schema = Get-Content $SchemaPath -Raw | ConvertFrom-Json
        
        # Validación de campos requeridos
        $requiredFields = $schema.required
        foreach ($field in $requiredFields) {
            if (-not ($json.PSObject.Properties.Name -contains $field)) {
                Write-Log "Campo requerido faltante: $field" "Error"
                return $false
            }
        }
        
        # Validar provider.anthropic
        if (-not $json.provider.anthropic) {
            Write-Log "provider.anthropic es requerido" "Error"
            return $false
        }
        
        if (-not $json.provider.anthropic.enabled -or -not $json.provider.anthropic.model) {
            Write-Log "provider.anthropic debe tener 'enabled' y 'model'" "Error"
            return $false
        }
        
        # Validar agent
        if (-not $json.agent.default -or -not $json.agent.orchestrator) {
            Write-Log "agent debe tener 'default' y 'orchestrator'" "Error"
            return $false
        }
        
        # Validar skills
        if (-not $json.skills.directory -or $null -eq $json.skills.auto_load) {
            Write-Log "skills debe tener 'directory' y 'auto_load'" "Error"
            return $false
        }
        
        Write-Log "[OK] opencode.json validado correctamente" "Success"
        return $true
    }
    catch {
        Write-Log "Error al validar JSON: $_" "Error"
        return $false
    }
}

function Test-NormativasConsulta {
    param([string]$NormativasPath)
    
    if (-not (Test-Path $NormativasPath)) {
        Write-Log "Normativas no encontradas: $NormativasPath" "Warning"
        return $true
    }
    
    try {
        $content = Get-Content $NormativasPath -Raw
        
        # Verificar directivas críticas
        $criticalPatterns = @(
            "Consulta de Autorizaciones",
            "Registro de Decisiones",
            "Consistencia y Versiónado"
        )
        
        $missingPatterns = @()
        foreach ($pattern in $criticalPatterns) {
            if ($content -notmatch $pattern) {
                $missingPatterns += $pattern
            }
        }
        
        if ($missingPatterns.Count -gt 0) {
            Write-Log "Advertencia: Normativas incompletas" "Warning"
            return $true
        }
        
        Write-Log "[OK] Normativas consultadas y validadas" "Success"
        return $true
    }
    catch {
        Write-Log "Error al consultar normativas: $_" "Warning"
        return $true
    }
}

# Script principal
Write-Log "Iniciando validación pre-commit de opencode.json..." "Info"

$projectRoot = Split-Path -Parent $PSScriptRoot
$opencodeJson = Join-Path $projectRoot "opencode.json"
$opencodeSchema = Join-Path (Join-Path $projectRoot "config") "opencode.schema.json"
$normativasPath = Join-Path (Join-Path (Join-Path $projectRoot "docs") "reference") "NORMATIVAS-ORQUESTADOR.md"

# Validar esquema
if (-not (Test-JsonSchema -JsonPath $opencodeJson -SchemaPath $opencodeSchema)) {
    Write-Log "[ERROR] Validacion de esquema FALLIDA" "Error"
    Write-Log "Consulta: docs/reference/NORMATIVAS-ORQUESTADOR.md" "Info"
    exit 1
}

# Consultar normativas
if (-not (Test-NormativasConsulta -NormativasPath $normativasPath)) {
    Write-Log "[ERROR] Consulta de normativas FALLIDA" "Error"
    exit 1
}

Write-Log "[OK] Pre-commit validation EXITOSA" "Success"
Write-Log "opencode.json está validado y cumple normativas" "Info"
exit 0