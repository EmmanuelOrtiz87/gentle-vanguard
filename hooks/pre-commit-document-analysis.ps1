#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pre-commit hook que detecta documentos nuevos en docs/requirements/ y los analiza.
.DESCRIPTION
    Compara el diff entre staged y HEAD para encontrar archivos de requisitos nuevos/modificados
    (PDF, DOCX, XLSX, PPTX, MD) y ejecuta el analisis automatico.
    No bloquea el commit — corre en background.
#>

$ErrorActionPreference = 'Continue'
$ProjectRoot = git rev-parse --show-toplevel 2>$null
if (-not $ProjectRoot) { exit 0 }

$DocAnalysisSkill = Join-Path $ProjectRoot 'skills' 'document-analysis-skill' 'invoke-document-analysis.ps1'
if (-not (Test-Path $DocAnalysisSkill)) { exit 0 }

$StagedFiles = git diff --cached --name-only --diff-filter=ACM 2>$null
$DocExtensions = @('.pdf', '.docx', '.doc', '.xlsx', '.xls', '.pptx', '.ppt', '.md')
$DocFiles = $StagedFiles | Where-Object {
    $ext = [System.IO.Path]::GetExtension($_).ToLower()
    return $ext -in $DocExtensions
}

if (-not $DocFiles) { exit 0 }

Write-Host "[Document Analysis] Documentos detectados en staged:" -ForegroundColor Cyan
$DocFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

$OutputDir = Join-Path $ProjectRoot 'docs' 'requirements-analysis'

foreach ($doc in $DocFiles) {
    $fullPath = Join-Path $ProjectRoot $doc
    if (-not (Test-Path $fullPath)) { continue }
    Write-Host "[Document Analysis] Analizando: $doc..." -ForegroundColor Cyan
    try {
        $job = Start-Job -ScriptBlock {
            param($Script, $Path, $Output)
            & $Script -DocumentPath $Path -Scope quick -Source document -OutputDir $Output -Quiet
        } -ArgumentList $DocAnalysisSkill, $fullPath, $OutputDir
        Write-Host "[Document Analysis] Analisis en background (Job ID: $($job.Id))" -ForegroundColor Green
    } catch { Write-Host "[Document Analysis] Error lanzando analisis: $_" -ForegroundColor Yellow }
}

# No bloqueamos el commit
exit 0
