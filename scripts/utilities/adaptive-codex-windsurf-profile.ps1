# adaptive-codex-windsurf-profile.ps1
# Temporarily applies optimized Codex/Windsurf profiles and auto-restores baseline when normalized.

[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Optimize', 'Restore', 'Status')]
    [string]$Mode = 'Auto',
    [string]$TimeZone = 'Argentina Standard Time',
    [int]$PeakStart = 9,
    [int]$PeakEnd = 15,
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

function Log-Info { param([string]$m) if (-not $Silent) { Write-Host "[INFO] $m" -ForegroundColor Gray } }
function Log-Ok { param([string]$m) if (-not $Silent) { Write-Host "[OK] $m" -ForegroundColor Green } }
function Log-Warn { param([string]$m) if (-not $Silent) { Write-Host "[WARN] $m" -ForegroundColor Yellow } }

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$sessionDir = Join-Path $repoRoot 'scripts/.session'
if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }

$statePath = Join-Path $sessionDir 'adaptive-codex-windsurf-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'

$codexPath = Join-Path $repoRoot '.codex/config.toml'
$windsurfPath = Join-Path $repoRoot '.windsurf/config.json'
$codexBaseline = Join-Path $sessionDir 'codex-config.baseline.toml'
$windsurfBaseline = Join-Path $sessionDir 'windsurf-config.baseline.json'

$codexOptimized = @'
# Codex project-scoped configuration (adaptive optimized)
model = "gpt-5.5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
allow_login_shell = false
web_search = "disabled"
project_doc_max_bytes = 32768
file_opener = "vscode"

[sandbox_workspace_write]
network_access = false

[history]
persistence = "save-all"
max_bytes = 5242880

[features]
multi_agent = true
enable_request_compression = true
shell_snapshot = true

[profiles]

[profiles.local_first_safe]
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "disabled"

[profiles.readonly_review]
approval_policy = "never"
sandbox_mode = "read-only"
web_search = "disabled"

[windows]
sandbox = "unelevated"
'@

$windsurfOptimized = @'
{
  "name": "Windsurf - Local-First Configuration",
  "version": "1.1.0",
  "description": "Optimized Windsurf settings for context efficiency and reliable Cascade behavior",
  "workspace": {
    "projectRoot": ".",
    "configFiles": ["opencode.json", "AGENTS.md", "CLAUDE.md", ".cursorrules", "docs/AGENTS.md"],
    "skillPaths": ["skills/", "~/.config/opencode/skills/"]
  },
  "aiSettings": {
    "temperature": 0.3,
    "maxTokens": 4500,
    "localFirst": true,
    "planFirstForComplex": true,
    "executionTemplate": {
      "goal": true,
      "context": true,
      "constraints": true,
      "doneWhen": true
    }
  },
  "toolPermissions": {
    "websearch": "deny",
    "webfetch": "deny",
    "externalTools": "ask",
    "note": "External tools only via explicit approval and orchestrator flow"
  },
  "contextManagement": {
    "useEngramMemory": true,
    "useLocalSkills": true,
    "useProjectDocs": true,
    "fastContext": true,
    "indexIgnoreFile": ".codeiumignore",
    "memoryTiering": {
      "hot": "active session",
      "warm": "1 day",
      "cold": "7 days"
    }
  },
  "cascade": {
    "restrictToLocal": true,
    "allowExternalTools": false,
    "gitignoreAccess": false,
    "adaptiveModelRouter": true,
    "webDocsSearch": "disabled"
  },
  "sessionManagement": {
    "autostart": {
      "enabled": true,
      "script": "scripts/utilities/session-autostart.cmd",
      "platform": "windows",
      "alternatives": {
        "linux": "bash ./scripts/utilities/session-autostart.sh",
        "macos": "bash ./scripts/utilities/session-autostart.sh"
      }
    },
    "tracking": {
      "project": "gentle-vanguard",
      "directory": ".",
      "sessionIdPattern": "session-YYYY-MM-DD-XX"
    }
  },
  "advanced": {
    "ssh": {
      "enabled": true,
      "linuxHostsOnly": true
    },
    "devContainers": {
      "enabled": true
    },
    "wsl": {
      "enabled": true
    },
    "marketplace": {
      "configurable": true
    }
  },
  "preProcessing": {
    "enabled": true,
    "mandatory": true,
    "script": "scripts/utilities/pre-process-input.ps1",
    "scriptArgs": {
      "UserInput": "USER_INPUT_HERE",
      "WorkspaceRoot": "."
    },
    "fallbackBehavior": "continue"
  },
  "language": {
    "default": "es",
    "technicalTerms": "en",
    "responseStyle": "concise, direct"
  }
}
'@

