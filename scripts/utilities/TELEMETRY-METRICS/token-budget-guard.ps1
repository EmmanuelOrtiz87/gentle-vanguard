param(
    [ValidateSet('status', 'check')]
    [string]$Mode = 'status',
    [string]$Task = 'general',
    [ValidateSet('low', 'medium', 'high')]
    [string]$Risk = 'medium',
    [int]$EstimatedChars = 0,
    [int]$ActualPromptTokens = 0,
    [int]$ActualCompletionTokens = 0,
    [switch]$Record,
    [switch]$Strict,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}
$configPath = Join-Path $repoRoot 'config\orchestrator.json'
$metricsDir = Join-Path $repoRoot 'docs\sessions\metrics'
$usageFile = Join-Path $metricsDir 'token-guard-usage.csv'

function Write-InfoLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[INFO] $Message" -ForegroundColor Gray
    }
}

function Write-WarnLine {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-OkLine {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[OK] $Message" -ForegroundColor Green
    }
}

function Get-DefaultGuardConfig {
    return @{
        enabled = $true
        non_blocking = $true
        require_engram = $true
        daily_budget_tokens = 120000
        soft_threshold_pct = 70
        hard_threshold_pct = 90
        enforce_on_commands = @('context-pack', 'compact-start', 'review', 'audit', 'end-session', 'publish')
        fallback_actions = @(
            './scripts/utilities/wf.ps1 response-mode simple',
            './scripts/utilities/wf.ps1 response-mode ultra',
            './scripts/utilities/wf.ps1 context-pack "<objective>"',
            './scripts/utilities/wf.ps1 compact-start "<objective>"',
            './scripts/utilities/wf.ps1 end-session "<task>" -SkipReview -SkipTests -Force',
            './scripts/utilities/run-engram.ps1 --help'
        )
    }
}

function Get-EstimatedTokens {
    param(
        [string]$TaskName,
        [string]$RiskLevel,
        [int]$Chars
    )

    if ($Chars -gt 0) {
        return [Math]::Ceiling($Chars / 4.0)
    }

    $baseByTask = @{
        'context-pack' = 1200
        'compact-start' = 1600
        'review' = 3200
        'audit' = 2200
        'end-session' = 1800
        'publish' = 4500
        'general' = 1000
    }

    $taskKey = $TaskName.ToLowerInvariant()
    $base = if ($baseByTask.ContainsKey($taskKey)) { $baseByTask[$taskKey] } else { $baseByTask['general'] }

    $riskMultiplier = switch ($RiskLevel) {
        'low' { 0.8 }
        'high' { 1.25 }
        default { 1.0 }
    }

    return [Math]::Ceiling($base * $riskMultiplier)
}

function Ensure-MetricsFile {
    if (-not (Test-Path $metricsDir)) {
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    }

    if (-not (Test-Path $usageFile)) {
        'timestamp,date,task,risk,estimated_tokens,status,engram_available,notes' | Set-Content -Path $usageFile -Encoding UTF8
    }
}

function Get-UsedTokensToday {
    Ensure-MetricsFile
    $today = (Get-Date -Format 'yyyy-MM-dd')
    $rows = Import-Csv -Path $usageFile -ErrorAction SilentlyContinue
    if (-not $rows) {
        return 0
    }

    $sum = 0
    foreach ($row in $rows) {
        if ($row.date -eq $today) {
            $tokens = 0
            if ($row.estimated_tokens -match '^\d+$') {
                $tokens = [int]$row.estimated_tokens
                $sum += $tokens
            }
        }
    }

    return $sum
}

function Save-UsageRecord {
    param(
        [string]$TaskName,
        [string]$RiskLevel,
        [int]$EstimatedTokens,
        [int]$ActualPromptTokens = 0,
        [int]$ActualCompletionTokens = 0,
        [string]$Status,
        [bool]$EngramAvailable,
        [string]$Notes
    )

    Ensure-MetricsFile
    $actualTotal = $ActualPromptTokens + $ActualCompletionTokens
    $line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'), (Get-Date -Format 'yyyy-MM-dd'), $TaskName, $RiskLevel, $EstimatedTokens, $ActualPromptTokens, $ActualCompletionTokens, $actualTotal, $Status, $EngramAvailable, ($Notes -replace ',', ';')
    Add-Content -Path $usageFile -Value $line -Encoding UTF8
}

function Get-EngramStatus {
    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if ($engramCmd) {
        return @{ available = $true; source = $engramCmd.Source }
    }

    $launcher = Join-Path $repoRoot 'scripts\utilities\run-engram.ps1'
    if (Test-Path $launcher) {
        return @{ available = $false; source = $launcher }
    }

    return @{ available = $false; source = '' }
}

