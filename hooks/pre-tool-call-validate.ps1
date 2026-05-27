#!/usr/bin/env pwsh
# pre-tool-call-validate.ps1
# Hook de validación JSON para llamadas a herramientas del agente AI
# Previene errores "Unterminated string" y JSON malformado
# Ubicación: hooks/pre-tool-call-validate.ps1

<#
.SYNOPSIS
    Valida parámetros JSON antes de que el agente AI ejecute una llamada a herramienta.

.DESCRIPTION
    Este hook intercepta llamadas a herramientas con parámetros JSON y:
    1. Valida sintaxis JSON estricta
    2. Detecta errores comunes (strings sin cerrar, braces desbalanceados)
    3. Auto-repara errores simples cuando es seguro hacerlo
    4. Bloquea llamadas con errores críticos que no pueden repararse
    
    Integración: Configurar en ~/.config/opencode/settings.json o equivalente

.PARAMETER ToolName
    Nombre de la herramienta que se va a llamar (ej: "bash", "read", "engram_mem_save")

.PARAMETER JsonPayload
    String JSON con los parámetros de la herramienta

.PARAMETER Context
    Contexto adicional para mensajes de error (opcional)

.PARAMETER AutoFix
    Si está presente, intenta reparar errores JSON simples automáticamente

.PARAMETER StrictMode
    Si está presente, bloquea cualquier error sin intentar reparación

.EXAMPLE
    # Uso directo
    .\pre-tool-call-validate.ps1 -ToolName "bash" -JsonPayload '{"command": "ls", "description": "List files"}'
    
    # Con auto-reparación
    .\pre-tool-call-validate.ps1 -ToolName "mem_save" -JsonPayload '{"title": "test", "content": "incomplete' -AutoFix

    # Modo estricto (bloquea todo)
    .\pre-tool-call-validate.ps1 -ToolName "read" -JsonPayload '{"filePath": "/path"}' -StrictMode

.OUTPUTS
    Object con propiedades:
    - Valid: $true/$false
    - RepairedJson: JSON reparado (si AutoFix y fue posible)
    - Error: Mensaje de error (si Valid es $false)
    - FixesApplied: Array de reparaciones realizadas

.NOTES
    Versión: 1.0.0
    Autor: Gentle-Vanguard
    Requiere: PowerShell 7.0+
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ToolName,
    
    [Parameter(Mandatory = $true)]
    [string]$JsonPayload,
    
    [string]$Context = "",
    
    [switch]$AutoFix,
    
    [switch]$StrictMode
)

$ErrorActionPreference = "Stop"
$ValidationVersion = "1.0.0"

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# Herramientas que requieren validación estricta (no se permite auto-fix)
$StrictTools = @(
    'engram_mem_judge',
    'engram_mem_compare', 
    'engram_mem_save',
    'git_commit',
    'git_push'
)

# Herramientas que pueden tener payloads grandes (menos estrictos)
$LargePayloadTools = @(
    'engram_mem_session_summary',
    'engram_mem_save'
)

# ============================================================================
# FUNCIONES DE VALIDACIÓN
# ============================================================================

function Test-JsonStructure {
    param([string]$Json)
    
    $result = @{
        Valid = $false
        Error = $null
        Position = 0
        Details = @{}
    }
    
    # Check 1: Vacío o whitespace
    if ([string]::IsNullOrWhiteSpace($Json)) {
        $result.Error = "JSON payload está vacío"
        return $result
    }
    
    $trimmed = $Json.Trim()
    
    # Check 2: Debe empezar con { o [
    if (-not ($trimmed.StartsWith('{') -or $trimmed.StartsWith('['))) {
        $result.Error = "JSON debe empezar con '{' o '['"
        $result.Position = 0
        return $result
    }
    
    # Check 3: Debe terminar con } o ]
    $endsCorrectly = $trimmed.EndsWith('}') -or $trimmed.EndsWith(']')
    
    # Check 4: Balance de símbolos (siempre ejecutar para tener detalles para repair)
    $analysis = Get-JsonSymbolAnalysis -Json $trimmed
    $result.Details = $analysis
    
    # Si no termina correctamente, reportar error pero mantener el análisis para posible repair
    if (-not $endsCorrectly) {
        $result.Error = "JSON debe terminar con '}' o ']'"
        $result.Position = $trimmed.Length - 1
        return $result
    }
    
    if ($analysis.UnterminatedString) {
        $result.Error = "String sin cerrar detectado"
        $result.Position = $analysis.UnterminatedPosition
        return $result
    }
    
    if ($analysis.UnmatchedBraces -ne 0) {
        $braceWord = if ($analysis.UnmatchedBraces -gt 0) { "faltan" } else { "sobran" }
        $result.Error = "Llaves desbalanceadas: $($braceWord) $($analysis.UnmatchedBraces) '}'"
        $result.Position = $trimmed.Length
        return $result
    }
    
    if ($analysis.UnmatchedBrackets -ne 0) {
        $bracketWord = if ($analysis.UnmatchedBrackets -gt 0) { "faltan" } else { "sobran" }
        $result.Error = "Corchetes desbalanceados: $($bracketWord) $($analysis.UnmatchedBrackets) ']'"
        $result.Position = $trimmed.Length
        return $result
    }
    
    # Check 5: Validación PowerShell final
    try {
        $null = $trimmed | ConvertFrom-Json -ErrorAction Stop
        $result.Valid = $true
    }
    catch {
        $result.Error = "Error de sintaxis JSON: $($_.Exception.Message)"
        $result.Position = 0
    }
    
    return $result
}

