param(
    [ValidateSet('status', 'route', 'gate')]
    [string]$Mode = 'status',
    [ValidateSet('ai', 'heavy-ai', 'network', 'local', 'metrics', 'any')]
    [string]$TaskType = 'any',
    [switch]$Strict,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$configPath = Join-Path $repoRoot 'config\orchestrator.json'
$tokenGuardScript = Join-Path $scriptDir '..\TELEMETRY-METRICS\token-budget-guard.ps1'
$runEngramScript = Join-Path $scriptDir 'run-engram.ps1'
$rateLimitStatePath = Join-Path $repoRoot '.event-bus\rate-limit-state.json'

function Write-InfoLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[INFO] $Message" -ForegroundColor Gray
    }
}

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

function Test-Network {
    $targets = @('1.1.1.1', 'github.com')
    foreach ($target in $targets) {
        try {
            $ok = Test-Connection -TargetName $target -Count 1 -Quiet -ErrorAction Stop
            if ($ok) { return $true }
        } catch {
            continue
        }
    }

    return $false
}

function Get-AICapability {
    $hasEnvProvider = $false
    foreach ($name in @('OPENAI_API_KEY', 'ANTHROPIC_API_KEY', 'AZURE_OPENAI_API_KEY', 'GITHUB_TOKEN', 'GEMINI_API_KEY')) {
        if (-not [string]::IsNullOrWhiteSpace([string](Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue).Value)) {
            $hasEnvProvider = $true
            break
        }
    }

    $opencodeCmd = Get-Command opencode -ErrorAction SilentlyContinue
    $hasOpencode = [bool]$opencodeCmd

    return @{
        has_env_provider = $hasEnvProvider
        has_opencode = $hasOpencode
        available = ($hasEnvProvider -or $hasOpencode)
    }
}

function Get-RateLimitLoad {
    if (-not (Test-Path $rateLimitStatePath)) {
        return @{ pct = 0; near_limit = $false; at_limit = $false; window_key = '' }
    }
    try {
        $state = Get-Content -Path $rateLimitStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $windowKey = [string]$state.window_key
        $count = [int]$state.count
        $limit = if ([int]$state.limit -gt 0) { [int]$state.limit } else { 60 }
        $pct = [math]::Round(($count / $limit) * 100, 1)
        return @{
            pct        = $pct
            near_limit = ($pct -ge 75)
            at_limit   = ($pct -ge 100)
            window_key = $windowKey
            count      = $count
            limit      = $limit
        }
    } catch {
        return @{ pct = 0; near_limit = $false; at_limit = $false; window_key = '' }
    }
}