function Read-Json {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { return Get-Content $Path -Raw | ConvertFrom-Json } catch { return $null }
}

function Save-Json {
    param([string]$Path, [object]$Data)
    $Data | ConvertTo-Json -Depth 50 | Out-File -FilePath $Path -Encoding UTF8 -Force
}

function Is-PeakHour {
    $summary = Read-Json -Path $summaryPath
    if ($summary -and $null -ne $summary.isPeakHour) { return [bool]$summary.isPeakHour }
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
        $local = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
        return ($local.Hour -ge $PeakStart -and $local.Hour -lt $PeakEnd)
    } catch {
        $fallback = [DateTime]::UtcNow.AddHours(-3)
        return ($fallback.Hour -ge $PeakStart -and $fallback.Hour -lt $PeakEnd)
    }
}

function Has-TokenPressure {
    $m = Read-Json -Path $metricsPath
    if (-not $m -or -not $m.metrics) { return $false }
    try {
        return ([int]$m.metrics.totalTokens -ge 12000)
    } catch {
        return $false
    }
}

function Notify-Change {
    param([string]$Reason, [string]$Details)
    $notify = Join-Path $repoRoot 'scripts/utilities/notify-codex-windsurf-optimization.ps1'
    if (Test-Path $notify) {
        & $notify -Reason $Reason -Details $Details -Silent:$Silent | Out-Null
    }
}

$state = Read-Json -Path $statePath
if (-not $state) {
    $state = [pscustomobject]@{
        optimizationActive = $false
        normalStreak = 0
        lastAction = 'none'
        lastReason = ''
        lastChangedAt = ''
    }
}

$peak = Is-PeakHour
$pressure = Has-TokenPressure
$shouldOptimize = ($peak -or $pressure)
$reason = if ($peak -and $pressure) { 'peak-hour + token-pressure' } elseif ($peak) { 'peak-hour' } elseif ($pressure) { 'token-pressure' } else { 'normalized' }

if ($Mode -eq 'Status') {
    Write-Host "[STATUS] optimizationActive=$($state.optimizationActive) shouldOptimize=$shouldOptimize reason=$reason normalStreak=$($state.normalStreak)"
    exit 0
}
if ($Mode -eq 'Optimize') { $shouldOptimize = $true; $reason = 'manual-optimize' }
if ($Mode -eq 'Restore') { $shouldOptimize = $false; $reason = 'manual-restore' }

if ($shouldOptimize) {
    $state.normalStreak = 0
    if (-not $state.optimizationActive) {
        if (Test-Path $codexPath) { Copy-Item $codexPath $codexBaseline -Force }
        if (Test-Path $windsurfPath) { Copy-Item $windsurfPath $windsurfBaseline -Force }

        $codexOptimized | Out-File -FilePath $codexPath -Encoding UTF8 -Force
        $windsurfOptimized | Out-File -FilePath $windsurfPath -Encoding UTF8 -Force

        $state.optimizationActive = $true
        $state.lastAction = 'optimized'
        $state.lastReason = $reason
        $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-Json -Path $statePath -Data $state

        Notify-Change -Reason 'Adaptive Codex/Windsurf optimization enabled (temporary)' -Details "Trigger: $reason. Baseline snapshot created and auto-restore will run when normalized."
        Log-Ok "Adaptive Codex/Windsurf optimization enabled ($reason)."
    } else {
        $state.lastReason = $reason
        Save-Json -Path $statePath -Data $state
        Log-Info "Optimization already active ($reason)."
    }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $codexBaseline) {
        Copy-Item $codexBaseline $codexPath -Force
        Remove-Item $codexBaseline -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $windsurfBaseline) {
        Copy-Item $windsurfBaseline $windsurfPath -Force
        Remove-Item $windsurfBaseline -Force -ErrorAction SilentlyContinue
    }

    $state.optimizationActive = $false
    $state.normalStreak = 0
    $state.lastAction = 'restored'
    $state.lastReason = 'normalized'
    $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-Json -Path $statePath -Data $state

    Notify-Change -Reason 'Adaptive Codex/Windsurf optimization reverted to baseline' -Details 'System signals normalized. Baseline configuration restored automatically.'
    Log-Ok 'Adaptive Codex/Windsurf profile restored to baseline.'
} else {
    Save-Json -Path $statePath -Data $state
    Log-Info "No change. reason=$reason normalStreak=$($state.normalStreak)"
}

exit 0