function Get-JsonSymbolAnalysis {
    param([string]$Json)
    
    $analysis = @{
        TotalQuotes = 0
        UnterminatedString = $false
        UnterminatedPosition = -1
        OpenBraces = 0
        CloseBraces = 0
        UnmatchedBraces = 0
        OpenBrackets = 0
        CloseBrackets = 0
        UnmatchedBrackets = 0
        InString = $false
        EscapeNext = $false
    }
    
    $chars = $Json.ToCharArray()
    
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $char = $chars[$i]
        
        if ($analysis.EscapeNext) {
            $analysis.EscapeNext = $false
            continue
        }
        
        if ($char -eq '\') {
            $analysis.EscapeNext = $true
            continue
        }
        
        if ($char -eq '"' -and -not $analysis.EscapeNext) {
            $analysis.TotalQuotes++
            $analysis.InString = -not $analysis.InString
            continue
        }
        
        if (-not $analysis.InString) {
            switch ($char) {
                '{' { $analysis.OpenBraces++ }
                '}' { $analysis.CloseBraces++ }
                '[' { $analysis.OpenBrackets++ }
                ']' { $analysis.CloseBrackets++ }
            }
        }
    }
    
    # Verificar string sin cerrar
    if ($analysis.InString) {
        $analysis.UnterminatedString = $true
        $analysis.UnterminatedPosition = $chars.Length
    }
    
    # Calcular desbalance
    $analysis.UnmatchedBraces = $analysis.OpenBraces - $analysis.CloseBraces
    $analysis.UnmatchedBrackets = $analysis.OpenBrackets - $analysis.CloseBrackets
    
    return $analysis
}

function Repair-JsonPayload {
    param(
        [string]$Json,
        [hashtable]$Analysis
    )
    
    $repaired = $Json.Trim()
    $fixes = @()
    
    # Fix 1: String sin cerrar
    if ($Analysis.UnterminatedString) {
        $repaired = $repaired + '"'
        $fixes += "Agregada comilla de cierre faltante"
    }
    
    # Fix 2: Llaves desbalanceadas
    # UnmatchedBraces > 0 significa: mas '{' que '}', faltan cerrar
    # UnmatchedBraces < 0 significa: mas '}' que '{', sobran cerrar
    if ($Analysis.UnmatchedBraces -gt 0) {
        # Faltan llaves de cierre - agregarlas
        $repaired = $repaired + ('}' * $Analysis.UnmatchedBraces)
        $fixes += "Agregadas $($Analysis.UnmatchedBraces) llave(s) de cierre"
    }
    elseif ($Analysis.UnmatchedBraces -lt 0) {
        # Sobran llaves de cierre - NO auto-reparar (peligroso)
        $excess = [Math]::Abs($Analysis.UnmatchedBraces)
        return @{ Success = $false; Error = "Sobran $excess llave(s) de cierre '}' - reparación automática no segura"; Fixes = $fixes }
    }
    
    # Fix 3: Corchetes desbalanceados
    # UnmatchedBrackets > 0 significa: mas '[' que ']', faltan cerrar
    # UnmatchedBrackets < 0 significa: mas ']' que '[', sobran cerrar
    if ($Analysis.UnmatchedBrackets -gt 0) {
        # Faltan corchetes de cierre - agregarlos
        $repaired = $repaired + (']' * $Analysis.UnmatchedBrackets)
        $fixes += "Agregados $($Analysis.UnmatchedBrackets) corchete(s) de cierre"
    }
    elseif ($Analysis.UnmatchedBrackets -lt 0) {
        # Sobran corchetes de cierre - NO auto-reparar (peligroso)
        $excess = [Math]::Abs($Analysis.UnmatchedBrackets)
        return @{ Success = $false; Error = "Sobran $excess corchete(s) de cierre ']' - reparación automática no segura"; Fixes = $fixes }
    }
    
    # Fix 4: Comas al final (trailing commas) - usar regex no-greedy
    $original = $repaired
    $iteration = 0
    $maxIterations = 10
    
    while ($iteration -lt $maxIterations) {
        # Regex: coma seguida de opcionalmente espacios y luego } o ]
        $newRepaired = $repaired -replace ',(\s*)([}\]])', '$1$2'
        if ($newRepaired -eq $repaired) { break }
        $repaired = $newRepaired
        $iteration++
    }
    
    if ($repaired -ne $original) {
        $fixes += "Eliminadas comas finales"
    }
    
    # Validar que la reparación funcionó
    try {
        $null = $repaired | ConvertFrom-Json -ErrorAction Stop
        return @{ Success = $true; Json = $repaired; Fixes = $fixes }
    }
    catch {
        return @{ Success = $false; Error = "Reparación fallida: $($_.Exception.Message)"; Fixes = $fixes }
    }
}

