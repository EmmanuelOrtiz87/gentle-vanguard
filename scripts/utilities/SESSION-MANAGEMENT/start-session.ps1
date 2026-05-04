param(
    [string]$TaskName,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$projectName = Split-Path $repoRoot -Leaf

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Get-ToolState {
    param([string]$Name, [string]$RelativeWrapper)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    $wrapperPath = Join-Path $repoRoot $RelativeWrapper

    if ($command) {
        return "available via PATH"
    }

    if (Test-Path $wrapperPath) {
        return "available via wrapper"
    }

    return "missing"
}

function Convert-ToSlug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return 'task'
    }

    return $slug
}

function New-SessionBriefContent {
    param(
        [string]$Branch,
        [string]$GitState,
        [string]$OrchestratorState,
        [string]$EngramState,
        [string]$State,
        [string]$CustomRulesState,
        [string]$ResponseModeState,
        [string]$ResponseModeAutoState,
        [string]$SessionFile,
        [string]$TaskFile
    )

    $taskReference = if ($TaskFile) { "- Task brief: $TaskFile" } else { "- Task brief: create with '.\scripts\utilities\wf.ps1 task-brief <name>' if needed" }

@"
# Session Start Brief

## Context

- Project: $projectName
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- Branch: $Branch
- Git state: $GitState
- Orchestrator: $OrchestratorState
- Engram: $EngramState
- : $State
- Custom rules: $CustomRulesState
- Response profile: $ResponseModeState
- Response auto-apply: $ResponseModeAutoState

## Objective

- Primary goal for this session:
- Expected outcome at handoff:

## Working Set

- Primary files or directories:
- Related documents or decisions:
- Risks or blockers known before starting:

## Acceptance Criteria

- [ ] Scope is clear and bounded
- [ ] Validation command is known before editing
- [ ] Documentation impact is identified
- [ ] Repository publication expectation is clear

## Recommended Commands

- Validate stack: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate-session-stack.ps1
- Project health: .\scripts\utilities\wf.ps1 health
- Project status: .\scripts\utilities\wf.ps1 status
$taskReference

## Notes

- Keep this brief updated if the session goal changes materially.
- Record durable decisions in ADRs or Engram, not only in chat.
"@
}

function Get-CustomRulesState {
    $rulesScript = Join-Path $PSScriptRoot 'custom-rules.ps1'
    if (-not (Test-Path $rulesScript)) {
        return 'unavailable (custom-rules script not found)'
    }

    try {
        $json = & $rulesScript -Mode status -AsJson -PassThru -Quiet
        if ([string]::IsNullOrWhiteSpace(($json | Out-String).Trim())) {
            return 'enabled but no status output'
        }

        $status = $json | ConvertFrom-Json
        return "enabled=$($status.enabled); loaded_files=$($status.totalFiles); root=$($status.root)"
    }
    catch {
        return 'failed to load custom rules status'
    }
}

function Get-ResponseModeState {
    $modeScript = Join-Path $PSScriptRoot 'response-mode.ps1'
    if (-not (Test-Path $modeScript)) {
        return 'unavailable (response-mode script not found)'
    }

    try {
        $json = & $modeScript -Mode status -AsJson -PassThru -Quiet
        if ([string]::IsNullOrWhiteSpace(($json | Out-String).Trim())) {
            return 'enabled but no status output'
        }

        $status = $json | ConvertFrom-Json
        return "active=$($status.active); allowed=$(@($status.allowed).Count)"
    }
    catch {
        return 'failed to load response profile status'
    }
}

