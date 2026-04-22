param(
    [Parameter(Mandatory=$false)]
    [string]$Agents = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Task = '',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('parallel', 'sequential', 'adaptive')]
    [string]$Mode = 'parallel',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('low', 'medium', 'high')]
    [string]$Risk = 'medium',
    
    [int]$MaxParallel = 4,
    
    [switch]$DryRun,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$agentRouter = Join-Path $scriptDir 'agent-router.ps1'
$eventBusScript = Join-Path $scriptDir 'event-bus.ps1'

function Write-AgentLine {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-MaxParallelByRisk {
    param([string]$RiskLevel)
    switch ($RiskLevel) {
        'low'    { return 4 }
        'medium' { return 3 }
        'high'   { return 2 }
    }
    return 2
}

function Get-ParallelConfig {
    param(
        [string[]]$AgentNames,
        [string]$TaskText,
        [string]$ExecutionMode,
        [string]$RiskLevel
    )
    
    $maxParallel = [Math]::Min((Get-MaxParallelByRisk -RiskLevel $RiskLevel), $MaxParallel)
    
    $config = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
        execution_id = "dispatch-$((Get-Date -Format 'yyyyMMdd-HHmmss'))"
        agents = $AgentNames
        task = $TaskText
        mode = $ExecutionMode
        risk = $RiskLevel
        max_parallel = $maxParallel
        total_agents = $AgentNames.Count
        estimated_duration_minutes = [Math]::Ceiling($AgentNames.Count / $maxParallel * 5)
        token_budget = @{
            per_agent = 3000
            coordination_overhead = 500
            estimated_total = ($AgentNames.Count * 3000) + 500
        }
        lanes = @()
    }
    
    if ($ExecutionMode -eq 'parallel') {
        $batch = @()
        for ($i = 0; $i -lt $AgentNames.Count; $i++) {
            $batch += @{
                agent = $AgentNames[$i]
                batch = [Math]::Floor($i / $maxParallel) + 1
                order = $i + 1
                depends_on = $null
            }
            if (($i + 1) % $maxParallel -eq 0 -or $i -eq $AgentNames.Count - 1) {
                $config.lanes += @{
                    batch_id = "batch-$([Math]::Floor($i / $maxParallel) + 1)"
                    agents = $batch.agent
                    parallel = $true
                }
                $batch = @()
            }
        }
    } elseif ($ExecutionMode -eq 'sequential') {
        for ($i = 0; $i -lt $AgentNames.Count; $i++) {
            $config.lanes += @{
                lane_id = "lane-$($AgentNames[$i])-$($i + 1)"
                agent = $AgentNames[$i]
                order = $i + 1
                depends_on = if ($i -gt 0) { $AgentNames[$i - 1] } else { $null }
                parallel = $false
            }
        }
    } elseif ($ExecutionMode -eq 'adaptive') {
        $independent = @()
        $dependent = @()
        
        $independentAgents = @('BA', 'DOC')
        foreach ($agent in $AgentNames) {
            if ($independentAgents -contains $agent) {
                $independent += $agent
            } else {
                $dependent += $agent
            }
        }
        
        $batch = 1
        if ($independent.Count -gt 0) {
            $config.lanes += @{
                batch_id = "batch-$batch-independent"
                agents = $independent
                phase = 'discovery'
                parallel = $true
            }
            $batch++
        }
        
        if ($dependent.Count -gt 0) {
            $depBatch = @()
            for ($i = 0; $i -lt $dependent.Count; $i++) {
                $depBatch += $dependent[$i]
                if (($i + 1) % $maxParallel -eq 0 -or $i -eq $dependent.Count - 1) {
                    $config.lanes += @{
                        batch_id = "batch-$batch-dependent"
                        agents = $depBatch
                        phase = 'execution'
                        depends_on_phase = 'discovery'
                        parallel = $true
                    }
                    $depBatch = @()
                    $batch++
                }
            }
        }
    }
    
    return $config
}

