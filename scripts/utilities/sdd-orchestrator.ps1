param(
    [ValidateSet('get-state', 'register-feature', 'update-phase', 'get-phase', 'list-features')]
    [string]$Action = 'get-state',
    [string]$FeatureName,
    [ValidateSet('init', 'explore', 'propose', 'spec', 'design', 'tasks', 'apply', 'verify', 'archive')]
    [string]$Phase,
    [string]$WorkspaceRoot = '.'
)

$ErrorActionPreference = 'Stop'
$stateFile = if ($WorkspaceRoot -eq '.') {
    Join-Path (Split-Path -Parent $PSScriptRoot | Split-Path -Parent) '.session\sdd-state.json'
} else {
    Join-Path (Resolve-Path $WorkspaceRoot) '.session\sdd-state.json'
}

# Phase → correct agent mapping
$phaseAgentMap = @{
    'init'    = 'BA'
    'explore' = 'BA'
    'propose' = 'SAD'
    'spec'    = 'SAD'
    'design'  = 'SAD'
    'tasks'   = 'DEV'
    'apply'   = 'DEV'
    'verify'  = 'QA'
    'archive' = 'DOC'
}

# Phase ordering for validation
$phaseOrder = @('init', 'explore', 'propose', 'spec', 'design', 'tasks', 'apply', 'verify', 'archive')
$phaseIndex = @{}
for ($i = 0; $i -lt $phaseOrder.Count; $i++) { $phaseIndex[$phaseOrder[$i]] = $i }

function Read-State {
    if (Test-Path $stateFile) {
        return Get-Content $stateFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Write-State($state) {
    $state.lastUpdated = (Get-Date -Format 'o')
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding UTF8
}

function Assert-PhaseOrder($currentPhase, $newPhase) {
    if ($currentPhase -and $phaseIndex.ContainsKey($currentPhase) -and $phaseIndex.ContainsKey($newPhase)) {
        if ($phaseIndex[$newPhase] -lt $phaseIndex[$currentPhase]) {
            Write-Warning "Phase regress: $currentPhase -> $newPhase (allowed but unusual)"
        }
    }
}

switch ($Action) {
    'get-state' {
        $state = Read-State
        if (-not $state) {
            Write-Output '{"version":"1.0.0","features":{},"lastUpdated":null}'
        } else {
            $state | ConvertTo-Json -Depth 10
        }
        break
    }

    'register-feature' {
        if (-not $FeatureName) { throw 'FeatureName required for register-feature' }
        $state = Read-State
        if (-not $state) {
            $state = [PSCustomObject]@{ version = '1.0.0'; features = @{}; lastUpdated = $null }
        }
        $safeName = $FeatureName -replace '[^a-zA-Z0-9_-]', '-'
        if ($state.features.PSObject.Properties[$safeName]) {
            Write-Output "FEATURE_EXISTS: $safeName (current: $($state.features.$safeName.phase))"
            return
        }
        $feature = [PSCustomObject]@{
            phase = 'init'
            createdAt = (Get-Date -Format 'o')
            updatedAt = (Get-Date -Format 'o')
            completedPhases = @()
            artifacts = @()
            assignedAgent = 'BA'
            status = 'active'
        }
        $state.features | Add-Member -MemberType NoteProperty -Name $safeName -Value $feature -Force
        Write-State $state
        Write-Output "FEATURE_REGISTERED: $safeName (phase: init, agent: BA)"
        break
    }

    'update-phase' {
        if (-not $FeatureName -or -not $Phase) { throw 'FeatureName and Phase required for update-phase' }
        $state = Read-State
        if (-not $state) { throw 'No SDD state found. Register a feature first.' }
        $safeName = $FeatureName -replace '[^a-zA-Z0-9_-]', '-'
        if (-not $state.features.PSObject.Properties[$safeName]) { throw "Feature '$safeName' not found" }

        $current = $state.features.$safeName
        Assert-PhaseOrder $current.phase $Phase

        $completedPhase = $current.phase
        if ($completedPhase -and $completedPhase -notin $current.completedPhases) {
            $current.completedPhases = @($current.completedPhases) + @($completedPhase)
        }
        $current.phase = $Phase
        $current.assignedAgent = $phaseAgentMap[$Phase]
        $current.updatedAt = (Get-Date -Format 'o')
        if ($Phase -eq 'archive') { $current.status = 'archived' }

        Write-State $state
        Write-Output "PHASE_UPDATED: $safeName -> $Phase (agent: $($phaseAgentMap[$Phase]))"
        break
    }

    'get-phase' {
        if (-not $FeatureName) { throw 'FeatureName required for get-phase' }
        $state = Read-State
        if (-not $state) { Write-Output 'NO_STATE'; return }
        $safeName = $FeatureName -replace '[^a-zA-Z0-9_-]', '-'
        if (-not $state.features.PSObject.Properties[$safeName]) { Write-Output 'FEATURE_NOT_FOUND'; return }
        Write-Output "PHASE:$($state.features.$safeName.phase)"
        Write-Output "AGENT:$($state.features.$safeName.assignedAgent)"
        Write-Output "STATUS:$($state.features.$safeName.status)"
        break
    }

    'list-features' {
        $state = Read-State
        if (-not $state -or ($state.features.PSObject.Properties.Count -eq 0)) {
            Write-Output 'NO_FEATURES'
            return
        }
        foreach ($prop in $state.features.PSObject.Properties) {
            $f = $prop.Value
            Write-Output "$($prop.Name) | phase=$($f.phase) | agent=$($f.assignedAgent) | status=$($f.status)"
        }
        break
    }
}