function Get-TruncationRisk {
    param([string]$Json, [string]$ToolName)
    
    $risks = @()
    $length = $Json.Length
    
    # Campos propensos a truncamiento
    $riskyFields = @('summary', 'content', 'observation', 'description', 'prompt')
    
    foreach ($field in $riskyFields) {
        if ($Json -match "`"$field`"\s*:") {
            # Extraer valor aproximado
            $pattern = "`"$field`"\s*:\s*`"([^`"]*)"
            $match = [regex]::Match($Json, $pattern)
            if ($match.Success -and $match.Groups[1].Length -gt 500) {
                $risks += "Campo '$field' muy largo ($($match.Groups[1].Length) chars) - riesgo de truncamiento"
            }
        }
    }
    
    # Longitud total
    if ($length -gt 2000) {
        $risks += "Payload muy largo ($length chars) - considerar usar referencias a archivos"
    }
    
    return $risks
}

# ============================================================================
# EJECUCIÓN PRINCIPAL
# ============================================================================

$contextPrefix = if ($Context) { "[$Context] " } else { "" }
$toolPrefix = "[$ToolName]"

Write-Verbose "$contextPrefix$toolPrefix Iniciando validación JSON..."

# Determinar modo
$isStrictTool = $ToolName -in $StrictTools
$isLargePayloadTool = $ToolName -in $LargePayloadTools
$effectiveStrictMode = $StrictMode -or $isStrictTool

# Validar estructura
$validation = Test-JsonStructure -Json $JsonPayload

# Preparar resultado
$output = @{
    Valid = $validation.Valid
    OriginalLength = $JsonPayload.Length
    ToolName = $ToolName
    Timestamp = (Get-Date -Format "o")
    ValidatorVersion = $ValidationVersion
}

if ($validation.Valid) {
    # Verificar riesgos de truncamiento
    $risks = Get-TruncationRisk -Json $JsonPayload -ToolName $ToolName
    if ($risks.Count -gt 0) {
        $output['Warnings'] = $risks
        Write-Warning "$contextPrefix$toolPrefix Advertencias de truncamiento:"
        foreach ($risk in $risks) {
            Write-Warning "  - $risk"
        }
    }
    
    $output['RepairedJson'] = $JsonPayload
    $output['FixesApplied'] = @()
    
    Write-Verbose "$contextPrefix$toolPrefix JSON válido"
}
else {
    Write-Warning "$contextPrefix$toolPrefix Error de validación: $($validation.Error)"
    
    # Intentar reparación si está permitido
    if ($AutoFix -and -not $effectiveStrictMode) {
        Write-Verbose "$contextPrefix$toolPrefix Intentando reparación automática..."
        
        $repair = Repair-JsonPayload -Json $JsonPayload -Analysis $validation.Details
        
        if ($repair.Success) {
            $output['Valid'] = $true
            $output['RepairedJson'] = $repair.Json
            $output['FixesApplied'] = $repair.Fixes
            $output['WasRepaired'] = $true
            
            Write-Host "$contextPrefix$toolPrefix JSON reparado automáticamente:" -ForegroundColor Yellow
            foreach ($fix in $repair.Fixes) {
                Write-Host "  ✓ $fix" -ForegroundColor Green
            }
        }
        else {
            $output['Error'] = $repair.Error
            $output['FixesAttempted'] = $repair.Fixes
            
            Write-Error "$contextPrefix$toolPrefix No se pudo reparar: $($repair.Error)"
        }
    }
    else {
        $output['Error'] = $validation.Error
        $output['CanRepair'] = -not $effectiveStrictMode
        
        if ($effectiveStrictMode) {
            Write-Error "$contextPrefix$toolPrefix Modo estricto activo - bloqueando llamada con JSON inválido"
        }
    }
}

# Output como JSON
return $output | ConvertTo-Json -Depth 5 -Compress
