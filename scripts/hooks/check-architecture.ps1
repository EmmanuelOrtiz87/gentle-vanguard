# check-architecture.ps1
# Valida reglas de arquitectura (importaciones cruzadas, estructura, etc.)

$ErrorActionPreference = 'Continue'

# Ejemplo: prohibir imports cruzados entre capas
$forbiddenPatterns = @(
    @{ Pattern = 'infra/.*domain'; Message = 'Infraestructura no debe importar dominio' },
    @{ Pattern = 'ui/.*infra'; Message = 'UI no debe importar infraestructura' }
)

$files = git diff --cached --name-only --diff-filter=ACM 2>$null
$failed = $false

foreach ($file in $files.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
    foreach ($rule in $forbiddenPatterns) {
        if ($content -match $rule.Pattern) {
            Write-Host "[ARCHITECTURE] $($rule.Message) en $file" -ForegroundColor Red
            $failed = $true
        }
    }
}

if ($failed) { exit 1 } else { exit 0 }
