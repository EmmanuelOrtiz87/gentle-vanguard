param(
    [string]$ConfigPath = $(Join-Path $PSScriptRoot '..\config\workspace.config.json'),
    [string]$ExamplePath = $(Join-Path $PSScriptRoot '..\config\workspace.portable.example.json'),
    [switch]$RunToolInstallers,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-PreferredPowerShellRunner {
    $runner = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($runner) { return $runner.Source }

    $runner = Get-Command powershell -ErrorAction SilentlyContinue
    if ($runner) { return $runner.Source }

    return $null
}

$cleanRuntime = Join-Path $PSScriptRoot 'clean-runtime.ps1'
if (Test-Path -LiteralPath $cleanRuntime) {
    $runnerPath = Get-PreferredPowerShellRunner
    if ($runnerPath) {
        & $runnerPath -NoProfile -ExecutionPolicy Bypass -File $cleanRuntime
    }
}

$configDir = Split-Path -Parent $ConfigPath
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if ((Test-Path $ConfigPath) -and -not $Force) {
    Write-Host "Config already exists: $ConfigPath"
} else {
    Copy-Item -Path $ExamplePath -Destination $ConfigPath -Force
    Write-Host "Created config from portable example: $ConfigPath"
}

$bootstrap = Join-Path $PSScriptRoot 'bootstrap-workspace.ps1'

$bootstrapArgs = @(
    '-ConfigPath', $ConfigPath
)

if ($RunToolInstallers) {
    $bootstrapArgs += '-RunToolInstallers'
}

$runnerPath = Get-PreferredPowerShellRunner
if ($runnerPath) {
    & $runnerPath -NoProfile -ExecutionPolicy Bypass -File $bootstrap @bootstrapArgs
} else {
    & $bootstrap @bootstrapArgs
}

# Start Session Audit
$auditScript = Join-Path $PSScriptRoot 'generate-session-audit.ps1'
if (Test-Path $auditScript) {
    try {
        & $auditScript -Start
    } catch {
        Write-Warning "Could not start audit session: $_"
    }
}
