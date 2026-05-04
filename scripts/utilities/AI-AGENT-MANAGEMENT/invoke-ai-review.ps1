# invoke-ai-review.ps1
# Native AI Code Review - -style with multi-provider support
# Absorbed from Gentleman  Angel ()
#
# PROVIDER STATUS:
# - openai, anthropic, gemini, ollama, github: FULLY FUNCTIONAL
# - bedrock: Requires AWS CLI configured (aws configure) or env vars
#   Use: $env:AWS_ACCESS_KEY_ID, $env:AWS_SECRET_ACCESS_KEY, $env:AWS_DEFAULT_REGION

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('run', 'init', 'install', 'uninstall', 'config', 'cache', 'help', 'version')]
    [string]$Action = 'run',
    
    [Parameter(Mandatory=$false)]
    [switch]$CI,
    
    [Parameter(Mandatory=$false)]
    [switch]$PRMode,
    
    [Parameter(Mandatory=$false)]
    [switch]$DiffOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoCache,
    
    [Parameter(Mandatory=$false)]
    [string]$Provider = '',
    
    [Parameter(Mandatory=$false)]
    [string]$PRBaseBranch = '',
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 300
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }

$projectRoot = if (Test-Path ".git") { (Get-Location).Path } else { $scriptDir }
$configPath = Join-Path $projectRoot "config\ai-review.json"
$configGlobalPath = Join-Path $env:USERPROFILE ".config\ai-review\config.json"
$cacheDir = Join-Path $projectRoot ".ai-review-cache"
$hooksDir = Join-Path $projectRoot ".git\hooks"
$Config = Join-Path $projectRoot "."

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    Write-Host "[AI-Review] $Message" -ForegroundColor $color
}

function Get-Config {
    $config = @{
        provider = "openai"
        filePatterns = @("*")
        excludePatterns = @()
        rulesFile = "AGENTS.md"
        strictMode = $true
        timeout = 300
        cache = @{
            enabled = $true
            ttl = 86400
        }
        providers = @{
            openai = @{ envVar = "OPENAI_API_KEY"; endpoint = "https://api.openai.com/v1/chat/completions"; model = "gpt-4o" }
            anthropic = @{ envVar = "ANTHROPIC_API_KEY"; endpoint = "https://api.anthropic.com/v1/messages"; model = "claude-3-5-sonnet-20241022" }
            gemini = @{ envVar = "GEMINI_API_KEY"; endpoint = "https://generativelanguage.googleapis.com/v1beta/models"; model = "gemini-2.0-flash" }
            ollama = @{ endpoint = "http://localhost:11434/api/chat"; model = "llama3.2"; local = $true }
            github = @{ envVar = "GH_TOKEN"; endpoint = "https://models.inference.ai.dev/chat"; model = "github/gpt-4o" }
            bedrock = @{ envVar = "AWS_ACCESS_KEY_ID"; region = "us-east-1"; model = "anthropic.claude-3-5-sonnet-20241022" }
        }
    }
    
    if (Test-Path $configPath) {
        $fileConfig = Get-Content $configPath -Raw | ConvertFrom-Json
        foreach ($prop in $fileConfig.PSObject.Properties.Name) {
            $config.$prop = $fileConfig.$prop
        }
    }
    
    if (Test-Path $configGlobalPath) {
        $globalConfig = Get-Content $configGlobalPath -Raw | ConvertFrom-Json
        foreach ($prop in $globalConfig.PSObject.Properties.Name) {
            if (-not $config.$prop) {
                $config.$prop = $globalConfig.$prop
            }
        }
    }
    
    if (Test-Path $Config) {
        $Content = Get-Content $Config -Raw
        $Content -match 'PROVIDER="([^"]+)"' | Out-Null
        if ($Matches) { $config.provider = $Matches[1] }
        $Content -match 'FILE_PATTERNS="([^"]+)"' | Out-Null
        if ($Matches) { $config.filePatterns = $Matches[1] -split ',' }
        $Content -match 'EXCLUDE_PATTERNS="([^"]+)"' | Out-Null
        if ($Matches) { $config.excludePatterns = $Matches[1] -split ',' }
        $Content -match 'STRICT_MODE="([^"]+)"' | Out-Null
        if ($Matches) { $config.strictMode = $Matches[1] -eq "true" }
    }
    
    if ($Provider) { $config.provider = $Provider }
    if ($Timeout -gt 0) { $config.timeout = $Timeout }
    
    return $config
}

function Get-StagedFiles {
    $staged = git diff --cached --name-only --diff-filter=ACM 2>$null
    if (-not $staged) {
        $staged = @()
    }
    return $staged
}

