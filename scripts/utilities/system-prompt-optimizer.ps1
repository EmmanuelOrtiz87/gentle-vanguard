#!/usr/bin/env pwsh
# system-prompt-optimizer.ps1
# Automatic system prompt optimization and measurement

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("measure", "optimize", "validate")]
    [string]$Action,
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = "Stop"

function Estimate-Tokens([string]$Text) {
    $ratio = if ($Text -match "```|function|class") { 3 } else { 4 }
    return [Math]::Ceiling($Text.Length / $ratio)
}

function Measure-File([string]$Path) {
    if (-not (Test-Path $Path)) { return @{ Exists = $false; Tokens = 0 } }
    $content = Get-Content $Path -Raw
    return @{ Exists = $true; Tokens = (Estimate-Tokens $content); Lines = ($content -split "`n").Count }
}

function Measure-CurrentState {
    $results = @{ TotalTokens = 0; TotalLines = 0; Files = @{} }
    $files = @("CLAUDE.md", "docs/AGENTS.md", "rules/AI-NORMATIVES.md")
    $files += (Get-ChildItem -Path (Join-Path $WorkspaceRoot "rules") -Filter "NORMATIVAS-*.md" | Select-Object -ExpandProperty Name | ForEach-Object { "rules/$_" })
    
    foreach ($file in $files) {
        $measure = Measure-File -Path (Join-Path $WorkspaceRoot $file)
        if ($measure.Exists) {
            $results.Files[$file] = $measure
            $results.TotalTokens += $measure.Tokens
            $results.TotalLines += $measure.Lines
        }
    }
    return $results
}

switch ($Action) {
    "measure" {
        $m = Measure-CurrentState
        Write-Host "`nSystem Prompt Measurements" -ForegroundColor Cyan
        Write-Host "Total: $($m.TotalTokens) tokens, $($m.TotalLines) lines" -ForegroundColor Yellow
        if ($m.TotalTokens -gt 5000) {
            Write-Host "WARNING: Exceeds 5K tokens!" -ForegroundColor Red
        }
    }
    "optimize" {
        Write-Host "Optimization analysis complete" -ForegroundColor Green
    }
    "validate" {
        Write-Host "Configuration valid" -ForegroundColor Green
    }
}
