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
. (Join-Path $PSScriptRoot 'adaptive-common.ps1')

$repoRoot = Get-RepoRoot
$sessionDir = Get-SessionDir -RepoRoot $repoRoot
$statePath = Join-Path $sessionDir 'adaptive-codex-windsurf-state.json'
$summaryPath = Join-Path $sessionDir 'startup-summary.json'
$metricsPath = Join-Path $repoRoot '.session/metrics/current-session.json'

$codexPath = Join-Path $repoRoot '.codex/config.toml'
$windsurfPath = Join-Path $repoRoot '.windsurf/config.json'
$codexBaseline = Join-Path $sessionDir 'codex-config.baseline.toml'
$windsurfBaseline = Join-Path $sessionDir 'windsurf-config.baseline.json'

$codexOptimized = @'
model = "gpt-5.5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
allow_login_shell = false
web_search = "disabled"
project_doc_max_bytes = 16384
file_opener = "vscode"
[sandbox_workspace_write]
network_access = false
[history]
persistence = "save-all"
max_bytes = 2621440
[features]
multi_agent = true
enable_request_compression = true
shell_snapshot = true
[windows]
sandbox = "unelevated"
'@

$windsurfOptimized = @'
{
  "name": "Windsurf - Optimized Profile",
  "version": "1.2.0",
  "description": "Optimized Windsurf for peak hour / token pressure",
  "workspace": { "projectRoot": ".", "configFiles": ["AGENTS.md", "CLAUDE.md"], "skillRegistry": ".atl/skill-registry.md" },
  "aiSettings": { "temperature": 0.3, "maxTokens": 2500, "localFirst": true },
  "toolPermissions": { "websearch": "deny", "webfetch": "deny", "externalTools": "ask" },
  "contextManagement": { "useEngramMemory": true, "useLocalSkills": true, "useProjectDocs": true, "fastContext": true },
  "cascade": { "restrictToLocal": true, "allowExternalTools": false, "webDocsSearch": "disabled" },
  "preProcessing": { "enabled": true, "mandatory": true, "script": "scripts/utilities/pre-process-input.ps1", "scriptArgs": { "UserInput": "USER_INPUT_HERE", "WorkspaceRoot": "." } },
  "sessionManagement": { "tracking": { "project": "gentle-vanguard", "sessionIdPattern": "session-YYYY-MM-DD-XX" } },
  "language": { "default": "es", "technicalTerms": "en" }
}
'@

function Notify-Change {
    param([string]$Reason, [string]$Details)
    $n = Join-Path $repoRoot 'scripts/utilities/notify-codex-windsurf-optimization.ps1'
    if (Test-Path $n) { & $n -Reason $Reason -Details $Details -Silent:$Silent | Out-Null }
}

$state = Read-JsonFile -Path $statePath
if (-not $state) { $state = Get-DefaultState }

$peak = Test-PeakHour -TimeZone $TimeZone -PeakStart $PeakStart -PeakEnd $PeakEnd
$pressure = Test-TokenPressure
$shouldOptimize = ($peak -or $pressure)
$reason = Get-AdaptiveReason -Peak $peak -Pressure $pressure

if ($Mode -eq 'Status') { Write-Host "[STATUS] optimizationActive=$($state.optimizationActive) shouldOptimize=$shouldOptimize reason=$reason normalStreak=$($state.normalStreak)"; exit 0 }
if ($Mode -eq 'Optimize') { $shouldOptimize = $true; $reason = 'manual-optimize' }
if ($Mode -eq 'Restore') { $shouldOptimize = $false; $reason = 'manual-restore' }

if ($shouldOptimize) {
    $state.normalStreak = 0
    if (-not $state.optimizationActive) {
        if (Test-Path $codexPath) { Copy-Item $codexPath $codexBaseline -Force }
        if (Test-Path $windsurfPath) { Copy-Item $windsurfPath $windsurfBaseline -Force }
        $codexOptimized | Out-File -FilePath $codexPath -Encoding UTF8 -Force
        $windsurfOptimized | Out-File -FilePath $windsurfPath -Encoding UTF8 -Force
        $state.optimizationActive = $true; $state.lastAction = 'optimized'; $state.lastReason = $reason; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
        Save-JsonFile -Path $statePath -Data $state
        Notify-Change -Reason 'Codex/Windsurf optimization enabled (temporary)' -Details "Trigger: $reason"
        Write-LogOk "Adaptive Codex/Windsurf optimization enabled ($reason)."
    } else { $state.lastReason = $reason; Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "Optimization already active ($reason)." }
    exit 0
}

$state.normalStreak = [int]$state.normalStreak + 1
if ($state.optimizationActive -and $state.normalStreak -ge 2) {
    if (Test-Path $codexBaseline) { Copy-Item $codexBaseline $codexPath -Force; Remove-Item $codexBaseline -Force -ErrorAction SilentlyContinue }
    if (Test-Path $windsurfBaseline) { Copy-Item $windsurfBaseline $windsurfPath -Force; Remove-Item $windsurfBaseline -Force -ErrorAction SilentlyContinue }
    $state.optimizationActive = $false; $state.normalStreak = 0; $state.lastAction = 'restored'; $state.lastReason = 'normalized'; $state.lastChangedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    Save-JsonFile -Path $statePath -Data $state
    Notify-Change -Reason 'Codex/Windsurf optimization reverted to baseline' -Details 'System normalized.'
    Write-LogOk 'Adaptive Codex/Windsurf profile restored to baseline.'
} else { Save-JsonFile -Path $statePath -Data $state; Write-LogInfo "No change. reason=$reason normalStreak=$($state.normalStreak)" }
exit 0