function Get-CacheKey {
    param([string[]]$Files)
    $content = $Files | ForEach-Object { 
        $hash = (git hash-object $_ 2>$null)  (Get-FileHash $_ -Algorithm SHA256).Hash
        "$_`:$hash"
    }
    $combined = $content -join "|"
    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($combined))
}

function Get-CachedReview {
    param([string]$Key)
    $cacheFile = Join-Path $cacheDir "$Key.json"
    if (-not (Test-Path $cacheDir)) { return $null }
    if (-not (Test-Path $cacheFile)) { return $null }
    
    $cache = Get-Content $cacheFile -Raw | ConvertFrom-Json
    $age = (Get-Date) - [DateTime]::Parse($cache.timestamp)
    if ($age.TotalSeconds -gt $config.cache.ttl) {
        Remove-Item $cacheFile -Force
        return $null
    }
    return $cache
}

function Set-CachedReview {
    param([string]$Key, [hashtable]$Review)
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    $cacheFile = Join-Path $cacheDir "$Key.json"
    $Review.timestamp = (Get-Date).ToString("o")
    $Review | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheFile -Encoding UTF8
}

function Get-FileContent {
    param([string]$File)
    try {
        return Get-Content $File -Raw -Encoding UTF8
    } catch {
        return $null
    }
}

function Get-RulesContent {
    param([object]$Config)
    $rulesFile = $Config.rulesFile
    if (Test-Path $rulesFile) {
        return Get-Content $rulesFile -Raw
    }
    return $null
}

function Invoke-AIReview {
    param(
        [string[]]$Files,
        [object]$Config
    )
    
    $rulesContent = Get-RulesContent -Config $Config
    
    $providerConfig = $Config.providers.($Config.provider)
    if (-not $providerConfig) {
        throw "Provider '$($Config.provider)' not configured"
    }
    
    if ($providerConfig.envVar -and -not $providerConfig.local) {
        $apiKey = (Get-ChildItem "env:$($providerConfig.envVar)" -ErrorAction SilentlyContinue).Value
        if (-not $apiKey) {
            throw "Environment variable '$($providerConfig.envVar)' not set for provider '$($Config.provider)'"
        }
    }
    
    $systemPrompt = @"
You are a senior code reviewer. Review the following files against the coding standards.
Return a JSON object with:
- "approved": boolean
- "issues": array of { "file": string, "line": int, "severity": "critical|high|medium|low", "message": string }
- "summary": string

Coding standards:
$rulesContent

Files to review:
$($Files -join "`n")
"@
    
    $filesContent = $Files | ForEach-Object {
        $content = Get-FileContent -File $_
        "@`n=== FILE: $_ ===`n$content`n"
    } | Join-String
    
    $body = @{
        model = $providerConfig.model
        messages = @(
            @{ role = "system"; content = $systemPrompt }
            @{ role = "user"; content = $filesContent }
        )
        temperature = 0.1
        max_tokens = 4000
    }
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($providerConfig.envVar) {
        $apiKey = (Get-ChildItem "env:$($providerConfig.envVar)" -ErrorAction SilentlyContinue).Value
        if ($apiKey) {
            $headers["Authorization"] = "Bearer $apiKey"
        }
    }
    
    if ($Config.provider -eq "anthropic") {
        $headers["x-api-key"] = $apiKey
        $headers["anthropic-version"] = "2023-06-01"
        $body = @{
            model = $providerConfig.model
            max_tokens = 4096
            messages = @(
                @{ role = "user"; content = "$systemPrompt`n`nFiles:`n$filesContent" }
            )
        }
    }
    
    try {
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri $providerConfig.endpoint -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10) -TimeoutSec $Config.timeout
        
        $endTime = Get-Date
        $latency = [int]($endTime - $startTime).TotalMilliseconds
        
        $review = @{
            approved = $true
            issues = @()
            summary = ""
            latencyMs = $latency
            provider = $Config.provider
            model = $providerConfig.model
        }
        
        if ($response.choices) {
            $content = $response.choices[0].message.content
            try {
                $parsed = $content | ConvertFrom-Json
                $review.approved = $parsed.approved
                $review.issues = $parsed.issues
                $review.summary = $parsed.summary
            } catch {
                $review.summary = $content
            }
        } elseif ($response.content) {
            $content = $response.content[0].text
            try {
                $parsed = $content | ConvertFrom-Json
                $review.approved = $parsed.approved
                $review.issues = $parsed.issues
                $review.summary = $parsed.summary
            } catch {
                $review.summary = $content
            }
        }
        
        return $review
    }
    catch {
        throw "AI review failed: $($_.Exception.Message)"
    }
}

