# token-usage-notifier.ps1
# Real-time token usage notification system
# Displays token metrics after each response and accumulated session totals

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("show", "accumulate", "summary", "toggle", "status", "auto")]
    [string]$Action,
    
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [string]$SessionId = "",
    [string]$Model = "",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

# Robust path resolution - FIXED: Use environment variable or traverse up to find repo root
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}

# FIXED: Better repo root detection
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    # Traverse up from script location to find repo root (look for .git or config directory)
    $root = $scriptRoot
    $found = $false
    while ($root -and -not $found) {
        if ((Test-Path (Join-Path $root '.git')) -or 
            (Test-Path (Join-Path $root 'config\orchestrator.json')) -or
            (Test-Path (Join-Path $root 'CLAUDE.md'))) {
            $found = $true
            break
        }
        $parent = Split-Path -Parent $root
        if ($parent -eq $root) { break }
        $root = $parent
    }
    if (-not $found) {
        # Fallback: use the original logic but go up one more level from scripts/utilities
        $root = Split-Path -Parent (Split-Path -Parent $scriptRoot)
    }
    $root
}

# Configuration
$configDir = Join-Path $repoRoot ".session"
$tokenUsageFile = Join-Path $configDir "token-usage.json"
$displayConfigFile = Join-Path $configDir "token-display-config.json"

# Ensure directory exists
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Initialize display config if not exists
function Initialize-DisplayConfig {
    if (-not (Test-Path $displayConfigFile)) {
        $defaultConfig = @{
            enabled = $true
            showAfterEachResponse = $true
            showAccumulated = $true
            compactMode = $true
            lastToggle = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            individualToggles = @{
                tokenUsage = $true
                contextSize = $true
                estimatedCost = $true
                sessionAccumulated = $true
            }
        }
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content $displayConfigFile
    }
}

# Estimate cost in USD from tokens — reads provider-costs.json for model rates
function Get-EstimatedCost {
    param($InputTokens, $OutputTokens, [string]$ModelName = "")

    $inputRate = 3.0   # default $/M tokens input
    $outputRate = 15.0 # default $/M tokens output

    if ($ModelName) {
        $costsFile = Join-Path $repoRoot "config\provider-costs.json"
        if (Test-Path $costsFile) {
            try {
                $costs = Get-Content $costsFile -Raw | ConvertFrom-Json
                # Search across all providers for matching model
                foreach ($prov in $costs.providers.PSObject.Properties) {
                    $models = $prov.Value.models
                    if ($models.PSObject.Properties[$ModelName]) {
                        $m = $models.PSObject.Properties[$ModelName].Value
                        $inputRate = [float]$m.input * 1000  # convert per-1K to per-M
                        $outputRate = [float]$m.output * 1000
                        break
                    }
                }
            } catch {}
        }
    }

    $inputCost = ($InputTokens / 1000000) * $inputRate
    $outputCost = ($OutputTokens / 1000000) * $outputRate
    return [math]::Round($inputCost + $outputCost, 5)
}

# Get display config
function Get-DisplayConfig {
    Initialize-DisplayConfig
    return Get-Content $displayConfigFile | ConvertFrom-Json
}

