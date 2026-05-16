# invoke-cloud-agent.ps1
# Cloud Agent Connector - Invoke cloud AI models securely
# Supports: AWS Bedrock, Difi, Azure OpenAI, and generic APIs

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('bedrock', 'difi', 'azure', 'openai', 'anthropic', 'gemini', 'ollama', 'custom')]
    [string]$Provider = 'openai',
    
    [Parameter(Mandatory=$false)]
    [string]$Agent = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Command = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Script = '',
    
    [Parameter(Mandatory=$false)]
    [switch]$Interactive,
    
    [Parameter(Mandatory=$false)]
    [switch]$Config,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListProviders,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestConnection,
    
    [Parameter(Mandatory=$false)]
    [switch]$StrictJson,
    
    [Parameter(Mandatory=$false)]
    [float]$Temperature = 0.1,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxTokens = 4096,
    
    [Parameter(Mandatory=$false)]
    [string]$ModelOverride = '',
    
    [Parameter(Mandatory=$false)]
    [string]$SystemPrompt = '',
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Headers = @{}
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }

$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$configDir = Join-Path $repoRoot 'config'
$localConfigPath = Join-Path $configDir 'cloud-agents.local.json'
$templateConfigPath = Join-Path $configDir 'cloud-agents.json'
$telemetryPath = Join-Path $repoRoot '.runtime\telemetry\cloud-agent-telemetry.csv'

function Import-EnvFile {
    param([string]$EnvFilePath)

    if (-not (Test-Path $EnvFilePath)) {
        return
    }

    foreach ($line in Get-Content $EnvFilePath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }

        if ($trimmed -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $name = $matches[1]
            $value = $matches[2].Trim()
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                $existing = (Get-ChildItem "env:$name" -ErrorAction SilentlyContinue).Value
                if ([string]::IsNullOrWhiteSpace($existing)) {
                    Set-Item -Path "env:$name" -Value $value
                }
            }
        }
    }
}

Import-EnvFile -EnvFilePath (Join-Path $repoRoot '.env.local')

function Get-CloudAgentConfig {
    param([string]$ProviderName)
    
    $localConfig = $null
    $templateConfig = $null
    
    if (Test-Path $localConfigPath) {
        $localConfig = Get-Content $localConfigPath -Raw | ConvertFrom-Json
    }
    
    if (Test-Path $templateConfigPath) {
        $templateConfig = Get-Content $templateConfigPath -Raw | ConvertFrom-Json
    }
    
    $providerConfig = $null
    if ($localConfig -and $localConfig.providers.$ProviderName) {
        $providerConfig = $localConfig.providers.$ProviderName
    } elseif ($templateConfig -and $templateConfig.providers.$ProviderName) {
        $providerConfig = $templateConfig.providers.$ProviderName
    }
    
    if (-not $providerConfig) {
        throw "Provider '$ProviderName' not found in configuration. Run with -Config to set up."
    }
    
    return $providerConfig
}

function Get-SecretFromEnv {
    param([string]$SecretName, [string]$Fallback = '')
    
    $value = (Get-ChildItem "env:$SecretName" -ErrorAction SilentlyContinue).Value
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = $Fallback
    }
    return $value
}

function Resolve-ProviderUri {
    param(
        [string]$ProviderName,
        [psobject]$ProviderConfig
    )

    $uri = [string]$ProviderConfig.endpoint

    $parsed = $null
    if (-not [Uri]::TryCreate($uri, [UriKind]::Absolute, [ref]$parsed)) {
        throw "Invalid provider endpoint URI: $uri"
    }

    $isLocalHttp = $parsed.Scheme -eq 'http' -and ($parsed.Host -in @('localhost', '127.0.0.1'))
    if ($parsed.Scheme -eq 'http' -and -not $isLocalHttp) {
        throw "Insecure HTTP endpoint is only allowed for localhost providers. Endpoint: $uri"
    }

    return $uri
}

