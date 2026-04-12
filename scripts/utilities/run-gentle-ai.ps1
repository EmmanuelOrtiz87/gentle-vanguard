param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Resolve-NativeGentleAI {
    $cmd = Get-Command gentle-ai -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -ne $MyInvocation.MyCommand.Path) {
        return $cmd.Source
    }
    return $null
}

function Show-Help {
    Write-Host "Gentle-AI compatibility launcher" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  .\scripts\utilities\run-gentle-ai.ps1 status" -ForegroundColor White
    Write-Host "  .\scripts\utilities\run-gentle-ai.ps1 update" -ForegroundColor White
    Write-Host "  .\scripts\utilities\run-gentle-ai.ps1 help" -ForegroundColor White
    Write-Host ""
    Write-Host "Behavior:" -ForegroundColor White
    Write-Host "  1. Uses native 'gentle-ai' command if available." -ForegroundColor White
    Write-Host "  2. Otherwise uses compatibility mode with local workflow tools." -ForegroundColor White
}

function Show-Status {
    $checks = @(
        @{ Name = "engram"; Desc = "Memory system" },
        @{ Name = "gga"; Desc = "Code review engine" },
        @{ Name = "gentle-ai"; Desc = "Native CLI (optional)" }
    )

    foreach ($check in $checks) {
        $cmd = Get-Command $check.Name -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Host "[OK] $($check.Name) - $($check.Desc)" -ForegroundColor Green
        } else {
            Write-Host "[WARN] $($check.Name) missing - $($check.Desc)" -ForegroundColor Yellow
        }
    }

    Write-Info "Compatibility mode active via run-gentle-ai.ps1"
}

function Invoke-Update {
    $updateScript = Join-Path $repoRoot "scripts\validation\update-all.ps1"
    if (-not (Test-Path $updateScript)) {
        Write-Warn "Update script not found: $updateScript"
        return 1
    }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateScript -Tools
    return $LASTEXITCODE
}

$native = Resolve-NativeGentleAI
if ($native) {
    & $native @Args
    exit $LASTEXITCODE
}

$command = if ($Args.Count -gt 0) { $Args[0].ToLowerInvariant() } else { "status" }

switch ($command) {
    "help" { Show-Help; exit 0 }
    "--help" { Show-Help; exit 0 }
    "-h" { Show-Help; exit 0 }
    "status" { Show-Status; exit 0 }
    "update" { exit (Invoke-Update) }
    default {
        Write-Warn "Native 'gentle-ai' command is not installed. Executing compatibility status instead."
        Show-Status
        exit 0
    }
}