function Get-CommunicationPresetConfig {
    $configPath = Join-Path $repoRoot 'config\orchestrator.json'
    $defaults = [ordered]@{
        enabled = $true
        defaultRisk = 'medium'
        defaultPreset = 'bugfix'
        defaultChatLevel = 'chat-compact'
        enforceChatLevelOnStart = $true
    }

    if (-not (Test-Path $configPath)) {
        return [pscustomobject]$defaults
    }

    try {
        $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($config.PSObject.Properties['communication_presets']) {
            $presets = $config.communication_presets
            if ($presets.PSObject.Properties['auto_apply_on_session_start']) {
                $defaults.enabled = [bool]$presets.auto_apply_on_session_start
            }
            if ($presets.PSObject.Properties['auto_apply_default_risk']) {
                $risk = [string]$presets.auto_apply_default_risk
                if ($risk -in @('low', 'medium', 'high')) {
                    $defaults.defaultRisk = $risk
                }
            }
            if ($presets.PSObject.Properties['default'] -and -not [string]::IsNullOrWhiteSpace([string]$presets.default)) {
                $defaults.defaultPreset = [string]$presets.default
            }
        }

        if ($config.PSObject.Properties['chat_response']) {
            $chat = $config.chat_response
            if ($chat.PSObject.Properties['default_level'] -and -not [string]::IsNullOrWhiteSpace([string]$chat.default_level)) {
                $defaults.defaultChatLevel = [string]$chat.default_level
            }
            if ($chat.PSObject.Properties['enforce_on_session_start']) {
                $defaults.enforceChatLevelOnStart = [bool]$chat.enforce_on_session_start
            }
        }
    }
    catch {
        return [pscustomobject]$defaults
    }

    return [pscustomobject]$defaults
}

function Get-SessionRecommendationInput {
    param(
        [string]$Branch,
        [string]$TaskName,
        [string]$DefaultPreset,
        [string]$DefaultRisk
    )

    $preset = $DefaultPreset
    $risk = $DefaultRisk

    if ($Branch -match '^(hotfix|release)/') {
        $risk = 'high'
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskName)) {
        $task = $TaskName.ToLowerInvariant()

        if ($task -match 'doc|readme|guide|manual|onboard') {
            $preset = 'docs'
        }
        elseif ($task -match 'audit|review|security|governance|compliance') {
            $preset = 'audit-review'
            if ($risk -eq 'low') {
                $risk = 'medium'
            }
        }
        elseif ($task -match 'refactor|cleanup|homologat|restruct') {
            $preset = 'refactor'
        }
        elseif ($task -match 'demo|board|executive|stakeholder') {
            $preset = 'executive-demo'
        }
        else {
            $preset = 'bugfix'
        }
    }

    return [pscustomobject]@{
        preset = $preset
        risk = $risk
    }
}

function Apply-ResponseModeRecommendation {
    param(
        [string]$Preset,
        [string]$Risk,
        [string]$ChatLevel,
        [bool]$EnforceChatLevelOnStart
    )

    $modeScript = Join-Path $PSScriptRoot 'response-mode.ps1'
    if (-not (Test-Path $modeScript)) {
        return 'skipped (response-mode script not found)'
    }

    try {
        if ($EnforceChatLevelOnStart -and -not [string]::IsNullOrWhiteSpace($ChatLevel)) {
            & $modeScript -Mode set-chat-level -ChatLevel $ChatLevel -SkipEngramLog -Quiet | Out-Null
            return "applied startup chat-level=$ChatLevel (architecture baseline)"
        }

        $json = & $modeScript -Mode recommend -Preset $Preset -Risk $Risk -AsJson -PassThru -SkipEngramLog -Quiet
        if ([string]::IsNullOrWhiteSpace(($json | Out-String).Trim())) {
            return 'skipped (recommendation returned empty output)'
        }

        $rec = $json | ConvertFrom-Json

        & $modeScript -Mode set-language -Language $rec.language -SkipEngramLog -Quiet | Out-Null
        & $modeScript -Mode set-detail -Detail $rec.detail -SkipEngramLog -Quiet | Out-Null
        & $modeScript -Mode set -Profile $rec.compression -SkipEngramLog -Quiet | Out-Null

        return "applied preset=$($rec.preset); risk=$($rec.risk); language=$($rec.language); detail=$($rec.detail); profile=$($rec.compression)"
    }
    catch {
        return "failed ($($_.Exception.Message))"
    }
}

