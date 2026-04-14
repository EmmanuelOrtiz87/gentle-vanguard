param(
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$configPath = Join-Path $repoRoot 'config\orchestrator.json'
$activationFile = Join-Path $repoRoot '.orchestrator-active'
$tokenGuardScript = Join-Path $scriptDir 'token-budget-guard.ps1'
$tokenUsageFile = Join-Path $repoRoot 'docs\sessions\metrics\token-guard-usage.csv'

function Resolve-EngramCommand {
    if ($env:ENGRAM_CMD) {
        return $env:ENGRAM_CMD
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) { return $engramCmd.Source }

    $pathsToCheck = @()
    if ($env:GOBIN) { $pathsToCheck += Join-Path $env:GOBIN 'engram.exe'; $pathsToCheck += Join-Path $env:GOBIN 'engram' }
    if ($env:GOPATH) { $pathsToCheck += Join-Path $env:GOPATH 'bin\engram.exe'; $pathsToCheck += Join-Path $env:GOPATH 'bin\engram' }
    if ($env:USERPROFILE) { $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram.exe'; $pathsToCheck += Join-Path $env:USERPROFILE 'go\bin\engram' }
    if ($env:HOME) { $pathsToCheck += Join-Path $env:HOME 'go/bin/engram' }

    foreach ($path in $pathsToCheck) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

function Get-TodayTokenUsageStats {
    param([string]$UsagePath)

    $now = Get-Date
    $today = $now.ToString('yyyy-MM-dd')
    if (-not (Test-Path $UsagePath)) {
        return @{
            used_today_tokens = 0
            entries_today = 0
            burn_rate_tokens_per_hour = 0.0
            eta_hours = $null
            eta_text = 'unknown'
        }
    }

    $rows = Import-Csv -Path $UsagePath -ErrorAction SilentlyContinue
    if (-not $rows) {
        return @{
            used_today_tokens = 0
            entries_today = 0
            burn_rate_tokens_per_hour = 0.0
            eta_hours = $null
            eta_text = 'unknown'
        }
    }

    $todayRows = @($rows | Where-Object { $_.date -eq $today })
    if ($todayRows.Count -eq 0) {
        return @{
            used_today_tokens = 0
            entries_today = 0
            burn_rate_tokens_per_hour = 0.0
            eta_hours = $null
            eta_text = 'unknown'
        }
    }

    $used = 0
    foreach ($row in $todayRows) {
        $value = 0
        if ([int]::TryParse([string]$row.estimated_tokens, [ref]$value)) {
            $used += $value
        }
    }

    $firstTimestamp = $null
    foreach ($row in $todayRows) {
        $parsed = $null
        if ([DateTime]::TryParse([string]$row.timestamp, [ref]$parsed)) {
            if (-not $firstTimestamp -or $parsed -lt $firstTimestamp) {
                $firstTimestamp = $parsed
            }
        }
    }

    $burnRate = 0.0
    if ($firstTimestamp) {
        $elapsedHours = ($now - $firstTimestamp).TotalHours
        if ($elapsedHours -lt 0.10) { $elapsedHours = 0.10 }
        $burnRate = [Math]::Round(($used / $elapsedHours), 2)
    }

    return @{
        used_today_tokens = $used
        entries_today = $todayRows.Count
        burn_rate_tokens_per_hour = $burnRate
        eta_hours = $null
        eta_text = 'unknown'
    }
}

$config = $null
if (Test-Path $configPath) {
    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$orchestratorActive = [bool](Test-Path $activationFile)
$workflowMode = if ($config -and $config.PSObject.Properties.Name -contains 'workflow_mode') { [string]$config.workflow_mode } else { 'unknown' }
$responseMode = if ($config -and $config.PSObject.Properties.Name -contains 'communication_response_mode') { [string]$config.communication_response_mode } else { 'unknown' }
$compression = if ($config -and $config.PSObject.Properties.Name -contains 'response_profiles' -and $config.response_profiles -and $config.response_profiles.active) { [string]$config.response_profiles.active } else { 'unknown' }

$engramPath = Resolve-EngramCommand
$engramAvailable = [bool]$engramPath

$tokenData = $null
if (Test-Path $tokenGuardScript) {
    try {
        $json = & $tokenGuardScript -Mode status -Task general -AsJson -Quiet
        if ($json) {
            $tokenData = $json | ConvertFrom-Json
        }
    } catch {
        $tokenData = $null
    }
}

$tokenStatus = if ($tokenData) { [string]$tokenData.status } else { 'UNKNOWN' }
$projectedPct = if ($tokenData) { [double]$tokenData.projected_pct } else { 0 }
$dailyBudget = if ($tokenData -and $tokenData.PSObject.Properties.Name -contains 'daily_budget_tokens') { [int]$tokenData.daily_budget_tokens } else { 0 }
$softThreshold = if ($tokenData -and $tokenData.PSObject.Properties.Name -contains 'soft_threshold_pct') { [double]$tokenData.soft_threshold_pct } else { 70 }
$hardThreshold = if ($tokenData -and $tokenData.PSObject.Properties.Name -contains 'hard_threshold_pct') { [double]$tokenData.hard_threshold_pct } else { 90 }

$usageStats = Get-TodayTokenUsageStats -UsagePath $tokenUsageFile
$usedTodayTokens = if ($tokenData -and $tokenData.PSObject.Properties.Name -contains 'used_today_tokens') { [int]$tokenData.used_today_tokens } else { [int]$usageStats.used_today_tokens }
$burnRate = [double]$usageStats.burn_rate_tokens_per_hour

$etaHours = $null
$etaText = 'unknown'
if ($dailyBudget -gt 0) {
    $remaining = $dailyBudget - $usedTodayTokens
    if ($remaining -le 0) {
        $etaHours = 0
        $etaText = 'now'
    } elseif ($burnRate -gt 0) {
        $etaHours = [Math]::Round(($remaining / $burnRate), 2)
        if ($etaHours -lt 1) {
            $etaText = '<1h'
        } elseif ($etaHours -le 24) {
            $etaText = "~$etaHours h"
        } else {
            $etaText = '>24h'
        }
    }
}

$trafficLight = 'GREEN'
if ($tokenStatus -eq 'HARD_LIMIT' -or $tokenStatus -eq 'ENGRAM_MISSING' -or $projectedPct -ge $hardThreshold -or -not $engramAvailable) {
    $trafficLight = 'RED'
} elseif ($tokenStatus -eq 'SOFT_LIMIT' -or $projectedPct -ge $softThreshold) {
    $trafficLight = 'YELLOW'
}

$riskLevel = 'low'
if (-not $orchestratorActive -or -not $engramAvailable -or $tokenStatus -eq 'HARD_LIMIT' -or $tokenStatus -eq 'ENGRAM_MISSING') {
    $riskLevel = 'high'
} elseif ($tokenStatus -eq 'SOFT_LIMIT' -or $projectedPct -ge 70) {
    $riskLevel = 'medium'
}

$recommendation = @()
if (-not $engramAvailable) {
    $recommendation += '.\\scripts\\utilities\\wf.ps1 install-engram'
    $recommendation += '.\\scripts\\utilities\\run-engram.ps1 --help'
} elseif ($tokenStatus -eq 'HARD_LIMIT') {
    $recommendation += '.\\scripts\\utilities\\wf.ps1 response-mode simple'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 response-mode ultra'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 context-pack "<objective>"'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 end-session "<task>" -SkipReview -SkipTests -Force'
} elseif ($tokenStatus -eq 'SOFT_LIMIT') {
    $recommendation += '.\\scripts\\utilities\\wf.ps1 compact-start "<objective>"'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 context-pack "<objective>"'
} else {
    $recommendation += '.\\scripts\\utilities\\orchestrator-next-steps.ps1'
    $recommendation += '.\\scripts\\utilities\\wf.ps1 token-guard'
}

$result = [ordered]@{
    orchestrator_active = $orchestratorActive
    workflow_mode = $workflowMode
    response_mode = $responseMode
    compression = $compression
    engram_available = $engramAvailable
    engram_path = if ($engramPath) { $engramPath } else { '' }
    token_guard_status = $tokenStatus
    token_projected_pct = $projectedPct
    token_daily_budget = $dailyBudget
    token_used_today = $usedTodayTokens
    token_burn_rate_per_hour = $burnRate
    token_eta_hours = $etaHours
    token_eta_text = $etaText
    traffic_light = $trafficLight
    risk_level = $riskLevel
    recommended_next_actions = $recommendation
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "`n=== Stack Dashboard ===" -ForegroundColor Cyan
Write-Host "Orchestrator active: $($result.orchestrator_active) | Workflow: $($result.workflow_mode)" -ForegroundColor White
Write-Host "Response mode: $($result.response_mode) | Compression: $($result.compression)" -ForegroundColor White
Write-Host "Engram available: $($result.engram_available)" -ForegroundColor White
Write-Host "Token guard: $($result.token_guard_status) | Projected: $($result.token_projected_pct)%" -ForegroundColor White
Write-Host "Budget today: $($result.token_used_today) / $($result.token_daily_budget) | Burn rate: $($result.token_burn_rate_per_hour)/h | ETA: $($result.token_eta_text)" -ForegroundColor White

if ($trafficLight -eq 'RED') {
    Write-Host "Executive traffic light: RED" -ForegroundColor Red
} elseif ($trafficLight -eq 'YELLOW') {
    Write-Host "Executive traffic light: YELLOW" -ForegroundColor Yellow
} else {
    Write-Host "Executive traffic light: GREEN" -ForegroundColor Green
}

if ($riskLevel -eq 'high') {
    Write-Host "Risk level: HIGH" -ForegroundColor Red
} elseif ($riskLevel -eq 'medium') {
    Write-Host "Risk level: MEDIUM" -ForegroundColor Yellow
} else {
    Write-Host "Risk level: LOW" -ForegroundColor Green
}

Write-Host "Recommended next actions:" -ForegroundColor Cyan
foreach ($action in $recommendation) {
    Write-Host "  - $action" -ForegroundColor Yellow
}

exit 0