$config = $null
if (Test-Path $configPath) {
    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$defaults = Get-DefaultGuardConfig
$guardConfig = @{}
foreach ($key in @($defaults.Keys)) {
    $guardConfig[$key] = $defaults[$key]
}
if ($config -and $config.subagent_orchestration -and $config.subagent_orchestration.token_budget_guard) {
    $custom = $config.subagent_orchestration.token_budget_guard
    foreach ($key in @($defaults.Keys)) {
        if ($custom.PSObject.Properties[$key]) {
            $guardConfig[$key] = $custom.$key
        }
    }
}

if (-not $guardConfig.enabled) {
    Write-OkLine 'Token budget guard is disabled in config.'
    exit 0
}

$estimatedTokens = Get-EstimatedTokens -TaskName $Task -RiskLevel $Risk -Chars $EstimatedChars
$usedToday = Get-UsedTokensToday
$projected = $usedToday + $estimatedTokens
$dailyBudget = [int]$guardConfig.daily_budget_tokens
$pct = if ($dailyBudget -gt 0) { [Math]::Round(($projected / $dailyBudget) * 100, 2) } else { 0 }

$soft = [double]$guardConfig.soft_threshold_pct
$hard = [double]$guardConfig.hard_threshold_pct
$status = 'PASS'
if ($pct -ge $hard) {
    $status = 'HARD_LIMIT'
} elseif ($pct -ge $soft) {
    $status = 'SOFT_LIMIT'
}

$engram = Get-EngramStatus
$engramRequiredIssue = ($guardConfig.require_engram -and -not $engram.available)
if ($engramRequiredIssue -and $status -eq 'PASS') {
    $status = 'ENGRAM_MISSING'
}

$alternatives = @($guardConfig.fallback_actions)
if (-not $engram.available) {
    $alternatives += './scripts/utilities/wf.ps1 install-engram'
    $alternatives += './scripts/utilities/run-engram.ps1 --help'
}

if ($Mode -eq 'check' -or $Record) {
    $actualPrompt = if ($ActualPromptTokens -gt 0) { $ActualPromptTokens } else { 0 }
    $actualCompletion = if ($ActualCompletionTokens -gt 0) { $ActualCompletionTokens } else { 0 }
    Save-UsageRecord -TaskName $Task -RiskLevel $Risk -EstimatedTokens $estimatedTokens -ActualPromptTokens $actualPrompt -ActualCompletionTokens $actualCompletion -Status $status -EngramAvailable:$engram.available -Notes "projected_pct=$pct; actual_tracking=$($actualPrompt -gt 0 -or $actualCompletion -gt 0)"
}

$result = [ordered]@{
    mode = $Mode
    task = $Task
    risk = $Risk
    status = $status
    estimated_tokens = $estimatedTokens
    used_today_tokens = $usedToday
    projected_tokens = $projected
    daily_budget_tokens = $dailyBudget
    projected_pct = $pct
    soft_threshold_pct = $soft
    hard_threshold_pct = $hard
    engram_required = [bool]$guardConfig.require_engram
    engram_available = [bool]$engram.available
    alternatives = $alternatives
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
} else {
    Write-Host "Token Budget Guard" -ForegroundColor Cyan
    Write-Host "Task: $Task | Risk: $Risk | Status: $status" -ForegroundColor Cyan
    Write-Host "Estimated: $estimatedTokens tokens | Used today: $usedToday | Projected: $projected / $dailyBudget ($pct%)" -ForegroundColor Cyan

    if ($status -eq 'SOFT_LIMIT' -or $status -eq 'HARD_LIMIT' -or $status -eq 'ENGRAM_MISSING') {
        Write-WarnLine 'Token budget alert triggered. Use one of the alternatives below to avoid session blockage:'
        if ($status -eq 'HARD_LIMIT') {
            Write-WarnLine 'Hard threshold reached: continue only with compact flow and close session safely.'
        }

        if ($engramRequiredIssue) {
            Write-WarnLine 'Engram is required by policy and was not found in PATH.'
        }

        Write-Host 'Alternatives:' -ForegroundColor Yellow
        foreach ($action in $alternatives) {
            Write-Host "  - $action" -ForegroundColor Yellow
        }
    } else {
        Write-OkLine 'Token budget is within threshold.'
    }
}

if ($Strict -and ($status -eq 'HARD_LIMIT' -or $status -eq 'ENGRAM_MISSING')) {
    exit 2
}

exit 0
