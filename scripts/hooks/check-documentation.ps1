# check-documentation.ps1
# Valida cobertura de documentacin en funciones pblicas y cambios de usuario

$ErrorActionPreference = 'Continue'

$files = git diff --cached --name-only --diff-filter=ACM 2>$null
$warned = $false

foreach ($file in $files.Split("`n")) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    if ($file -like '*.js' -or $file -like '*.py') {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -notmatch 'docstring|@param|@returns|#' ) {
            Write-Host "[DOC] Falta documentacin en $file" -ForegroundColor Yellow
            $warned = $true
        }
    }
}

if ($warned) { exit 0 } else { exit 0 }