function Get-DefaultProvider {
    $configs = @()
    if (Test-Path $localConfigPath) {
        $configs += ,(Get-Content $localConfigPath -Raw | ConvertFrom-Json)
    }
    if (Test-Path $templateConfigPath) {
        $configs += ,(Get-Content $templateConfigPath -Raw | ConvertFrom-Json)
    }

    foreach ($cfg in $configs) {
        if (-not $cfg -or -not $cfg.providers) {
            continue
        }

        foreach ($name in $cfg.providers.PSObject.Properties.Name) {
            $provider = $cfg.providers.$name
            if (-not $provider.enabled) {
                continue
            }
            if ($provider.auth_type -eq 'aws_sigv4') {
                continue
            }
            return [string]$name
        }
    }

    return 'openai'
}

function Get-CurrentSessionId {
    if (-not [string]::IsNullOrWhiteSpace($env:GV_SESSION_ID)) {
        return [string]$env:GV_SESSION_ID
    }

    $sessionsPath = Join-Path $repoRoot 'docs\sessions'
    if (-not (Test-Path $sessionsPath)) {
        return ''
    }

    $latest = Get-ChildItem -Path $sessionsPath -Filter '*-session-start.md' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest) {
        return ''
    }

    return ($latest.BaseName -replace '-session-start$', '')
}

function Get-ProviderHeaders {
    param(
        [string]$ProviderName,
        [psobject]$ProviderConfig,
        [hashtable]$IncomingHeaders
    )

    $headers = @{
        'Content-Type' = 'application/json'
        'User-Agent' = 'Gentle-Vanguard-CloudAgent/1.0'
    }

    if ($ProviderConfig.api_key_env) {
        $apiKey = Get-SecretFromEnv -SecretName $ProviderConfig.api_key_env
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            throw "Missing API key environment variable: $($ProviderConfig.api_key_env)"
        }

        switch ($ProviderName) {
            'gemini' {
                $headers['x-goog-api-key'] = $apiKey
            }
            'azure' {
                $headers['api-key'] = $apiKey
            }
            'anthropic' {
                $headers['x-api-key'] = $apiKey
                $headers['anthropic-version'] = '2023-06-01'
            }
            default {
                $headers['Authorization'] = "Bearer $apiKey"
            }
        }
    }

    if ($ProviderConfig.auth_type -eq 'aws_sigv4') {
        throw "Provider '$ProviderName' requires aws_sigv4 auth, which is not supported by invoke-cloud-agent.ps1 HTTP path yet. Use providers with API key auth or run through a signed proxy endpoint."
    }

    foreach ($key in $IncomingHeaders.Keys) {
        $headers[$key] = $IncomingHeaders[$key]
    }

    return $headers
}

function Build-ProviderRequestBody {
    param(
        [string]$ProviderName,
        [psobject]$ProviderConfig,
        [hashtable]$RequestParams
    )

    $model = if ($RequestParams.Model) { $RequestParams.Model } else { $ProviderConfig.model }

    switch ($ProviderName) {
        'anthropic' {
            return @{
                model = $model
                messages = $RequestParams.Messages | Where-Object { $_.role -ne 'system' }
                temperature = $RequestParams.Temperature
                max_tokens = $RequestParams.MaxTokens
            }
        }
        'gemini' {
            $systemMessage = $RequestParams.Messages | Where-Object { $_.role -eq 'system' } | Select-Object -First 1
            $contentMessages = $RequestParams.Messages | Where-Object { $_.role -ne 'system' }
            $contents = @()
            foreach ($msg in $contentMessages) {
                $geminiRole = if ($msg.role -eq 'assistant') { 'model' } else { 'user' }
                $contents += @{
                    role = $geminiRole
                    parts = @(@{ text = [string]$msg.content })
                }
            }

            $body = @{
                generationConfig = @{
                    temperature = $RequestParams.Temperature
                    maxOutputTokens = $RequestParams.MaxTokens
                }
                contents = $contents
            }

            if ($systemMessage) {
                $body.system_instruction = @{ parts = @(@{ text = [string]$systemMessage.content }) }
            }

            return $body
        }
        'ollama' {
            return @{
                model = $model
                messages = $RequestParams.Messages
                stream = $false
                options = @{
                    temperature = $RequestParams.Temperature
                    num_predict = $RequestParams.MaxTokens
                }
            }
        }
        default {
            $body = @{
                model = $model
                messages = $RequestParams.Messages
                temperature = $RequestParams.Temperature
                max_tokens = $RequestParams.MaxTokens
            }

            if ($ProviderConfig.response_format) {
                $body.response_format = $ProviderConfig.response_format
            }

            return $body
        }
    }
}

