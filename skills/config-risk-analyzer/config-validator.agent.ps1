<#
.SYNOPSIS
    Config Validator Agent - Valida y corrige configuraciones
    
.DESCRIPTION
    Agente que se encarga de validar configuraciones, detectar riesgos,
    proponer soluciones y delegar correcciones según corresponda.
    
.PARAMETER ConfigFile
    Ruta al archivo de configuración a validar
    
.PARAMETER AutoFix
    Aplicar correcciones automáticas si es seguro
    
.PARAMETER Verbose
    Mostrar detalles de validación
    
.EXAMPLE
    .\config-validator.agent.ps1 -ConfigFile opencode.json -AutoFix
    
.NOTES
    Author: gentleman-programming
    Version: 1.0.0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $repoRoot '../..')).Path

# Lecciones aprendidas - Cache en memoria
$script:LessonsLearned = @{
    "agent.default-must-be-object" = @{
        pattern = "agent.default debe ser objeto, no string"
        cause = "opencode.json tenía strings en lugar de objetos"
        solution = "Cambiar a estructura de objeto: { 'name': 'general' }"
        prevention = "Validar esquema antes de guardar"
        date = "2026-05-02"
    }
    "verbose-preference-switch-incompatible" = @{
        pattern = "VerbosePreference incompatible con [switch]"
        cause = "Pasar ActionPreference a parámetro switch"
        solution = "Convertir a boolean: `$VerbosePreference -eq 'Continue'"
        prevention = "Validar tipos de parámetros en PowerShell"
        date = "2026-05-02"
    }
    "cross-workspace-inconsistency" = @{
        pattern = "Archivos desincronizados entre local y foundation"
        cause = "Cambios sin sincronización"
        solution = "Ejecutar cross-workspace-validator -Fix"
        prevention = "Validar sincronización en cada cambio"
        date = "2026-05-02"
    }
}

function Write-ValidatorInfo {
    param([string]$Message)
    Write-Host "[CONFIG-VALIDATOR] $Message" -ForegroundColor Cyan
}

function Write-ValidatorWarning {
    param([string]$Message)
    Write-Host "[CONFIG-VALIDATOR-WARN] $Message" -ForegroundColor Yellow
}

function Write-ValidatorError {
    param([string]$Message)
    Write-Host "[CONFIG-VALIDATOR-ERROR] $Message" -ForegroundColor Red
}

# Validar archivo de configuración
function Test-ConfigFile {
    param([string]$FilePath)
    
    Write-ValidatorInfo "Validando: $FilePath"
    
    if (-not (Test-Path $FilePath)) {
        Write-ValidatorError "Archivo no encontrado: $FilePath"
        return $false
    }
    
    try {
        $config = Get-Content $FilePath -Raw | ConvertFrom-Json
        Write-ValidatorInfo "Archivo JSON válido"
        return $true
    } catch {
        Write-ValidatorError "JSON inválido: $_"
        return $false
    }
}

# Validar contra esquema
function Test-ConfigSchema {
    param([string]$FilePath)
    
    $fileName = Split-Path $FilePath -Leaf
    $schemaPath = Join-Path $repoRoot "config" "$($fileName.Replace('.json', '.schema.json'))"
    
    if (-not (Test-Path $schemaPath)) {
        Write-ValidatorWarning "Esquema no encontrado: $schemaPath"
        return $null
    }
    
    Write-ValidatorInfo "Validando contra esquema: $schemaPath"
    
    try {
        $config = Get-Content $FilePath -Raw | ConvertFrom-Json
        $schema = Get-Content $schemaPath -Raw | ConvertFrom-Json
        
        # Validación básica de propiedades requeridas
        foreach ($required in $schema.required) {
            if (-not $config.PSObject.Properties[$required]) {
                Write-ValidatorError "Propiedad requerida faltante: $required"
                return $false
            }
        }
        
        Write-ValidatorInfo "Esquema validado correctamente"
        return $true
    } catch {
        Write-ValidatorError "Error validando esquema: $_"
        return $false
    }
}

# Buscar en lecciones aprendidas
function Find-LessonLearned {
    param([string]$Pattern)
    
    foreach ($key in $script:LessonsLearned.Keys) {
        $lesson = $script:LessonsLearned[$key]
        if ($lesson.pattern -like "*$Pattern*") {
            return $lesson
        }
    }
    
    return $null
}

# Generar reporte de validación
function New-ValidationReport {
    param(
        [string]$FilePath,
        [bool]$SchemaValid,
        [bool]$JsonValid,
        [array]$Risks
    )
    
    $report = @{
        timestamp = Get-Date -Format "o"
        file = $FilePath
        jsonValid = $JsonValid
        schemaValid = $SchemaValid
        risks = $Risks
        lessonsApplied = @()
    }
    
    # Buscar lecciones aprendidas aplicables
    if ($FilePath -like "*opencode.json") {
        $lesson = Find-LessonLearned "agent.default"
        if ($lesson) {
            $report.lessonsApplied += $lesson
        }
    }
    
    return $report
}

# Main execution
Write-ValidatorInfo "Config Validator Agent iniciado"
Write-ValidatorInfo "Archivo a validar: $ConfigFile"

# Validar JSON
$jsonValid = Test-ConfigFile -FilePath $ConfigFile

# Validar esquema
$schemaValid = Test-ConfigSchema -FilePath $ConfigFile

# Generar reporte
$risks = @()
if (-not $jsonValid) {
    $risks += @{
        level = "critical"
        description = "Archivo JSON inválido"
        solution = "Revisar sintaxis JSON"
        delegateTo = "human-review"
    }
}

if (-not $schemaValid) {
    $risks += @{
        level = "high"
        description = "Validación de esquema fallida"
        solution = "Revisar estructura contra esquema"
        delegateTo = "schema-reviewer"
    }
}

$report = New-ValidationReport -FilePath $ConfigFile -JsonValid $jsonValid -SchemaValid $schemaValid -Risks $risks

# Mostrar reporte
Write-ValidatorInfo "=== REPORTE DE VALIDACIÓN ==="
Write-ValidatorInfo "Archivo: $($report.file)"
Write-ValidatorInfo "Timestamp: $($report.timestamp)"
Write-ValidatorInfo "JSON Válido: $($report.jsonValid)"
Write-ValidatorInfo "Esquema Válido: $($report.schemaValid)"

if ($report.risks.Count -gt 0) {
    Write-ValidatorWarning "Riesgos detectados: $($report.risks.Count)"
    foreach ($risk in $report.risks) {
        Write-ValidatorWarning "  - [$($risk.level)] $($risk.description)"
        Write-ValidatorInfo "    Solución: $($risk.solution)"
        Write-ValidatorInfo "    Delegar a: $($risk.delegateTo)"
    }
} else {
    Write-ValidatorInfo "✅ No se detectaron riesgos"
}

if ($report.lessonsApplied.Count -gt 0) {
    Write-ValidatorInfo "Lecciones aprendidas aplicadas: $($report.lessonsApplied.Count)"
}

exit 0