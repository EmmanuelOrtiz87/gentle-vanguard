# check-api.ps1
# Valida reglas de diseo de API (OpenAPI, convenciones, breaking changes)

$ErrorActionPreference = 'Continue'

# Ejemplo: advertir si falta doc OpenAPI en controladores nuevos
$files = git diff --cached --name-only --diff-filter=ACM 2>$null
$failed = $false

foreach ($file in $files.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    if ($file -like '*controller*' -or $file -like '*api*') {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -notmatch 'openapi|swagger') {
            Write-Host "[API] Falta documentacin OpenAPI/Swagger en $file" -ForegroundColor Yellow
            $failed = $true
        }
    }
}

if ($failed) { exit 1 } else { exit 0 }
