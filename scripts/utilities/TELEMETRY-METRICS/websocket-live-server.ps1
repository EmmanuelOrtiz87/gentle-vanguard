<#
.SYNOPSIS
    Lightweight HTTP Server for live dashboard with Server-Sent Events (SSE).

.DESCRIPTION
    Provides real-time push updates to dashboard HTML clients using Server-Sent Events.
    Replaces HTTP meta-refresh with true push notifications.
    
    Endpoints:
    - GET /dashboard.html  → Serves HTML with SSE client
    - GET /events         → SSE stream (push updates)
    - POST /update        → Receive new snapshot data
    - GET /health         → Server status

.PARAMETER Port
    HTTP server port. Default: 8090

.PARAMETER DashboardPath
    Path to dashboard.html artifact. Default: ./reports/dashboard.html

.PARAMETER SnapshotPath
    Path to latest snapshot JSON. Default: ./reports/stack-live-observability-latest.json

.PARAMETER RefreshInterval
    Interval (ms) to poll for new snapshot data. Default: 5000 (5 seconds)

.EXAMPLE
    .\\websocket-live-server.ps1 -Port 8090 -DashboardPath ./reports/dashboard.html
#>

param(
    [int]$Port = 8090,
    [string]$DashboardPath = './reports/dashboard.html',
    [string]$SnapshotPath = './reports/stack-live-observability-latest.json',
    [int]$RefreshInterval = 5000
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

$DashboardPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DashboardPath)
$SnapshotPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SnapshotPath)

if (-not (Test-Path $DashboardPath)) {
    throw "Dashboard not found: $DashboardPath"
}

# Global state
$lastSnapshotData = @{}
$lastSnapshotHash = ''
$clients = New-Object System.Collections.Concurrent.ConcurrentBag[System.Net.HttpListenerResponse]

function Get-MapValue {
    param(
        $Map,
        [string[]]$Path,
        $Default = $null
    )

    $cursor = $Map
    foreach ($part in $Path) {
        if ($null -eq $cursor) { return $Default }
        if ($cursor -is [System.Collections.IDictionary]) {
            if (-not $cursor.Contains($part)) { return $Default }
            $cursor = $cursor[$part]
            continue
        }
        if ($cursor.PSObject.Properties.Name -contains $part) {
            $cursor = $cursor.$part
            continue
        }
        return $Default
    }
    if ($null -eq $cursor) { return $Default }
    return $cursor
}

function Get-SnapshotData {
    if (-not (Test-Path $SnapshotPath)) {
        return @{}
    }
    try {
        return Get-Content $SnapshotPath -Raw | ConvertFrom-Json -AsHashtable
    } catch {
        return @{}
    }
}

function Get-SnapshotHash {
    param([hashtable]$Data)
    $json = $Data | ConvertTo-Json -Depth 5
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hash.ComputeHash($bytes)
    return ([BitConverter]::ToString($hashBytes) -replace '-').Substring(0, 16)
}

# HTML snippet for SSE client
$sseClientScript = @'
<script>
if (window.EventSource) {
    const eventSource = new EventSource('/events');
    
    eventSource.onmessage = function(event) {
        try {
            const data = JSON.parse(event.data);
            console.log('[DASHBOARD-SSE] Update received:', data);
            
            // Update timestamp
            const timestamp = document.getElementById('live-timestamp');
            if (timestamp) {
                timestamp.textContent = new Date().toLocaleTimeString();
            }
            
            // Update metrics
            if (data.metrics) {
                for (const [key, value] of Object.entries(data.metrics)) {
                    const card = document.querySelector('[data-live-key="' + key + '"]');
                    if (card) {
                        const valueElem = card.querySelector('.value');
                        if (valueElem) {
                            valueElem.textContent = value;
                        }
                    }
                }
            }
            
        } catch (e) {
            console.error('[DASHBOARD-SSE] Parse error:', e);
        }
    };
    
    eventSource.onerror = function() {
        console.warn('[DASHBOARD-SSE] Connection error, waiting for automatic reconnect...');
    };
    
    console.log('[DASHBOARD-SSE] Connected to /events stream');
} else {
    console.warn('[DASHBOARD-SSE] EventSource not supported, falling back to polling');
    setInterval(function() {
        location.reload();
    }, 15000);
}
</script>
'@

