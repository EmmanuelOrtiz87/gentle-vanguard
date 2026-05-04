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
    
    # Extract execution_id from payload for cross-event correlation
    $executionId = $null
    if ($PayloadJson) {
        try {
            $p = $PayloadJson | ConvertFrom-Json
            $executionId = if ($p.execution_id) { $p.execution_id } elseif ($p.lane_id) { $p.lane_id -replace '^agent-[A-Z]+-', 'dispatch-' } else { $null }
        } catch { }
    }

    $history = Get-History
    $entry = @{
        timestamp    = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
        event        = $EventName
        execution_id = $executionId
        payload      = if ($PayloadJson) { $PayloadJson } else { $null }
        status       = $Status
        handlers_triggered = 0
    }
    
    $history.events = @($entry) + $history.events | Select-Object -First $history.max_history
    $history | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $eventBusPath 'history.json') -Encoding UTF8
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

# ─── GOVERNANCE ENFORCEMENT ─────────────────────────────────────────────────
# Reads config/event-registry.json and config/event-governance-config.json.
# Returns @{ Allowed=$true/$false; Reason='...' }
function Invoke-EventGovernance {
    param(
        [string]$EventName,
        [string]$PayloadJson
    )

    $registryPath   = Join-Path $repoRoot 'config\event-registry.json'
    $governancePath = Join-Path $repoRoot 'config\event-governance-config.json'

    # 1. Load configs (fail-open: if configs missing, allow but warn)
    if (-not (Test-Path $registryPath) -or -not (Test-Path $governancePath)) {
        Write-Host "  [GOV-WARN] Governance config not found — skipping enforcement" -ForegroundColor Yellow
        return @{ Allowed = $true; Reason = 'config-missing' }
    }

    $registry   = Get-Content -Path $registryPath   -Raw | ConvertFrom-Json
    $governance = Get-Content -Path $governancePath -Raw | ConvertFrom-Json

    $eventDef = $registry.registry.PSObject.Properties[$EventName]

    # 2. Unknown event check
    if (-not $eventDef) {
        Write-Host "  [GOV-WARN] '$EventName' is not in event-registry.json — proceeding unvalidated" -ForegroundColor Yellow
        return @{ Allowed = $true; Reason = 'unregistered-event' }
    }

    # 3. Enabled check
    if ($eventDef.Value.enabled -eq $false) {
        return @{ Allowed = $false; Reason = "Event '$EventName' is disabled in registry" }
    }

    # 4. Payload size check (max_bytes = 10240)
    $maxBytes = $governance.governance.security.policies.size_limit.max_bytes
    if (-not $maxBytes) { $maxBytes = 10240 }
    if ($PayloadJson) {
        $payloadBytes = [System.Text.Encoding]::UTF8.GetByteCount($PayloadJson)
        if ($payloadBytes -gt $maxBytes) {
            return @{ Allowed = $false; Reason = "Payload size $payloadBytes bytes exceeds max $maxBytes bytes" }
        }
        # Soft warning at 80%
        if ($payloadBytes -gt ($maxBytes * 0.8)) {
            Write-Host "  [GOV-WARN] Payload $payloadBytes / $maxBytes bytes (>80% limit)" -ForegroundColor Yellow
        }
    }

    # 5. Required fields schema check
    $requiredFields = $eventDef.Value.schema.required
    if ($requiredFields -and $PayloadJson) {
        try {
            $payload = $PayloadJson | ConvertFrom-Json
            foreach ($field in $requiredFields) {
                if ($null -eq $payload.PSObject.Properties[$field]) {
                    return @{ Allowed = $false; Reason = "Schema validation failed: required field '$field' missing in payload" }
                }
            }
        } catch {
            return @{ Allowed = $false; Reason = "Payload is not valid JSON: $($_.Exception.Message)" }
        }
    }

    # 6. Rate limit check (sliding window — count events in last 60s from history)
    $rateLimitEnabled = $governance.governance.rate_limiting.enabled
    if ($rateLimitEnabled) {
        $rateLimit = $eventDef.Value.rate_limit
        if ($rateLimit -and $rateLimit.max_per_minute) {
            $history = Get-History
            $windowStart = (Get-Date).AddSeconds(-60)
            $recentCount = 0
            if ($history.events) {
                foreach ($entry in $history.events) {
                    if ($entry.event -eq $EventName) {
                        try {
                            $ts = [datetime]::Parse($entry.timestamp)
                            if ($ts -ge $windowStart) { $recentCount++ }
                        } catch { }
                    }
                }
            }
            $maxPerMin = $rateLimit.max_per_minute
            $softLimit = [math]::Floor($maxPerMin * 0.8)
            if ($recentCount -ge $maxPerMin) {
                return @{ Allowed = $false; Reason = "Rate limit exceeded: $recentCount/$maxPerMin per minute for '$EventName'" }
            }
            if ($recentCount -ge $softLimit) {
                Write-Host "  [GOV-WARN] Rate limit approaching: $recentCount/$maxPerMin for '$EventName'" -ForegroundColor Yellow
            }
        }
    }

    return @{ Allowed = $true; Reason = 'ok' }
}
# ─────────────────────────────────────────────────────────────────────────────

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
        
        $resolvedHandlerPath = Resolve-HandlerScriptPath -Path $HandlerScript
        if ($HandlerScript -and -not $resolvedHandlerPath) {
            Write-Host "[ERROR] Handler script must exist inside repository root: $repoRoot" -ForegroundColor Red
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
            $count = @(Get-EventHandlers -Subscriptions $subs -EventName $normalizedEvent).Count
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
                                Write-Host "    [WARN] Skipping invalid handler path: $($handler.script)" -ForegroundColor Yellow
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
                foreach ($handler in (Get-EventHandlers -Subscriptions $subs -EventName $normalizedEvent)) {
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
    
    'emit' {
        if ([string]::IsNullOrWhiteSpace($Event)) {
            Write-Host "[ERROR] Event name required" -ForegroundColor Red
            exit 1
        }
        
        $normalizedEvent = $Event.ToLower()

        # ── Governance gate ──────────────────────────────────────────────────
        $govResult = Invoke-EventGovernance -EventName $normalizedEvent -PayloadJson $Payload
        if (-not $govResult.Allowed) {
            Write-Host "[GOV-BLOCK] Event '$normalizedEvent' blocked: $($govResult.Reason)" -ForegroundColor Red
            Add-HistoryEntry -EventName $normalizedEvent -PayloadJson $Payload -Status "blocked:$($govResult.Reason)"
            exit 1
        }
        # ─────────────────────────────────────────────────────────────────────

        $subs = Get-Subscriptions
        
        Write-Host "Emitting: $normalizedEvent" -ForegroundColor Cyan
        if ($Payload) {
            Write-Host "  Payload: $Payload" -ForegroundColor Gray
        }
        
        $handlersTriggered = 0
    Write-Host "  .\wf.ps1 events emit <EVENT> [P]  Emit event with optional payload"
    Write-Host "  .\wf.ps1 events handlers [EVENT]  List handlers"
    Write-Host "  .\wf.ps1 events history           Show event history"
    Write-Host "  .\wf.ps1 events clear             Clear event history"
}
