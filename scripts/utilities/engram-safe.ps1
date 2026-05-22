# engram-safe.ps1
# Funciones seguras para llamar a herramientas Engram sin errores de JSON parsing
# Importar este script en otros scripts que usen engram_mem_save, engram_mem_session_end, etc.

$ErrorActionPreference = 'Continue'

<#
.SYNOPSIS
    Escapa una cadena para uso seguro en JSON
.DESCRIPTION
    Reemplaza caracteres problematicos (saltos de linea, comillas, backslashes) 
    para evitar errores de parsing en JSON
#>
function ConvertTo-SafeJsonString {
    param([string]$String)
    if ([string]::IsNullOrEmpty($String)) { return "" }
    
    $escaped = $String -replace '\\', '\\\\' `
                       -replace '"', '\\"' `
                       -replace "`r`n", '\\n' `
                       -replace "`n", '\\n' `
                       -replace "`r", '\\n' `
                       -replace "`t", '\\t'
    return $escaped
}

<#
.SYNOPSIS
    Valida que un string no exceda el limite de longitud para JSON
.DESCRIPTION
    Trunca strings muy largos y agrega indicador [...truncated]
#>
function Limit-JsonStringLength {
    param(
        [string]$String,
        [int]$MaxLength = 4000
    )
    if ($String.Length -gt $MaxLength) {
        return $String.Substring(0, $MaxLength - 15) + " [...truncated]"
    }
    return $String
}

<#
.SYNOPSIS
    Prepara contenido para mem_save de forma segura
.DESCRIPTION
    Valida y escapa el contenido para evitar errores de JSON parsing
    cuando se llama a engram_mem_save
#>
function New-SafeMemSaveContent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("decision", "architecture", "bugfix", "pattern", "config", "discovery", "learning", "manual")]
        [string]$Type = "manual",
        
        [Parameter(Mandatory=$false)]
        [string]$Project = "gentle-vanguard"
    )
    
    # Escapar contenido
    $safeTitle = ConvertTo-SafeJsonString -String $Title
    $safeContent = ConvertTo-SafeJsonString -String $Content
    
    # Limitar longitud
    $safeTitle = Limit-JsonStringLength -String $safeTitle -MaxLength 200
    $safeContent = Limit-JsonStringLength -String $safeContent -MaxLength 4000
    
    return @{
        title = $safeTitle
        content = $safeContent
        type = $Type
        project = $Project
    }
}

<#
.SYNOPSIS
    Prepara summary para mem_session_end de forma segura
.DESCRIPTION
    Valida y escapa el summary para evitar errores de JSON parsing
#>
function New-SafeSessionEndSummary {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SessionId,
        
        [Parameter(Mandatory=$false)]
        [string]$Summary = ""
    )
    
    if ([string]::IsNullOrWhiteSpace($Summary)) {
        return "Session $SessionId completed"
    }
    
    # Escapar y limitar
    $safeSummary = ConvertTo-SafeJsonString -String $Summary
    $safeSummary = Limit-JsonStringLength -String $safeSummary -MaxLength 500
    
    return $safeSummary
}

<#
.SYNOPSIS
    Valida que un path de archivo existe antes de usarlo
.DESCRIPTION
    Previene errores de file not found
#>
function Test-SafeFilePath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "File"
    )
    
    if (-not (Test-Path $Path)) {
        Write-Warning "$Description not found: $Path"
        return $false
    }
    return $true
}

<#
.SYNOPSIS
    Ejecuta un comando con manejo de errores robusto
.DESCRIPTION
    Captura errores y retorna resultado estructurado
#>
function Invoke-SafeCommand {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Command,
        
        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage = "Command failed",
        
        [Parameter(Mandatory=$false)]
        [switch]$ContinueOnError
    )
    
    try {
        $result = & $Command 2>&1
        return @{
            Success = $true
            Output = $result
            Error = $null
        }
    } catch {
        $errorMsg = "$ErrorMessage`: $($_.Exception.Message)"
        Write-Warning $errorMsg
        
        if (-not $ContinueOnError) {
            throw $_
        }
        
        return @{
            Success = $false
            Output = $null
            Error = $errorMsg
        }
    }
}

# Exportar funciones
Export-ModuleMember -Function @(
    'ConvertTo-SafeJsonString',
    'Limit-JsonStringLength', 
    'New-SafeMemSaveContent',
    'New-SafeSessionEndSummary',
    'Test-SafeFilePath',
    'Invoke-SafeCommand'
)

Write-Verbose "Engram safe functions loaded"
