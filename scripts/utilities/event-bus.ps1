param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('list', 'subscribe', 'unsubscribe', 'emit', 'handlers', 'clear', 'history')]
    [string]$Action = 'list',
    
    [Parameter(Mandatory=$false)]
    [string]$Event = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Payload = '',
    
    [Parameter(Mandatory=$false)]
    [string]$HandlerScript = '',
    
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$eventBusPath = Join-Path $repoRoot '.event-bus'

function Initialize-EventBus {
    if (-not (Test-Path $eventBusPath)) {
        New-Item -ItemType Directory -Path $eventBusPath -Force | Out-Null
    }
    $subscriptionsPath = Join-Path $eventBusPath 'subscriptions.json'
    $historyPath = Join-Path $eventBusPath 'history.json'
    
    if (-not (Test-Path $subscriptionsPath)) {
        @{
            version = '1.0'
            subscriptions = @{}
            created = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $subscriptionsPath -Encoding UTF8
    }
    
    if (-not (Test-Path $historyPath)) {
        @{
            version = '1.0'
            events = @()
            max_history = 100
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath $historyPath -Encoding UTF8
    }
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
        [string]$Status
    )
    
    $history = Get-History
    $entry = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
        event = $EventName
        payload = if ($PayloadJson) { $PayloadJson } else { $null }
        status = $Status
        handlers_triggered = 0
    }
    
    $history.events = @($entry) + $history.events | Select-Object -First $history.max_history
    $history | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $eventBusPath 'history.json') -Encoding UTF8
}

$STANDARD_EVENTS = @{
    'dispatch.started' = @{
        description = 'Fired when parallel dispatch begins'
        payload_schema = '@{ execution_id; mode; agents[] }'
        example = '{"execution_id":"dispatch-20260415", "mode":"parallel", "agents":["DEV","QA"]}'
    }
    'dispatch.completed' = @{
        description = 'Fired when parallel dispatch finishes'
        payload_schema = '@{ execution_id; results_count }'
        example = '{"execution_id":"dispatch-20260415", "results_count":3}'
    }
    'agent.dispatched' = @{
        description = 'Fired when single agent is dispatched'
        payload_schema = '@{ agent; task; lane_id }'
        example = '{"agent":"DEV", "task":"implement auth", "lane_id":"agent-DEV-1"}'
    }
    'agent.completed' = @{
        description = 'Fired when single agent completes'
        payload_schema = '@{ agent; status; token_estimate }'
        example = '{"agent":"DEV", "status":"ready", "token_estimate":4500}'
    }
    'session.started' = @{
        description = 'Fired when session begins'
        payload_schema = '@{ session_id; project }'
        example = '{"session_id":"session-20260415", "project":"myapp"}'
    }
    'session.ended' = @{
        description = 'Fired when session closes'
        payload_schema = '@{ session_id; duration_minutes; tokens_used }'
        example = '{"session_id":"session-20260415", "duration_minutes":45, "tokens_used":12000}'
    }
    'workflow.checkpoint' = @{
        description = 'Fired on workflow checkpoint creation'
        payload_schema = '@{ checkpoint_label; branch }'
        example = '{"checkpoint_label":"feature-auth", "branch":"main"}'
    }
    'workflow.publish' = @{
        description = 'Fired on publish/commit action'
        payload_schema = '@{ action; branch; files_changed }'
        example = '{"action":"commit", "branch":"feature-auth", "files_changed":5}'
    }
    'validation.started' = @{
        description = 'Fired when validation begins'
        payload_schema = '@{ validation_type; scope }'
        example = '{"validation_type":"gitflow", "scope":"pr"}'
    }
    'validation.completed' = @{
        description = 'Fired when validation completes'
        payload_schema = '@{ validation_type; passed; findings_count }'
        example = '{"validation_type":"gitflow", "passed":true, "findings_count":0}'
    }
}

Initialize-EventBus

