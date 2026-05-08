#!/usr/bin/env pwsh
param([switch]$Fix)

$jsonFiles = git diff --cached --name-only --diff-filter=ACM | Select-String '\.json$'
$hasErrors = $false

foreach ($file in $jsonFiles) {
    $path = $file.Line
    if (-not (Test-Path $path)) { continue }
    try {
        $content = Get-Content $path -Raw -ErrorAction Stop
        $null = $content | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host "[ERROR] Invalid JSON: $path - $_" -ForegroundColor Red
        $hasErrors = $true
    }
}

if ($hasErrors) { exit 1 }
Write-Host "[OK] All JSON files valid" -ForegroundColor Green
exit 0
