param(
    [string]$ConfigPath = $(Join-Path $PSScriptRoot '..\config\workspace.config.json'),
    [Parameter(ValueFromRemainingArguments = $true)]
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

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$defaultDataRoot = Join-Path $workspaceRoot '.engram-data'

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

$engramCmd = Get-Command engram -ErrorAction SilentlyContinue
if (-not $engramCmd) {
    throw "engram not found in PATH. Install the tool or add it to PATH before using this launcher."
}

& engram @EngramArgs
exit $LASTEXITCODE