# Toggle display setting
function Toggle-Display {
    $config = Get-DisplayConfig
    $config.enabled = -not $config.enabled
    $config.lastToggle = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $config | ConvertTo-Json -Depth 10 | Set-Content $displayConfigFile
    
    $status = if ($config.enabled) { "ENABLED" } else { "DISABLED" }
    $padding = " " * (22 - $status.Length)
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           TOKEN USAGE DISPLAY $status$padding║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Get current session ID
function Get-CurrentSessionId {
    if ($SessionId) { return $SessionId }
    
    # Try to get from session file in .session directory
    $sessionFile = Get-ChildItem (Join-Path $configDir "session-*.json") -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if ($sessionFile) {
        try {
            $sessionData = Get-Content $sessionFile.FullName | ConvertFrom-Json
            return $sessionData.sessionId
        } catch {}
    }
    
    # Fallback: check logs directory for most recent session
    $logsDir = Join-Path $repoRoot 'logs'
    $logSessionFile = Get-ChildItem (Join-Path $logsDir "session-*.json") -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if ($logSessionFile) {
        try {
            $sessionData = Get-Content $logSessionFile.FullName | ConvertFrom-Json
            # Handle both sessionId (logs) and SessionId (session files) case sensitivity
            return $sessionData.sessionId ?? $sessionData.SessionId
        } catch {}
    }
    
    # Final fallback: check token-usage.json for current session
    if (Test-Path $tokenUsageFile) {
        try {
            $data = Get-Content $tokenUsageFile -Raw | ConvertFrom-Json
            if ($data.sessionId) { return $data.sessionId }
        } catch {}
    }
    
    # Last resort: return empty string instead of "unknown" for better UX
    return ""
}

# Initialize or load token usage data
function Get-TokenUsageData {
    $currentSession = Get-CurrentSessionId
    
    if (Test-Path $tokenUsageFile) {
        $data = Get-Content $tokenUsageFile | ConvertFrom-Json
        if ($data.sessionId -ne $currentSession) {
            # New session, reset counters
            return @{
                sessionId = $currentSession
                startTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                messages = @()
                totalInputTokens = 0
                totalOutputTokens = 0
                totalTokens = 0
                totalContextChars = 0
                messageCount = 0
            }
        }
        return $data
    }
    
    return @{
        sessionId = $currentSession
        startTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        messages = @()
        totalInputTokens = 0
        totalOutputTokens = 0
        totalTokens = 0
        totalContextChars = 0
        messageCount = 0
    }
}

# Save token usage data
function Save-TokenUsageData($data) {
    $data | ConvertTo-Json -Depth 10 | Set-Content $tokenUsageFile
}

# Display current message metrics (respects individualToggles)
function Show-CurrentMetrics {
    param([int]$InTok, [int]$OutTok, [int]$CtxChars)
    
    $config = Get-DisplayConfig
    if (-not $config.enabled -or $Silent) { return }
    
    $total = $InTok + $OutTok
    $showToken = [bool]($config.individualToggles -and $config.individualToggles.tokenUsage)
    $showCtx = [bool]($config.individualToggles -and $config.individualToggles.contextSize)
    $showCost = [bool]($config.individualToggles -and $config.individualToggles.estimatedCost)
    
    $any = $showToken -or $showCtx -or $showCost
    if (-not $any) { return }
    
    if ($config.compactMode) {
        Write-Host ""
        Write-Host "┌─ This Turn ────────────────────┐" -ForegroundColor DarkGray
        if ($showToken) {
            Write-Host "│ Input:  " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($InTok.ToString().PadLeft(6))" -ForegroundColor Green -NoNewline
            Write-Host " tk │" -ForegroundColor DarkGray
            Write-Host "│ Output: " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($OutTok.ToString().PadLeft(6))" -ForegroundColor Cyan -NoNewline
            Write-Host " tk │" -ForegroundColor DarkGray
            Write-Host "│ Total:  " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($total.ToString().PadLeft(6))" -ForegroundColor Yellow -NoNewline
            Write-Host " tk │" -ForegroundColor DarkGray
        }
        if ($showCtx) {
            Write-Host "│ Context:" -ForegroundColor DarkGray -NoNewline
            Write-Host "$($CtxChars.ToString().PadLeft(6))" -ForegroundColor Magenta -NoNewline
            Write-Host " ch │" -ForegroundColor DarkGray
        }
        if ($showCost) {
            $cost = Get-EstimatedCost -InputTokens $InTok -OutputTokens $OutTok -ModelName $Model
            Write-Host "│ Cost:   " -ForegroundColor DarkGray -NoNewline
            Write-Host "$('$' + $cost.ToString('F5').PadLeft(8))" -ForegroundColor DarkYellow -NoNewline
            Write-Host "   │" -ForegroundColor DarkGray
        }
        Write-Host "└───────────────────────────────┘" -ForegroundColor DarkGray
    } else {
        Write-Host ""
        Write-Host "=== This Turn ===" -ForegroundColor Cyan
        if ($showToken) {
            Write-Host "  Input Tokens:  $InTok" -ForegroundColor Green
            Write-Host "  Output Tokens: $OutTok" -ForegroundColor Cyan
            Write-Host "  Total Tokens:  $total" -ForegroundColor Yellow
        }
        if ($showCtx) {
            Write-Host "  Context Chars: $CtxChars" -ForegroundColor Magenta
        }
        if ($showCost) {
            $cost = Get-EstimatedCost -InputTokens $InTok -OutputTokens $OutTok -ModelName $Model
            Write-Host "  Est. Cost:     `$$cost" -ForegroundColor DarkYellow
        }
        Write-Host "=================" -ForegroundColor Cyan
    }
}

# Display accumulated metrics (respects individualToggles.sessionAccumulated)
function Show-AccumulatedMetrics {
    $config = Get-DisplayConfig
    if (-not $config.enabled -or $Silent) { return }
    if ($config.individualToggles -and -not $config.individualToggles.sessionAccumulated) { return }
    
    $data = Get-TokenUsageData
    
    if ($data.messageCount -eq 0) { return }
    
    $avgInput = if ($data.messageCount -gt 0) { [math]::Round($data.totalInputTokens / $data.messageCount) } else { 0 }
    $avgOutput = if ($data.messageCount -gt 0) { [math]::Round($data.totalOutputTokens / $data.messageCount) } else { 0 }
    $totalCost = Get-EstimatedCost -InputTokens $data.totalInputTokens -OutputTokens $data.totalOutputTokens -ModelName $Model
    
    if ($config.compactMode) {
        Write-Host "┌─ Session Accumulated ─────────┐" -ForegroundColor DarkGray
        Write-Host "│ Messages:    " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($data.messageCount.ToString().PadLeft(6))" -ForegroundColor White -NoNewline
        Write-Host "    │" -ForegroundColor DarkGray
        Write-Host "│ Total In:   " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($data.totalInputTokens.ToString().PadLeft(6))" -ForegroundColor Green -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Total Out:  " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($data.totalOutputTokens.ToString().PadLeft(6))" -ForegroundColor Cyan -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Grand Total:" -ForegroundColor DarkGray -NoNewline
        Write-Host "$($data.totalTokens.ToString().PadLeft(6))" -ForegroundColor Yellow -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Avg In/Out: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$("$avgInput/$avgOutput".PadLeft(6))" -ForegroundColor Magenta -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Total Cost: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$('$' + $totalCost.ToString('F4').PadLeft(7))" -ForegroundColor DarkYellow -NoNewline
        Write-Host "   │" -ForegroundColor DarkGray
        Write-Host "└───────────────────────────────┘" -ForegroundColor DarkGray
    } else {
        Write-Host ""
        Write-Host "=== Session Accumulated ===" -ForegroundColor Cyan
        Write-Host "  Messages:      $($data.messageCount)" -ForegroundColor White
        Write-Host "  Total Input:   $($data.totalInputTokens) tokens" -ForegroundColor Green
        Write-Host "  Total Output:  $($data.totalOutputTokens) tokens" -ForegroundColor Cyan
        Write-Host "  Grand Total:   $($data.totalTokens) tokens" -ForegroundColor Yellow
        Write-Host "  Avg In/Out:    $avgInput / $avgOutput tokens" -ForegroundColor Magenta
        Write-Host "  Total Cost:    `$$totalCost" -ForegroundColor DarkYellow
        Write-Host "===========================" -ForegroundColor Cyan
    }
}

# Accumulate metrics for current message
function Accumulate-Metrics {
    param($InputTokens, $OutputTokens, $ContextChars)
    
    $data = Get-TokenUsageData
    
    $message = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        inputTokens = $InputTokens
        outputTokens = $OutputTokens
        totalTokens = $InputTokens + $OutputTokens
        contextChars = $ContextChars
    }
    
    $data.messages += $message
    $data.totalInputTokens += $InputTokens
    $data.totalOutputTokens += $OutputTokens
    $data.totalTokens += ($InputTokens + $OutputTokens)
    $data.totalContextChars += $ContextChars
    $data.messageCount = $data.messages.Count
    
    Save-TokenUsageData $data
}

