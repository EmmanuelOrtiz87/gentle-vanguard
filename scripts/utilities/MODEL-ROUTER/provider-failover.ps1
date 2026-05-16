param(
    [ValidateSet('check', 'status', 'route', 'reset')]
    [string]$Action = 'check',
    [string]$AgentType = '',
    [switch]$AsJson,
    [switch]$Quiet
)

$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot 'config\orchestrator.json'))) {
    $repoRoot = Split-Path -Parent $repoRoot
}
$statePath = Join-Path $repoRoot '.session\provider-state.json'
$routerPath = Join-Path $repoRoot 'config\model-router.json'
$cloudAgentsPath = Join-Path $repoRoot 'config\cloud-agents.json'

$providers = @{
    openrouter = @{
        name = 'OpenRouter'
        priority = 0
        testUrl = 'https://openrouter.ai/api/v1/auth/key'
        envKey = 'OPENROUTER_API_KEY'
        timeout = 5
        local = $false
    }
    anthropic = @{
        name = 'Anthropic Direct'
        priority = 1
        testUrl = 'https://api.anthropic.com/v1/messages'
        envKey = 'ANTHROPIC_API_KEY'
        timeout = 5
        local = $false
    }
    openai = @{
        name = 'OpenAI Direct'
        priority = 2
        testUrl = 'https://api.openai.com/v1/models'
        envKey = 'OPENAI_API_KEY'
        timeout = 5
        local = $false
    }
    ollama = @{
        name = 'Ollama (Local)'
        priority = 3
        testUrl = 'http://localhost:11434/api/tags'
        envKey = $null
        timeout = 2
        local = $true
    }
}

function Get-ProviderState {
    if (Test-Path $statePath) {
        try { return Get-Content $statePath -Raw | ConvertFrom-Json } catch { }
    }
    return @{ lastCheck = $null; providers = @{} }
}

function Save-ProviderState {
    param($State)
    $dir = Split-Path -Parent $statePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $State | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath -Encoding UTF8
}

function Test-ProviderAvailable {
    param($Provider)
    $result = @{ name = $Provider.name; key = $Provider.keys[0]; available = $false; latency = $null; error = $null }

    if ($Provider.local) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $null = Invoke-WebRequest -Uri $Provider.testUrl -Method GET -TimeoutSec $Provider.timeout -ErrorAction Stop
            $sw.Stop()
            $result.available = $true
            $result.latency = [math]::Round($sw.Elapsed.TotalMilliseconds)
        } catch {
            $sw.Stop()
            $result.error = $_.Exception.Message
        }
        return $result
    }

    $apiKey = [Environment]::GetEnvironmentVariable($Provider.envKey)
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        $result.error = "Missing env var: $($Provider.envKey)"
        return $result
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $headers = @{ 'Authorization' = "Bearer $apiKey" }
        if ($Provider.key -eq 'anthropic') { $headers['anthropic-version'] = '2023-06-01' }
        $null = Invoke-WebRequest -Uri $Provider.testUrl -Method GET -Headers $headers -TimeoutSec $Provider.timeout -ErrorAction Stop
        $sw.Stop()
        $result.available = $true
        $result.latency = [math]::Round($sw.Elapsed.TotalMilliseconds)
    } catch {
        $sw.Stop()
        $result.error = $_.Exception.Message
    }

    return $result
}

function Get-RouteDecision {
    param($State)
    $available = @($State.providers.PSObject.Properties | Where-Object { $_.Value.available })
    $sorted = $available | Sort-Object { if ($providers.ContainsKey($_.Name)) { $providers[$_.Name].priority } else { 99 } }
    if ($sorted.Count -eq 0) {
        return @{ provider = $null; note = 'No providers available'; fallback = 'opencode/big-pickle' }
    }
    $best = $sorted[0]
    $note = if ($best.Name -ne 'openrouter') { "Failover active: primary (OpenRouter) unavailable, using $($best.Name)" } else { 'Primary provider operational' }
    return @{ provider = $best.Name; note = $note; latency = $best.Value.latency }
}