function Invoke-ParallelDispatch {
    param(
        [string[]]$AgentNames,
        [string]$TaskText,
        [string]$ExecutionMode,
        [string]$RiskLevel
    )
    
    $config = Get-ParallelConfig -AgentNames $AgentNames -TaskText $TaskText -ExecutionMode $ExecutionMode -RiskLevel $RiskLevel
    
    if ($DryRun) {
        if ($AsJson) {
            $config | ConvertTo-Json -Depth 5
            return
        }
        
        Write-AgentLine "`n=== PARALLEL DISPATCH PLAN ===" 'Cyan'
        Write-AgentLine "Execution ID: $($config.execution_id)" 'Gray'
        Write-AgentLine "Mode: $($config.mode)" 'White'
        Write-AgentLine "Risk: $($config.risk)" 'White'
        Write-AgentLine "Max Parallel: $($config.max_parallel)" 'White'
        Write-AgentLine "Est. Duration: ~$($config.estimated_duration_minutes) min" 'Gray'
        Write-AgentLine "Token Budget: ~$($config.token_budget.estimated_total) chars" 'Gray'
        Write-AgentLine ""
        
        Write-AgentLine "Lanes:" 'Yellow'
        foreach ($lane in $config.lanes) {
            if ($lane.parallel) {
                Write-Host "  [BATCH $($lane.batch_id)]" -ForegroundColor Green
                foreach ($agent in $lane.agents) {
                    Write-Host "    - $agent" -ForegroundColor Gray
                }
            } else {
                Write-Host "  [LANE $($lane.order)] $agent" -ForegroundColor Yellow
                if ($lane.depends_on) {
                    Write-Host "    depends on: $($lane.depends_on)" -ForegroundColor DarkGray
                }
            }
        }
        
        Write-AgentLine "`n--- Dry run complete ---" 'Cyan'
        return
    }
    
    Write-AgentLine "`n=== PARALLEL DISPATCH EXECUTION ===" 'Cyan'
    Write-AgentLine "Starting $($config.total_agents) agents in $Mode mode..." 'White'
    
    if (Test-Path $eventBusScript) {
        & $eventBusScript -Action emit -Event 'dispatch.started' -Payload (@{ execution_id = $config.execution_id; mode = $ExecutionMode; agents = $AgentNames } | ConvertTo-Json -Compress)
    }
    
    $results = @()
    $batchNum = 0
    
    foreach ($lane in $config.lanes) {
        if ($lane.parallel) {
            $batchNum++
            Write-AgentLine "`n[Batch $batchNum] Running $($lane.agents.Count) agents in parallel..." 'Green'
            
            $jobs = @()
            foreach ($agent in $lane.agents) {
                Write-Host "  Dispatching: $agent" -ForegroundColor Gray
                $job = Start-Job -ScriptBlock {
                    param($script, $agentName, $taskDesc)
                    & $script -Agent $agentName -Task $taskDesc -AsJson | ConvertFrom-Json
                } -ArgumentList $agentRouter, $agent, $TaskText
                $jobs += @{
                    job = $job
                    agent = $agent
                }
            }
            
            Write-Host "  Waiting for batch to complete..." -ForegroundColor DarkGray
            $jobs | ForEach-Object { 
                $_.result = Receive-Job -Job $_.job -Wait
                Remove-Job -Job $_.job
            }
            
            foreach ($job in $jobs) {
                $results += $job.result
            }
        } else {
            Write-AgentLine "`n[Lane $($lane.order)] Running $($lane.agent)..." 'Yellow'
            if ($lane.depends_on) {
                Write-Host "  (waiting for $($lane.depends_on))" -ForegroundColor DarkGray
            }
            
            $result = & $agentRouter -Agent $lane.agent -Task $TaskText -AsJson | ConvertFrom-Json
            $results += $result
        }
    }
    
    if (Test-Path $eventBusScript) {
        & $eventBusScript -Action emit -Event 'dispatch.completed' -Payload (@{ execution_id = $config.execution_id; results_count = $results.Count } | ConvertTo-Json -Compress)
    }
    
    return @{
        execution_id = $config.execution_id
        config = $config
        results = $results
        summary = @{
            total = $results.Count
            ready = @($results | Where-Object { $_.status -eq 'ready' }).Count
            failed = @($results | Where-Object { $_.status -eq 'failed' }).Count
            blocked = @($results | Where-Object { $_.status -eq 'blocked' }).Count
        }
    }
}

$validAgents = @('BA', 'SAD', 'DEV', 'QA', 'OPS', 'GOV', 'DOC')

if ([string]::IsNullOrWhiteSpace($Agents)) {
    if ($AsJson) {
        @{ error = 'agents required'; example = '.\wf.ps1 dispatch "DEV,QA" "implement feature"' } | ConvertTo-Json
        exit 1
    }
    
    Write-Host "Usage: .\wf.ps1 dispatch <AGENTS> <TASK> [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "AGENTS: Comma-separated list (e.g., DEV,QA,BA)" -ForegroundColor White
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Mode parallel|sequential|adaptive (default: parallel)" -ForegroundColor Gray
    Write-Host "  -Risk low|medium|high (default: medium)" -ForegroundColor Gray
    Write-Host "  -MaxParallel N (default: 4)" -ForegroundColor Gray
    Write-Host "  -DryRun (preview only)" -ForegroundColor Gray
    Write-Host "  -AsJson (structured output)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\wf.ps1 dispatch `"DEV,QA`" `"implement auth`"" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 dispatch `"BA,SAD`" `"plan feature`" -DryRun" -ForegroundColor Gray
    Write-Host "  .\wf.ps1 dispatch `"DEV,QA,OPS`" `"deploy`" -Mode adaptive" -ForegroundColor Gray
    exit 1
}

$agentList = $Agents -split ',' | ForEach-Object { $_.Trim().ToUpper() } | Where-Object { $validAgents -contains $_ }

if ($agentList.Count -eq 0) {
    Write-Host "[ERROR] No valid agents specified" -ForegroundColor Red
    Write-Host "Valid agents: $($validAgents -join ', ')" -ForegroundColor Gray
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-Host "[ERROR] Task description required" -ForegroundColor Red
    exit 1
}

if ($AsJson) {
    $result = Invoke-ParallelDispatch -AgentNames $agentList -TaskText $Task -ExecutionMode $Mode -RiskLevel $Risk
    $result | ConvertTo-Json -Depth 5
} else {
    $result = Invoke-ParallelDispatch -AgentNames $agentList -TaskText $Task -ExecutionMode $Mode -RiskLevel $Risk
    
    Write-AgentLine "`n=== DISPATCH SUMMARY ===" 'Cyan'
    Write-Host "Execution ID: $($result.execution_id)" -ForegroundColor White
    Write-Host "Total dispatched: $($result.summary.total)" -ForegroundColor White
    Write-Host "  Ready: $($result.summary.ready)" -ForegroundColor Green
    Write-Host "  Failed: $($result.summary.failed)" -ForegroundColor Red
    Write-Host "  Blocked: $($result.summary.blocked)" -ForegroundColor Yellow
}
