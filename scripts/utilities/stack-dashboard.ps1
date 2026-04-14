param(
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$configPath = Join-Path $repoRoot 'config\orchestrator.json'
$activationFile = Join-Path $repoRoot '.orchestrator-active'
$tokenGuardScript = Join-Path $scriptDir 'token-budget-guard.ps1'

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

$config = $null
if (Test-Path $configPath) {
    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$orchestratorActive = [bool](Test-Path $activationFile)
$workflowMode = if ($config -and $config.PSObject.Properties.Name -contains 'workflow_mode') { [string]$config.workflow_mode } else { 'unknown' }
$responseMode = if ($config -and $config.PSObject.Properties.Name -contains 'communication_response_mode') { [string]$config.communication_response_mode } else { 'unknown' }
$compression = if ($config -and $config.PSObject.Properties.Name -contains 'response_profiles' -and $config.response_profiles -and $config.response_profiles.active) { [string]$config.response_profiles.active } else { 'unknown' }

$engramPath = Resolve-EngramCommand
$engramAvailable = [bool]$engramPath

$tokenData = $null
if (Test-Path $tokenGuardScript) {
    try {
        $json = & $tokenGuardScript -Mode status -Task general -AsJson -Quiet
        if ($json) {
            $tokenData = $json | ConvertFrom-Json
        }
    } catch {
        $tokenData = $null
    }
}

$tokenStatus = if ($tokenData) { [string]$tokenData.status } else { 'UNKNOWN' }
$projectedPct = if ($tokenData) { [double]$tokenData.projected_pct } else { 0 }

$riskLevel = 'low'
if (-not $orchestratorActive -or -not $engramAvailable -or $tokenStatus -eq 'HARD_LIMIT' -or $tokenStatus -eq 'ENGRAM_MISSING') {
    $riskLevel = 'high'
} elseif ($tokenStatus -eq 'SOFT_LIMIT' -or $projectedPct -ge 70) {
    $riskLevel = 'medium'
}

$recommendation = @()
if (-not $engramAvailable) {
    $recommendation += '.\\scripts\\utilities\\wf.ps1 install-engram'
    $recommendation += '.\\scripts\\utilities\\run-engram.ps1 --help'
} elseif ($tokenStatus -eq 'HARD_LIMIT') {
    $recommendation += '.\\scripts\\utilities\\wf.ps1 response-mode simple'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 response-mode ultra'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 context-pack "<objective>"'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 end-session "<task>" -SkipReview -SkipTests -Force'
} elseif ($tokenStatus -eq 'SOFT_LIMIT') {
    $recommendation += '.\\scripts\\utilities\\wf.ps1 compact-start "<objective>"'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 context-pack "<objective>"'
} else {
    $recommendation += '.\\scripts\\utilities\\orchestrator-next-steps.ps1'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 token-guard'
}

$result = [ordered]@{
    orchestrator_active = $orchestratorActive
    workflow_mode = $workflowMode
    response_mode = $responseMode
    compression = $compression
    engram_available = $engramAvailable
    engram_path = if ($engramPath) { $engramPath } else { '' }
    token_guard_status = $tokenStatus
    token_projected_pct = $projectedPct
    risk_level = $riskLevel
    recommended_next_actions = $recommendation
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "`n=== Stack Dashboard ===" -ForegroundColor Cyan
Write-Host "Orchestrator active: $($result.orchestrator_active) | Workflow: $($result.workflow_mode)" -ForegroundColor White
Write-Host "Response mode: $($result.response_mode) | Compression: $($result.compression)" -ForegroundColor White
Write-Host "Engram available: $($result.engram_available)" -ForegroundColor White
Write-Host "Token guard: $($result.token_guard_status) | Projected: $($result.token_projected_pct)%" -ForegroundColor White

if ($riskLevel -eq 'high') {
    Write-Host "Risk level: HIGH" -ForegroundColor Red
} elseif ($riskLevel -eq 'medium') {
    Write-Host "Risk level: MEDIUM" -ForegroundColor Yellow
} else {
    Write-Host "Risk level: LOW" -ForegroundColor Green
}

Write-Host "Recommended next actions:" -ForegroundColor Cyan
foreach ($action in $recommendation) {
    Write-Host "  - $action" -ForegroundColor Yellow
}

exit 0
