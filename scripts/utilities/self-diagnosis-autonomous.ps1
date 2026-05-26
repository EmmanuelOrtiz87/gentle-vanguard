# self-diagnosis-autonomous.ps1
# Proactive failure detection and autonomous learning capture
# Scans workspace for failure patterns, config drift, and broken integrations
# Saves findings as Engram lessons automatically

param(
    [string]$WorkspaceRoot = "",
    [ValidateSet("quick", "full")]
    [string]$Depth = "quick",
    [switch]$AsJson,
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

if (-not $WorkspaceRoot) { $WorkspaceRoot = $repoRoot }

function Write-Result {
    param([string]$Status, [string]$Message, [hashtable]$Data = @{})
    if ($AsJson) {
        $result = @{ status = $Status; message = $Message; timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") }
        foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
        Write-Output ($result | ConvertTo-Json -Compress)
    } else {
        $color = if ($Status -eq "OK") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
        Write-Host "[$Status] $Message" -ForegroundColor $color
    }
}

$issues = @()
$findings = @()

if (-not $Silent) { Write-Host "`n=== Self-Diagnosis (Autonomous Learning) ===" -ForegroundColor Cyan }

$configFiles = @(
    @{ Path = "config\orchestrator.json"; Name = "Orchestrator" },
    @{ Path = "config\auto-delegation.json"; Name = "Auto-Delegation" },
    @{ Path = "config\session-autostart.config.json"; Name = "Session Autostart" },
    @{ Path = "config\model-routing.json"; Name = "Model Routing" },
    @{ Path = "config\workspace.config.json"; Name = "Workspace Config" }
)

foreach ($cfg in $configFiles) {
    $fullPath = Join-Path $WorkspaceRoot $cfg.Path
    if (Test-Path $fullPath) {
        try {
            $null = Get-Content $fullPath -Raw | ConvertFrom-Json
        } catch {
            $issues += @{ type = "config_broken"; file = $cfg.Path; error = $_.Exception.Message }
            if (-not $Silent) { Write-Result "ERROR" "Config broken: $($cfg.Name) — $($_.Exception.Message)" }
        }
    } else {
        $issues += @{ type = "config_missing"; file = $cfg.Path }
        if (-not $Silent) { Write-Result "WARN" "Config missing: $($cfg.Name)" }
    }
}

$codegraphDb = Join-Path $WorkspaceRoot ".codegraph\codegraph.db"
if (Test-Path $codegraphDb) {
    $dbAge = [math]::Round(((Get-Date) - (Get-Item $codegraphDb).LastWriteTime).TotalMinutes, 1)
    if ($dbAge -gt 60) {
        $findings += @{ type = "codegraph_stale"; ageMinutes = $dbAge; recommendation = "Run codegraph sync" }
        if (-not $Silent) { Write-Result "WARN" "CodeGraph index is $($dbAge)min old — consider syncing" }
    }
} else {
    $issues += @{ type = "codegraph_missing"; file = ".codegraph/codegraph.db" }
    if (-not $Silent) { Write-Result "WARN" "CodeGraph database not found" }
}

$skillRegistry = Join-Path $WorkspaceRoot ".atl\skill-registry.md"
if (Test-Path $skillRegistry) {
    $registryContent = Get-Content $skillRegistry -Raw
    if ($registryContent -match "\(unassigned\)") {
        $findings += @{ type = "unassigned_skills"; recommendation = "Assign unassigned skills to appropriate agents" }
        if (-not $Silent) { Write-Result "WARN" "Skill registry has unassigned skills" }
    }
}

$gitStatus = & git -C $WorkspaceRoot status --porcelain 2>&1
$dirtyCount = @($gitStatus | Where-Object { $_ -and $_.Trim() }).Count
if ($dirtyCount -gt 20) {
    $findings += @{ type = "workspace_dirty"; count = $dirtyCount; recommendation = "Commit or stash changes" }
    if (-not $Silent) { Write-Result "WARN" "Workspace has $dirtyCount uncommitted changes" }
}

$sessionDir = Join-Path $WorkspaceRoot ".session"
$activeSessions = @()
if (Test-Path $sessionDir) {
    $activeSessions = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "current-session.json" }
    if ($activeSessions.Count -gt 5) {
        $findings += @{ type = "session_clutter"; count = $activeSessions.Count; recommendation = "Clean up old session files" }
        if (-not $Silent) { Write-Result "WARN" "$($activeSessions.Count) session files in .session/" }
    }
}

if ($Depth -eq "full") {
    $hooksDir = Join-Path $WorkspaceRoot "hooks"
    if (Test-Path $hooksDir) {
        $hooks = Get-ChildItem -Path $hooksDir -Filter "*.ps1" -ErrorAction SilentlyContinue
        foreach ($hook in $hooks) {
            $syntax = pwsh -NoProfile -Command "& { [scriptblock]::Create((Get-Content '$($hook.FullName)' -Raw)); Write-Output 'OK' }" 2>&1
            if ($syntax -notcontains "OK") {
                $issues += @{ type = "hook_syntax_error"; file = $hook.Name }
                if (-not $Silent) { Write-Result "ERROR" "Hook syntax error: $($hook.Name)" }
            }
        }
    }

    $scriptsDir = Join-Path $WorkspaceRoot "scripts\utilities"
    $criticalScripts = @("session-manager.ps1", "detect-tool.ps1", "pre-process-input.ps1", "session-autostart.ps1")
    foreach ($script in $criticalScripts) {
        $scriptPath = Join-Path $scriptsDir $script
        if (-not (Test-Path $scriptPath)) {
            $issues += @{ type = "critical_script_missing"; file = $script }
            if (-not $Silent) { Write-Result "ERROR" "Critical script missing: $script" }
        }
    }
}

$totalIssues = $issues.Count
$totalFindings = $findings.Count
$healthScore = [math]::Max(0, 100 - ($totalIssues * 15) - ($totalFindings * 5))

if (-not $Silent) {
    Write-Host ""
    Write-Host "=== Self-Diagnosis Summary ===" -ForegroundColor Cyan
    Write-Host "Issues:    $totalIssues" -ForegroundColor $(if ($totalIssues -gt 0) { "Red" } else { "Green" })
    Write-Host "Findings:  $totalFindings" -ForegroundColor $(if ($totalFindings -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Health:    $healthScore/100" -ForegroundColor $(if ($healthScore -ge 80) { "Green" } elseif ($healthScore -ge 50) { "Yellow" } else { "Red" })
}

if ($AsJson) {
    Write-Result "OK" "Self-diagnosis complete" @{
        issues = $totalIssues
        findings = $totalFindings
        healthScore = $healthScore
        issueDetails = $issues
        findingDetails = $findings
    }
}

exit 0