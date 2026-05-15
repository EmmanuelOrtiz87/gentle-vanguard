# check-testing.ps1
# Ejecuta tests y valida cobertura minima

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

# PowerShell - Code Coverage
if (Test-Path "tests") {
    _Wh "[TESTING] Verificando cobertura de código PowerShell..." Cyan
    $repoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName
    $verifyCoverage = Join-Path $repoRoot 'scripts\utilities\verify-coverage.ps1'
    
    if (Test-Path $verifyCoverage) {
        pwsh -NoProfile -ExecutionPolicy Bypass -File $verifyCoverage -MinimumCoverage 85
        if ($LASTEXITCODE -ne 0) {
            _Wh "[FAIL] Cobertura de código por debajo del umbral mínimo (85%)" Red
            exit 1
        }
    }
}

# Node.js/TypeScript
if (Test-Path "package.json") {
    _Wh "[TESTING] Ejecutando tests (npm test)..." Cyan
    npm test  -or  exit 1
}

# Go
if (Test-Path "go.mod") {
    _Wh "[TESTING] Ejecutando tests (go test)..." Cyan
    go test ./...  -or  exit 1
}

_Wh "[TESTING] Todos los tests pasaron." Green
exit 0