switch ($Action) {
    'list' {
        Write-Host "`n=== EVENT BUS - STANDARD EVENTS ===" -ForegroundColor Cyan
        Write-Host "Location: $eventBusPath" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Standard Events:" -ForegroundColor Yellow
        foreach ($evt in ($STANDARD_EVENTS.GetEnumerator() | Sort-Object Key)) {
            Write-Host "  $($evt.Key)" -ForegroundColor Green
            Write-Host "    $($evt.Value.description)" -ForegroundColor Gray
        }
        
        $subs = Get-Subscriptions
        $subCount = if ($subs.subscriptions.PSObject.Properties.Count) { $subs.subscriptions.PSObject.Properties.Count } else { 0 }
        
        Write-Host ""
        Write-Host "Active Subscriptions: $subCount" -ForegroundColor White
        
        $history = Get-History
        $eventCount = if ($history.events) { $history.events.Count } else { 0 }
        Write-Host "Event History: $eventCount entries" -ForegroundColor White
    }
    
    'subscribe' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Event name required for subscribe" -ForegroundColor Red
            Write-Host "Usage: .\wf.ps1 events subscribe <EVENT> [HANDLER_SCRIPT]" -ForegroundColor Yellow
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()
        
        if (-not ($STANDARD_EVENTS.Keys -contains $normalizedEvent)) {
            Write-Host "[WARN] '$normalizedEvent' is not a standard event" -ForegroundColor Yellow
            Write-Host "Standard events: $($STANDARD_EVENTS.Keys -join ', ')" -ForegroundColor Gray
        }
        
        $subs = Get-Subscriptions
        $handlerId = "handler-$((Get-Date -Format 'yyyyMMdd-HHmmss'))"
        
        $newHandler = @{
            id = $handlerId
            script = if ($HandlerScript) { $HandlerScript } else { 'default-logger' }
            subscribed_at = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
            active = $true
        }
        
        if (-not $subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
            $subs.subscriptions | Add-Member -NotePropertyName $normalizedEvent -NotePropertyValue @()
        }
        
        $handlers = @($subs.subscriptions.$normalizedEvent) + @($newHandler)
        $subs.subscriptions.$normalizedEvent = $handlers
        
        Set-Subscriptions -Data $subs
        
        Write-Host "[OK] Subscribed handler $handlerId to '$normalizedEvent'" -ForegroundColor Green
        Write-Host "    Script: $($newHandler.script)" -ForegroundColor Gray
    }
    
    'unsubscribe' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Event name required" -ForegroundColor Red
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()
        $subs = Get-Subscriptions
        
        if ($subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
            $count = @($subs.subscriptions.$normalizedEvent).Count
            $subs.subscriptions.PSObject.Properties.Remove($normalizedEvent)
            Set-Subscriptions -Data $subs
            Write-Host "[OK] Unsubscribed $count handlers from '$normalizedEvent'" -ForegroundColor Green
        } else {
            Write-Host "[INFO] No handlers subscribed to '$normalizedEvent'" -ForegroundColor Gray
        }
    }
    
    'emit' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Event name required" -ForegroundColor Red
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()
        $subs = Get-Subscriptions
        
        Write-Host "Emitting: $normalizedEvent" -ForegroundColor Cyan
        if ($Payload) {
            Write-Host "  Payload: $Payload" -ForegroundColor Gray
        }
        
        $handlersTriggered = 0
        
        if ($subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
            foreach ($handler in $subs.subscriptions.$normalizedEvent) {
                if ($handler.active) {
                    Write-Host "  [HANDLER] $($handler.id): $($handler.script)" -ForegroundColor Green
                    $handlersTriggered++
                    
                    if ($handler.script -ne 'default-logger') {
                        try {
                            if (Test-Path $handler.script) {
                                Invoke-Expression "& '$($handler.script)' -Event '$normalizedEvent' -Payload '$Payload'"
                            }
                        } catch {
                            Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
            }
        }
        
        Add-HistoryEntry -EventName $normalizedEvent -PayloadJson $Payload -Status 'emitted'
        Write-Host "[OK] Event emitted. Handlers triggered: $handlersTriggered" -ForegroundColor Green
    }
    
    'handlers' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            $subs = Get-Subscriptions
            Write-Host "`n=== ALL SUBSCRIBED HANDLERS ===" -ForegroundColor Cyan
            
            foreach ($prop in $subs.subscriptions.PSObject.Properties) {
                Write-Host "`n$($prop.Name):" -ForegroundColor Yellow
                foreach ($handler in $prop.Value) {
                    $status = if ($handler.active) { '[ACTIVE]' } else { '[INACTIVE]' }
                    Write-Host "  $status $($handler.id)" -ForegroundColor $(if ($handler.active) { 'Green' } else { 'Gray' })
                    Write-Host "       Script: $($handler.script)" -ForegroundColor DarkGray
                    Write-Host "       Since: $($handler.subscribed_at)" -ForegroundColor DarkGray
                }
            }
        } else {
            $normalizedEvent = $Event.ToLower()
            $subs = Get-Subscriptions
            
            if ($subs.subscriptions.PSObject.Properties[$normalizedEvent]) {
                Write-Host "`nHandlers for '$normalizedEvent':" -ForegroundColor Yellow
                foreach ($handler in $subs.subscriptions.$normalizedEvent) {
                    Write-Host "  $($handler.id): $($handler.script)" -ForegroundColor Green
                }
            } else {
                Write-Host "[INFO] No handlers for '$normalizedEvent'" -ForegroundColor Gray
            }
        }
    }
    
    'history' {
        $history = Get-History
        Write-Host "`n=== EVENT HISTORY (last $($history.events.Count)) ===" -ForegroundColor Cyan
        
        foreach ($entry in $history.events | Select-Object -First 20) {
            $statusColor = switch ($entry.status) {
                'emitted' { 'Green' }
                'error' { 'Red' }
                default { 'Gray' }
            }
            
            Write-Host "$($entry.timestamp) [$($entry.status)] $($entry.event)" -ForegroundColor $statusColor
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
        Write-Host "[OK] Event history cleared" -ForegroundColor Green
    }
}

if ($Action -eq 'list' -and -not $Quiet) {
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\wf.ps1 events list              List events and subscriptions"
    Write-Host "  .\wf.ps1 events subscribe <EVENT>  Subscribe to event"
    Write-Host "  .\wf.ps1 events unsubscribe <EV>   Unsubscribe from event"
    Write-Host "  .\wf.ps1 events emit <EVENT> [P]  Emit event with optional payload"
    Write-Host "  .\wf.ps1 events handlers [EVENT]  List handlers"
    Write-Host "  .\wf.ps1 events history           Show event history"
    Write-Host "  .\wf.ps1 events clear             Clear event history"
}
