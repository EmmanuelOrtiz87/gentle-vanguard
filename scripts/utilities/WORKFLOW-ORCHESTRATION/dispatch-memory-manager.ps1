# dispatch-memory-manager.ps1
# Gestor de memoria persistente para dispatch-agent
# Integra Engram con el sistema de dispatch para mantener contexto entre ejecuciones

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('save', 'load', 'list', 'clear', 'sync', 'reconcile', 'handoff')]
    [string]$Action = 'load',
    
    [Parameter(Mandatory=$false)]
    [string]$ExecutionId = '',
    
    [Parameter(Mandatory=$false)]
    [hashtable]$DispatchContext = @{},
    
    [Parameter(Mandatory=$false)]
    [string]$SessionId = '',
    
    [switch]$AsJson,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# Configuracin de rutas
$engramDataDir = Join-Path $repoRoot '.engram-data'
$dispatchMemoryDir = Join-Path $engramDataDir 'dispatch-memory'
$dispatchRegistry = Join-Path $dispatchMemoryDir 'dispatch-registry.json'
$dispatchContextDir = Join-Path $dispatchMemoryDir 'contexts'

# Inicializar directorios
function Initialize-MemoryStructure {
    if (-not (Test-Path $dispatchMemoryDir)) {
        New-Item -ItemType Directory -Path $dispatchMemoryDir -Force | Out-Null
    }
    if (-not (Test-Path $dispatchContextDir)) {
        New-Item -ItemType Directory -Path $dispatchContextDir -Force | Out-Null
    }
    if (-not (Test-Path $dispatchRegistry)) {
        @{ dispatches = @(); last_updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz' } | ConvertTo-Json | Out-File -FilePath $dispatchRegistry -Encoding UTF8
    }
}

function Write-DispatchLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    if ($Verbose -or $Level -eq 'ERROR') {
        $color = switch ($Level) {
            'ERROR' { 'Red' }
            'WARN' { 'Yellow' }
            'SUCCESS' { 'Green' }
            default { 'Cyan' }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Get-DispatchRegistry {
    if (Test-Path $dispatchRegistry) {
        return Get-Content -Path $dispatchRegistry -Raw | ConvertFrom-Json
    }
    return @{ dispatches = @(); last_updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz' }
}

function Save-DispatchRegistry {
    param([object]$Registry)
    $Registry.last_updated = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    $Registry | ConvertTo-Json -Depth 10 | Out-File -FilePath $dispatchRegistry -Encoding UTF8 -Force
}

function Save-DispatchMemory {
    param(
        [string]$ExecutionId,
        [hashtable]$Context,
        [string]$SessionId = ''
    )
    
    Initialize-MemoryStructure
    
    if ([string]::IsNullOrWhiteSpace($ExecutionId)) {
        Write-DispatchLog "ExecutionId requerido para guardar memoria" -Level 'ERROR'
        return $false
    }
    
    try {
        $contextFile = Join-Path $dispatchContextDir "$ExecutionId.json"
        
        $memoryEntry = @{
            execution_id = $ExecutionId
            session_id = if ([string]::IsNullOrWhiteSpace($SessionId)) { $env:WFS_SESSION_ID } else { $SessionId }
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
            context = $Context
            status = 'saved'
        }
        
        $memoryEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $contextFile -Encoding UTF8 -Force
        
        # Actualizar registro
        $registry = Get-DispatchRegistry
        $existingIndex = $registry.dispatches | Where-Object { $_.execution_id -eq $ExecutionId }
        
        if (-not $existingIndex) {
            $registry.dispatches += @{
                execution_id = $ExecutionId
                session_id = $memoryEntry.session_id
                timestamp = $memoryEntry.timestamp
                status = 'saved'
            }
        }
        
        Save-DispatchRegistry -Registry $registry
        
        Write-DispatchLog "Contexto de dispatch guardado: $ExecutionId" -Level 'SUCCESS'
        return $true
    } catch {
        Write-DispatchLog "Error al guardar memoria de dispatch: $_" -Level 'ERROR'
        return $false
    }
}

function Load-DispatchMemory {
    param(
        [string]$ExecutionId,
        [string]$SessionId = ''
    )
    
    Initialize-MemoryStructure
    
    try {
        if (-not [string]::IsNullOrWhiteSpace($ExecutionId)) {
            # Cargar contexto especfico
            $contextFile = Join-Path $dispatchContextDir "$ExecutionId.json"
            if (Test-Path $contextFile) {
                $memory = Get-Content -Path $contextFile -Raw | ConvertFrom-Json
                Write-DispatchLog "Contexto de dispatch cargado: $ExecutionId" -Level 'SUCCESS'
                return $memory
            } else {
                Write-DispatchLog "No se encontr contexto para: $ExecutionId" -Level 'WARN'
                return $null
            }
        } else {
            # Cargar contexto ms reciente de la sesin
            $registry = Get-DispatchRegistry
            $currentSession = if ([string]::IsNullOrWhiteSpace($SessionId)) { $env:WFS_SESSION_ID } else { $SessionId }
            
            $latestDispatch = $registry.dispatches | 
                Where-Object { $_.session_id -eq $currentSession } | 
                Sort-Object -Property timestamp -Descending | 
                Select-Object -First 1
            
            if ($latestDispatch) {
                $contextFile = Join-Path $dispatchContextDir "$($latestDispatch.execution_id).json"
                if (Test-Path $contextFile) {
                    $memory = Get-Content -Path $contextFile -Raw | ConvertFrom-Json
                    Write-DispatchLog "Contexto ms reciente cargado: $($latestDispatch.execution_id)" -Level 'SUCCESS'
                    return $memory
                }
            }
            
            Write-DispatchLog "No hay contexto previo disponible" -Level 'WARN'
            return $null
        }
    } catch {
        Write-DispatchLog "Error al cargar memoria de dispatch: $_" -Level 'ERROR'
        return $null
    }
}

function List-DispatchMemory {
    param(
        [string]$SessionId = '',
        [int]$Limit = 10
    )
    
    Initialize-MemoryStructure
    
    try {
        $registry = Get-DispatchRegistry
        $currentSession = if ([string]::IsNullOrWhiteSpace($SessionId)) { $env:WFS_SESSION_ID } else { $SessionId }
        
        $dispatches = $registry.dispatches | 
            Where-Object { $_.session_id -eq $currentSession } | 
            Sort-Object -Property timestamp -Descending | 
            Select-Object -First $Limit
        
        return @{
            session_id = $currentSession
            total_count = ($registry.dispatches | Where-Object { $_.session_id -eq $currentSession }).Count
            recent_dispatches = $dispatches
        }
    } catch {
        Write-DispatchLog "Error al listar memoria de dispatch: $_" -Level 'ERROR'
        return @{ error = $_.Exception.Message }
    }
}

function Clear-DispatchMemory {
    param(
        [string]$ExecutionId = '',
        [string]$SessionId = '',
        [switch]$Force
    )
    
    Initialize-MemoryStructure
    
    try {
        if (-not [string]::IsNullOrWhiteSpace($ExecutionId)) {
            # Limpiar contexto especfico
            $contextFile = Join-Path $dispatchContextDir "$ExecutionId.json"
            if (Test-Path $contextFile) {
                Remove-Item -Path $contextFile -Force
                
                # Actualizar registro
                $registry = Get-DispatchRegistry
                $registry.dispatches = @($registry.dispatches | Where-Object { $_.execution_id -ne $ExecutionId })
                Save-DispatchRegistry -Registry $registry
                
                Write-DispatchLog "Contexto eliminado: $ExecutionId" -Level 'SUCCESS'
                return $true
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($SessionId) -and $Force) {
            # Limpiar toda la sesin
            $registry = Get-DispatchRegistry
            $dispatchesToRemove = @($registry.dispatches | Where-Object { $_.session_id -eq $SessionId })
            
            foreach ($dispatch in $dispatchesToRemove) {
                $contextFile = Join-Path $dispatchContextDir "$($dispatch.execution_id).json"
                if (Test-Path $contextFile) {
                    Remove-Item -Path $contextFile -Force
                }
            }
            
            $registry.dispatches = @($registry.dispatches | Where-Object { $_.session_id -ne $SessionId })
            Save-DispatchRegistry -Registry $registry
            
            Write-DispatchLog "Contextos de sesin eliminados: $SessionId" -Level 'SUCCESS'
            return $true
        } else {
            Write-DispatchLog "Especifique ExecutionId o use -Force con SessionId" -Level 'WARN'
            return $false
        }
    } catch {
        Write-DispatchLog "Error al limpiar memoria de dispatch: $_" -Level 'ERROR'
        return $false
    }
}

function Detect-ContextConflicts {
    param([array]$Contexts)
    $conflicts = @()
    $allKeys = @{}
    foreach ($ctx in $Contexts) {
        if ($ctx.context) {
            foreach ($kv in $ctx.context.PSObject.Properties) {
                if (-not $allKeys.ContainsKey($kv.Name)) {
                    $allKeys[$kv.Name] = @{ values = @(); sources = @() }
                }
                $val = if ($kv.Value) { $kv.Value.ToString() } else { '' }
                $allKeys[$kv.Name].values += $val
                $allKeys[$kv.Name].sources += $ctx.execution_id
            }
        }
    }
    foreach ($key in $allKeys.Keys) {
        $unique = $allKeys[$key].values | Select-Object -Unique
        if ($unique.Count -gt 1) {
            $conflicts += @{ key = $key; values = $unique; sources = $allKeys[$key].sources }
        }
    }
    return $conflicts
}

function Merge-Contexts {
    param([array]$Contexts)
    $merged = @{}
    $sorted = $Contexts | Sort-Object -Property timestamp
    foreach ($ctx in $sorted) {
        if ($ctx.context) {
            foreach ($kv in $ctx.context.PSObject.Properties) {
                $val = $kv.Value
                if ($val -is [array]) {
                    $existing = if ($merged.ContainsKey($kv.Name)) { $merged[$kv.Name] } else { @() }
                    $merged[$kv.Name] = @($existing + $val) | Select-Object -Unique
                } elseif ($val -is [System.Management.Automation.PSCustomObject]) {
                    $existing = if ($merged.ContainsKey($kv.Name)) { $merged[$kv.Name] } else { @{} }
                    foreach ($nk in $val.PSObject.Properties) {
                        $existing | Add-Member -NotePropertyName $nk.Name -NotePropertyValue $nk.Value -Force
                    }
                    $merged[$kv.Name] = $existing
                } else {
                    $merged[$kv.Name] = $val
                }
            }
        }
    }
    return $merged
}

function Sync-DispatchMemory {
    param(
        [string]$SessionId = '',
        [string]$TargetSessionId = '',
        [switch]$DryRun
    )
    
    Initialize-MemoryStructure
    
    try {
        $registry = Get-DispatchRegistry
        $currentSession = if ([string]::IsNullOrWhiteSpace($SessionId)) { $env:WFS_SESSION_ID } else { $SessionId }
        $sessionDispatches = @($registry.dispatches | Where-Object { $_.session_id -eq $currentSession })
        
        Write-DispatchLog "Reconciliando $($sessionDispatches.Count) dispatches de sesin: $currentSession" -Level 'INFO'

        $contexts = @()
        foreach ($d in $sessionDispatches) {
            $cf = Join-Path $dispatchContextDir "$($d.execution_id).json"
            if (Test-Path $cf) { $contexts += (Get-Content $cf -Raw | ConvertFrom-Json) }
        }

        $conflicts = Detect-ContextConflicts -Contexts $contexts
        $merged = Merge-Contexts -Contexts $contexts
        $staleness = @()
        $cutoff = (Get-Date).AddDays(-14)
        foreach ($d in $sessionDispatches) {
            try { if ([datetime]::Parse($d.timestamp) -lt $cutoff) { $staleness += $d } } catch {}
        }

        # Cross-session reconciliation
        $crossSessionMerged = $null
        if ($TargetSessionId -and $TargetSessionId -ne $currentSession) {
            $targetDispatches = @($registry.dispatches | Where-Object { $_.session_id -eq $TargetSessionId })
            $targetContexts = @()
            foreach ($d in $targetDispatches) {
                $cf = Join-Path $dispatchContextDir "$($d.execution_id).json"
                if (Test-Path $cf) { $targetContexts += (Get-Content $cf -Raw | ConvertFrom-Json) }
            }
            $crossSessionMerged = Merge-Contexts -Contexts $targetContexts
            Write-DispatchLog "Cross-session merge: $TargetSessionId -> $currentSession" -Level 'INFO'
        }

        # Save reconciliation artifact
        $reconFile = Join-Path $dispatchMemoryDir "reconciliation-$currentSession.json"
        $report = @{
            session_id = $currentSession
            target_session_id = $TargetSessionId
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
            total_dispatches = $sessionDispatches.Count
            conflict_count = $conflicts.Count
            conflicts = $conflicts
            staleness_count = $staleness.Count
            stale_dispatches = @($staleness | ForEach-Object { $_.execution_id })
            merged_keys = @($merged.Keys)
            has_cross_session = ($null -ne $crossSessionMerged)
            dry_run = $DryRun -eq $true
        }

        if (-not $DryRun) {
            $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reconFile -Encoding UTF8 -Force
            # Save merged context as session canonical context
            $sessionContextFile = Join-Path $dispatchMemoryDir "session-context-$currentSession.json"
            @{ session_id = $currentSession; merged = $merged; cross_session = $crossSessionMerged } | ConvertTo-Json -Depth 5 | Out-File -FilePath $sessionContextFile -Encoding UTF8 -Force
            Write-DispatchLog "Reconciliation saved to $reconFile" -Level 'SUCCESS'
        } else {
            Write-DispatchLog "Dry-run: no changes written" -Level 'INFO'
        }

        return $report
    } catch {
        Write-DispatchLog "Error al reconciliar memoria de dispatch: $_" -Level 'ERROR'
        return @{ error = $_.Exception.Message }
    }
}

function Invoke-Handoff {
    param(
        [string]$FromSessionId,
        [string]$ToSessionId
    )
    Initialize-MemoryStructure
    $registry = Get-DispatchRegistry
    $fromDispatches = @($registry.dispatches | Where-Object { $_.session_id -eq $FromSessionId })
    $toDispatches = @($registry.dispatches | Where-Object { $_.session_id -eq $ToSessionId })
    
    $fromContexts = @()
    foreach ($d in $fromDispatches) {
        $cf = Join-Path $dispatchContextDir "$($d.execution_id).json"
        if (Test-Path $cf) { $fromContexts += (Get-Content $cf -Raw | ConvertFrom-Json) }
    }
    $mergedFrom = Merge-Contexts -Contexts $fromContexts

    $handoffFile = Join-Path $dispatchMemoryDir "handoff-$FromSessionId-to-$ToSessionId.json"
    @{
        from_session = $FromSessionId
        to_session = $ToSessionId
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
        from_dispatch_count = $fromDispatches.Count
        to_dispatch_count = $toDispatches.Count
        context = $mergedFrom
    } | ConvertTo-Json -Depth 5 | Out-File -FilePath $handoffFile -Encoding UTF8 -Force
    Write-DispatchLog "Handoff: $FromSessionId -> $ToSessionId ($($fromDispatches.Count) dispatches)" -Level 'SUCCESS'
    return @{ handoff = $handoffFile; from = $FromSessionId; to = $ToSessionId; context_keys = @($mergedFrom.Keys) }
}

# Ejecutar accin solicitada
Initialize-MemoryStructure

$result = switch ($Action) {
    'save' {
        if ([string]::IsNullOrWhiteSpace($ExecutionId)) {
            Write-DispatchLog "ExecutionId requerido para accin 'save'" -Level 'ERROR'
            @{ error = 'ExecutionId required' }
        } else {
            $success = Save-DispatchMemory -ExecutionId $ExecutionId -Context $DispatchContext -SessionId $SessionId
            @{ success = $success; execution_id = $ExecutionId }
        }
    }
    'load' {
        Load-DispatchMemory -ExecutionId $ExecutionId -SessionId $SessionId
    }
    'list' {
        List-DispatchMemory -SessionId $SessionId
    }
    'clear' {
        Clear-DispatchMemory -ExecutionId $ExecutionId -SessionId $SessionId -Force:$Force
    }
    'sync' {
        Sync-DispatchMemory -SessionId $SessionId
    }
    'reconcile' {
        Sync-DispatchMemory -SessionId $SessionId -DryRun:$Force -TargetSessionId $Scope
    }
    'handoff' {
        if ([string]::IsNullOrWhiteSpace($ExecutionId) -or [string]::IsNullOrWhiteSpace($SessionId)) {
            @{ error = 'ExecutionId (from session) and SessionId (to session) required for handoff' }
        } else {
            Invoke-Handoff -FromSessionId $ExecutionId -ToSessionId $SessionId
        }
    }
    default {
        @{ error = "Accin no reconocida: $Action" }
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 10
} else {
    $result
}