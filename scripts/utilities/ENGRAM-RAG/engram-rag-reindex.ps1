#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Full re-index of Engram observations into the vector index.
.DESCRIPTION
    Removes existing index metadata and runs a full rebuild via
    engram-vector-index.ps1. Use this when many new memories have been
    added or when you want to ensure the index is completely fresh.
.PARAMETER Project
    Filter observations to a specific project.
.PARAMETER ExportFile
    Path to a pre-existing engram export JSON. Skips calling engram export.
#>

param(
    [string]$Project = "",
    [string]$ExportFile = ""
)

$ErrorActionPreference = "Continue"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) {
    $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$indexDir = Join-Path $repoRoot '.session' 'engram-rag'
$indexFile = Join-Path $indexDir 'vector-index.json'
$metaFile = Join-Path $indexDir 'index-meta.json'
$tmpExport = Join-Path $indexDir '_export-tmp.json'

function Write-Log { param([string]$M, [string]$C = "Cyan") Write-Host "[ENGRAM-RAG-REINDEX] $M" -ForegroundColor $C }

Write-Log "Starting full re-index..."

# Clean up existing index
if (Test-Path $indexFile) {
    Remove-Item $indexFile -Force
    Write-Log "Removed existing index file"
}
if (Test-Path $metaFile) {
    Remove-Item $metaFile -Force
    Write-Log "Removed existing index metadata"
}
if (Test-Path $tmpExport) {
    Remove-Item $tmpExport -Force
}

# Run vector index build
$indexScript = Join-Path $PSScriptRoot 'engram-vector-index.ps1'
if (-not (Test-Path $indexScript)) {
    Write-Log "Vector index script not found: $indexScript" Red
    exit 1
}

$argsList = @('-Force')
if ($Project) { $argsList += @('-Project', $Project) }
if ($ExportFile) { $argsList += @('-ExportFile', $ExportFile) }

Write-Log "Running: engram-vector-index.ps1 $($argsList -join ' ')"
& $indexScript @argsList

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-Log "Re-index failed with exit code $LASTEXITCODE" Red
    exit $LASTEXITCODE
}

Write-Log "Re-index complete" Green
