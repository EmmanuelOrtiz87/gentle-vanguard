#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Document Analysis Orchestrator — analiza documentos de requerimientos y produce estimaciones.
.DESCRIPTION
    Pipeline completo: extrae texto del documento (via sidecar Python), analiza con LLM real
    (opencode), consulta Jira/Confluence, y genera reporte con tecnologias, especialistas,
    dependencias, tiempos y costos.
.PARAMETER DocumentPath
    Ruta al documento de requerimientos (PDF, DOCX, XLSX, PPTX, MD, TXT).
.PARAMETER Scope
    full | quick | tech-only | cost-only. Default: full.
.PARAMETER Source
    document | jira | confluence | all. Default: all.
.PARAMETER OutputFormat
    markdown | pdf | docx | xlsx. Default: markdown.
.PARAMETER JiraProject
    Opcional: proyecto Jira para buscar tickets relacionados.
.PARAMETER ConfluenceSpace
    Opcional: espacio Confluence con info de equipos/especialistas.
.PARAMETER OutputDir
    Directorio de salida para el reporte. Default: docs/requirements-analysis/
.PARAMETER Quiet
    Suprimir output verbose.
#>

param(
    [string]$DocumentPath = '',
    [ValidateSet('full', 'quick', 'tech-only', 'cost-only')]
    [string]$Scope = 'full',
    [ValidateSet('document', 'jira', 'confluence', 'all')]
    [string]$Source = 'all',
    [ValidateSet('markdown', 'pdf', 'docx', 'xlsx')]
    [string]$OutputFormat = 'markdown',
    [string]$JiraProject = '',
    [string]$ConfluenceSpace = '',
    [string]$OutputDir = '',
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DocumentPath)) {
    Write-Host "[document-analysis-init] No DocumentPath provided, skipping analysis" -ForegroundColor DarkGray
    return @{ status = 'skipped'; reason = 'no_document_path' } | ConvertTo-Json
}

$ScriptDir = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ScriptDir -Parent
$SidecarDir = Join-Path $PSScriptRoot 'sidecar'
$ConnectorsDir = Join-Path $PSScriptRoot 'connectors'
$AnalysisDir = Join-Path $ProjectRoot '.session' 'document-analysis'
$Script:StepResults = @{}
$Script:AnalysisStart = Get-Date

if (-not $OutputDir) { $OutputDir = Join-Path $ProjectRoot 'docs' 'requirements-analysis' }
New-Item -ItemType Directory -Path $AnalysisDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    if (-not $Quiet) {
        $ts = Get-Date -Format 'HH:mm:ss'
        Write-Host "[$ts] [$Level] $Message" -ForegroundColor $(if ($Level -eq 'ERROR') { 'Red' } elseif ($Level -eq 'WARN') { 'Yellow' } else { 'Cyan' })
    }
}

function Invoke-Sidecar {
    param([string]$Command, [hashtable]$Payload = @{})
    $payload = $Payload.Clone()
    $payload['command'] = $Command
    $payload['id'] = [guid]::NewGuid().ToString()
    $json = $payload | ConvertTo-Json -Compress
    try {
        $result = & python "$SidecarDir/main.py" --action $Command --payload ($payload | ConvertTo-Json -Compress) 2>$null
        if (-not $result) {
            $result = echo $json | python "$SidecarDir/main.py" 2>$null
        }
        return $result | ConvertFrom-Json
    } catch {
        Write-Log "Sidecar error: $_" 'ERROR'
        return $null
    }
}

function Read-DocumentContent {
    param([string]$Path)
    Write-Log "Leyendo documento: $Path"
    if (-not (Test-Path $Path)) { throw "Documento no encontrado: $Path" }

    $result = Invoke-Sidecar -Command 'read_document' -Payload @{path = $Path; options = @{language = 'spa'}}
    if (-not $result -or $result.type -eq 'error') {
        Write-Log "Fallo lectura directa, intentando process_document..." 'WARN'
        $result = Invoke-Sidecar -Command 'read_document' -Payload @{path = $Path}
        if (-not $result -or $result.type -eq 'error') { throw "No se pudo leer el documento: $($result.error)" }
    }
    return $result.result
}

