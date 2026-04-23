<#
.SYNOPSIS
    Enhanced Event Bus - Integrates governance, validation, and audit capabilities
    
.DESCRIPTION
    Improved event bus with schema validation, security policies, rate limiting, and audit trails.
    Automatically enforces governance policies through the governance layer.
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('list', 'subscribe', 'unsubscribe', 'emit', 'handlers', 'clear', 'history', 'governance-status')]
    [string]$Action = 'list',
    
    [Parameter(Mandatory=$false)]
    [string]$Event = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Payload = '',
    
    [Parameter(Mandatory=$false)]
    [string]$HandlerScript = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Actor = 'unknown',
    
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$eventBusPath = Join-Path $repoRoot '.event-bus'
$governanceLayerScript = Join-Path $scriptDir 'event-governance-layer.ps1'

function Initialize-EventBus {
    if (-not (Test-Path $eventBusPath)) {
        New-Item -ItemType Directory -Path $eventBusPath -Force | Out-Null
    }
    
    $subscriptionsPath = Join-Path $eventBusPath 'subscriptions.json'
    $historyPath = Join-Path $eventBusPath 'history.json'
    
    if (-not (Test-Path $subscriptionsPath)) {
        @{
            version = '2.0'
            subscriptions = @{}
            created = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $subscriptionsPath -Encoding UTF8
    }
    
    if (-not (Test-Path $historyPath)) {
        @{
            version = '2.0'
            events = @()
            max_history = 100
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $historyPath -Encoding UTF8
    }
    
    & $governanceLayerScript -Action initialize -Quiet
}

function Get-Subscriptions {
    $subscriptionsPath = Join-Path $eventBusPath 'subscriptions.json'
    if (Test-Path $subscriptionsPath) {
        return (Get-Content -Path $subscriptionsPath -Raw | ConvertFrom-Json)
    }
    return $null
}

function Set-Subscriptions {
    param([object]$Data)
    $subscriptionsPath = Join-Path $eventBusPath 'subscriptions.json'
    $Data | ConvertTo-Json -Depth 3 | Out-File -FilePath $subscriptionsPath -Encoding UTF8
}

function Get-History {
    $historyPath = Join-Path $eventBusPath 'history.json'
    if (Test-Path $historyPath) {
        return (Get-Content -Path $historyPath -Raw | ConvertFrom-Json)
    }
    return $null
}

function Add-HistoryEntry {
    param(
        [string]$EventName,
        [string]$PayloadJson,
        [string]$Status,
        [string]$ActorName
    )
    
    $history = Get-History
    $entry = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
        event = $EventName
        payload = if ($PayloadJson) { $PayloadJson } else { $null }
        status = $Status
        actor = $ActorName
        handlers_triggered = 0
    }
    
    $history.events = @($entry) + $history.events | Select-Object -First $history.max_history
    $history | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $eventBusPath 'history.json') -Encoding UTF8
}

function Resolve-HandlerScriptPath {
    param([string]$Path)
    
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -eq 'default-logger') {
        return $null
    }
    
    $candidate = if ([IO.Path]::IsPathRooted($Path)) {
        $Path
    } else {
        Join-Path $repoRoot $Path
    }
    
    $resolved = Resolve-Path -Path $candidate -ErrorAction SilentlyContinue
    if (-not $resolved) {
        return $null
    }
    
    $resolvedPath = $resolved.Path
    if (-not $resolvedPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }
    
    return $resolvedPath
}

function Get-EventHandlers {
    param(
        [object]$Subscriptions,
        [string]$EventName
    )
    
    if (-not $Subscriptions -or [string]::IsNullOrWhiteSpace($EventName)) {
        return @()
    }
    
    $property = $Subscriptions.subscriptions.PSObject.Properties[$EventName]
    if (-not $property) {
        return @()
    }
    
    return @($property.Value)
}

$STANDARD_EVENTS = @{
    'dispatch.started' = @{ description = 'Disparado cuando comienza el dispatch paralelo'; category = 'orchestration' }
    'dispatch.completed' = @{ description = 'Disparado cuando finaliza el dispatch paralelo'; category = 'orchestration' }
    'agent.dispatched' = @{ description = 'Disparado cuando se despacha un agente'; category = 'agent' }
    'agent.completed' = @{ description = 'Disparado cuando un agente se completa'; category = 'agent' }
    'session.started' = @{ description = 'Disparado cuando comienza una sesión'; category = 'session' }
    'session.ended' = @{ description = 'Disparado cuando finaliza una sesión'; category = 'session' }
    'security.violation' = @{ description = 'Disparado cuando se viola una política de seguridad'; category = 'security' }
    'audit.event' = @{ description = 'Disparado para registro de auditoría'; category = 'audit' }
}