function Invoke-Gate {
    param(
        [string]$RuntimeMode,
        [string]$TokenStatus,
        [string]$GateReason,
        [string]$Task,
        [hashtable]$RateLimit
    )

    # Task categories: local/metrics always pass; network/ai/heavy-ai depend on mode
    $alwaysLocal = @('local', 'metrics', 'any')

    if ($Task -in $alwaysLocal) {
        $decision = 'allowed'
        $gateNote  = 'Local/metrics tasks always allowed.'
    } elseif ($RuntimeMode -eq 'ai_orchestrated') {
        $decision = 'allowed'
        $gateNote  = 'Full runtime available.'
    } elseif ($RuntimeMode -eq 'offline_deterministic') {
        if ($Task -in @('network', 'ai', 'heavy-ai')) {
            $decision = 'blocked'
            $gateNote  = "Offline mode: $GateReason. Network/AI tasks blocked."
        } else {
            $decision = 'allowed'
            $gateNote  = 'Offline mode: local-only tasks allowed.'
        }
    } elseif ($RuntimeMode -eq 'hybrid_guarded') {
        if ($TokenStatus -eq 'HARD_LIMIT') {
            if ($Task -in @('ai', 'heavy-ai')) {
                $decision = 'blocked'
                $gateNote  = 'Token HARD_LIMIT: AI tasks blocked.'
            } else {
                $decision = 'warned'
                $gateNote  = 'Token HARD_LIMIT: proceed with caution, prefer local scripts.'
            }
        } elseif ($TokenStatus -eq 'SOFT_LIMIT') {
            if ($Task -eq 'heavy-ai') {
                $decision = 'blocked'
                $gateNote  = 'Token SOFT_LIMIT: heavy-AI tasks blocked.'
            } elseif ($Task -eq 'ai') {
                $decision = 'warned'
                $gateNote  = 'Token SOFT_LIMIT: AI tasks allowed but monitor usage.'
            } else {
                $decision = 'allowed'
                $gateNote  = 'Token SOFT_LIMIT: non-AI tasks allowed.'
            }
        } else {
            # engram missing or other hybrid reason
            $decision = 'warned'
            $gateNote  = "Hybrid guarded ($GateReason): continuity risk, proceed carefully."
        }
    } else {
        $decision = 'allowed'
        $gateNote  = 'Unknown mode: defaulting to allowed.'
    }

    # Rate-limit overlay: if event bus near capacity, add advisory
    $rlNote = ''
    if ($RateLimit.near_limit -and $decision -eq 'allowed') {
        $decision = 'warned'
        $rlNote = " Event-bus rate limit at $($RateLimit.pct)% ($($RateLimit.count)/$($RateLimit.limit))."
    } elseif ($RateLimit.at_limit) {
        if ($decision -ne 'blocked') { $decision = 'warned' }
        $rlNote = " Event-bus rate limit FULL - new events will be rejected."
    }

    # Exit code mapping
    $exitCode = switch ($decision) {
        'allowed' { 0 }
        'warned'  { 1 }
        'blocked' { 2 }
        default   { 0 }
    }

    return @{
        decision   = $decision
        exit_code  = $exitCode
        note       = ($gateNote + $rlNote).Trim()
        task_type  = $Task
        runtime_mode = $RuntimeMode
        token_status = $TokenStatus
        rate_limit_pct = $RateLimit.pct
    }
}

function Get-TokenStatus {
    if (-not (Test-Path $tokenGuardScript)) {
        return @{
            status = 'UNKNOWN'
            projected_pct = 0
        }
    }

    try {
        $json = & $tokenGuardScript -Mode status -Task general -AsJson -Quiet
        if ($json) {
            $data = $json | ConvertFrom-Json
            return @{
                status = [string]$data.status
                projected_pct = [double]$data.projected_pct
            }
        }
    } catch {
        return @{
            status = 'UNKNOWN'
            projected_pct = 0
        }
    }

    return @{
        status = 'UNKNOWN'
        projected_pct = 0
    }
}