function Build-AnalysisPrompt {
    param($DocContent, $JiraData, $ConfluenceData)
    $text = $DocContent.content
    if ([string]::IsNullOrEmpty($text)) { $text = $DocContent.text }
    if ($text.Length -gt 12000) { $text = $text.Substring(0, 12000) + '...(truncado)' }

    $prompt = @"
Eres un analista senior de requerimientos de software. Analiza el siguiente documento y produce un JSON con:

1. technologies[] — tecnologias detectadas (lenguajes, frameworks, herramientas, plataformas)
2. design_patterns[] — patrones de diseno/arquitectura identificados
3. specialists[] — especialistas necesarios con su rol y seniority
4. areas[] — areas tecnologicas involucradas
5. dependencies[] — dependencias con otros equipos/sistemas
6. time_estimate — estimacion de tiempo: {hours, days, weeks, phases: [{name, hours, description}]}
7. cost_estimate — estimacion de costo: {usd, currency: "USD", breakdown: [{concept, amount}]}
8. confidence — nivel de confianza del analisis (0.0-1.0)
9. risks[] — riesgos identificados
10. summary — resumen ejecutivo en 3 parrafos

Documento a analizar:
---
$text
---
"@
    if ($JiraData) { $prompt += "`n`nDatos de Jira (tickets relacionados):`n---`n$(($JiraData | ConvertTo-Json -Depth 3).Substring(0, [Math]::Min(3000, ($JiraData | ConvertTo-Json -Depth 3).Length)))" }
    if ($ConfluenceData) { $prompt += "`n`nDatos de Confluence (equipos/especialistas):`n---`n$(($ConfluenceData | ConvertTo-Json -Depth 3).Substring(0, [Math]::Min(3000, ($ConfluenceData | ConvertTo-Json -Depth 3).Length)))" }
    $prompt += "`n`nResponde SOLO con el JSON, sin explicaciones adicionales."
    return $prompt
}

