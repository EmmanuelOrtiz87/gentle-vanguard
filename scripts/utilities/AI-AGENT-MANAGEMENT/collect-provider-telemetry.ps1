<#
.SYNOPSIS
    Collects real provider telemetry and records health-check rows in cloud-agent-telemetry.csv.

.DESCRIPTION
    For each provider declared in cloud-agents.json / cloud-agents.local.json:
      - enabled + API key set      -> performs a lightweight test call; records real latency/tokens/status.
      - enabled + API key missing  -> records MISSING_KEY (no API call made).
      - disabled                   -> records DISABLED (no API call made, skippable with -SkipDisabled).

    Results are appended to .runtime/telemetry/cloud-agent-telemetry.csv.
    Local config (cloud-agents.local.json) overrides the template config per provider.
    Env vars are also loaded from .env.local if present.

.PARAMETER DryRun
    Print what would be written without modifying the CSV.

.PARAMETER SkipDisabled
    Do not write DISABLED rows for providers with enabled:false.

.EXAMPLE
    pwsh -File collect-provider-telemetry.ps1
    pwsh -File collect-provider-telemetry.ps1 -DryRun
    pwsh -File collect-provider-telemetry.ps1 -SkipDisabled
#>
param(
    [switch]$DryRun,
    [switch]$SkipDisabled
)

$ErrorActionPreference = 'Continue'
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$configDir = Join-Path $repoRoot 'config'

$telemetryPath = Join-Path $repoRoot '.runtime\telemetry\cloud-agent-telemetry.csv'
$envFilePath   = Join-Path $repoRoot '.env.local'

# -- Helpers --------------------------------------------------------------------
function Import-EnvFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    foreach ($line in Get-Content $Path) {
        $t = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($t) -or $t.StartsWith('#')) { continue }
        if ($t -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $n = $matches[1]; $v = $matches[2].Trim()
            if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
                $v = $v.Substring(1, $v.Length - 2)
            }
            if (-not [string]::IsNullOrWhiteSpace($n) -and
                [string]::IsNullOrWhiteSpace((Get-ChildItem "env:$n" -ErrorAction SilentlyContinue).Value)) {
                Set-Item -Path "env:$n" -Value $v
            }
        }
    }
}

function Sanitize-CsvCell {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $safe = ($Value -replace '[\r\n]+', ' ')
    if ($safe.TrimStart() -match '^[=+\-@]') { $safe = "'$safe" }
    return $safe
}

