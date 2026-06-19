#Requires -Version 7.0
<#
.SYNOPSIS
    Saga Orchestrator — Coordinates distributed transactions with compensating actions

.DESCRIPTION
    Implements the Saga pattern for multi-step operations across cloud providers,
    state persistence, and skill execution. On failure, runs compensating actions
    to maintain consistency.

.NOTES
    Part of Phase 5 — Advanced Patterns v4.0
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('execute', 'compensate', 'status', 'list')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$SagaId,

    [Parameter(Mandatory = $false)]
    [string]$Definition,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$sagaDir = Join-Path $root '.session' 'sagas'
$sagaLog = Join-Path $root '.session' 'saga.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $c = @{'INFO' = 'Cyan'; 'WARN' = 'Yellow'; 'ERROR' = 'Red'; 'SUCCESS' = 'Green'}[$Level]
    if (-not $Quiet) { Write-Host "[$t] [SAGA] [$Level] $Message" -ForegroundColor $c }
    Add-Content -Path $sagaLog -Value "[$t] [$Level] $Message" -ErrorAction SilentlyContinue
}

function Ensure-Dirs {
    if (-not (Test-Path $sagaDir)) { New-Item -ItemType Directory -Path $sagaDir -Force | Out-Null }
}

function New-SagaId {
    return "saga-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(-join ((1..6) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) }))"
}

function Get-SagaPath {
    param([string]$Id)
    return Join-Path $sagaDir "$Id.json"
}

function Save-SagaState {
    param([hashtable]$State)
    $State | ConvertTo-Json -Depth 10 | Set-Content (Get-SagaPath -Id $State.id)
}

