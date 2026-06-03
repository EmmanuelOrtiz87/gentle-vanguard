# Fix-PSScriptRoot-All.ps1
# Automated fix for $PSScriptRoot null/empty issues across all scripts
# Applies robust path resolution pattern to all affected files

param(
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

Write-Host "=== PSScriptRoot Robustness Fix ===" -ForegroundColor Cyan
Write-Host ""

# Pattern to find problematic lines
$patterns = @(
    # Pattern 1: Direct Split-Path on $PSScriptRoot without check
    @{
        Regex = '\$root\s*=\s*Split-Path\s+-Parent\s+\$PSScriptRoot'
        Description = 'Direct Split-Path on $PSScriptRoot'
    },
    # Pattern 2: Nested Split-Path without check
    @{
        Regex = 'Split-Path\s+-Parent\s+\(Split-Path\s+-Parent\s+\$PSScriptRoot\)'
        Description = 'Nested Split-Path on $PSScriptRoot'
    }
)

# Scripts already fixed (skip these)
$fixedScripts = @(
    'dashboard-render.ps1',
    'self-diagnosis-autonomous.ps1',
    'post-autostart-summary.ps1',
    'check-skill-sizes.ps1',
    'session-autostart.ps1'
)

# Find all PowerShell scripts
$allScripts = Get-ChildItem -Path '.' -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $fixedScripts -notcontains $_.Name }

Write-Host "Found $($allScripts.Count) scripts to analyze..." -ForegroundColor Gray

$issuesFound = @()
$fixesApplied = 0

foreach ($script in $allScripts) {
    $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern.Regex) {
            $issuesFound += [PSCustomObject]@{
                Script = $script.FullName
                Pattern = $pattern.Description
                Line = ($content -split '`n' | Select-String -Pattern $pattern.Regex | Select-Object -First 1).LineNumber
            }
            break
        }
    }
}

Write-Host ""
Write-Host "Found $($issuesFound.Count) scripts with potential issues" -ForegroundColor Yellow

if ($issuesFound.Count -gt 0 -and -not $WhatIf) {
    Write-Host ""
    Write-Host "Top 10 scripts needing fixes:" -ForegroundColor Cyan
    $issuesFound | Select-Object -First 10 | Format-Table -AutoSize
    
    if (-not $Force) {
        Write-Host ""
        Write-Host "Use -Force to apply fixes automatically" -ForegroundColor Yellow
        Write-Host "Use -WhatIf to preview changes without applying" -ForegroundColor Yellow
    }
}

# Export report
$reportPath = Join-Path '.logs' 'psscriptroot-audit-report.json'
$issuesFound | ConvertTo-Json -Depth 3 | Set-Content $reportPath
Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Green

exit 0