# Show final session summary
function Show-SessionSummary {
    $data = Get-TokenUsageData
    
    try {
        $startTime = [DateTime]::ParseExact($data.startTime, "yyyy-MM-ddTHH:mm:ss", $null)
        $duration = (Get-Date) - $startTime
        $durationStr = "{0:hh\:mm\:ss}" -f $duration
    } catch {
        $durationStr = "N/A"
    }
    
    $avgInput = if ($data.messageCount -gt 0) { [math]::Round($data.totalInputTokens / $data.messageCount) } else { 0 }
    $avgOutput = if ($data.messageCount -gt 0) { [math]::Round($data.totalOutputTokens / $data.messageCount) } else { 0 }
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    SESSION TOKEN SUMMARY                         ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Session ID:    $($data.sessionId.PadRight(47)) ║" -ForegroundColor White
    Write-Host "║  Duration:      $($durationStr.PadRight(47)) ║" -ForegroundColor White
    Write-Host "║  Messages:      $($data.messageCount.ToString().PadRight(47)) ║" -ForegroundColor White
    Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  TOTAL INPUT:   $($data.totalInputTokens.ToString().PadLeft(10)) tokens" -ForegroundColor Green -NoNewline
    Write-Host " ($($avgInput) avg/msg)".PadRight(19) -ForegroundColor DarkGray -NoNewline
    Write-Host " ║" -ForegroundColor Cyan
    Write-Host "║  TOTAL OUTPUT:  $($data.totalOutputTokens.ToString().PadLeft(10)) tokens" -ForegroundColor Cyan -NoNewline
    Write-Host " ($($avgOutput) avg/msg)".PadRight(19) -ForegroundColor DarkGray -NoNewline
    Write-Host " ║" -ForegroundColor Cyan
    Write-Host "║  GRAND TOTAL:   $($data.totalTokens.ToString().PadLeft(10)) tokens" -ForegroundColor Yellow -NoNewline
    Write-Host "".PadRight(32) -NoNewline
    Write-Host " ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Context Chars: $($data.totalContextChars.ToString().PadLeft(48)) ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Save to Engram
    try {
        $summary = @{
            sessionId = $data.sessionId
            duration = $durationStr
            messages = $data.messageCount
            totalInput = $data.totalInputTokens
            totalOutput = $data.totalOutputTokens
            grandTotal = $data.totalTokens
            avgInput = $avgInput
            avgOutput = $avgOutput
            contextChars = $data.totalContextChars
        }
        
        # Note: In real implementation, this would call engram_mem_save
        # For now, we just display
    } catch {}
}

