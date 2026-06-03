param(
    [switch]$Verbose,
    [switch]$Fix,
    [switch]$ShowLesson
)

$ErrorActionPreference = 'Stop'
$script:Errors = @()
$script:Fixed = @()

function Write-Learn {
    param([string]$Message)
    if ($Verbose -or $ShowLesson) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$patterns = @('*.ps1', '*.psm1')
$scanned = 0

$learnedLesson = @"

[SEARCH] LECCIN: PowerShell Parser Error - `[OK]` al inicio de lnea


PROBLEMA:
  En PowerShell, `[OK]` al inicio de una lnea (sin variable precedente)
  se interpreta como una expresin de ndice, causando error de parser.
  
  Ejemplo que falla:
    #[OK] Validation passed     PowerShell interpreta [OK] como ndice

  Ejemplo correcto:
    Write-Output "[OK] Validation passed"
    Write-Host "[OK] Validation passed" -ForegroundColor Green
    Write-Host @"
    [# OK] Validation passed
    "@

PORQUE FALLA:
  Los brackets [] en PowerShell tienen significados especiales:
  - [string] = tipo cast  
  - $array[0] = ndice de array
  - [OK] = expresin invlida sin contexto

DNDE APLICA:
  Scripts standalone que se ejecutan en hooks, CI, o como entrypoint
  (dentro de funciones NO falla porque hay contexto)

SOLUCIN:
  1. Usar Write-Output o Write-Host con string entre comillas
  2. Usar here-string @"..."@ para multi-lnea
  3. Usar funcin helper: function Write-Ok { param($m) ... }

EJEMPLOS:
   Write-Output "[# OK] Todo bien"
   Write-Host "[# OK] Passed" -ForegroundColor Green  
   Write-Host @"
  [# OK] Line 1
  [# OK] Line 2
  "@ -ForegroundColor Green
   #[OK] Passed (sin Write-Output/Write-Host)

APRENDIZAJE INTEGRADO EN:
  - validate-script-governance.ps1 (regla automatizada)
  - auto-fix-delegate.ps1 (flujo automtico detect-fix-delegate)
  - .git/hooks/pre-push (valida automticamente)
  - auto-delegation.json (SCRIPT-GOV keywords)

"@

Get-ChildItem -Path $repoRoot -Include $patterns -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\node_modules\\'
} | ForEach-Object {
    $scanned++
    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return }

    if ($content -match '@"[\s\S]*?\[(OK|ERROR|FAIL|PASS|WARN)\][\s\S]*?"@') {
        return
    }

    $lines = $content -split "`r?`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNum = $i + 1

        if ($line -match '^\s*\[(OK|ERROR|FAIL|PASS|WARN)\]\s+\w+') {
            $script:Errors += [ordered]@{
                file = $_.Name
                path = $_.FullName
                line = $lineNum
                content = $line.Trim()
                issue = "Pattern '[$($matches[1])]' at start of line - requires Write-Output/Write-Host"
            }
        }
    }
}

if ($script:Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "" -ForegroundColor Yellow
    Write-Host "  $($script:Errors.Count) errores de parser detectados" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow

    $script:Errors | ForEach-Object {
        Write-Host "   $($_.file):$($_.line)" -ForegroundColor Red
        Write-Host "     $($_.content)" -ForegroundColor Gray
    }

    if ($Fix) {
        Write-Host ""
        Write-Host "[TOOL] Aplicando correcciones automticas..." -ForegroundColor Yellow

        $errorsByFile = $script:Errors | Group-Object -Property path
        foreach ($fileGroup in $errorsByFile) {
            $filePath = $fileGroup.Name
            $fileContent = Get-Content -Path $filePath -Raw -Encoding UTF8

            foreach ($err in $fileGroup.Group) {
                if ($fileContent -match '(\s*)\[OK\](\s+\S)') {
                    $fileContent = $fileContent -replace '(\s*)\[OK\](\s+\S)', '$1Write-Output "[OK]$2'
                    $script:Fixed += $err.file
                }
                if ($fileContent -match '(\s*)\[ERROR\](\s+\S)') {
                    $fileContent = $fileContent -replace '(\s*)\[ERROR\](\s+\S)', '$1Write-Error "[ERROR]$2'
                    $script:Fixed += $err.file
                }
            }

            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
        }

        Write-Host "   $($script:Fixed.Count) archivos corregidos" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host " Para auto-corregir ejecutar:" -ForegroundColor Cyan
        Write-Host "   .\scripts\diagnostics\auto-learn.ps1 -Fix" -ForegroundColor White
    }
}

if ($ShowLesson -or $Verbose) {
    Write-Host $learnedLesson
}

if ($script:Errors.Count -eq 0) {
    Write-Host " Script governance: Sin errores de parser" -ForegroundColor Green
    exit 0
}

exit 1