function Invoke-LLMAnalysis {
    param([string]$Prompt)
    Write-Log "Enviando analisis a LLM..."
    $promptFile = Join-Path $AnalysisDir "prompt-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $Prompt | Out-File -FilePath $promptFile -Encoding utf8

    $resultFile = Join-Path $AnalysisDir "analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    try {
        $opencodeArgs = @('execute', "-m", "openrouter/qwen/qwen-3.6-plus", "-p", $Prompt, "--json", "-o", $resultFile)
        $process = Start-Process -FilePath "opencode" -ArgumentList $opencodeArgs -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0 -and (Test-Path $resultFile)) {
            return Get-Content $resultFile -Raw | ConvertFrom-Json
        }
    } catch { Write-Log "LLM directo fallo, usando fallback: $_" 'WARN' }

    $opencodeCmd = "opencode execute -m openrouter/qwen/qwen-3.6-plus -p `"$Prompt`" --json"
    try {
        $result = Invoke-Expression $opencodeCmd 2>$null
        if ($result) {
            $result | Out-File -FilePath $resultFile -Encoding utf8
            return $result | ConvertFrom-Json
        }
    } catch { Write-Log "LLM fallback fallo: $_" 'WARN' }

    return $null
}

function Generate-FallbackAnalysis {
    param($DocContent)
    Write-Log "Generando analisis fallback basado en regex..." 'WARN'
    $text = $DocContent.content
    if ([string]::IsNullOrEmpty($text)) { $text = $DocContent.text }
    if (-not $text) { $text = '' }

    $techPatterns = @{
        'javascript|node\.?js|react|angular|vue' = 'JavaScript/Node.js'
        'python|django|flask|fastapi' = 'Python'
        'java|spring|jvm|kotlin' = 'Java'
        '\.net|c#|asp\.net' = '.NET'
        'go|golang' = 'Go'
        'rust|cargo' = 'Rust'
        'sql|postgres|mysql|sqlite|mongodb|redis' = 'Base de Datos'
        'docker|kubernetes|k8s|container' = 'Containers/K8s'
        'aws|azure|gcp|cloud' = 'Cloud'
        'api|rest|graphql|grpc' = 'API'
        'microservice|micro-servicio' = 'Microservicios'
        'machine learning|ml|ia|inteligencia artificial' = 'ML/AI'
    }
    $technologies = @()
    foreach ($pattern in $techPatterns.Keys) {
        if ($text -match $pattern) { $technologies += $techPatterns[$pattern] }
    }
    $technologies = $technologies | Select-Object -Unique

    $areaPatterns = @{
        'frontend|ui|ux' = 'Frontend'
        'backend|api|servicio' = 'Backend'
        'base de datos|data|storage' = 'Data/Storage'
        'infra|devops|deploy|ci/cd' = 'DevOps/Infra'
        'seguridad|security|auth|oauth' = 'Security'
        'testing|test|qa|calidad' = 'QA/Testing'
        'mobile|ios|android' = 'Mobile'
    }
    $areas = @()
    foreach ($pattern in $areaPatterns.Keys) {
        if ($text -match $pattern) { $areas += $areaPatterns[$pattern] }
    }
    $areas = $areas | Select-Object -Unique

    return [PSCustomObject]@{
        technologies   = $technologies
        design_patterns = @()
        specialists    = @()
        areas          = $areas
        dependencies   = @()
        time_estimate  = @{hours = 0; days = 0; weeks = 0; phases = @()}
        cost_estimate  = @{usd = 0; currency = 'USD'; breakdown = @()}
        confidence     = 0.3
        risks          = @()
        summary        = "Analisis fallback basado en deteccion de patrones basicos. Se recomienda usar LLM para analisis completo."
    }
}

function Generate-Report {
    param($Analysis, $DocMetadata, $OutputPath)
    Write-Log "Generando reporte en formato: $OutputFormat"

    $reportContent = @"
# Analisis de Requerimientos

**Documento:** $(Split-Path $DocumentPath -Leaf)
**Fecha:** $((Get-Date).ToString('yyyy-MM-dd HH:mm'))
**Scope:** $Scope | **Fuente:** $Source
**Confianza:** $($Analysis.confidence)

---

## Resumen Ejecutivo

$($Analysis.summary)

---

## Tecnologias Detectadas

$(($Analysis.technologies | ForEach-Object { "- $_" }) -join "`n")

## Patrones de Diseno

$(($Analysis.design_patterns | ForEach-Object { "- $_" }) -join "`n")

## Especialistas Requeridos

$(($Analysis.specialists | ForEach-Object { "- $($_.rol) ($($_.seniority))" }) -join "`n")

## Areas Involucradas

$(($Analysis.areas | ForEach-Object { "- $_" }) -join "`n")

## Dependencias

$(($Analysis.dependencies | ForEach-Object { "- $_" }) -join "`n")

## Estimacion de Tiempo

- **Horas:** $($Analysis.time_estimate.hours)
- **Dias:** $($Analysis.time_estimate.days)
- **Semanas:** $($Analysis.time_estimate.weeks)

### Fases

$(($Analysis.time_estimate.phases | ForEach-Object { "- $($_.name): $($_.hours)h — $($_.description)" }) -join "`n")

## Estimacion de Costo

- **Total USD:** `$$($Analysis.cost_estimate.usd)

### Desglose

$(($Analysis.cost_estimate.breakdown | ForEach-Object { "- $($_.concept): `$$($_.amount)" }) -join "`n")

## Riesgos

$(($Analysis.risks | ForEach-Object { "- $_" }) -join "`n")

---