function Load-SagaState {
    param([string]$Id)
    $path = Get-SagaPath -Id $Id
    if (-not (Test-Path $path)) { throw "Saga $Id not found" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Invoke-Step {
    param([hashtable]$Step, [hashtable]$Context)
    Write-Log "  Step: $($Step.name) [$($Step.type)]" 'INFO'

    $start = Get-Date
    $result = @{ success = $true; output = $null; error = $null }

    try {
        switch ($Step.type) {
            'script' {
                if ($Step.script) {
                    $result.output = & $Step.script @($Step.args ?? @())
                }
            }
            'http' {
                if ($Step.url) {
                    $body = if ($Step.body) { $Step.body | ConvertTo-Json } else { $null }
                    $response = Invoke-RestMethod -Method $($Step.method ?? 'POST') -Uri $Step.url -Body $body -ContentType 'application/json' -ErrorAction Stop
                    $result.output = $response
                }
            }
            'pscommand' {
                if ($Step.command) {
                    $result.output = Invoke-Expression -Command $Step.command
                }
            }
            'checkpoint' {
                $ckpt = & (Join-Path $root 'scripts/utilities/ops/STATE-PERSISTENCE/checkpoint-manager.ps1') -Action create -Label $Step.label -Quiet:$Quiet
                $result.output = $ckpt
            }
            default { throw "Unknown step type: $($Step.type)" }
        }
    } catch {
        $result.success = $false
        $result.error = $_.Exception.Message
    }

    $result.durationMs = [math]::Round(((Get-Date) - $start).TotalMilliseconds)
    return $result
}

function Invoke-Compensation {
    param([hashtable]$Step, [hashtable]$Context)
    if (-not $Step.compensate) {
        Write-Log "  No compensation defined for $($Step.name)" 'WARN'
        return $true
    }

    Write-Log "  Compensating: $($Step.name)" 'WARN'

    try {
        $comp = $Step.compensate
        switch ($comp.type) {
            'script' {
                if ($comp.script) { & $comp.script @($comp.args ?? @()) }
            }
            'rollback' {
                $ckptId = $Context.lastCheckpointId
                if ($ckptId) {
                    & (Join-Path $root 'scripts/utilities/ops/STATE-PERSISTENCE/rollback-orchestrator.ps1') -CheckpointId $ckptId -Force -Quiet:$Quiet
                }
            }
            'pscommand' {
                if ($comp.command) { Invoke-Expression -Command $comp.command }
            }
            default { Write-Log "Unknown compensation type: $($comp.type)" 'WARN' }
        }
        return $true
    } catch {
        Write-Log "  Compensation failed: $_" 'ERROR'
        return $false
    }
}

# ===== MAIN =====

switch ($Action) {
    'execute' {
        Ensure-Dirs
        $definitionObj = if ($Definition) { $Definition | ConvertFrom-Json } else { throw 'Definition JSON required' }

        $sagaId = if ($SagaId) { $SagaId } else { New-SagaId }

        $saga = @{
            id          = $sagaId
            name        = $definitionObj.name ?? 'Unnamed Saga'
            status      = 'running'
            startedAt   = (Get-Date -Format 'o')
            steps       = @()
            currentStep = 0
            context     = @{}
        }

        Write-Log "Saga $sagaId started: $($saga.name)" 'SUCCESS'

        $steps = $definitionObj.steps ?? @()
        $failed = $false

        for ($i = 0; $i -lt $steps.Count; $i++) {
            $stepDef = $steps[$i]
            $saga.currentStep = $i + 1

            $result = Invoke-Step -Step $stepDef -Context $saga.context
            $saga.steps += @{
                name       = $stepDef.name
                type       = $stepDef.type
                status     = if ($result.success) { 'completed' } else { 'failed' }
                durationMs = $result.durationMs
                error      = $result.error
            }

            if ($result.success) {
                Write-Log "  Step $($i+1)/$($steps.Count) OK ($($result.durationMs)ms)" 'SUCCESS'
                if ($stepDef.checkpoint) { $saga.context.lastCheckpointId = $result.output?.checkpointId }
            } else {
                Write-Log "  Step $($i+1)/$($steps.Count) FAILED: $($result.error)" 'ERROR'
                $failed = $true

                for ($j = $i; $j -ge 0; $j--) {
                    $compResult = Invoke-Compensation -Step $steps[$j] -Context $saga.context
                    $saga.steps[$j].compensated = $compResult
                }
                break
            }
        }

        $saga.status = if ($failed) { 'compensated' } else { 'completed' }
        $saga.completedAt = (Get-Date -Format 'o')
        Save-SagaState -State $saga

        if ($failed) {
            Write-Log "Saga $sagaId compensated after step $($saga.currentStep)" 'ERROR'
        } else {
            Write-Log "Saga $sagaId completed successfully" 'SUCCESS'
        }

        return $saga
    }

    'compensate' {
        if (-not $SagaId) { throw 'SagaId required' }
        $saga = Load-SagaState -Id $SagaId

        if ($saga.status -ne 'completed') {
            throw "Saga $SagaId is in status '$($saga.status)' — can only compensate completed sagas"
        }

        Write-Log "Triggering compensation for saga $SagaId ($($saga.name))" 'WARN'
        $saga.status = 'compensating'

        for ($i = $saga.steps.Count - 1; $i -ge 0; $i--) {
            $stepDef = $saga.steps[$i]
            $compResult = $true
            if ($stepDef.compensate) {
                $compResult = Invoke-Compensation -Step $stepDef -Context $saga.context
            }
            $saga.steps[$i].compensated = $compResult
        }

        $saga.status = 'compensated'
        $saga.compensatedAt = (Get-Date -Format 'o')
        Save-SagaState -State $saga
        Write-Log "Saga $SagaId fully compensated" 'WARN'
        return $saga
    }

    'status' {
        if (-not $SagaId) { throw 'SagaId required' }
        return Load-SagaState -Id $SagaId
    }

    'list' {
        $sagas = @()
        if (Test-Path $sagaDir) {
            $sagas = Get-ChildItem -Path $sagaDir -Filter '*.json' | ForEach-Object {
                $s = Get-Content $_.FullName -Raw | ConvertFrom-Json
                @{
                    id          = $s.id
                    name        = $s.name
                    status      = $s.status
                    startedAt   = $s.startedAt
                    steps       = $s.steps.Count
                    completedAt = $s.completedAt
                }
            }
        }
        return $sagas | Sort-Object startedAt -Descending
    }
}