function Sanitize-CsvCell {
    param([string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    $safe = ($Value -replace '[\r\n]+', ' ')
    $trimmedLead = $safe.TrimStart()
    if ($trimmedLead -match '^[=+\-@]') {
        $safe = "'$safe"
    }
    return $safe
}

function Get-TokenUsage {
    param(
        [object]$Response,
        [string]$ProviderName,
        [int]$FallbackInput,
        [int]$FallbackOutput
    )

    $input = $FallbackInput
    $output = $FallbackOutput

    if ($Response -and $Response.usage) {
        if ($Response.usage.prompt_tokens -or $Response.usage.completion_tokens) {
            if ($Response.usage.prompt_tokens -match '^\d+$') {
                $input = [int]$Response.usage.prompt_tokens
            }
            if ($Response.usage.completion_tokens -match '^\d+$') {
                $output = [int]$Response.usage.completion_tokens
            }
            return @{ Input = $input; Output = $output }
        }
        if ($Response.usage.input_tokens -or $Response.usage.output_tokens) {
            if ($Response.usage.input_tokens -match '^\d+$') {
                $input = [int]$Response.usage.input_tokens
            }
            if ($Response.usage.output_tokens -match '^\d+$') {
                $output = [int]$Response.usage.output_tokens
            }
            return @{ Input = $input; Output = $output }
        }
    }

    return @{ Input = $FallbackInput; Output = $FallbackOutput }
}

function Write-Telemetry {
    param(
        [string]$Provider,
        [string]$Model,
        [int]$InputTokens,
        [int]$OutputTokens,
        [int]$LatencyMs,
        [string]$Status,
        [string]$ErrorMessage = ''
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $userId = $env:USERNAME
    $sessionId = Get-CurrentSessionId
    $requestId = [guid]::NewGuid().ToString()

    $safeUser = if ([string]::IsNullOrWhiteSpace($userId)) { 'unknown' } else { [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($userId)) }
    $safeUser = Sanitize-CsvCell -Value $safeUser
    $safeSession = Sanitize-CsvCell -Value $sessionId
    $safeRequest = Sanitize-CsvCell -Value $requestId
    $safeProvider = Sanitize-CsvCell -Value $Provider
    $safeModel = Sanitize-CsvCell -Value $Model
    $safeStatus = Sanitize-CsvCell -Value $Status
    $safeError = Sanitize-CsvCell -Value $ErrorMessage
    
    if (-not (Test-Path (Split-Path $telemetryPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $telemetryPath -Parent) -Force | Out-Null
    }
    
    if (Test-Path $telemetryPath) {
        $header = Get-Content -Path $telemetryPath -TotalCount 1 -ErrorAction SilentlyContinue
        if ($header -and $header -notmatch 'Session_ID') {
            $legacyPath = "$telemetryPath.legacy.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -Path $telemetryPath -Destination $legacyPath -Force
        }
    }

    if (-not (Test-Path $telemetryPath)) {
        'Timestamp,User_ID,Session_ID,Request_ID,Provider,Model,InputTokens,OutputTokens,LatencyMs,Status,ErrorMessage' | Out-File -FilePath $telemetryPath -Encoding UTF8
    }

    [pscustomobject]@{
        Timestamp = $timestamp
        User_ID = $safeUser
        Session_ID = $safeSession
        Request_ID = $safeRequest
        Provider = $safeProvider
        Model = $safeModel
        InputTokens = $InputTokens
        OutputTokens = $OutputTokens
        LatencyMs = $LatencyMs
        Status = $safeStatus
        ErrorMessage = $safeError
    } | Export-Csv -Path $telemetryPath -Append -NoTypeInformation -Encoding UTF8
}

function Invoke-CloudRequest {
    param(
        [hashtable]$RequestParams
    )
    
    $providerConfig = Get-CloudAgentConfig -ProviderName $RequestParams.Provider
    $startTime = Get-Date
    
    try {
        $headers = Get-ProviderHeaders -ProviderName $RequestParams.Provider -ProviderConfig $providerConfig -IncomingHeaders $RequestParams.Headers
        $requestUri = Resolve-ProviderUri -ProviderName $RequestParams.Provider -ProviderConfig $providerConfig
        $body = Build-ProviderRequestBody -ProviderName $RequestParams.Provider -ProviderConfig $providerConfig -RequestParams $RequestParams
        $resolvedModel = if ($RequestParams.Model) { $RequestParams.Model } else { $providerConfig.model }
        
        $bodyJson = $body | ConvertTo-Json -Depth 10
        
        $params = @{
            Uri = $requestUri
            Method = 'POST'
            Headers = $headers
            Body = $bodyJson
            TimeoutSec = 120
        }
        
        $response = Invoke-RestMethod @params
        
        $endTime = Get-Date
        $latencyMs = [int]($endTime - $startTime).TotalMilliseconds
        
        $usage = Get-TokenUsage -Response $response -ProviderName $RequestParams.Provider -FallbackInput 0 -FallbackOutput 0
        $inputTokens = $usage.Input
        $outputTokens = $usage.Output
        
        Write-Telemetry -Provider $RequestParams.Provider -Model $resolvedModel `
            -InputTokens $inputTokens -OutputTokens $outputTokens `
            -LatencyMs $latencyMs -Status 'SUCCESS'
        
        return @{
            Success = $true
            Response = $response
            LatencyMs = $latencyMs
        }
    }
    catch {
        $endTime = Get-Date
        $latencyMs = [int]($endTime - $startTime).TotalMilliseconds
        
        Write-Telemetry -Provider $RequestParams.Provider -Model $providerConfig.model `
            -InputTokens 0 -OutputTokens 0 -LatencyMs $latencyMs `
            -Status 'ERROR' -ErrorMessage $_.Exception.Message
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            LatencyMs = $latencyMs
        }
    }
}

function Show-InteractiveMode {
    Write-Host "`n=== Cloud Agent Connector - Interactive Mode ===" -ForegroundColor Cyan
    Write-Host "Available providers: bedrock, difi, azure, openai, anthropic, gemini, ollama, custom"
    Write-Host "Type 'quit' to exit, 'config' to manage configuration`n" -ForegroundColor Gray
    
    while ($true) {
        $provider = Read-Host "`nProvider"
        if ($provider -eq 'quit') { break }
        if ($provider -eq 'config') {
            Show-ConfigMenu
            continue
        }
        
        $model = Read-Host "Model (or Enter for default)"
        $systemPrompt = Read-Host "System Prompt (optional)"
        $userMessage = Read-Host "Message"
        
        if ([string]::IsNullOrWhiteSpace($userMessage)) { continue }
        
        $messages = @(
            @{ role = 'user'; content = $userMessage }
        )
        
        if ($systemPrompt) {
            $messages = @(
                @{ role = 'system'; content = $systemPrompt },
                @{ role = 'user'; content = $userMessage }
            )
        }
        
        $params = @{
            Provider = $provider
            Model = if ($model) { $model } else { '' }
            Messages = $messages
            Temperature = $Temperature
            MaxTokens = $MaxTokens
            Headers = $Headers
        }
        
        Write-Host "`nExecuting..." -ForegroundColor Yellow
        $result = Invoke-CloudRequest -RequestParams $params
        
        if ($result.Success) {
            Write-Host "`n=== Response ===" -ForegroundColor Green
            $result.Response | ConvertTo-Json -Depth 10
        } else {
            Write-Host "`n=== Error ===" -ForegroundColor Red
            Write-Host $result.Error
        }
        
        Write-Host "`nLatency: $($result.LatencyMs)ms" -ForegroundColor Gray
    }
}

function Show-ConfigMenu {
    Write-Host "`n=== Configuration Menu ===" -ForegroundColor Cyan
    Write-Host "1. View current configuration"
    Write-Host "2. Create local config template"
    Write-Host "3. Edit provider settings"
    Write-Host "4. Test connection"
    Write-Host "5. Back`n"
    
    $choice = Read-Host "Option"
    
    switch ($choice) {
        '1' {
            Write-Host "`n--- Local Config ---" -ForegroundColor Yellow
            if (Test-Path $localConfigPath) {
                Get-Content $localConfigPath | Format-Json
            } else {
                Write-Host "No local config found. Use option 2 to create." -ForegroundColor Gray
            }
            Write-Host "`n--- Template Config ---" -ForegroundColor Yellow
            if (Test-Path $templateConfigPath) {
                Get-Content $templateConfigPath | Format-Json
            } else {
                Write-Host "No template config found." -ForegroundColor Gray
            }
        }
        '2' {
            Write-Host "Creating local config template at: $localConfigPath" -ForegroundColor Yellow
            
            $template = @{
                version = '1.0'
                providers = @{
                    bedrock = @{
                        enabled = $false
                        endpoint = 'https://YOUR_SIGNED_PROXY/bedrock/invoke'
                        model = 'anthropic.claude-3-5-sonnet-20241022'
                        auth_type = 'proxy_signed'
                        response_format = @{ type = 'json_object' }
                    }
                    difi = @{
                        enabled = $false
                        endpoint = 'https://api.difi.ai/v1/chat/completions'
                        model = 'difi-model'
                        api_key_env = 'DIFI_API_KEY'
                    }
                    azure = @{
                        enabled = $false
                        endpoint = 'https://YOUR_RESOURCE.openai.azure.com/openai/deployments/YOUR_DEPLOYMENT/chat/completions?api-version=2024-02-01'
                        model = 'gpt-4o'
                        api_key_env = 'AZURE_OPENAI_KEY'
                        api_version = '2024-02-01'
                    }
                    openai = @{
                        enabled = $false
                        endpoint = 'https://api.openai.com/v1/chat/completions'
                        model = 'gpt-4o'
                        api_key_env = 'OPENAI_API_KEY'
                    }
                    anthropic = @{
                        enabled = $false
                        endpoint = 'https://api.anthropic.com/v1/messages'
                        model = 'claude-3-5-sonnet-20241022'
                        api_key_env = 'ANTHROPIC_API_KEY'
                    }
                    ollama = @{
                        enabled = $false
                        endpoint = 'http://localhost:11434/api/chat'
                        model = 'llama3.2'
                        local = $true
                    }
                }
            }
            
            $template | ConvertTo-Json -Depth 10 | Out-File -FilePath $localConfigPath -Encoding UTF8
            Write-Host "Template created. Edit $localConfigPath for provider metadata (endpoints, models, enabled flags)." -ForegroundColor Green
            Write-Host "IMPORTANT: Keep secrets in environment variables / .env.local, never in config JSON." -ForegroundColor Red
        }
        '3' {
            Write-Host "Editing local config..." -ForegroundColor Yellow
            if (Test-Path $localConfigPath) {
                code $localConfigPath
            } else {
                Write-Host "Run option 2 first to create the config." -ForegroundColor Red
            }
        }
        '4' {
            Write-Host "`nTesting connections..." -ForegroundColor Yellow
            $providers = @('bedrock', 'difi', 'azure', 'openai', 'ollama')
            foreach ($p in $providers) {
                try {
                    $config = Get-CloudAgentConfig -ProviderName $p
                    Write-Host "$p : Config OK (enabled: $($config.enabled))" -ForegroundColor Green
                } catch {
                    Write-Host "$p : Not configured" -ForegroundColor Gray
                }
            }
        }
    }
}

function Get-ProviderList {
    $providers = @()
    $config = $null
    
    if (Test-Path $localConfigPath) {
        $config = Get-Content $localConfigPath -Raw | ConvertFrom-Json
    } elseif (Test-Path $templateConfigPath) {
        $config = Get-Content $templateConfigPath -Raw | ConvertFrom-Json
    }
    
    if ($config -and $config.providers) {
        foreach ($name in $config.providers.PSObject.Properties.Name) {
            $p = $config.providers.$name
            $apiKeyEnvVar = if ($p.api_key_env) { (Get-ChildItem "env:$($p.api_key_env)" -ErrorAction SilentlyContinue).Value } else { $null }
            $providers += [PSCustomObject]@{
                Name = $name
                Enabled = $p.enabled
                Model = $p.model
                Endpoint = $p.endpoint
                HasApiKey = -not [string]::IsNullOrWhiteSpace($apiKeyEnvVar)
            }
        }
    }
    
    return $providers
}

if ($ListProviders) {
    Write-Host "`n=== Available Cloud Providers ===" -ForegroundColor Cyan
    $list = Get-ProviderList
    if ($list.Count -eq 0) {
        Write-Host "No providers configured. Run with -Config to set up." -ForegroundColor Yellow
    } else {
        $list | Format-Table -AutoSize
    }
    return
}

if ($Config) {
    Show-ConfigMenu
    return
}

if ($Interactive) {
    Show-InteractiveMode
    return
}

if (-not $PSBoundParameters.ContainsKey('Provider')) {
    $Provider = Get-DefaultProvider
}

if ($TestConnection) {
    Write-Host "Testing $Provider connection..." -ForegroundColor Cyan
    
    $providerConfig = Get-CloudAgentConfig -ProviderName $Provider
    $result = Invoke-CloudRequest -RequestParams @{
        Provider = $Provider
        Messages = @(@{ role = 'user'; content = 'Ping' })
        Temperature = 0
        MaxTokens = 10
        Headers = $Headers
    }
    
    if ($result.Success) {
        Write-Host "Connection successful! Latency: $($result.LatencyMs)ms" -ForegroundColor Green
    } else {
        Write-Host "Connection failed: $($result.Error)" -ForegroundColor Red
    }
    return
}

$messages = @()

if ($Command) {
    $messages += @{ role = 'user'; content = $Command }
} elseif ($Script) {
    if (-not (Test-Path $Script)) {
        throw "Script file not found: $Script"
    }
    $scriptContent = Get-Content $Script -Raw
    $messages += @{ role = 'user'; content = "Execute this script and return the result: `n$scriptContent" }
} elseif ($Agent) {
    $systemDefault = "You are an expert AI agent. Execute tasks precisely and return ONLY JSON tool calls or the requested data. No conversational filler. If you cannot execute, return an error object."
    $system = if ($SystemPrompt) { $SystemPrompt } else { $systemDefault }
    $messages += @{ role = 'system'; content = $system }
    $messages += @{ role = 'user'; content = $Agent }
} else {
    throw "Provide -Command, -Script, -Agent, or use -Interactive mode. Run -Help for usage."
}

$systemInstruction = "STRICT MODE: You are an execution engine. Return ONLY valid JSON tool calls or requested data. No narration."
if ($StrictJson) {
    if ($messages[0].role -eq 'system') {
        $messages[0].content = $messages[0].content + " " + $systemInstruction
    } else {
        $messages = @(@{ role = 'system'; content = $systemInstruction }) + $messages
    }
}

$params = @{
    Provider = $Provider
    Model = if ($ModelOverride) { $ModelOverride } else { '' }
    Messages = $messages
    Temperature = $Temperature
    MaxTokens = $MaxTokens
    Headers = $Headers
}

$result = Invoke-CloudRequest -RequestParams $params

if ($result.Success) {
    if ($result.Response.choices) {
        $result.Response.choices[0].message.content
    } elseif ($result.Response.content) {
        $result.Response.content[0].text
    } else {
        $result.Response | ConvertTo-Json -Depth 5
    }
} else {
    throw "Cloud agent request failed: $($result.Error)"
}