switch ($Action) {
    'check' {
        $state = Get-ProviderState
        $state.lastCheck = (Get-Date -Format 'o')
        if (-not $state.providers) { $state | Add-Member -NotePropertyName providers -NotePropertyValue @{} }

        foreach ($pk in $providers.Keys) {
            $p = $providers[$pk]
            $p | Add-Member -NotePropertyName keys -NotePropertyValue @($pk) -Force
            $r = Test-ProviderAvailable -Provider $p
            if (-not $state.providers.$pk) { $state.providers | Add-Member -NotePropertyName $pk -NotePropertyValue @{} }
            $state.providers.$pk = @{ available = $r.available; latency = $r.latency; error = $r.error; lastCheck = $state.lastCheck }
        }

        Save-ProviderState -State $state
        $route = Get-RouteDecision -State $state

        if (-not $Quiet) {
            Write-Host "`n=== Provider Failover Status ===" -ForegroundColor Cyan
            foreach ($pk in $providers.Keys) {
                $p = $state.providers.$pk
                $icon = if ($p.available) { '[OK]' } else { '[DOWN]' }
                $color = if ($p.available) { 'Green' } else { 'Red' }
                $lat = if ($p.latency) { "$($p.latency)ms" } else { '--' }
                Write-Host "  $icon $($providers[$pk].name) - $lat" -ForegroundColor $color
                if (-not $p.available -and $p.error) { Write-Host "       $($p.error)" -ForegroundColor DarkGray }
            }
            Write-Host "`n  Route: $($route.note)" -ForegroundColor Yellow
        }

        if ($AsJson) {
            $state | Add-Member -NotePropertyName route -NotePropertyValue $route -Force
            $state | ConvertTo-Json -Depth 5
        }
    }

    'status' {
        $state = Get-ProviderState
        if (-not $state.lastCheck) {
            if (-not $Quiet) { Write-Host '[INFO] No provider check has been run yet. Run "provider-failover check" first.' -ForegroundColor Yellow }
            if ($AsJson) { @{ checked = $false; providers = @{}; route = @{ provider = $null; note = 'No data' } } | ConvertTo-Json }
            return
        }
        $route = Get-RouteDecision -State $state
        if (-not $Quiet) {
            Write-Host "`n=== Provider Status ===" -ForegroundColor Cyan
            Write-Host "  Last check: $($state.lastCheck)" -ForegroundColor Gray
            foreach ($pk in $providers.Keys) {
                $p = $state.providers.$pk
                if (-not $p) { continue }
                $icon = if ($p.available) { '[OK]' } else { '[DOWN]' }
                $color = if ($p.available) { 'Green' } else { 'Red' }
                $lat = if ($p.latency) { "$($p.latency)ms" } else { '--' }
                Write-Host "  $icon $($providers[$pk].name) - $lat" -ForegroundColor $color
            }
            Write-Host "  Route: $($route.note)" -ForegroundColor Yellow
        }
        if ($AsJson) { $state | Add-Member -NotePropertyName route -NotePropertyValue $route -Force; $state | ConvertTo-Json -Depth 5 }
    }

    'route' {
        $state = Get-ProviderState
        $route = Get-RouteDecision -State $state
        if ($AsJson) { $route | ConvertTo-Json; return }
        Write-Host "Route: $($route.provider)" -ForegroundColor Cyan
        Write-Host "Note: $($route.note)" -ForegroundColor Yellow
    }

    'reset' {
        if (Test-Path $statePath) { Remove-Item $statePath -Force }
        if (-not $Quiet) { Write-Host '[OK] Provider state reset.' -ForegroundColor Green }
        if ($AsJson) { @{ status = 'reset' } | ConvertTo-Json }
    }
}