# Show current status (with individual toggles)
function Show-Status {
    $config = Get-DisplayConfig
    $data = Get-TokenUsageData
    
    # Ensure individualToggles exist
    if (-not $config.individualToggles) {
        $config | Add-Member -MemberType NoteProperty -Name "individualToggles" -Value @{
            tokenUsage = $true; contextSize = $true; estimatedCost = $true; sessionAccumulated = $true
        }
    }
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              NOTIFICATION STATUS                          ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    $ge = if ($config.enabled) { "ENABLED " } else { "DISABLED" }
    Write-Host "║  Global:           $ge" -ForegroundColor $(if($config.enabled){'Green'}else{'Red'}) -NoNewline
    Write-Host "                             ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    $t = if ($config.individualToggles.tokenUsage) { "ON " } else { "OFF" }
    Write-Host "║  Token Usage:      $t" -ForegroundColor $(if($config.individualToggles.tokenUsage){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    $c = if ($config.individualToggles.contextSize) { "ON " } else { "OFF" }
    Write-Host "║  Context Size:     $c" -ForegroundColor $(if($config.individualToggles.contextSize){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    $e = if ($config.individualToggles.estimatedCost) { "ON " } else { "OFF" }
    Write-Host "║  Estimated Cost:   $e" -ForegroundColor $(if($config.individualToggles.estimatedCost){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    $a = if ($config.individualToggles.sessionAccumulated) { "ON " } else { "OFF" }
    Write-Host "║  Session Accum:    $a" -ForegroundColor $(if($config.individualToggles.sessionAccumulated){'Green'}else{'Red'}) -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Compact Mode:     $(if($config.compactMode){'ON '}else{'OFF'})" -ForegroundColor White -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    Write-Host "║  Show After Each:  $(if($config.showAfterEachResponse){'ON '}else{'OFF'})" -ForegroundColor White -NoNewline
    Write-Host "                                   ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    $sessionIdDisplay = if ([string]::IsNullOrWhiteSpace($data.sessionId)) { "N/A" } else { $data.sessionId }
    Write-Host "  Current Session:   $sessionIdDisplay" -ForegroundColor White
    Write-Host "  Messages Tracked:  $($data.messageCount)" -ForegroundColor White
    Write-Host "  Total Tokens:      $($data.totalTokens)" -ForegroundColor Yellow
    Write-Host "  Total Cost:       $" -ForegroundColor DarkYellow -NoNewline
    $totalCost = Get-EstimatedCost -InputTokens $data.totalInputTokens -OutputTokens $data.totalOutputTokens -ModelName $Model
    Write-Host "$totalCost" -ForegroundColor DarkYellow
    Write-Host ""
}

# Main execution
switch ($Action) {
    "show" {
        Show-CurrentMetrics -InTok $InputTokens -OutTok $OutputTokens -CtxChars $ContextChars
    }
    "accumulate" {
        Accumulate-Metrics -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars
        if ((Get-DisplayConfig).showAfterEachResponse) {
            Show-CurrentMetrics -InTok $InputTokens -OutTok $OutputTokens -CtxChars $ContextChars
        }
        if ((Get-DisplayConfig).showAccumulated) {
            Show-AccumulatedMetrics
        }
    }
    "auto" {
        # Auto-display hook: muestra el estado actual sin acumular nuevo turno
        # Se ejecuta al inicio de cada turno desde pre-process-input.ps1
        $config = Get-DisplayConfig
        if (-not $config.enabled) { return }
        
        $data = Get-TokenUsageData
        if ($data.messageCount -gt 0) {
            Show-AccumulatedMetrics
        }
    }
    "summary" {
        Show-SessionSummary
    }
    "toggle" {
        Toggle-Display
    }
    "status" {
        Show-Status
    }
}

exit 0
