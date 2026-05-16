# auto-delegation-wrapper.ps1
# Canonical wrapper for routing and delegating tasks to the agent-router

param(
    [Parameter(Position=0)]
    [string]$TaskDescription,

    [string]$Agent,

    [ValidateSet('run', 'plan', 'validate', 'status')]
    [string]$Action = 'run',

    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
if ($env:GV_BASE_DIR) {
    $repoRoot = $env:GV_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
$scriptDir = $PSScriptRoot
$agentRouter = Join-Path $scriptDir 'AI-AGENT-MANAGEMENT\agent-router.ps1'

function Write-WrapperLine {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-RoutingConfig {
    $autoDelegationPath = Join-Path $repoRoot 'config\auto-delegation.json'
    if (Test-Path $autoDelegationPath) {
        $ad = Get-Content $autoDelegationPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return @{ keywordMappings = $ad.keywordMappings; Enabled = $true }
    }
    return @{ keywordMappings = @{}; Enabled = $false }
}

function Route-TaskToAgent {
    param([Parameter(Mandatory = $true)][string]$TaskText)

    $config = Get-RoutingConfig
    $taskLower = $TaskText.ToLowerInvariant()
    $matches = @{}

    foreach ($agentKey in $config.keywordMappings.Keys) {
        $count = 0
        foreach ($keyword in $config.keywordMappings[$agentKey]) {
            if ($taskLower.Contains($keyword.ToLowerInvariant())) {
                $count++
            }
        }

        if ($count -gt 0) {
            $matches[$agentKey] = $count
        }
    }

    if ($matches.Count -eq 0) {
        return @{
            status = 'no-match'
            requires_manual_decision = $true
            suggestion = 'Provide a more specific task description'
            all_matches = @{}
        }
    }

    $topAgent = $matches.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    return @{
        status = 'routed'
        primary_agent = [string]$topAgent.Name
        confidence = [math]::Min(80, 50 + ([int]$topAgent.Value * 10))
        all_matches = $matches
        requires_manual_decision = $false
    }
}

function Invoke-CanonicalDelegation {
    param(
        [Parameter(Mandatory = $true)][string]$AgentName,
        [Parameter(Mandatory = $true)][string]$TaskText,
        [Parameter(Mandatory = $true)][string]$ActionType
    )

    if (-not (Test-Path $agentRouter)) {
        throw "agent-router.ps1 not found at $agentRouter"
    }

    $routerOutput = & $agentRouter -Agent $AgentName -Task $TaskText -Action $ActionType -AsJson
    if (-not $routerOutput) {
        throw 'agent-router returned no output'
    }

    return $routerOutput | ConvertFrom-Json
}

function Build-WrapperResult {
    param(
        [string]$TaskText,
        [string]$ResolvedAgent,
        [string]$ActionType,
        [object]$Routing,
        [object]$Delegation
    )

    return [ordered]@{
        status = if ($Delegation -and $Delegation.status) { $Delegation.status } elseif ($Routing -and $Routing.status) { $Routing.status } else { 'unknown' }
        task = $TaskText
        action = $ActionType
        resolved_agent = $ResolvedAgent
        token_estimate = if ($Delegation -and $Delegation.token_estimate) { $Delegation.token_estimate } else { $null }
        routing = $Routing
        delegation = $Delegation
        delegated_via = 'agent-router'
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    }
}

if ([string]::IsNullOrWhiteSpace($TaskDescription)) {
    if ($AsJson) {
        @{ error = 'task description required'; example = '.\scripts\utilities\auto-delegation-wrapper.ps1 "implement login flow"' } | ConvertTo-Json -Depth 6
    } else {
        Write-WrapperLine 'Usage: .\scripts\utilities\auto-delegation-wrapper.ps1 [TASK] [-Agent BA|SAD|DEV|QA|OPS|GOV|DOC] [-Action run|plan|validate|status] [-AsJson]' 'Yellow'
    }
    exit 1
}

$routing = $null
$resolvedAgent = $Agent

if ([string]::IsNullOrWhiteSpace($resolvedAgent)) {
    $routing = Route-TaskToAgent -TaskText $TaskDescription
    if ($routing.requires_manual_decision) {
        if ($AsJson) {
            $routing | ConvertTo-Json -Depth 6
        } else {
            Write-WrapperLine "No routing match for task: $TaskDescription" 'Yellow'
            Write-WrapperLine $routing.suggestion 'Gray'
        }
        exit 0
    }

    $resolvedAgent = $routing.primary_agent
}

$delegation = Invoke-CanonicalDelegation -AgentName $resolvedAgent -TaskText $TaskDescription -ActionType $Action
$result = Build-WrapperResult -TaskText $TaskDescription -ResolvedAgent $resolvedAgent -ActionType $Action -Routing $routing -Delegation $delegation

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-WrapperLine "Delegated task to AGENT-$resolvedAgent via agent-router" 'Cyan'
    Write-WrapperLine "Task: $TaskDescription" 'Gray'
    if ($routing -and $routing.confidence) {
        Write-WrapperLine "Routing confidence: $($routing.confidence)" 'Gray'
    }
    Write-WrapperLine "Status: $($result.status)" 'Green'
}