Initialize-EventBus

switch ($Action) {
    'list' {
        Write-Host "`n=== EVENT BUS MEJORADO - EVENTOS ESTÁNDAR ===" -ForegroundColor Cyan
        Write-Host "Ubicación: $eventBusPath" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Eventos Estándar:" -ForegroundColor Yellow
        foreach ($evt in ($STANDARD_EVENTS.GetEnumerator() | Sort-Object Key)) {
            Write-Host "  $($evt.Key)" -ForegroundColor Green
            Write-Host "    $($evt.Value.description)" -ForegroundColor Gray
        }
        
        $subs = Get-Subscriptions
        $subCount = if ($subs.subscriptions.PSObject.Properties.Count) { $subs.subscriptions.PSObject.Properties.Count } else { 0 }
        
        Write-Host ""
        Write-Host "Suscripciones Activas: $subCount" -ForegroundColor White
        
        $history = Get-History
        $eventCount = if ($history.events) { $history.events.Count } else { 0 }
        Write-Host "Historial de Eventos: $eventCount entradas" -ForegroundColor White
        Write-Host ""
        Write-Host "Governance: HABILITADO" -ForegroundColor Green
        Write-Host "  - Validación de esquemas: SÍ" -ForegroundColor Green
        Write-Host "  - Políticas de seguridad: SÍ" -ForegroundColor Green
        Write-Host "  - Rate limiting: SÍ" -ForegroundColor Green
        Write-Host "  - Auditoría completa: SÍ" -ForegroundColor Green
    }
    
    'subscribe' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Nombre de evento requerido" -ForegroundColor Red
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()
        
        if (-not ($STANDARD_EVENTS.Keys -contains $normalizedEvent)) {
            Write-Host "[WARN] '$normalizedEvent' no es un evento estándar" -ForegroundColor Yellow
        }
        
        $subs = Get-Subscriptions
        $handlerId = "handler-$((Get-Date -Format 'yyyyMMdd-HHmmss'))"
        
        $resolvedHandlerPath = Resolve-HandlerScriptPath -Path $HandlerScript
        if ($HandlerScript -and -not $resolvedHandlerPath) {
            Write-Host "[ERROR] El script debe estar dentro del repositorio" -ForegroundColor Red
            exit 1
        }

        $newHandler = @{
            id = $handlerId
            script = if ($resolvedHandlerPath) { $resolvedHandlerPath } else { 'default-logger' }
            subscribed_at = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
            active = $true
        }
        
        if (-not $subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
            $subs.subscriptions | Add-Member -NotePropertyName $normalizedEvent -NotePropertyValue @()
        }
        
        $handlers = @(Get-EventHandlers -Subscriptions $subs -EventName $normalizedEvent) + @($newHandler)
        $subs.subscriptions.PSObject.Properties[$normalizedEvent].Value = $handlers
        
        Set-Subscriptions -Data $subs
        
        Write-Host "[OK] Suscrito handler $handlerId a '$normalizedEvent'" -ForegroundColor Green
        Write-Host "    Script: $($newHandler.script)" -ForegroundColor Gray
    }
    
    'unsubscribe' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Nombre de evento requerido" -ForegroundColor Red
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()
        $subs = Get-Subscriptions
        
        if ($subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
            $count = @(Get-EventHandlers -Subscriptions $subs -EventName $normalizedEvent).Count
            $subs.subscriptions.PSObject.Properties.Remove($normalizedEvent)
            Set-Subscriptions -Data $subs
            Write-Host "[OK] Desuscrito $count handlers de '$normalizedEvent'" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Sin handlers suscritos a '$normalizedEvent'" -ForegroundColor Gray
        }
    }
    
    'emit' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Nombre de evento requerido" -ForegroundColor Red
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()
        
        # Governance validation
        $validationResult = & $governanceLayerScript -Action validate -EventName $normalizedEvent -Payload $Payload -Actor $Actor -ActionType 'emit'
        
        if (-not $validationResult.valid) {
            Write-Host "[BLOCKED] Emisión bloqueada por governance:" -ForegroundColor Red
            $validationResult.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            Add-HistoryEntry -EventName $normalizedEvent -PayloadJson $Payload -Status 'blocked' -ActorName $Actor
            exit 1
        }
        
        $subs = Get-Subscriptions
        
        Write-Host "Emitiendo: $normalizedEvent" -ForegroundColor Cyan
        if ($Payload) {
            Write-Host "  Payload: $Payload" -ForegroundColor Gray
        }
        
        $handlersTriggered = 0
        
        if ($subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
            foreach ($handler in (Get-EventHandlers -Subscriptions $subs -EventName $normalizedEvent)) {
                if ($handler.active) {
                    Write-Host "  [HANDLER] $($handler.id): $($handler.script)" -ForegroundColor Green
                    $handlersTriggered++
                    
                    if ($handler.script -ne 'default-logger') {
                        try {
                            $handlerPath = Resolve-HandlerScriptPath -Path $handler.script
                            if ($handlerPath) {
                                & $handlerPath -Event $normalizedEvent -Payload $Payload
                            } else {
                                Write-Host "    [WARN] Ruta de handler inválida: $($handler.script)" -ForegroundColor Yellow
                            }
                        } catch {
                            Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
            }
        }
        
        Add-HistoryEntry -EventName $normalizedEvent -PayloadJson $Payload -Status 'emitted' -ActorName $Actor
        Write-Host "[OK] Evento emitido. Handlers disparados: $handlersTriggered" -ForegroundColor Green
    }
    
    'handlers' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            $subs = Get-Subscriptions
            Write-Host "`n=== TODOS LOS HANDLERS SUSCRITOS ===" -ForegroundColor Cyan
            
            foreach ($prop in $subs.subscriptions.PSObject.Properties) {
                Write-Host "`n$($prop.Name):" -ForegroundColor Yellow
                foreach ($handler in $prop.Value) {
                    $status = if ($handler.active) { '[ACTIVO]' } else { '[INACTIVO]' }
                    Write-Host "  $status $($handler.id)" -ForegroundColor $(if ($handler.active) { 'Green' } else { 'Gray' })
                    Write-Host "       Script: $($handler.script)" -ForegroundColor DarkGray
                    Write-Host "       Desde: $($handler.subscribed_at)" -ForegroundColor DarkGray
                }
            }
        } else {
            $normalizedEvent = $Event.ToLower()
            $subs = Get-Subscriptions
            
            if ($subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
                Write-Host "`nHandlers para '$normalizedEvent':" -ForegroundColor Yellow
                foreach ($handler in (Get-EventHandlers -Subscriptions $subs -EventName $normalizedEvent)) {
                    Write-Host "  $($handler.id): $($handler.script)" -ForegroundColor Green
                }
            } else {
                Write-Host "[INFO] Sin handlers para '$normalizedEvent'" -ForegroundColor Gray
            }
        }
    }
    
    'history' {
        $history = Get-History
        Write-Host "`n=== HISTORIAL DE EVENTOS (últimos $($history.events.Count)) ===" -ForegroundColor Cyan
        
        foreach ($entry in $history.events | Select-Object -First 20) {
            $statusColor = switch ($entry.status) {
                'emitted' { 'Green' }
                'blocked' { 'Red' }
                'error' { 'Red' }
                default { 'Gray' }
            }
            
            Write-Host "$($entry.timestamp) [$($entry.status)] $($entry.event) (actor: $($entry.actor))" -ForegroundColor $statusColor
            if ($entry.payload) {
                Write-Host "  Payload: $($entry.payload)" -ForegroundColor DarkGray
            }
        }
    }
    
    'clear' {
        $historyPath = Join-Path $eventBusPath 'history.json'
        $history = Get-History
        $history.events = @()
        $history | ConvertTo-Json -Depth 3 | Out-File -FilePath $historyPath -Encoding UTF8
        Write-Host "[OK] Historial de eventos limpiado" -ForegroundColor Green
    }
    
    'governance-status' {
        & $governanceLayerScript -Action report
    }
}

if ($Action -eq 'list' -and -not $Quiet) {
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  .\event-bus-enhanced.ps1 list                      Listar eventos y suscripciones" -ForegroundColor Gray
    Write-Host "  .\event-bus-enhanced.ps1 subscribe <EVENT>         Suscribirse a evento" -ForegroundColor Gray
    Write-Host "  .\event-bus-enhanced.ps1 emit <EVENT> [PAYLOAD]   Emitir evento" -ForegroundColor Gray
    Write-Host "  .\event-bus-enhanced.ps1 handlers [EVENT]          Listar handlers" -ForegroundColor Gray
    Write-Host "  .\event-bus-enhanced.ps1 history                   Mostrar historial" -ForegroundColor Gray
    Write-Host "  .\event-bus-enhanced.ps1 governance-status         Estado de governance" -ForegroundColor Gray
    Write-Host ""
}