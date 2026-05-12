param(
    [switch]$Validate,
    [switch]$Report
)

$ErrorActionPreference = 'Stop'
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
Set-Location $repoRoot

$fixedCount = 0
$failedCount = 0
$issues = @()

function Fix-Script {
    param(
        [string]$ScriptPath,
        [string]$IssueType
    )
    
    $content = Get-Content $ScriptPath -Raw
    $originalContent = $content
    
    try {
        switch ($IssueType) {
            'shell-operators' {
                $content = $content -replace '\|\|', ' -or '
                $content = $content -replace '&&', ' -and '
            }
            'null-coalescing' {
                $content = $content -replace '\?\?', ''
            }
            'escape-sequences' {
                $content = $content -replace '\$_\\"', '$_'
                $content = $content -replace '\\"', '"'
            }
        }
        
        if ($content -ne $originalContent) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($ScriptPath, $content, $utf8NoBom)
            return $true
        }
    } catch {
        return $false
    }
    
    return $false
}

function Validate-Script {
    param([string]$ScriptPath)
    
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath,
        [ref]$null,
        [ref]$errors
    ) | Out-Null
    
    return $errors.Count -eq 0
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Script Normalization - Phase 2 & 3 Implementation" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$scriptsToFix = @(
    @{ Path = '.\scripts\hooks\check-quality.ps1'; Type = 'shell-operators' }
    @{ Path = '.\scripts\hooks\check-testing.ps1'; Type = 'shell-operators' }
    @{ Path = '.\scripts\utilities\migrate-structure.ps1'; Type = 'null-coalescing' }
    @{ Path = '.\scripts\utilities\invoke-ai-review.ps1'; Type = 'null-coalescing' }
    @{ Path = '.\scripts\utilities\create-skill.ps1'; Type = 'escape-sequences' }
)

Write-Host "Fixing scripts with known issues..." -ForegroundColor Cyan
Write-Host ""

foreach ($script in $scriptsToFix) {
    if (Test-Path $script.Path) {
        $relativePath = $script.Path -replace [regex]::Escape($repoRoot), '.'
        Write-Host "Processing: $relativePath" -ForegroundColor White
        
        if (Fix-Script -ScriptPath $script.Path -IssueType $script.Type) {
            Write-Host "  [FIXED] Applied $($script.Type) fixes" -ForegroundColor Green
            $fixedCount++
            
            if (Validate-Script -ScriptPath $script.Path) {
                Write-Host "  [OK] Script validates successfully" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] Script still has validation issues" -ForegroundColor Yellow
                $issues += $relativePath
            }
        } else {
            Write-Host "  [SKIP] No changes needed" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [ERROR] Script not found" -ForegroundColor Red
        $failedCount++
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Scripts fixed: $fixedCount" -ForegroundColor Green
Write-Host "Scripts failed: $failedCount" -ForegroundColor Yellow
Write-Host ""

if ($Validate) {
    Write-Host "Running full validation..." -ForegroundColor Cyan
    & ".\scripts\utilities\audit-script-normalization.ps1" -Report
}

exit 0