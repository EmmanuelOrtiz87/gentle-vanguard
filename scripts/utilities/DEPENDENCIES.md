<# .SYNOPSIS Validates documentation consistency and completeness

.DESCRIPTION Checks that all scripts have proper documentation, READMEs exist, and documentation
follows standards

.PARAMETER Path Root path to validate (default: current directory)

.PARAMETER Verbose Show detailed validation messages

.PARAMETER Fix Attempt to fix issues automatically

.EXAMPLE .\validate-documentation.ps1 -Path "scripts\utilities" -Verbose

.NOTES Author: Gentle-Vanguard Team versión: 1.0.0 Last Updated: 2026-04-22 #>

param( [string]$Path = ".",
    [switch]$Verbose, [switch]$Fix )

$ErrorActionPreference = "Stop"
$issues = @() $warnings = @()
$passed = @()

# ===== FUNCTIONS =====

function Write-Log { param([string]$Message, [string]$Level = "INFO")
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) { "ERROR" { "Red" }
"WARN" { "Yellow" } "SUCCESS" { "Green" } default { "White" } } Write-Host "[$timestamp] [$Level]
$Message" -ForegroundColor $color }

function Test-ScriptHeader { param([string]$ScriptPath)

    $content = Get-Content -Path $ScriptPath -Raw

    $hasHeader = $content -match '<#\s*\.SYNOPSIS'
    $hasSynopsis = $content -match '\.SYNOPSIS'
    $hasDescription = $content -match '\.DESCRIPTION'
    $hasExample = $content -match '\.EXAMPLE'

    if (-not $hasHeader) {
        return $false, "Missing script header"
    }
    if (-not $hasSynopsis) {
        return $false, "

{ "prompt_tokens": 72799, "prompt_unit_price": "0", "prompt_price_unit": "0", "prompt_price": "0",
"completion_tokens": 8096, "completion_unit_price": "0", "completion_price_unit": "0",
"completion_price": "0", "total_tokens": 80895, "total_price": "0", "currency": "USD", "latency":
52.204, "time_to_first_token": 3.746, "time_to_generate": 48.458 }

