# run-gga.ps1
# Wrapper script to execute the 'gga' command for AI-powered code review.
# It locates the gga binary and executes it via bash if available.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path

$candidateGgaPaths = @(
    (Join-Path $workspaceRoot "tools\gentleman-guardian-angel\bin\gga"),
    (Join-Path $workspaceRoot "..\gentleman-guardian-angel\bin\gga"),
    (Join-Path $env:USERPROFILE "bin\gga")
)

$ggaBinaryPath = $null
foreach ($candidate in $candidateGgaPaths) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
        $ggaBinaryPath = $candidate
        break
    }
}

if (-not $ggaBinaryPath) {
    Write-Error "GGA binary not found. Checked: $($candidateGgaPaths -join ', ')"
    exit 1
}

$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCommand) {
    $bashExecutable = $bashCommand.Source
} else {
    $gitBashPaths = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe"
    )
    foreach ($path in $gitBashPaths) {
        if (Test-Path -LiteralPath $path) {
            $bashExecutable = $path
            break
        }
    }
    
    if (-not $bashExecutable) {
        Write-Error "bash is required to run GGA. Please ensure Git Bash is installed."
        exit 1
    }
}

Set-Location $workspaceRoot
& $bashExecutable $ggaBinaryPath @Args
exit $LASTEXITCODE
