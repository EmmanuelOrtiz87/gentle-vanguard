param(
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../../')
Set-Location $repoRoot

function Test-ScriptCompliance {
    param([string]$ScriptPath)
    
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath,
        [ref]$null,
        [ref]$errors
    ) | Out-Null
    
    return $errors.Count -eq 0
}

$localBranch = git rev-parse --abbrev-ref HEAD 2>$null

if ($localBranch -eq 'main' -or $localBranch -eq 'develop') {
    Write-Host "Cannot push directly to protected branch: $localBranch" -ForegroundColor Red
    exit 1
}

$changedScripts = @(git diff origin/develop...HEAD --name-only --diff-filter=ACM 2>$null | Where-Object { $_ -like '*.ps1' })

if ($changedScripts.Count -eq 0) {
    exit 0
}

$hasIssues = $false

foreach ($script in $changedScripts) {
    $fullPath = Join-Path $repoRoot $script
    
    if (-not (Test-Path $fullPath)) {
        continue
    }
    
    if (-not (Test-ScriptCompliance -ScriptPath $fullPath)) {
        if (-not $hasIssues) {
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Red
            Write-Host "Script Compliance Check Failed" -ForegroundColor Red
            Write-Host "========================================================" -ForegroundColor Red
            Write-Host ""
            $hasIssues = $true
        }
        
        Write-Host "ERROR: $script has syntax errors" -ForegroundColor Red
    } elseif ($Verbose) {
        Write-Host "OK: $script" -ForegroundColor Green
    }
}

if ($hasIssues) {
    Write-Host ""
    Write-Host "Please fix the syntax errors before pushing." -ForegroundColor Red
    Write-Host ""
    Write-Host "Run: .\scripts\utilities\audit-script-normalization.ps1 -Report" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

exit 0