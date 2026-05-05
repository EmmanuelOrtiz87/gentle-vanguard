<#
.SYNOPSIS
    Message Queue adapter for the Gentleman Foundation event bus.

.DESCRIPTION
    Provides a real MQ backend for team environments. Supports three adapters:
    - file   : default file-based (existing .event-bus/history.json) — no extra deps
    - redis  : Redis pub/sub via redis-cli (requires Redis server + redis-cli in PATH)
    - webhook: HTTP POST relay to a configured webhook URL (team shared endpoint)

    Falls back to 'file' adapter automatically if the configured backend is unavailable.

    Configuration (config/mq-config.json):
    {
      "adapter": "redis",           // "file" | "redis" | "webhook"
      "redis": { "host": "127.0.0.1", "port": 6379, "channel": "gf-events" },
      "webhook": { "url": "https://team-relay.example.com/events", "secret_env": "GF_WEBHOOK_SECRET" }
    }

.PARAMETER Action
    publish  - Publish a message to the configured backend
    consume  - Pull recent messages from the backend (redis LRANGE / file fallback)
    status   - Show current adapter status and connectivity
    test     - Test connectivity to the configured backend

.PARAMETER Channel
    Channel/topic name. Default: 'gf-events'

.PARAMETER Payload
    JSON payload string to publish.

.EXAMPLE
    .\mq-adapter.ps1 -Action publish -Channel gf-events -Payload '{"event":"workflow.checkpoint"}'
    .\mq-adapter.ps1 -Action status
    .\mq-adapter.ps1 -Action test
