# token-usage-notifier.ps1
# Real-time token usage notification system
# Displays token metrics after each response and accumulated session totals

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("show", "accumulate", "summary", "toggle", "status")]
    [string]$Action,
    
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [string]$SessionId = "",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

# Robust path resolution
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    Get-Location
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)

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
        }
        $defaultConfig | ConvertTo-Json | Set-Content $displayConfigFile
    }
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
    $config | ConvertTo-Json | Set-Content $displayConfigFile
    
    $status = if ($config.enabled) { "ENABLED" } else { "DISABLED" }
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           TOKEN USAGE DISPLAY $status" -ForegroundColor Cyan -NoNewline
    if ($config.enabled) {
        Write-Host "           ║" -ForegroundColor Cyan
    } else {
        Write-Host "          ║" -ForegroundColor Cyan
    }
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    return $config.enabled
}

# Get current session ID
function Get-CurrentSessionId {
    if ($SessionId) { return $SessionId }
    
    # Try to get from session file
    $sessionFile = Get-ChildItem (Join-Path $configDir "session-*.json") -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if ($sessionFile) {
        try {
            $sessionData = Get-Content $sessionFile.FullName | ConvertFrom-Json
            return $sessionData.sessionId
        } catch {}
    }
    
    return "unknown"
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

# Display current message metrics
function Show-CurrentMetrics {
    param($InputTokens, $OutputTokens, $ContextChars)
    
    $config = Get-DisplayConfig
    if (-not $config.enabled -or $Silent) { return }
    
    $total = $InputTokens + $OutputTokens
    
    if ($config.compactMode) {
        Write-Host ""
        Write-Host "┌─ Token Usage ─────────────────┐" -ForegroundColor DarkGray
        Write-Host "│ Input:  " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($InputTokens.ToString().PadLeft(6))" -ForegroundColor Green -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Output: " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($OutputTokens.ToString().PadLeft(6))" -ForegroundColor Cyan -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Total:  " -ForegroundColor DarkGray -NoNewline
        Write-Host "$($total.ToString().PadLeft(6))" -ForegroundColor Yellow -NoNewline
        Write-Host " tk │" -ForegroundColor DarkGray
        Write-Host "│ Context:" -ForegroundColor DarkGray -NoNewline
        Write-Host "$($ContextChars.ToString().PadLeft(6))" -ForegroundColor Magenta -NoNewline
        Write-Host " ch │" -ForegroundColor DarkGray
        Write-Host "└───────────────────────────────┘" -ForegroundColor DarkGray
    } else {
        Write-Host ""
        Write-Host "=== Token Usage (Current Message) ===" -ForegroundColor Cyan
        Write-Host "  Input Tokens:  $InputTokens" -ForegroundColor Green
        Write-Host "  Output Tokens: $OutputTokens" -ForegroundColor Cyan
        Write-Host "  Total Tokens:  $total" -ForegroundColor Yellow
        Write-Host "  Context Chars: $ContextChars" -ForegroundColor Magenta
        Write-Host "=====================================" -ForegroundColor Cyan
    }
}

# Display accumulated metrics
function Show-AccumulatedMetrics {
    $config = Get-DisplayConfig
    if (-not $config.enabled -or $Silent) { return }
    
    $data = Get-TokenUsageData
    
    if ($data.messageCount -eq 0) { return }
    
    $avgInput = if ($data.messageCount -gt 0) { [math]::Round($data.totalInputTokens / $data.messageCount) } else { 0 }
    $avgOutput = if ($data.messageCount -gt 0) { [math]::Round($data.totalOutputTokens / $data.messageCount) } else { 0 }
    
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
        Write-Host "└───────────────────────────────┘" -ForegroundColor DarkGray
    } else {
        Write-Host ""
        Write-Host "=== Session Accumulated ===" -ForegroundColor Cyan
        Write-Host "  Messages:      $($data.messageCount)" -ForegroundColor White
        Write-Host "  Total Input:   $($data.totalInputTokens) tokens" -ForegroundColor Green
        Write-Host "  Total Output:  $($data.totalOutputTokens) tokens" -ForegroundColor Cyan
        Write-Host "  Grand Total:   $($data.totalTokens) tokens" -ForegroundColor Yellow
        Write-Host "  Avg In/Out:    $avgInput / $avgOutput tokens" -ForegroundColor Magenta
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

# Show current status
function Show-Status {
    $config = Get-DisplayConfig
    $data = Get-TokenUsageData
    
    Write-Host ""
    Write-Host "Token Usage Notifier Status" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host "Display Enabled: $($config.enabled)" -ForegroundColor $(if($config.enabled){'Green'}else{'Red'})
    Write-Host "Show After Each:   $($config.showAfterEachResponse)" -ForegroundColor White
    Write-Host "Show Accumulated:  $($config.showAccumulated)" -ForegroundColor White
    Write-Host "Compact Mode:      $($config.compactMode)" -ForegroundColor White
    Write-Host "Last Toggle:       $($config.lastToggle)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Current Session:   $($data.sessionId)" -ForegroundColor White
    Write-Host "Messages Tracked:  $($data.messageCount)" -ForegroundColor White
    Write-Host "Total Tokens:      $($data.totalTokens)" -ForegroundColor Yellow
    Write-Host ""
}

# Main execution
switch ($Action) {
    "show" {
        Show-CurrentMetrics -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars
    }
    "accumulate" {
        Accumulate-Metrics -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars
        if ((Get-DisplayConfig).showAfterEachResponse) {
            Show-CurrentMetrics -InputTokens $InputTokens -OutputTokens $OutputTokens -ContextChars $ContextChars
        }
        if ((Get-DisplayConfig).showAccumulated) {
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
