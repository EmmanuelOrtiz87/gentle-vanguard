# dispatch-memory-manager.ps1
# Gestor de memoria persistente para dispatch-agent
# Integra Engram con el sistema de dispatch para mantener contexto entre ejecuciones

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('save', 'load', 'list', 'clear', 'sync')]
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

function Sync-DispatchMemory {
    param(
        [string]$SessionId = ''
    )
    
    Initialize-MemoryStructure
    
    try {
        $registry = Get-DispatchRegistry
        $currentSession = if ([string]::IsNullOrWhiteSpace($SessionId)) { $env:WFS_SESSION_ID } else { $SessionId }
        
        $sessionDispatches = @($registry.dispatches | Where-Object { $_.session_id -eq $currentSession })
        
        Write-DispatchLog "Sincronizando $($sessionDispatches.Count) dispatches de sesin: $currentSession" -Level 'INFO'
        
        $syncReport = @{
            session_id = $currentSession
            total_dispatches = $sessionDispatches.Count
            synced_at = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
            dispatches = $sessionDispatches
        }
        
        return $syncReport
    } catch {
        Write-DispatchLog "Error al sincronizar memoria de dispatch: $_" -Level 'ERROR'
        return @{ error = $_.Exception.Message }
    }
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
    default {
        @{ error = "Accin no reconocida: $Action" }
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 10
} else {
    $result
}