#>
param(
    [Parameter(Position=0)]
    [ValidateSet('publish', 'consume', 'status', 'test')]
    [string]$Action = 'status',

    [string]$Channel  = 'gf-events',
    [string]$Payload  = '',
    [int]$MaxMessages = 20,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..\..') -ErrorAction SilentlyContinue)?.Path
if (-not $repoRoot) { $repoRoot = (Get-Item $scriptDir).Parent.Parent.Parent.FullName }

$configPath = Join-Path $repoRoot 'config\mq-config.json'
$historyPath = Join-Path $repoRoot '.event-bus\history.json'

# ── Load config ───────────────────────────────────────────────────────────────
function Get-MqConfig {
    if (Test-Path $configPath) {
        try { return Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
    }
    # Defaults: file adapter
    return [PSCustomObject]@{
        adapter = 'file'
        redis   = [PSCustomObject]@{ host = '127.0.0.1'; port = 6379; channel = 'gf-events' }
        webhook = [PSCustomObject]@{ url = ''; secret_env = 'GF_WEBHOOK_SECRET' }
    }
}

$cfg = Get-MqConfig
$adapter = if ($cfg.adapter) { $cfg.adapter } else { 'file' }

# ── Redis helpers ─────────────────────────────────────────────────────────────
function Test-RedisAvailable {
    try {
        $out = & redis-cli -h $cfg.redis.host -p $cfg.redis.port PING 2>&1
        return ($out -match 'PONG')
    } catch { return $false }
}

function Publish-Redis {
    param([string]$Chan, [string]$Msg)
    # Use RPUSH for durable list + PUBLISH for real-time subscribers
    & redis-cli -h $cfg.redis.host -p $cfg.redis.port RPUSH "$Chan" $Msg 2>&1 | Out-Null
    & redis-cli -h $cfg.redis.host -p $cfg.redis.port PUBLISH "$Chan" $Msg 2>&1 | Out-Null
}

function Consume-Redis {
    param([string]$Chan, [int]$Max)
    $items = & redis-cli -h $cfg.redis.host -p $cfg.redis.port LRANGE "$Chan" "-$Max" -1 2>&1
    return $items
}

# ── Webhook helpers ───────────────────────────────────────────────────────────
function Test-WebhookAvailable {
    $url = $cfg.webhook.url
    if (-not $url) { return $false }
    try {
        $resp = Invoke-WebRequest -Uri $url -Method HEAD -TimeoutSec 3 -ErrorAction Stop 2>&1
        return $resp.StatusCode -lt 500
    } catch { return $false }
}

function Publish-Webhook {
    param([string]$Chan, [string]$Msg)
    $url    = $cfg.webhook.url
    $secret = if ($cfg.webhook.secret_env) { [System.Environment]::GetEnvironmentVariable($cfg.webhook.secret_env) } else { '' }
    $body   = @{ channel = $Chan; payload = $Msg; timestamp = (Get-Date -Format 'o') } | ConvertTo-Json -Compress
    $headers = @{ 'Content-Type' = 'application/json' }
    if ($secret) { $headers['X-GF-Signature'] = $secret }
    Invoke-RestMethod -Uri $url -Method POST -Body $body -Headers $headers -TimeoutSec 5 -ErrorAction Stop | Out-Null
}

# ── File adapter helpers (always available as fallback) ───────────────────────
function Publish-File {
    param([string]$Chan, [string]$Msg)
    # File adapter just appends to .event-bus/history.json — handled by event-bus.ps1
    # Here we just append a raw entry to an MQ fallback log
    $mqLog = Join-Path $repoRoot ".event-bus\mq-fallback.jsonl"
    $entry = @{ timestamp = (Get-Date -Format 'o'); channel = $Chan; payload = $Msg } | ConvertTo-Json -Compress
    Add-Content -Path $mqLog -Value $entry -Encoding UTF8
}

function Consume-File {
    param([string]$Chan, [int]$Max)
    $mqLog = Join-Path $repoRoot ".event-bus\mq-fallback.jsonl"
    if (-not (Test-Path $mqLog)) { return @() }
    return Get-Content $mqLog -Encoding UTF8 | Select-Object -Last $Max
}

# ── Effective adapter selection with fallback ─────────────────────────────────
function Get-EffectiveAdapter {
    switch ($adapter) {
        'redis' {
            if (Test-RedisAvailable) { return 'redis' }
            if (-not $Quiet) { Write-Host "  [WARN] Redis unavailable — falling back to file adapter" -ForegroundColor Yellow }
            return 'file'
        }
        'webhook' {
            if (Test-WebhookAvailable) { return 'webhook' }
            if (-not $Quiet) { Write-Host "  [WARN] Webhook unavailable — falling back to file adapter" -ForegroundColor Yellow }
            return 'file'
        }
        default { return 'file' }
    }
}

# ── Actions ───────────────────────────────────────────────────────────────────
switch ($Action) {

    'publish' {
        if (-not $Payload) {
            Write-Host "[ERROR] -Payload required for publish action" -ForegroundColor Red; exit 1
        }
        $eff = Get-EffectiveAdapter
        switch ($eff) {
            'redis'   { Publish-Redis   -Chan $Channel -Msg $Payload }
            'webhook' { Publish-Webhook -Chan $Channel -Msg $Payload }
            default   { Publish-File    -Chan $Channel -Msg $Payload }
        }
        if (-not $Quiet) {
            Write-Host "[OK] Published to '$Channel' via '$eff' adapter" -ForegroundColor Green
        }
    }

    'consume' {
        $eff = Get-EffectiveAdapter
        $messages = switch ($eff) {
            'redis'  { Consume-Redis -Chan $Channel -Max $MaxMessages }
            default  { Consume-File  -Chan $Channel -Max $MaxMessages }
        }
        if ($messages) {
            $messages | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "[INFO] No messages in channel '$Channel'" -ForegroundColor Gray
        }
    }

    'status' {
        Write-Host "`n=== MQ ADAPTER STATUS ===" -ForegroundColor Cyan
        Write-Host "  Configured adapter : $adapter" -ForegroundColor White
        switch ($adapter) {
            'redis' {
                $ok = Test-RedisAvailable
                $status = if ($ok) { '[OK] Connected' } else { '[WARN] Unavailable' }
                $color  = if ($ok) { 'Green' } else { 'Yellow' }
                Write-Host "  Redis $($cfg.redis.host):$($cfg.redis.port) — $status" -ForegroundColor $color
                if (-not $ok) { Write-Host "  Fallback: file adapter active" -ForegroundColor Yellow }
            }
            'webhook' {
                $ok = Test-WebhookAvailable
                $status = if ($ok) { '[OK] Reachable' } else { '[WARN] Unreachable' }
                $color  = if ($ok) { 'Green' } else { 'Yellow' }
                Write-Host "  Webhook $($cfg.webhook.url) — $status" -ForegroundColor $color
                if (-not $ok) { Write-Host "  Fallback: file adapter active" -ForegroundColor Yellow }
            }
            default {
                Write-Host "  File adapter: always available" -ForegroundColor Green
                $mqLog = Join-Path $repoRoot ".event-bus\mq-fallback.jsonl"
                $count = if (Test-Path $mqLog) { (Get-Content $mqLog).Count } else { 0 }
                Write-Host "  Fallback log entries: $count" -ForegroundColor Gray
            }
        }
        Write-Host "  Config: $configPath" -ForegroundColor Gray
        Write-Host ""
    }

    'test' {
        Write-Host "`n=== MQ ADAPTER CONNECTIVITY TEST ===" -ForegroundColor Cyan
        $testPayload = @{ event = 'mq.test'; timestamp = (Get-Date -Format 'o'); source = 'mq-adapter-test' } | ConvertTo-Json -Compress

        # Always test file
        try {
            Publish-File -Chan $Channel -Msg $testPayload
            Write-Host "  [PASS] file adapter" -ForegroundColor Green
        } catch { Write-Host "  [FAIL] file adapter: $($_.Exception.Message)" -ForegroundColor Red }

        # Test configured adapter if not file
        if ($adapter -eq 'redis') {
            if (Test-RedisAvailable) {
                try {
                    Publish-Redis -Chan $Channel -Msg $testPayload
                    Write-Host "  [PASS] redis adapter ($($cfg.redis.host):$($cfg.redis.port))" -ForegroundColor Green
                } catch { Write-Host "  [FAIL] redis adapter: $($_.Exception.Message)" -ForegroundColor Red }
            } else {
                Write-Host "  [WARN] redis not reachable at $($cfg.redis.host):$($cfg.redis.port)" -ForegroundColor Yellow
            }
        }
        if ($adapter -eq 'webhook') {
            if (Test-WebhookAvailable) {
                try {
                    Publish-Webhook -Chan $Channel -Msg $testPayload
                    Write-Host "  [PASS] webhook adapter ($($cfg.webhook.url))" -ForegroundColor Green
                } catch { Write-Host "  [FAIL] webhook adapter: $($_.Exception.Message)" -ForegroundColor Red }
            } else {
                Write-Host "  [WARN] webhook not reachable: $($cfg.webhook.url)" -ForegroundColor Yellow
            }
        }
        Write-Host ""
    }
}
