param(
    [switch]$Fix,
    [switch]$Report,
    [string]$OutputPath = '.\docs\audit\script-normalization-report.md'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
Set-Location $repoRoot

$issues = @()
$totalScripts = 0
$fixedScripts = 0

function Test-ScriptNormalization {
    param(
        [string]$ScriptPath,
        [switch]$FixIssues
    )
    
    $scriptIssues = @()
    $content = Get-Content $ScriptPath -Raw
    
    # Check for emojis and special characters
    $emojiPattern = '[^\x00-\x7F]'
    if ($content -match $emojiPattern) {
        $scriptIssues += 'Contains non-ASCII characters (emojis or special symbols)'
        
        if ($FixIssues) {
            $content = $content -replace '[^\x00-\x7F]', ''
        }
    }
    
    # Check for UTF-8 BOM
    $bytes = [System.IO.File]::ReadAllBytes($ScriptPath)
    if ($bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $scriptIssues += 'File has UTF-8 BOM'
        
        if ($FixIssues) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($ScriptPath, $content, $utf8NoBom)
        }
    }
    
    # Check for unbalanced braces
    $openBraces = ($content | Select-String -Pattern '\{' -AllMatches).Matches.Count
    $closeBraces = ($content | Select-String -Pattern '\}' -AllMatches).Matches.Count
    if ($openBraces -ne $closeBraces) {
        $scriptIssues += "Unbalanced braces: $openBraces open, $closeBraces closed"
    }
    
    # Check for unbalanced here-strings
    $openHere = ($content | Select-String -Pattern '@"' -AllMatches).Matches.Count
    $closeHere = ($content | Select-String -Pattern '"@' -AllMatches).Matches.Count
    if ($openHere -ne $closeHere) {
        $scriptIssues += "Unbalanced here-strings: $openHere open, $closeHere closed"
    }
    
    # Check for unbalanced parentheses
    $openParen = ($content | Select-String -Pattern '\(' -AllMatches).Matches.Count
    $closeParen = ($content | Select-String -Pattern '\)' -AllMatches).Matches.Count
    if ($openParen -ne $closeParen) {
        $scriptIssues += "Unbalanced parentheses: $openParen open, $closeParen closed"
    }
    
    # Validate PowerShell syntax
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath,
        [ref]$null,
        [ref]$errors
    ) | Out-Null
    
    if ($errors.Count -gt 0) {
        foreach ($error in $errors) {
            $scriptIssues += "Syntax error: $($error.Message)"
        }
    }
    
    # Save fixed content if needed
    if ($FixIssues -and $scriptIssues.Count -gt 0) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($ScriptPath, $content, $utf8NoBom)
    }
    
    return $scriptIssues
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Script Normalization Audit" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$scripts = Get-ChildItem -Path .\scripts -Filter *.ps1 -Recurse
$totalScripts = $scripts.Count

Write-Host "Found $totalScripts scripts to audit" -ForegroundColor Cyan
Write-Host ""

foreach ($script in $scripts) {
    $relativePath = $script.FullName -replace [regex]::Escape($repoRoot), '.'
    $scriptIssues = Test-ScriptNormalization -ScriptPath $script.FullName -FixIssues:$Fix
    
    if ($scriptIssues.Count -gt 0) {
        $status = if ($Fix) { 'FIXED' } else { 'ISSUE' }
        Write-Host "[$status] $relativePath" -ForegroundColor Yellow
        
        foreach ($issue in $scriptIssues) {
            Write-Host "       - $issue" -ForegroundColor Gray
        }
        
        $issues += @{
            Script = $relativePath
            Issues = $scriptIssues
            Fixed = $Fix
        }
        
        if ($Fix) {
            $fixedScripts++
        }
    } else {
        Write-Host "[OK] $relativePath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Audit Summary" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Total scripts: $totalScripts" -ForegroundColor White
Write-Host "Scripts with issues: $($issues.Count)" -ForegroundColor Yellow
Write-Host "Scripts fixed: $fixedScripts" -ForegroundColor Green
Write-Host ""

if ($Report) {
    $reportContent = @"
# Script Normalization Audit Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Total Scripts**: $totalScripts
**Scripts with Issues**: $($issues.Count)
**Scripts Fixed**: $fixedScripts

## Normalization Standards

Scripts must comply with:
- No emojis or special Unicode characters
- UTF-8 encoding without BOM
- Balanced braces, parentheses, and here-strings
- Valid PowerShell syntax
- ASCII-only text (except in comments for documentation)

## Issues Found

"@
    
    if ($issues.Count -eq 0) {
        $reportContent += "`nAll scripts are compliant with normalization standards.`n"
    } else {
        foreach ($issue in $issues) {
            $reportContent += "`n### $($issue.Script)`n"
            $reportContent += "Issues:`n"
            foreach ($item in $issue.Issues) {
                $reportContent += "- $item`n"
            }
            if ($issue.Fixed) {
                $reportContent += "**Status**: Fixed`n"
            }
        }
    }
    
    $reportContent += "`n## Compliance Status`n"
    $compliancePercent = if ($totalScripts -gt 0) { [math]::Round((($totalScripts - $issues.Count) / $totalScripts) * 100, 2) } else { 0 }
    $reportContent += "**Compliance**: $compliancePercent%`n"
    
    $reportDir = Split-Path $OutputPath
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
}

if ($issues.Count -eq 0) {
    Write-Host "All scripts are compliant!" -ForegroundColor Green
    exit 0
} else {
    if ($Fix) {
        Write-Host "Fixed $fixedScripts scripts" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Run with -Fix to automatically fix issues" -ForegroundColor Yellow
        exit 1
    }
}