$config = $null
if (Test-Path $configPath) {
    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$networkAvailable = Test-Network
$aiCapability = Get-AICapability
$token = Get-TokenStatus
$engramPath = Resolve-EngramCommand
$engramAvailable = [bool]$engramPath
$rateLimit = Get-RateLimitLoad

$runtimeMode = 'ai_orchestrated'
$reason = 'AI and network capabilities available'
$delegationStrategy = 'orchestrator->subagents+skills'

if (-not $networkAvailable) {
    $runtimeMode = 'offline_deterministic'
    $reason = 'Network unavailable'
    $delegationStrategy = 'orchestrator->local scripts only'
} elseif (-not $aiCapability.available) {
    $runtimeMode = 'offline_deterministic'
    $reason = 'No AI provider/tool detected'
    $delegationStrategy = 'orchestrator->local scripts only'
} elseif ($token.status -eq 'HARD_LIMIT') {
    $runtimeMode = 'hybrid_guarded'
    $reason = 'Token hard limit reached'
    $delegationStrategy = 'orchestrator->minimal AI + deterministic scripts'
} elseif ($token.status -eq 'SOFT_LIMIT') {
    $runtimeMode = 'hybrid_guarded'
    $reason = 'Token soft limit reached'
    $delegationStrategy = 'orchestrator->compact AI + script fallback'
} elseif (-not $engramAvailable) {
    $runtimeMode = 'hybrid_guarded'
    $reason = 'Engram unavailable; continuity risk'
    $delegationStrategy = 'orchestrator->AI with mandatory continuity fallback'
}

$actions = @()
if ($runtimeMode -eq 'offline_deterministic') {
    $actions += '.\\scripts\\utilities\\wf.ps1 status'
    $actions += '.\\scripts\\utilities\\wf.ps1 context-pack "<objective>"'
    $actions += '.\\scripts\\utilities\\wf.ps1 end-session "<task>" -SkipReview -SkipTests -Force'
    if (Test-Path $runEngramScript) {
        $actions += '.\\scripts\\utilities\\run-engram.ps1 --help'
    }
} elseif ($runtimeMode -eq 'hybrid_guarded') {
    $actions += '.\\scripts\\utilities\\wf.ps1 response-mode simple'
    $actions += '.\\scripts\\utilities\\wf.ps1 response-mode ultra'
    $actions += '.\\scripts\\utilities\\wf.ps1 compact-start "<objective>"'
    $actions += '.\\scripts\\utilities\\wf.ps1 token-guard'
    if (-not $engramAvailable) {
        $actions += '.\\scripts\\utilities\\wf.ps1 install-engram'
    }
} else {
    $actions += '.\\scripts\\utilities\\orchestrator-next-steps.ps1'
    $actions += '.\\scripts\\utilities\\wf.ps1 stack-dashboard'
}

# --- GATE MODE ----------------------------------------------------------------
if ($Mode -eq 'gate') {
    $gateResult = Invoke-Gate -RuntimeMode $runtimeMode -TokenStatus $token.status `
        -GateReason $reason -Task $TaskType -RateLimit $rateLimit

    if ($AsJson) {
        $gateResult | ConvertTo-Json -Depth 3
    } else {
        $color = switch ($gateResult.decision) {
            'allowed' { 'Green'  }
            'warned'  { 'Yellow' }
            'blocked' { 'Red'    }
            default   { 'White'  }
        }
        Write-Host "[GATE] $($gateResult.decision.ToUpper())" -ForegroundColor $color -NoNewline
        Write-Host " - task: $($gateResult.task_type) | mode: $($gateResult.runtime_mode) | token: $($gateResult.token_status) | event-bus: $($gateResult.rate_limit_pct)%"
        Write-Host "       $($gateResult.note)" -ForegroundColor $color
    }
    exit $gateResult.exit_code
}
# -----------------------------------------------------------------------------

    $result = [ordered]@{
        runtime_mode = $runtimeMode
        reason = $reason
        delegation_strategy = $delegationStrategy
        network_available = $networkAvailable
        ai_available = [bool]$aiCapability.available
        ai_env_provider = [bool]$aiCapability.has_env_provider
        ai_tool_available = [bool]$aiCapability.has_opencode
        engram_available = $engramAvailable
        engram_path = if ($engramPath) { $engramPath } else { '' }
        token_status = $token.status
        token_projected_pct = $token.projected_pct
        rate_limit_pct = $rateLimit.pct
        rate_limit_near = $rateLimit.near_limit
        recommended_next_actions = $actions
    }

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host 'Runtime Router' -ForegroundColor Cyan
    Write-Host "Mode: $($result.runtime_mode)" -ForegroundColor Cyan
    Write-Host "Reason: $($result.reason)" -ForegroundColor Cyan
    Write-Host "Delegation: $($result.delegation_strategy)" -ForegroundColor Cyan
    Write-Host "Network: $($result.network_available) | AI: $($result.ai_available) | Engram: $($result.engram_available)" -ForegroundColor White
    Write-Host "Token status: $($result.token_status) ($($result.token_projected_pct)%) | Event-bus: $($result.rate_limit_pct)%" -ForegroundColor White
    Write-Host 'Recommended next actions:' -ForegroundColor Yellow
    foreach ($action in $actions) {
        Write-Host "  - $action" -ForegroundColor Yellow
    }
}

if ($Strict -and $runtimeMode -eq 'offline_deterministic' -and -not $engramAvailable) {
    exit 2
}

exit 0
