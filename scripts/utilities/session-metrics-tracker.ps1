# session-metrics-tracker.ps1
# Tracks and persists session metrics during the session lifecycle
# Called from start-session.ps1 and end-session.ps1

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "update", "end", "status")]
    [string]$Action,
    [string]$SessionId,
    [string]$ProjectRoot = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [int]$ContextChars = 0,
    [int]$ToolCalls = 0,
    [int]$FilesRead = 0,
    [int]$FilesEdited = 0,
    [int]$FilesCreated = 0,
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

if (-not $ProjectRoot) {
    $ProjectRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) { $env:GV_BASE_DIR } else {
        $root = Split-Path -Parent $PSScriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
        if (-not $root) { $root = $PSScriptRoot }
        $root
    }
}

$metricsDir = Join-Path $ProjectRoot ".session\metrics"
$stateFile = Join-Path $metricsDir "current-session.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Silent) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Get-CostEstimate {
    param([int]$Tokens)
    $costPer1M = 15.0
    return [math]::Round(($Tokens / 1000000) * $costPer1M, 4)
}

if (-not (Test-Path $metricsDir)) {
    New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    Write-Log "Created metrics directory: $metricsDir"
}

switch ($Action) {
    "start" {
        $SessionId = if ($SessionId) { $SessionId } else { "session-$(Get-Date -Format 'yyyy-MM-dd-HH')" }
        
        $data = @{
            sessionId = $SessionId
            startTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            lastUpdate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            status = "active"
            metrics = @{
                inputTokens = $InputTokens
                outputTokens = $OutputTokens
                totalTokens = $InputTokens + $OutputTokens
                estimatedCostUsd = Get-CostEstimate -Tokens ($InputTokens + $OutputTokens)
                contextChars = $ContextChars
                toolCalls = $ToolCalls
                filesRead = $FilesRead
                filesEdited = $FilesEdited
                filesCreated = $FilesCreated
            }
        }
        
        $data | ConvertTo-Json -Depth 5 | Out-File -FilePath $stateFile -Encoding UTF8
        Write-Log "Started tracking session: $SessionId" "OK"
    }
    
    "update" {
        if (-not (Test-Path $stateFile)) {
            Write-Log "No active session to update. Run with -Action start first." "WARN"
            exit 0
        }
        
        $data = Get-Content $stateFile -Raw | ConvertFrom-Json
        
        $data | Add-Member -NotePropertyName 'lastUpdate' -NotePropertyValue (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") -Force
        $data | Add-Member -NotePropertyName 'status' -NotePropertyValue 'active' -Force
        
        if ($InputTokens -gt 0) { $data.metrics.inputTokens += $InputTokens }
        if ($OutputTokens -gt 0) { $data.metrics.outputTokens += $OutputTokens }
        if ($ContextChars -gt 0) { $data.metrics.contextChars += $ContextChars }
        if ($ToolCalls -gt 0) { $data.metrics.toolCalls += $ToolCalls }
        if ($FilesRead -gt 0) { $data.metrics.filesRead += $FilesRead }
        if ($FilesEdited -gt 0) { $data.metrics.filesEdited += $FilesEdited }
        if ($FilesCreated -gt 0) { $data.metrics.filesCreated += $FilesCreated }
        
        $data.metrics.totalTokens = $data.metrics.inputTokens + $data.metrics.outputTokens
        $data.metrics.estimatedCostUsd = Get-CostEstimate -Tokens $data.metrics.totalTokens
        
        $data | ConvertTo-Json -Depth 5 | Out-File -FilePath $stateFile -Encoding UTF8
        Write-Log "Updated session metrics" "OK"
    }
    
    "end" {
        if (-not (Test-Path $stateFile)) {
            Write-Log "No active session to end." "WARN"
            exit 0
        }
        
        $data = Get-Content $stateFile -Raw | ConvertFrom-Json
        
        $endTime = Get-Date
        $data | Add-Member -NotePropertyName 'endTime' -NotePropertyValue ($endTime.ToString("yyyy-MM-ddTHH:mm:ss")) -Force
        $data | Add-Member -NotePropertyName 'lastUpdate' -NotePropertyValue ($endTime.ToString("yyyy-MM-ddTHH:mm:ss")) -Force
        $data | Add-Member -NotePropertyName 'status' -NotePropertyValue 'completed' -Force
        
        $startTime = [DateTime]::ParseExact($data.startTime, @('yyyy-MM-ddTHH:mm:ss', 'MM/dd/yyyy HH:mm:ss', 'yyyy-MM-dd HH:mm:ss', 'MM/dd/yyyy hh:mm:ss tt'), [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None)
        $data | Add-Member -NotePropertyName 'durationSeconds' -NotePropertyValue ([math]::Round(($endTime - $startTime).TotalSeconds, 0)) -Force
        
        $sessionFile = Join-Path $ProjectRoot ".session\$($data.sessionId).json"
        $sessionFileAlt = Join-Path $ProjectRoot "session\$($data.sessionId).json"
        if (-not (Test-Path $sessionFile) -and (Test-Path $sessionFileAlt)) {
            $sessionFile = $sessionFileAlt
        }
        if (Test-Path $sessionFile) {
            $sessionData = Get-Content $sessionFile -Raw | ConvertFrom-Json
            $sessionData | Add-Member -NotePropertyName "endTime" -NotePropertyValue $data.endTime -Force
            $sessionData | Add-Member -NotePropertyName "durationSeconds" -NotePropertyValue $data.durationSeconds -Force
            $sessionData | Add-Member -NotePropertyName "metrics" -NotePropertyValue $data.metrics -Force
            $sessionData | ConvertTo-Json -Depth 5 | Out-File -FilePath $sessionFile -Encoding UTF8
            Write-Log "Saved metrics to session file" "OK"
        }
        
        Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
        Write-Log "Ended session: $($data.sessionId)" "OK"
    }
    
    "status" {
        if (-not (Test-Path $stateFile)) {
            Write-Log "No active session." "WARN"
            exit 0
        }
        
        $data = Get-Content $stateFile -Raw | ConvertFrom-Json
        
        Write-Host ""
        Write-Host "=== Session Metrics Status ===" -ForegroundColor Cyan
        Write-Host "Session: $($data.sessionId)" -ForegroundColor White
        Write-Host "Started: $($data.startTime)" -ForegroundColor White
        Write-Host "Last Update: $($data.lastUpdate)" -ForegroundColor White
        Write-Host "Status: $($data.status)" -ForegroundColor White
        Write-Host ""
        Write-Host "Metrics:" -ForegroundColor White
        Write-Host "  Input Tokens: $($data.metrics.inputTokens)" -ForegroundColor Gray
        Write-Host "  Output Tokens: $($data.metrics.outputTokens)" -ForegroundColor Gray
        Write-Host "  Total Tokens: $($data.metrics.totalTokens)" -ForegroundColor Gray
        Write-Host "  Est. Cost: `$$($data.metrics.estimatedCostUsd)" -ForegroundColor Gray
        Write-Host "  Context Chars: $($data.metrics.contextChars)" -ForegroundColor Gray
        Write-Host "  Tool Calls: $($data.metrics.toolCalls)" -ForegroundColor Gray
        Write-Host "  Files Read: $($data.metrics.filesRead)" -ForegroundColor Gray
        Write-Host "  Files Edited: $($data.metrics.filesEdited)" -ForegroundColor Gray
        Write-Host "  Files Created: $($data.metrics.filesCreated)" -ForegroundColor Gray
    }
}

exit 0
