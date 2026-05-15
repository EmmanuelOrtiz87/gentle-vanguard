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

function Resolve-WorkspacePath {
    param(
        [string]$Path,
        [string]$WorkspaceRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $Path))
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

if ($env:FOUNDATION_BASE_DIR) {
    $workspaceRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $workspaceRoot = $searchDir
}
$defaultDataRoot = Join-Path $workspaceRoot '.engram-data'
$engramSafeScript = Join-Path $workspaceRoot 'scripts\utilities\engram-safe.ps1'
if (Test-Path $engramSafeScript) {
    . $engramSafeScript
}

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $workspaceRoot 'config\workspace.config.json'
}

# Initialization validation
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Environment not initialized or config missing. Run 'scripts/foundation/bootstrap.ps1' first."
}

# Health check for critical dependencies
$skillsDir = Join-Path $workspaceRoot "skills"
if (-not (Test-Path $skillsDir)) {
    Write-Warning "Skills directory not detected. Some AI capabilities may not be available."
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

$dataRoot = Resolve-WorkspacePath -Path $dataRoot -WorkspaceRoot $workspaceRoot

$engramDataDir = $dataRoot
Ensure-Directory -Path $engramDataDir

# Engram state uses the configured workspace data root.
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
        & $installScript
        $engramPath = Resolve-EngramCommand
    }
}

$engramFallback = Join-Path $engramDataDir 'fallback-memory.json'

function Write-ContinuityLog {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    $logEntry = @{
        timestamp = $timestamp
        level = $Level
        message = $Message
        session = $env:WFS_SESSION_ID
    }
    $logFile = Join-Path $engramDataDir 'continuity-log.jsonl'
    $logEntry | ConvertTo-Json -Compress | Out-File -FilePath $logFile -Append -Encoding UTF8
    
    $color = switch ($Level) {
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Gray' }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Save-ToFallback {
    param(
        [string]$Operation,
        [hashtable]$Data
    )
    
    if (-not (Test-Path $engramFallback)) {
        @{} | ConvertTo-Json | Out-File -FilePath $engramFallback -Encoding UTF8
    }
    
    try {
        $fallback = Get-Content $engramFallback -Raw | ConvertFrom-Json
        if (-not $fallback.sessions) {
            $fallback | Add-Member -NotePropertyName 'sessions' -NotePropertyValue @{}
        }
        
        $sessionId = $env:WFS_SESSION_ID
        if ([string]::IsNullOrWhiteSpace($sessionId)) {
            $sessionId = 'unknown-session'
        }
        
        if (-not $fallback.sessions.$sessionId) {
            $fallback.sessions | Add-Member -NotePropertyName $sessionId -NotePropertyValue @{}
        }
        
        $fallback.sessions.$sessionId | Add-Member -NotePropertyName $Operation -NotePropertyValue $Data -Force
        $fallback | ConvertTo-Json -Depth 10 | Out-File -FilePath $engramFallback -Encoding UTF8
        Write-ContinuityLog -Message "Persisted '$Operation' to fallback memory" -Level 'INFO'
    } catch {
        Write-ContinuityLog -Message "Failed to save fallback memory: $_" -Level 'ERROR'
    }
}

if (-not $engramPath) {
    Write-ContinuityLog -Message 'Engram CLI not available. Operating in offline continuity mode.' -Level 'WARN'
    Write-Host '[INFO] All session data will be stored locally in .engram-data/ for later sync.' -ForegroundColor Cyan
    
    if ($EngramArgs -and $EngramArgs.Count -gt 0) {
        Save-ToFallback -Operation 'pending-sync' -Data @{ args = $EngramArgs; timestamp = Get-Date }
    }
    
    exit 0
}

try {
    if (Get-Command Invoke-FoundationEngram -ErrorAction SilentlyContinue) {
        $result = Invoke-FoundationEngram -RepoRoot $workspaceRoot -Arguments $EngramArgs
        $result.Output | ForEach-Object { Write-Host $_ }
        if (-not $result.Success) {
            Write-ContinuityLog -Message "Engram exited with code $($result.ExitCode). Saving state to fallback." -Level 'WARN'
            Save-ToFallback -Operation 'last-command' -Data @{ args = $EngramArgs; exitCode = $result.ExitCode }
        }
        exit $result.ExitCode
    } else {
        & "$engramPath" @EngramArgs
        if ($LASTEXITCODE -ne 0) {
            Write-ContinuityLog -Message "Engram exited with code $LASTEXITCODE. Saving state to fallback." -Level 'WARN'
            Save-ToFallback -Operation 'last-command' -Data @{ args = $EngramArgs; exitCode = $LASTEXITCODE }
        }
    }
} catch {
    Write-ContinuityLog -Message "Engram execution failed: $_. State saved to fallback." -Level 'ERROR'
    Save-ToFallback -Operation 'error-state' -Data @{ args = $EngramArgs; error = $_.Exception.Message }
    exit 1
}

exit $LASTEXITCODE
