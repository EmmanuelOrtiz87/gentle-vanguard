param(
    [switch]$Verbose
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

function Test-ScriptNormalization {
    param([string]$ScriptPath)
    
    $issues = @()
    $content = Get-Content $ScriptPath -Raw
    
    # Check for non-ASCII characters
    if ($content -match '[^\x00-\x7F]') {
        $issues += 'Contains non-ASCII characters'
    }
    
    # Check for UTF-8 BOM
    $bytes = [System.IO.File]::ReadAllBytes($ScriptPath)
    if ($bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $issues += 'File has UTF-8 BOM'
    }
    
    # Validate PowerShell syntax
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath,
        [ref]$null,
        [ref]$errors
    ) | Out-Null
    
    if ($errors.Count -gt 0) {
        $issues += "Syntax errors: $($errors.Count)"
    }
    
    return $issues
}

$stagedScripts = @(git diff --cached --name-only --diff-filter=ACM 2>$null | Where-Object { $_ -like '*.ps1' })

if ($stagedScripts.Count -eq 0) {
    exit 0
}

$hasIssues = $false

foreach ($script in $stagedScripts) {
    $fullPath = Join-Path $repoRoot $script
    
    if (-not (Test-Path $fullPath)) {
        continue
    }
    
    $issues = Test-ScriptNormalization -ScriptPath $fullPath
    
    if ($issues.Count -gt 0) {
        if (-not $hasIssues) {
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Red
            Write-Host "Script Normalization Validation Failed" -ForegroundColor Red
            Write-Host "========================================================" -ForegroundColor Red
            Write-Host ""
            $hasIssues = $true
        }
        
        Write-Host "ERROR: $script" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    } elseif ($Verbose) {
        Write-Host "OK: $script" -ForegroundColor Green
    }
}

if ($hasIssues) {
    Write-Host ""
    Write-Host "Please fix the issues above before committing." -ForegroundColor Red
    Write-Host ""
    Write-Host "Run: .\scripts\utilities\audit-script-normalization.ps1 -Fix -Report" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

exit 0