*Generado por Gentle-Vanguard Document Analysis Skill*
"@

    $reportContent | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Log "Reporte guardado: $OutputPath"
    return $OutputPath
}

try {
    Write-Log "=== Iniciando analisis de documento ==="
    $Script:StepResults.document_path = $DocumentPath
    $Script:StepResults.scope = $Scope
    $Script:StepResults.source = $Source

    if (-not (Test-Path $DocumentPath)) {
        throw "El documento no existe: $DocumentPath"
    }

    $docContent = Read-DocumentContent -Path $DocumentPath
    $Script:StepResults.doc_content = $docContent
    Write-Log "Documento leido: $(@($docContent.content, $docContent.text) -ne '' | Select -First 1).Length caracteres"

    $jiraData = $null
    if ($Source -in @('jira', 'all') -and $JiraProject) {
        Write-Log "Consultando Jira proyecto: $JiraProject"
        $jiraScript = Join-Path $ConnectorsDir 'jira-connector.ps1'
        if (Test-Path $jiraScript) {
            try { $jiraData = & $jiraScript -Action search -Project $JiraProject -Query $Script:StepResults.doc_content.metadata.title -Quiet } catch {}
        }
    }

    $confluenceData = $null
    if ($Source -in @('confluence', 'all') -and $ConfluenceSpace) {
        Write-Log "Consultando Confluence espacio: $ConfluenceSpace"
        $confScript = Join-Path $ConnectorsDir 'confluence-connector.ps1'
        if (Test-Path $confScript) {
            try { $confluenceData = & $confScript -Action getSpace -SpaceKey $ConfluenceSpace -Quiet } catch {}
        }
    }

    $prompt = Build-AnalysisPrompt -DocContent $docContent -JiraData $jiraData -ConfluenceData $confluenceData
    $analysis = Invoke-LLMAnalysis -Prompt $prompt

    if (-not $analysis) {
        Write-Log "LLM no disponible, usando analisis fallback" 'WARN'
        $analysis = Generate-FallbackAnalysis -DocContent $docContent
    }

    $Script:StepResults.analysis = $analysis

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportFile = Join-Path $OutputDir "requirements-analysis-$timestamp.md"
    Generate-Report -Analysis $analysis -DocMetadata $docContent.metadata -OutputPath $reportFile

    $analysisResult = @{
        status        = 'success'
        document      = $DocumentPath
        report        = $reportFile
        technologies  = $analysis.technologies
        specialists   = $analysis.specialists
        areas         = $analysis.areas
        dependencies  = $analysis.dependencies
        time_hours    = $analysis.time_estimate.hours
        cost_usd      = $analysis.cost_estimate.usd
        confidence    = $analysis.confidence
        elapsed_ms    = [math]::Round(((Get-Date) - $Script:AnalysisStart).TotalMilliseconds)
    }

    $resultFile = Join-Path $AnalysisDir "result-$timestamp.json"
    $analysisResult | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultFile -Encoding utf8

    Write-Log "=== Analisis completado ==="
    Write-Log "Reporte: $reportFile"
    Write-Log "Tecnologias: $($analysis.technologies -join ', ')"
    Write-Log "Tiempo estimado: $($analysis.time_estimate.hours)h / $($analysis.time_estimate.days)d"
    Write-Log "Costo estimado: USD `$$($analysis.cost_estimate.usd)"

    return $analysisResult | ConvertTo-Json -Depth 5

} catch {
    Write-Log "Error en analisis: $_" 'ERROR'
    $errorResult = @{
        status   = 'error'
        document = $DocumentPath
        error    = $_.ToString()
        elapsed_ms = [math]::Round(((Get-Date) - $Script:AnalysisStart).TotalMilliseconds)
    }
    $errorFile = Join-Path $AnalysisDir "error-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $errorResult | ConvertTo-Json | Out-File -FilePath $errorFile -Encoding utf8
    return $errorResult | ConvertTo-Json -Depth 3
}
