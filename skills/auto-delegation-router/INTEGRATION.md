# Auto-Delegation Router - Integration Guide

## Quick Start

### 1. Load Module
```powershell
Import-Module ".\skills\auto-delegation-router\auto-delegation-router.ps1" -Force
```

### 2. Enable Auto-Delegation
```powershell
Enable-AutoDelegation
```

### 3. Route Tasks
```powershell
$task = "Implement login feature with React"
$routing = Route-TaskToAgent -TaskDescription $task
```

## Configuration

### Enable/Disable
```powershell
Enable-AutoDelegation      # Enable
Disable-AutoDelegation     # Disable
```

### Adjust Threshold
```powershell
Set-ConfidenceThreshold -Threshold 70
```

## Orchestrator Integration

Add to orchestrator initialization:

```powershell
function Invoke-OrchestratorWithAutoRouting {
    param([string]$TaskDescription, [bool]$UseAutoRouting = $true)
    
    if ($UseAutoRouting) {
        $routing = Route-TaskToAgent -TaskDescription $TaskDescription
        
        if ($routing.Status -eq "Success") {
            # Dispatch to primary agent
            Invoke-Agent -AgentName $routing.PrimaryAgent -Task $TaskDescription
            
            # Dispatch to secondary agents
            foreach ($agent in $routing.SecondaryAgents) {
                Invoke-Agent -AgentName $agent -Task $TaskDescription -Mode "Secondary"
            }
            
            Log-Routingdecisión -RoutingResult $routing
        }
    }
}
```

## Metrics

```powershell
$metrics = Get-RoutingMetrics
$metrics | ConvertTo-Json
```

## Troubleshooting

- **Not working**: Check if enabled with `$config = Get-AutoDelegationConfig`
- **Low confidence**: Use more specific task descriptions
- **Wrong routing**: Review keyword mappings in config/auto-delegation.json

## References

- [SKILL.md](./SKILL.md) - Full documentation
- [Multi-Agent Registry](../multi-agent-registry/SKILL.md)
- [Orchestrator](../project-orchestrator-skill/SKILL.md)
