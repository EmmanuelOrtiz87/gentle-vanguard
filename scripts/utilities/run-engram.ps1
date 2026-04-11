param(
    [string]$ConfigPath,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$EngramArgs
)

$ErrorActionPreference = 'Stop'

function Resolve-ConfigText {
    param(
        [string]$Text,
        [hashtable]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    $resolved = $Text
    foreach ($key in $Context.Keys) {
        $resolved = $resolved.Replace("{$key}", [string]$Context[$key])
    }

    return $resolved
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$defaultDataRoot = Join-Path $workspaceRoot '.engram-data'

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $workspaceRoot 'config\workspace.config.json'
}

# Initialization validation
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Environment not initialized or config missing. Run 'scripts/bootstrap.ps1' first."
}

# Health check for critical dependencies
$skillsDir = Join-Path $workspaceRoot "tools/Gentleman-Skills"
if (-not (Test-Path $skillsDir)) {
    Write-Warning "Gentleman-Skills not detected. Some AI capabilities may not be available."
}

$config = $null
if (Test-Path -LiteralPath $ConfigPath) {
    $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$configContext = @{
    workspaceRoot = $workspaceRoot
    dataRoot = $defaultDataRoot
    toolsRoot = $(Join-Path $workspaceRoot 'tools')
    projectsRoot = $(Join-Path $workspaceRoot 'projects')
}

$dataRoot = if ($config -and $config.dataRoot) {
    Resolve-ConfigText -Text $config.dataRoot -Context $configContext
} else {
    $defaultDataRoot
}

$engramDataDir = Join-Path $dataRoot 'engram-session'
Ensure-Directory -Path $engramDataDir

# Engram state stays outside any repository checkout.
$env:ENGRAM_DATA_DIR = $engramDataDir
Write-Host "[OK] Engram Session Data: $env:ENGRAM_DATA_DIR" -ForegroundColor Cyan

function Resolve-EngramCommand {
    if ($env:ENGRAM_CMD) {
        return $env:ENGRAM_CMD
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) { return $engramCmd.Source }

    $pathsToCheck = @()
    if ($env:GOBIN) { $pathsToCheck += Join-Path $env:GOBIN 'engram.exe'; $pathsToCheck += Join-Path $env:GOBIN 'engram' }
    if ($env:GOPATH) { $pathsToCheck += Join-Path $env:GOPATH 'bin\engram.exe'; $pathsToCheck += Join-Path $env:GOPATH 'bin\engram' }
    if ($env:USERPROFILE) { $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram.exe'; $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram' }
    if ($env:HOME) { $pathsToCheck += Join-Path $env:HOME 'go/bin/engram' }

    foreach ($path in $pathsToCheck) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

$engramPath = Resolve-EngramCommand
if (-not $engramPath) {
    $installScript = Join-Path $PSScriptRoot 'install-engram.ps1'
    if (Test-Path $installScript) {
        Write-Host "Engram CLI not found in PATH. Attempting install..." -ForegroundColor Yellow
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript
        $engramPath = Resolve-EngramCommand
    }
}

if (-not $engramPath) {
    throw "engram not found. Install the tool or add it to PATH before using this launcher."
}

& "$engramPath" @EngramArgs
exit $LASTEXITCODE
