# check-architecture.ps1
# Valida reglas de arquitectura (importaciones cruzadas, estructura, etc.)

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

# Prohibir imports cruzados entre capas
$forbiddenPatterns = @(
    @{ Pattern = 'infra/.*domain'; Message = 'Infraestructura no debe importar dominio' },
    @{ Pattern = 'ui/.*infra';     Message = 'UI no debe importar infraestructura' }
)

$files = git diff --cached --name-only --diff-filter=ACM 2>$null
$failed = $false

foreach ($file in $files.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    $content = git show ":0:$file" 2>$null
    if (-not $content) { continue }
    foreach ($rule in $forbiddenPatterns) {
        if ($content -match $rule.Pattern) {
            _Wh "[ARCHITECTURE] $($rule.Message) en $file" Red
            $failed = $true
        }
    }
}

if ($failed) { exit 1 } else { exit 0 }
