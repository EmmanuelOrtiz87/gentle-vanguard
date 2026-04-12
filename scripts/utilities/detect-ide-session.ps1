param(
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

function Get-ParentProcessNames {
    $names = @()
    try {
        $pidCursor = $PID
        for ($i = 0; $i -lt 3; $i++) {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$pidCursor"
            if (-not $proc) { break }
            $parentId = $proc.ParentProcessId
            if (-not $parentId) { break }
            $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$parentId"
            if (-not $parent) { break }
            $names += $parent.Name
            $pidCursor = $parentId
        }
    } catch {
        Write-Verbose "Unable to resolve full parent process tree"
    }
    return $names
}

function Get-ActivationCommand {
    $onDemandScript = Join-Path $repoRoot 'scripts\utilities\stack-on-demand.ps1'
    $legacyActivateScript = Join-Path $repoRoot 'scripts\activate-project-orchestrator.ps1'
    $wfScript = Join-Path $repoRoot 'scripts\utilities\wf.ps1'

    if (Test-Path $onDemandScript) {
        return '.\\scripts\\utilities\\stack-on-demand.ps1 -Action activate'
    }

    if (Test-Path $legacyActivateScript) {
        return '.\\scripts\\activate-project-orchestrator.ps1'
    }

    if (Test-Path $wfScript) {
        return '.\\scripts\\utilities\\wf.ps1 health'
    }

    return 'powershell -NoProfile -ExecutionPolicy Bypass -File <repo>/scripts/utilities/wf.ps1 health'
}

$parentNames = Get-ParentProcessNames
$termProgram = $env:TERM_PROGRAM

$ideName = 'terminal'
$source = 'none'
$confidence = 'low'

if ($env:VSCODE_GIT_IPC_HANDLE -or $termProgram -eq 'vscode' -or ($parentNames -match 'Code.exe|Code - Insiders.exe')) {
    $ideName = 'vscode'
    $source = 'env/process'
    $confidence = 'high'
} elseif ($env:JETBRAINS_IDE -or $env:IDEA_INITIAL_DIRECTORY -or ($parentNames -match 'idea64.exe|pycharm64.exe|webstorm64.exe|rider64.exe')) {
    $ideName = 'jetbrains'
    $source = 'env/process'
    $confidence = 'medium'
} elseif ($parentNames -match 'devenv.exe') {
    $ideName = 'visual-studio'
    $source = 'process'
    $confidence = 'medium'
} elseif ($termProgram) {
    $ideName = "terminal-$termProgram"
    $source = 'env'
    $confidence = 'low'
}

$isIdeSession = @('vscode', 'jetbrains', 'visual-studio') -contains $ideName
$activationCommand = Get-ActivationCommand
$startSessionCommand = '.\\scripts\\utilities\\wf.ps1 start-session'

$result = [pscustomobject]@{
    ideName = $ideName
    isIdeSession = $isIdeSession
    source = $source
    confidence = $confidence
    parentProcesses = $parentNames
    recommendedActivationCommand = $activationCommand
    recommendedSessionCommand = $startSessionCommand
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
    exit 0
}

if (-not $Quiet) {
    Write-Host "IDE detection: $($result.ideName) (confidence=$($result.confidence))" -ForegroundColor Cyan
    if (-not $result.isIdeSession) {
        Write-Host "No known IDE session detected. Recommended activation:" -ForegroundColor Yellow
        Write-Host "  $($result.recommendedActivationCommand)" -ForegroundColor White
    }
}

$result