# HTTP Handler
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "=== LIVE DASHBOARD SERVER ===" -ForegroundColor Cyan
    Write-Host "Listening on: http://localhost:$Port" -ForegroundColor Green
    Write-Host "Dashboard:    http://localhost:$Port/dashboard.html" -ForegroundColor Green
    Write-Host "SSE Stream:   http://localhost:$Port/events" -ForegroundColor Green
    Write-Host "Health:       http://localhost:$Port/health" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $response.ContentType = 'text/plain; charset=utf-8'
            
            switch ($request.RawUrl) {
                '/dashboard.html' {
                    $dashboardHtml = Get-Content $DashboardPath -Raw
                    $dashboardHtml = [regex]::Replace($dashboardHtml, '<meta\s+http-equiv=`?"refresh`?"[^>]*>', '', 'IgnoreCase')
                    $enhancedHtml = $dashboardHtml -replace '</body>', "$sseClientScript`n</body>"
                    $response.ContentType = 'text/html; charset=utf-8'
                    $data = [System.Text.Encoding]::UTF8.GetBytes($enhancedHtml)
                    $response.OutputStream.Write($data, 0, $data.Length)
                    $response.StatusCode = 200
                    Write-Host "[OK] GET /dashboard.html" -ForegroundColor Gray
                }
                
                '/events' {
                    $response.ContentType = 'text/event-stream'
                    $response.Headers['Cache-Control'] = 'no-cache'
                    $response.StatusCode = 200

                    Write-Host "[OK] SSE /events connected" -ForegroundColor Gray

                    $snapshot = Get-SnapshotData
                    $hash = Get-SnapshotHash $snapshot
                    $lastSnapshotHash = $hash
                    $payload = @{
                        timestamp     = Get-Date -Format 'o'
                        retry_ms      = $RefreshInterval
                        metrics       = @{
                            traffic_light    = [string](Get-MapValue -Map $snapshot -Path @('executive_traffic_light') -Default 'GREEN')
                            token_status     = [string](Get-MapValue -Map $snapshot -Path @('token', 'status') -Default 'OK')
                            events_5m        = [string](Get-MapValue -Map $snapshot -Path @('events', 'last_5m') -Default 0)
                            routing_accuracy = [string](Get-MapValue -Map $snapshot -Path @('routing', 'accuracy') -Default 'N/A')
                        }
                    }

                    $sseMessage = "retry: $RefreshInterval`n" + "data: " + ($payload | ConvertTo-Json -Depth 5) + "`n`n"
                    $sseBytes = [System.Text.Encoding]::UTF8.GetBytes($sseMessage)
                    $response.OutputStream.Write($sseBytes, 0, $sseBytes.Length)
                    $response.OutputStream.Flush()

                    Write-Host "[INFO] SSE /events closed" -ForegroundColor Gray
                }
                
                '/health' {
                    $response.ContentType = 'application/json'
                    $health = @{
                        status    = 'OK'
                        timestamp = Get-Date -Format 'o'
                        uptime_sec = [System.Environment]::TickCount / 1000
                        dashboard = if (Test-Path $DashboardPath) { 'available' } else { 'missing' }
                    }
                    $data = [System.Text.Encoding]::UTF8.GetBytes(($health | ConvertTo-Json))
                    $response.OutputStream.Write($data, 0, $data.Length)
                    $response.StatusCode = 200
                }
                
                default {
                    $response.StatusCode = 404
                    $data = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                    $response.OutputStream.Write($data, 0, $data.Length)
                }
            }
            
            $response.OutputStream.Close()
        } catch {
            Write-Host "[ERROR] Handler: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "[ERROR] Server failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
}
