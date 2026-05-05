# check-documentation.ps1
# Valida cobertura de documentacion en funciones publicas y cambios de usuario

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

$files = git diff --cached --name-only --diff-filter=ACM 2>$null
$warned = $false

foreach ($file in $files.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    if ($file -like '*.js' -or $file -like '*.py') {
        $content = git show ":0:$file" 2>$null
        if ($content -and $content -notmatch 'docstring|@param|@returns|#') {
            _Wh "[DOC] Falta documentacion en $file" Yellow
            $warned = $true
        }
    }
}

exit 0