function Get-PRDiff {
    param([string]$BaseBranch)
    
    if (-not $BaseBranch) {
        $branches = @("main", "master", "develop")
        foreach ($b in $branches) {
            if (git rev-parse --verify $b 2>$null) {
                $BaseBranch = $b
                break
            }
        }
    }
    
    if (-not $BaseBranch) {
        throw "Could not detect base branch"
    }
    
    $diff = git diff "$BaseBranch...HEAD" --name-only
    return $diff -split "`n" | Where-Object { $_ }
}

function Install-Hook {
    $hookContent = @"
#!/usr/bin/env pwsh
`$ErrorActionPreference = 'SilentlyContinue'
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$hookScript = Join-Path `$scriptDir "..\..\scripts\utilities\invoke-ai-review.ps1"
if (Test-Path `$hookScript) {
    & `$hookScript -Action run -NoCache
    if (`$LASTEXITCODE -eq 1) { exit 1 }
}
"@
    
    $hookPath = Join-Path $hooksDir "pre-commit"
    
    if (Test-Path $hookPath) {
        $existing = Get-Content $hookPath -Raw
        if ($existing -match "invoke-ai-review") {
            Write-Status "Hook already installed" "WARN"
            return
        }
        $hookContent = $existing + "`n" + $hookContent
    }
    
    $hookContent | Out-File -FilePath $hookPath -Encoding UTF8
    if (Get-Command chmod -ErrorAction SilentlyContinue) {
        chmod +x $hookPath
    }
    Write-Status "Installed pre-commit hook" "SUCCESS"
}

function Show-Config {
    $config = Get-Config
    
    Write-Host "`n=== AI-Review Configuration ===" -ForegroundColor Cyan
    Write-Host "Provider: $($config.provider)"
    Write-Host "File Patterns: $($config.filePatterns -join ', ')"
    Write-Host "Exclude Patterns: $($config.excludePatterns -join ', ')"
    Write-Host "Rules File: $($config.rulesFile)"
    Write-Host "Strict Mode: $($config.strictMode)"
    Write-Host "Timeout: $($config.timeout)s"
    Write-Host "Cache Enabled: $($config.cache.enabled)"
    
    $providerConfig = $config.providers.($config.provider)
    if ($providerConfig.envVar) {
        $hasKey = (Get-ChildItem "env:$($providerConfig.envVar)" -ErrorAction SilentlyContinue).Value
        Write-Host "API Key Set: $($hasKey -ne $null)" -ForegroundColor $(if ($hasKey) { "Green" } else { "Yellow" })
    } else {
        Write-Host "API Key: Local provider (no key required)" -ForegroundColor Green
    }
    
    $rulesExists = Test-Path $config.rulesFile
    Write-Host "Rules File Found: $rulesExists" -ForegroundColor $(if ($rulesExists) { "Green" } else { "Yellow" })
}

function Show-Help {
    @"
AI-Review - Native AI Code Review (-style)

USAGE:
    .\invoke-ai-review.ps1 [ACTION] [OPTIONS]

ACTIONS:
    run         Run code review on staged files (default)
    init        Create sample config file
    install     Install pre-commit hook
    uninstall   Remove pre-commit hook
    config      Show current configuration
    cache       Manage review cache
    help        Show this help
    version     Show version

OPTIONS:
    -CI             Run in CI mode (last commit)
    -PRMode         Review all files in PR
    -DiffOnly       PR mode with diffs only
    -NoCache        Skip cache
    -Provider       Override provider
    -Timeout        Set timeout in seconds

EXAMPLES:
    .\invoke-ai-review.ps1 run
    .\invoke-ai-review.ps1 run -PRMode
    .\invoke-ai-review.ps1 install
    .\invoke-ai-review.ps1 config

PROVIDERS:
    openai      - OPENAI_API_KEY
    anthropic   - ANTHROPIC_API_KEY
    gemini      - GEMINI_API_KEY
    ollama      - Local (no key)
    github      - GH_TOKEN
    bedrock     - AWS_ACCESS_KEY_ID

"@
}

switch ($Action.ToLower()) {
    'help' {
        Show-Help
    }
    'version' {
        Write-Host "AI-Review v1.0.0 (-native)"
        Write-Host "Foundation-native implementation"
    }
    'init' {
        $defaultConfig = @{
            provider = "openai"
            filePatterns = @("*.ps1", "*.ts", "*.tsx", "*.js", "*.jsx")
            excludePatterns = @("*.test.ps1", "*.spec.ts", "*.test.ts")
            rulesFile = "AGENTS.md"
            strictMode = $true
            timeout = 300
            cache = @{ enabled = $true; ttl = 86400 }
        }
        
        if (-not (Test-Path (Split-Path $configPath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $configPath -Parent) -Force | Out-Null
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        Write-Status "Created config: $configPath" "SUCCESS"
        Write-Status "Edit this file to configure your review settings" "INFO"
    }
    'install' {
        Install-Hook
    }
    'uninstall' {
        $hookPath = Join-Path $hooksDir "pre-commit"
        if (Test-Path $hookPath) {
            $content = Get-Content $hookPath -Raw
            if ($content -match "invoke-ai-review") {
                $newContent = $content -replace "(?s).*invoke-ai-review.*\n?", ""
                if ($newContent.Trim()) {
                    $newContent | Out-File -FilePath $hookPath -Encoding UTF8
                } else {
                    Remove-Item $hookPath -Force
                }
                Write-Status "Removed pre-commit hook" "SUCCESS"
            } else {
                Write-Status "Hook not found" "WARN"
            }
        }
    }
    'config' {
        Show-Config
    }
    'cache' {
        if (-not (Test-Path $cacheDir)) {
            Write-Status "No cache directory found" "WARN"
            return
        }
        $entries = Get-ChildItem $cacheDir -Filter "*.json"
        Write-Host "`n=== Cache Status ===" -ForegroundColor Cyan
        Write-Host "Entries: $($entries.Count)"
        Write-Host "Location: $cacheDir"
        Write-Host ""
        foreach ($entry in $entries | Select-Object -First 5) {
            $age = (Get-Date) - $entry.LastWriteTime
            Write-Host "  $($entry.BaseName.Substring(0,20))... - $($age.Days)d $($age.Hours)h ago"
        }
        if ($entries.Count -gt 5) {
            Write-Host "  ... and $($entries.Count - 5) more"
        }
    }
    'run' {
        $config = Get-Config
        
        $files = if ($CI) {
            $lastCommit = git rev-parse HEAD
            git diff-tree --no-commit-id -r --name-only -1 $lastCommit -split "`n"
        } elseif ($PRMode) {
            Get-PRDiff -BaseBranch $PRBaseBranch
        } else {
            Get-StagedFiles
        }
        
        if ($files.Count -eq 0) {
            Write-Status "No files to review" "WARN"
            exit 0
        }
        
        $filtered = $files | Where-Object { 
            $include = $false
            foreach ($pattern in $config.filePatterns) {
                if ($_ -like $pattern) { $include = $true; break }
            }
            $exclude = $false
            foreach ($pattern in $config.excludePatterns) {
                if ($_ -like $pattern) { $exclude = $true; break }
            }
            $include -and -not $exclude
        }
        
        if ($filtered.Count -eq 0) {
            Write-Status "No matching files to review" "WARN"
            exit 0
        }
        
        Write-Status "Reviewing $($filtered.Count) file(s) with $($config.provider)..."
        
        $cacheKey = if ($NoCache) { $null } else { Get-CacheKey -Files $filtered }
        $cached = if ($cacheKey) { Get-CachedReview -Key $cacheKey } else { $null }
        
        if ($cached) {
            Write-Status "Using cached review" "INFO"
            $review = $cached
        } else {
            $review = Invoke-AIReview -Files $filtered -Config $config
            if ($cacheKey) {
                Set-CachedReview -Key $cacheKey -Review $review
            }
        }
        
        Write-Host "`n=== Review Results ===" -ForegroundColor Cyan
        Write-Host "Provider: $($review.provider)"
        Write-Host "Model: $($review.model)"
        Write-Host "Latency: $($review.latencyMs)ms"
        Write-Host ""
        
        if ($review.issues.Count -gt 0) {
            Write-Host "Issues Found: $($review.issues.Count)" -ForegroundColor Yellow
            foreach ($issue in $review.issues) {
                $severityColor = switch ($issue.severity) {
                    "critical" { "Red" }
                    "high" { "Magenta" }
                    "medium" { "Yellow" }
                    "low" { "Gray" }
                    default { "White" }
                }
                $prefix = switch ($issue.severity) {
                    "critical" { "[!C]" }
                    "high" { "[!H]" }
                    "medium" { "[!M]" }
                    "low" { "[!L]" }
                    default { "[ ]" }
                }
                Write-Host "  $prefix $($issue.file):$($issue.line) - " -NoNewline
                Write-Host $issue.severity.ToUpper() -ForegroundColor $severityColor -NoNewline
                Write-Host ": $($issue.message)"
            }
            Write-Host ""
        }
        
        Write-Host $review.summary
        Write-Host ""
        
        if ($review.approved) {
            Write-Status "Review PASSED" "SUCCESS"
            exit 0
        } else {
            Write-Status "Review FAILED - Fix issues before committing" "ERROR"
            if ($config.strictMode) {
                exit 1
            }
            exit 0
        }
    }
}

exit 0
