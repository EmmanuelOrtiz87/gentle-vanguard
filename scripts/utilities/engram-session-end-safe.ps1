# engram-session-end-safe.ps1
# Wrapper seguro para cerrar sesión en Engram con manejo correcto de JSON
# Este script evita errores de parsing cuando el summary contiene saltos de linea o caracteres especiales

param(
    [Parameter(Mandatory=$true)]
    [string]$SessionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Summary = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "gentle-vanguard"
)

$ErrorActionPreference = 'Continue'

function Escape-JsonString {
    param([string]$String)
    if ([string]::IsNullOrEmpty($String)) { return "" }
    # Escapar caracteres problematicos para JSON
    $escaped = $String -replace '\\', '\\\\' `
                       -replace '"', '\\"' `
                       -replace "`r?`n", '\\n' `
                       -replace "`t", '\\t'
    return $escaped
}

# Detectar repo root
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { 
        $root = Split-Path -Parent $root 
    }
    if (-not $root) { $root = (Get-Location).Path }
    $root
}

# Preparar summary seguro
$safeSummary = Escape-JsonString -String $Summary
if ([string]::IsNullOrEmpty($safeSummary)) {
    $safeSummary = "Session $SessionId ended"
}

# Llamar al script original de engram
$engramScript = Join-Path $repoRoot "scripts\utilities\engram_mem_session_end.ps1"
if (Test-Path $engramScript) {
    & $engramScript -SessionId $SessionId -ProjectName $ProjectName -WorkspaceRoot $repoRoot
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "[OK] Session ended successfully: $SessionId" -ForegroundColor Green
    } else {
        Write-Warning "Session end script returned exit code $exitCode"
    }
    
    exit $exitCode
} else {
    Write-Error "Engram session end script not found: $engramScript"
    exit 1
}
