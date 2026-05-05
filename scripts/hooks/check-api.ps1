# check-api.ps1
# Valida reglas de diseno de API (OpenAPI, convenciones, breaking changes)

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

# Advertir si falta doc OpenAPI en controladores nuevos
$files = git diff --cached --name-only --diff-filter=ACM 2>$null
$failed = $false

foreach ($file in $files.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    if ($file -like '*controller*' -or $file -like '*api*') {
        $content = git show ":0:$file" 2>$null
        if ($content -and $content -notmatch 'openapi|swagger') {
            _Wh "[API] Falta documentacion OpenAPI/Swagger en $file" Yellow
            $failed = $true
        }
    }
}

if ($failed) { exit 1 } else { exit 0 }