function Write-TelemetryRow {
    param(
        [string]$Provider,
        [string]$Model,
        [int]   $InputTokens,
        [int]   $OutputTokens,
        [long]  $LatencyMs,
        [string]$Status,
        [string]$ErrorMessage = ''
    )

    $ts        = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $userStr   = if ($env:USERNAME) { $env:USERNAME } else { 'agent' }
    $userId    = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($userStr))
    $sessionId = if ($env:FOUNDATION_SESSION_ID) { $env:FOUNDATION_SESSION_ID } else { 'telemetry-collect' }
    $requestId = [Guid]::NewGuid().ToString()

    $row = '"' + (Sanitize-CsvCell $ts)           + '",' +
           '"' + (Sanitize-CsvCell $userId)        + '",' +
           '"' + (Sanitize-CsvCell $sessionId)     + '",' +
           '"' + (Sanitize-CsvCell $requestId)     + '",' +
           '"' + (Sanitize-CsvCell $Provider)      + '",' +
           '"' + (Sanitize-CsvCell $Model)         + '",' +
           '"' + $InputTokens                      + '",' +
           '"' + $OutputTokens                     + '",' +
           '"' + $LatencyMs                        + '",' +
           '"' + (Sanitize-CsvCell $Status)        + '",' +
           '"' + (Sanitize-CsvCell $ErrorMessage)  + '"'

    if ($DryRun) {
        Write-Host "[DRY-RUN] $Provider | $Model | ${Status} | lat=${LatencyMs}ms in=${InputTokens} out=${OutputTokens}" -ForegroundColor DarkCyan
    } else {
        $dir = Split-Path -Parent $telemetryPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        if (-not (Test-Path $telemetryPath)) {
            Set-Content -Path $telemetryPath -Encoding UTF8 `
                -Value 'Timestamp,User_ID,Session_ID,Request_ID,Provider,Model,InputTokens,OutputTokens,LatencyMs,Status,ErrorMessage'
        }
        Add-Content -Path $telemetryPath -Value $row -Encoding UTF8
    }
}

# -- Load provider configs ------------------------------------------------------
Import-EnvFile -Path $envFilePath

$providerMap = [ordered]@{}
$templatePath = Join-Path $configDir 'cloud-agents.json'
$localPath    = Join-Path $configDir 'cloud-agents.local.json'

foreach ($cfgPath in @($templatePath, $localPath)) {
    if (-not (Test-Path $cfgPath)) { continue }
    $parsed = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($parsed -and $parsed.providers) {
        foreach ($name in $parsed.providers.PSObject.Properties.Name) {
            $providerMap[$name] = $parsed.providers.$name   # local overrides template
        }
    }
}

if ($providerMap.Count -eq 0) {
    Write-Host '[WARN] No providers found in config. Nothing to collect.' -ForegroundColor Yellow
    exit 0
}

Write-Host "[INFO] Collecting telemetry for $($providerMap.Count) provider(s)..." -ForegroundColor Cyan
if ($DryRun) { Write-Host '[INFO] DRY-RUN mode - CSV will not be modified.' -ForegroundColor Yellow }

# -- Process each provider ------------------------------------------------------
foreach ($providerName in $providerMap.Keys) {
    $cfg       = $providerMap[$providerName]
    $model     = if ($cfg.model)   { [string]$cfg.model }   else { 'unknown' }
    $isEnabled = [bool]$cfg.enabled
    $isLocal   = [bool]$cfg.local

    # -- Disabled ----------------------------------------------------------------
    if (-not $isEnabled) {
        if ($SkipDisabled) {
            Write-Host "  [$providerName] SKIP (disabled)" -ForegroundColor DarkGray
        } else {
            Write-Host "  [$providerName] DISABLED" -ForegroundColor DarkGray
            Write-TelemetryRow -Provider $providerName -Model $model `
                -InputTokens 0 -OutputTokens 0 -LatencyMs 0 `
                -Status 'DISABLED' -ErrorMessage 'Provider is disabled in cloud-agents config'
        }
        continue
    }

    # -- Missing API key ---------------------------------------------------------
    if ($cfg.api_key_env -and -not $isLocal) {
        $apiKeyValue = (Get-ChildItem "env:$($cfg.api_key_env)" -ErrorAction SilentlyContinue).Value
        if ([string]::IsNullOrWhiteSpace($apiKeyValue)) {
            Write-Host "  [$providerName] MISSING_KEY ($($cfg.api_key_env) not set)" -ForegroundColor Yellow
            Write-TelemetryRow -Provider $providerName -Model $model `
                -InputTokens 0 -OutputTokens 0 -LatencyMs 0 `
                -Status 'MISSING_KEY' -ErrorMessage "Required env var '$($cfg.api_key_env)' is not set"
            continue
        }
    }

    # -- Validate endpoint URI ---------------------------------------------------
    $endpoint  = [string]$cfg.endpoint
    $parsedUri = $null
    if (-not [Uri]::TryCreate($endpoint, [UriKind]::Absolute, [ref]$parsedUri)) {
        Write-Host "  [$providerName] INVALID_ENDPOINT: $endpoint" -ForegroundColor Red
        Write-TelemetryRow -Provider $providerName -Model $model `
            -InputTokens 0 -OutputTokens 0 -LatencyMs 0 `
            -Status 'INVALID_ENDPOINT' -ErrorMessage "Invalid endpoint URI: $endpoint"
        continue
    }
    if ($parsedUri.Scheme -eq 'http' -and $parsedUri.Host -notin @('localhost', '127.0.0.1')) {
        Write-Host "  [$providerName] INSECURE_ENDPOINT" -ForegroundColor Red
        Write-TelemetryRow -Provider $providerName -Model $model `
            -InputTokens 0 -OutputTokens 0 -LatencyMs 0 `
            -Status 'INSECURE_ENDPOINT' -ErrorMessage 'HTTP endpoint is only allowed for localhost providers'
        continue
    }

    # -- Build request headers ---------------------------------------------------
    $headers = @{
        'Content-Type' = 'application/json'
        'User-Agent'   = 'Foundation-CloudAgent/1.0'
    }
    if ($cfg.api_key_env) {
        $apiKey = (Get-ChildItem "env:$($cfg.api_key_env)" -ErrorAction SilentlyContinue).Value
        switch ($providerName) {
            'gemini'    { $headers['x-goog-api-key']    = $apiKey }
            'azure'     { $headers['api-key']            = $apiKey }
            'anthropic' {
                $headers['x-api-key']          = $apiKey
                $headers['anthropic-version']  = '2023-06-01'
            }
            default     { $headers['Authorization'] = "Bearer $apiKey" }
        }
    }

    # -- Build minimal test payload ----------------------------------------------
    $testMsg = @(@{ role = 'user'; content = 'Reply with the single word: pong' })
    $body = switch ($providerName) {
        'anthropic' {
            @{ model = $model; messages = $testMsg; max_tokens = 10; temperature = 0.0 }
        }
        'gemini' {
            @{
                contents         = @(@{ role = 'user'; parts = @(@{ text = 'Reply with the single word: pong' }) })
                generationConfig = @{ maxOutputTokens = 10; temperature = 0.0 }
            }
        }
        'ollama' {
            @{ model = $model; messages = $testMsg; stream = $false; options = @{ num_predict = 10; temperature = 0.0 } }
        }
        default {
            @{ model = $model; messages = $testMsg; max_tokens = 10; temperature = 0.0 }
        }
    }

    # -- Execute test call -------------------------------------------------------
    Write-Host "  [$providerName] Testing $model @ $endpoint ..." -ForegroundColor Cyan
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = Invoke-RestMethod -Uri $endpoint -Method Post `
            -Headers $headers -Body ($body | ConvertTo-Json -Depth 10) -ErrorAction Stop
        $sw.Stop()
        $latencyMs = $sw.ElapsedMilliseconds

        $inputTokens  = 0
        $outputTokens = 0
        if ($resp.usage) {
            if ($resp.usage.prompt_tokens)     { $inputTokens  = [int]$resp.usage.prompt_tokens }
            if ($resp.usage.completion_tokens) { $outputTokens = [int]$resp.usage.completion_tokens }
            if ($resp.usage.input_tokens)      { $inputTokens  = [int]$resp.usage.input_tokens }
            if ($resp.usage.output_tokens)     { $outputTokens = [int]$resp.usage.output_tokens }
        }

        Write-Host "  [$providerName] SUCCESS ${latencyMs}ms in=${inputTokens} out=${outputTokens}" -ForegroundColor Green
        Write-TelemetryRow -Provider $providerName -Model $model `
            -InputTokens $inputTokens -OutputTokens $outputTokens `
            -LatencyMs $latencyMs -Status 'SUCCESS'

    } catch {
        $sw.Stop()
        $latencyMs = $sw.ElapsedMilliseconds
        $errMsg    = $_.Exception.Message
        if ($errMsg.Length -gt 250) { $errMsg = $errMsg.Substring(0, 250) }

        Write-Host "  [$providerName] ERROR ${latencyMs}ms: $errMsg" -ForegroundColor Red
        Write-TelemetryRow -Provider $providerName -Model $model `
            -InputTokens 0 -OutputTokens 0 `
            -LatencyMs $latencyMs -Status 'ERROR' -ErrorMessage $errMsg
    }
}

if ($DryRun) {
    Write-Host "`n[DRY-RUN] No rows written to CSV." -ForegroundColor Yellow
} else {
    Write-Host "`n[OK] Telemetry appended to: $telemetryPath" -ForegroundColor Green
}