function New-TaskBriefContent {
    param([string]$TaskTitle)

@"
# Task Brief: $TaskTitle

## Goal

- Problem to solve:
- Desired outcome:

## Scope

- In scope:
- Out of scope:

## Key Files

- Primary implementation files:
- Tests or validation files:
- Documentation files:

## Acceptance Criteria

- [ ] Behavior is implemented
- [ ] Focused validation passes
- [ ] Documentation updated if needed
- [ ] Ready for audit and repository publication review

## Risks

- Technical risk:
- Product or workflow risk:
- Rollback or fallback plan:

## Status

- Current state:
- Next concrete step:
"@
}

Write-Step "Preparing session artifacts"

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ([string]::IsNullOrWhiteSpace($branch)) {
    $branch = 'unknown'
}

$gitStatus = git status --short 2>$null
$gitState = if ([string]::IsNullOrWhiteSpace(($gitStatus -join '').Trim())) { 'clean' } else { 'has uncommitted changes' }

$orchestratorMarker = Test-Path (Join-Path $repoRoot '.orchestrator-active')
$orchestratorState = if ($orchestratorMarker) { 'active marker present' } else { 'marker missing' }
$engramState = Get-ToolState -Name 'engram' -RelativeWrapper 'scripts\utilities\run-engram.ps1'
$State = Get-ToolState -Name '' -RelativeWrapper 'scripts\utilities\run-.ps1'
$customRulesState = Get-CustomRulesState
$presetConfig = Get-CommunicationPresetConfig
$responseModeAutoState = 'disabled by config'
if ($presetConfig.enabled) {
    $input = Get-SessionRecommendationInput -Branch $branch -TaskName $TaskName -DefaultPreset $presetConfig.defaultPreset -DefaultRisk $presetConfig.defaultRisk
    $responseModeAutoState = Apply-ResponseModeRecommendation -Preset $input.preset -Risk $input.risk -ChatLevel $presetConfig.defaultChatLevel -EnforceChatLevelOnStart $presetConfig.enforceChatLevelOnStart
}
$responseModeState = Get-ResponseModeState

$sessionsDir = Join-Path $repoRoot 'docs\sessions'
$tasksDir = Join-Path $repoRoot 'docs\tasks'
New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null

$sessionFile = Join-Path $sessionsDir ("{0}-session-start.md" -f (Get-Date -Format 'yyyy-MM-dd-HHmmss'))
if ((Test-Path $sessionFile) -and -not $Force) {
    $sessionFile = Join-Path $sessionsDir ("{0}-session-start-{1}.md" -f (Get-Date -Format 'yyyy-MM-dd'), (Get-Date -Format 'HHmmss'))
}

$taskFile = $null
if (-not [string]::IsNullOrWhiteSpace($TaskName)) {
    $taskSlug = Convert-ToSlug -Value $TaskName
    $taskFile = Join-Path $tasksDir ("{0}.md" -f $taskSlug)
    if ((Test-Path $taskFile) -and -not $Force) {
        Write-Warn "Task brief already exists: $taskFile"
    } else {
        New-TaskBriefContent -TaskTitle $TaskName | Out-File -FilePath $taskFile -Encoding UTF8
        Write-Ok "Task brief created: $taskFile"
    }
}

New-SessionBriefContent -Branch $branch -GitState $gitState -OrchestratorState $orchestratorState -EngramState $engramState -State $State -CustomRulesState $customRulesState -ResponseModeState $responseModeState -ResponseModeAutoState $responseModeAutoState -SessionFile $sessionFile -TaskFile $taskFile | Out-File -FilePath $sessionFile -Encoding UTF8

Write-Ok "Session brief created: $sessionFile"

$compactScript = Join-Path $PSScriptRoot 'compact-start.ps1'
if (Test-Path $compactScript) {
    Write-Step "Optimizing context for efficiency"
    try {
        & $compactScript -Objective "Session $($branch): $($TaskName)" -NoClipboard | Out-Null
        Write-Ok "Context optimized with compact-start"
    }
    catch {
        Write-Warn "compact-start skipped: $_"
    }
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Review the generated session brief." -ForegroundColor Yellow
Write-Host "2. Run '.\scripts\utilities\wf.ps1 health' if stack readiness is uncertain." -ForegroundColor Yellow
Write-Host "3. Keep the task brief updated as the scope changes." -ForegroundColor Yellow
