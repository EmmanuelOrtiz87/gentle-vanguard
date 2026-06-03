# self-diagnosis.ps1
# Detects when response config is harming task execution and recommends break glass override.
# Called by: pre-process-input.ps1 when SELF-DIAG trigger matched, or agent-initiated.

param(
    [string]$CurrentProfile = "",
    [string]$CurrentChatLevel = "",
    [string]$TaskDescription = "",
    [int]$TurnCount = 0,
    [string[]]$UserComplaints = @(),
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$orchestratorPath = Join-Path $repoRoot "config\orchestrator.json"
$diagnosis = @{
    timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    current_profile = $CurrentProfile
    current_chat_level = $CurrentChatLevel
    issues = @()
    severity = "none"
    recommended_action = "none"
    break_glass_needed = $false
}

if (Test-Path $orchestratorPath) {
    $config = Get-Content $orchestratorPath -Raw | ConvertFrom-Json
    $breakGlass = $config.response_policy.break_glass
} else {
    Write-Warning "orchestrator.json not found at $orchestratorPath"
    return $diagnosis
}

$restrictiveProfiles = @("ultra")
$restrictiveChatLevels = @("chat-compact")

if ($CurrentProfile -in $restrictiveProfiles) {
    $diagnosis.issues += @{
        check = "response_profile"
        severity = "high"
        message = "Current profile '$CurrentProfile' is ultra-restrictive"
        recommendation = "Override to 'lleno' profile for adequate task completion bandwidth"
    }
}

if ($CurrentChatLevel -in $restrictiveChatLevels) {
    $diagnosis.issues += @{
        check = "chat_level"
        severity = "high"
        message = "Current chat level '$CurrentChatLevel' limits output"
        recommendation = "Override to 'chat-balanced' for adequate output room"
    }
}

if ($TurnCount -ge 3) {
    $diagnosis.issues += @{
        check = "turn_count"
        severity = "medium"
        message = "Task has spanned $TurnCount turns without completion"
        recommendation = "Break glass to less restrictive profile"
    }
}

if ($UserComplaints.Count -gt 0) {
    $diagnosis.issues += @{
        check = "user_feedback"
        severity = "high"
        message = "User reported incompleteness $($UserComplaints.Count) time(s)"
        recommendation = "CRITICAL: Break glass immediately"
    }
}

$severityScore = 0
foreach ($issue in $diagnosis.issues) {
    switch ($issue.severity) { "high" { $severityScore += 3 } "medium" { $severityScore += 1 } }
}

if ($severityScore -ge 3) {
    $diagnosis.severity = "high"; $diagnosis.break_glass_needed = $true; $diagnosis.recommended_action = "break_glass"
} elseif ($severityScore -ge 1) {
    $diagnosis.severity = "medium"
    $diagnosis.break_glass_needed = ($UserComplaints.Count -gt 0 -or $TurnCount -ge 5)
    $diagnosis.recommended_action = if ($diagnosis.break_glass_needed) { "break_glass" } else { "monitor" }
}

if ($diagnosis.break_glass_needed -and $breakGlass) {
    $diagnosis.recommended_override = @{
        profile = $breakGlass.override_to_profile
        chat_level = $breakGlass.override_to_chat_level
        detail = $breakGlass.override_to_detail
    }
}

if (-not $CheckOnly -and $diagnosis.break_glass_needed) {
    $auditDir = Join-Path $repoRoot ".logs"
    $auditFile = Join-Path $auditDir "self-diagnosis-audit.jsonl"
    try { New-Item -ItemType Directory -Path $auditDir -Force | Out-Null; Add-Content -Path $auditFile -Value ($diagnosis | ConvertTo-Json -Compress) } catch { }
}

Write-Output ($diagnosis | ConvertTo-Json -Depth 5)
return $diagnosis
