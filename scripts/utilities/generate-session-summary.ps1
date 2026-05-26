param(
    [string]$SessionId = "",
    [string]$ProjectName = "gentle-vanguard",
    [string]$WorkspaceRoot = "",
    [string]$OutputDir = "",
    [switch]$ToFile,
    [switch]$NoExit
)

$ErrorActionPreference = 'Continue'

if (-not $WorkspaceRoot) {
    $WorkspaceRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
        $root = Split-Path -Parent $PSScriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
        if (-not $root) { $root = $PSScriptRoot }
        $root
    }
}

Set-Location $WorkspaceRoot

# Detect session
if (-not $SessionId) {
    $sessionDir = Join-Path $WorkspaceRoot "session"
    $latest = Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $data = Get-Content $latest.FullName -Raw | ConvertFrom-Json
        $SessionId = $data.sessionId
    }
}
if (-not $SessionId) { $SessionId = "current" }

# Collect data
$branch = git rev-parse --abbrev-ref HEAD 2>$null
if (-not $branch) { $branch = "unknown" }

$recentCommits = git log --oneline -10 2>$null
if (-not $recentCommits) { $recentCommits = "No commits" }

$gitStatus = git status --short 2>$null
$hasChanges = (-not [string]::IsNullOrWhiteSpace($gitStatus))

$changedFiles = @()
if ($hasChanges) {
    $changedFiles = $gitStatus -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

$startTime = ""
$taskCount = 0
$todoItems = @()
$todoFiles = Get-ChildItem -Path $WorkspaceRoot -Filter "*.todo.json" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $todoFiles) { $todoFiles = Get-ChildItem -Path $WorkspaceRoot -Filter "todowrite*" -Recurse -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1 }

# Build summary
$summaryLines = @()
$summaryLines += "## Goal"
$summaryLines += ""
$summaryLines += "[Describe lo que se trabajó en esta sesión]"
$summaryLines += ""
$summaryLines += "## Accomplished"
$summaryLines += ""

if ($hasChanges -and $changedFiles.Count -gt 0) {
    $summaryLines += "- ✅ Changes in $($changedFiles.Count) file(s):"
    $changedFiles | ForEach-Object { $summaryLines += "  - $_" }
} else {
    $summaryLines += "- ✅ [Describe completed tasks]"
}

$summaryLines += "- 🔲 [Pending items]"
$summaryLines += ""
$summaryLines += "## Discoveries"
$summaryLines += ""
$summaryLines += "- [Technical learnings, gotchas, edge cases]"
$summaryLines += ""
$summaryLines += "## Relevant Files"
$summaryLines += ""

$modifiedFiles = @()
if ($hasChanges) {
    $modifiedFiles = $changedFiles | ForEach-Object {
        if ($_ -match '^\s*[MARCUD?]+\s+(.+\.\w+)') { $matches[1] }
    } | Where-Object { $_ } | Sort-Object -Unique
}
if ($modifiedFiles.Count -gt 0) {
    $modifiedFiles | ForEach-Object { $summaryLines += "- $_" }
}

$summary = $summaryLines -join "`n"

if ($ToFile) {
    if (-not $OutputDir) { $OutputDir = Join-Path $WorkspaceRoot ".local\session-artifacts" }
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    $outFile = Join-Path $OutputDir "session-summary-draft-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $summary | Out-File -FilePath $outFile -Encoding UTF8
    Write-Host "[OK] Session summary draft: $outFile" -ForegroundColor Green
}

$summary
