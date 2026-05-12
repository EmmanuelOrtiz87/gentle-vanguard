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

# FF-015: load hook output safety filter
$_safetyModule = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safetyModule) { . $_safetyModule }

function Write-HookInfo {
    param([string]$Msg)
    if (Get-Command 'Write-SafeHook' -ErrorAction SilentlyContinue) {
        Write-SafeHook $Msg -Color Cyan
    } else {
        Write-Host $Msg -ForegroundColor Cyan
    }
}

function Write-HookError {
    param([string]$Msg)
    if (Get-Command 'Write-SafeHook' -ErrorAction SilentlyContinue) {
        Write-SafeHook $Msg -Color Red
    } else {
        Write-Host $Msg -ForegroundColor Red
    }
}

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
    Write-HookError "Cannot push directly to protected branch: $localBranch"
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
            Write-Host ''
            Write-HookError '========================================================'
            Write-HookError 'Script Compliance Check Failed'
            Write-HookError '========================================================'
            Write-Host ''
            $hasIssues = $true
        }
        
        Write-HookError "ERROR: $script has syntax errors"
    } elseif ($Verbose) {
        Write-HookInfo "OK: $script"
    }
}

if ($hasIssues) {
    Write-Host ''
    Write-HookError 'Please fix the syntax errors before pushing.'
    Write-Host ''
    Write-HookInfo 'Run: .\scripts\utilities\audit-script-normalization.ps1 -Report'
    Write-Host ''
    exit 1
}

exit 0