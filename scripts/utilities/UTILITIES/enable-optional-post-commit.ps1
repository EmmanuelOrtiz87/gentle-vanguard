param(
    [switch]$Disable,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

$configDir = Join-Path $repoRoot '.config'
$hooksDir = Join-Path $repoRoot '.githooks'
$scriptsProjectDir = Join-Path $repoRoot 'scripts\project'
$markerFile = Join-Path $configDir 'optional-post-commit.enabled'
$hookFile = Join-Path $hooksDir 'post-commit'
$postCommitScript = Join-Path $scriptsProjectDir 'project-post-commit.ps1'

if ($Disable) {
    Write-Step 'Disabling optional post-commit automation'
    if (Test-Path $markerFile) {
        Remove-Item $markerFile -Force
        Write-Ok 'Disabled marker removed.'
    } else {
        Write-Warn 'Optional post-commit marker was already absent.'
    }
    Write-Host "To re-enable, run: .\scripts\utilities\enable-optional-post-commit.ps1" -ForegroundColor Cyan
    exit 0
}

Write-Step 'Enabling optional post-commit automation'
New-Item -ItemType Directory -Force -Path $configDir, $hooksDir, $scriptsProjectDir | Out-Null

if ((Test-Path $postCommitScript) -and (-not $Force)) {
    Write-Warn 'project-post-commit.ps1 already exists; preserving current file (use -Force to overwrite).'
} else {
    $postCommitContent = @'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..\..")
Set-Location $projectRoot

$markerPath = Join-Path $projectRoot '.config/optional-post-commit.enabled'
if (-not (Test-Path $markerPath)) {
    exit 0
}

$powershell = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $powershell) {
    $powershell = Get-Command powershell -ErrorAction SilentlyContinue
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    exit 0
}

if (-not (Get-Command engram -ErrorAction SilentlyContinue)) {
    Write-Host '[WARN] engram not found; skipping post-commit memory sync.' -ForegroundColor Yellow
    exit 0
}

$commitHash = git rev-parse --short HEAD 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commitHash)) {
    exit 0
}

$projectName = Split-Path $projectRoot -Leaf
$commitMessage = git log -1 --pretty=%B HEAD
$changedFiles = git diff-tree --no-commit-id --name-only -r HEAD | Out-String
$title = "Auto-save commit $commitHash"
$body = @"
Commit message:
$commitMessage

Changed files:
$changedFiles
"@

try {
    & engram save "$title" "$body" --type decision --project $projectName --scope project --topic "commit/$commitHash"
} catch {
    Write-Host "[WARN] failed to save commit memory: $_" -ForegroundColor Yellow
}

$reviewScript = Join-Path $projectRoot 'scripts\utilities\generate-session-review.ps1'
if ($env:AUTO_SESSION_REVIEW_ON_COMMIT -eq '1' -and (Test-Path $reviewScript)) {
    try {
        if ($powershell) {
            & $powershell.Source -NoProfile -ExecutionPolicy Bypass -File $reviewScript
        } else {
            & $reviewScript
        }
    } catch {
        Write-Host "[WARN] failed to generate session review: $_" -ForegroundColor Yellow
    }
}
'@
    [System.IO.File]::WriteAllText($postCommitScript, $postCommitContent, [System.Text.UTF8Encoding]::new($false))
    Write-Ok 'Created scripts/project/project-post-commit.ps1'
}

if ((Test-Path $hookFile) -and (-not $Force)) {
    Write-Warn '.githooks/post-commit already exists; preserving current file (use -Force to overwrite).'
} else {
    $hookContent = @'
#!/bin/sh
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
HOOK_SCRIPT="$REPO_ROOT/scripts/project/project-post-commit.ps1"
MARKER_FILE="$REPO_ROOT/.config/optional-post-commit.enabled"

if [ -z "$REPO_ROOT" ] || [ ! -f "$HOOK_SCRIPT" ]; then
  exit 0
fi

if [ ! -f "$MARKER_FILE" ]; then
  exit 0
fi

if command -v pwsh >/dev/null 2>&1; then
  OUTPUT="$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOOK_SCRIPT" 2>&1)"
  EXIT_CODE=$?
elif command -v powershell >/dev/null 2>&1; then
    OUTPUT="$(powershell -NoProfile -ExecutionPolicy Bypass -File "$HOOK_SCRIPT" 2>&1)"
  EXIT_CODE=$?
else
  printf '%s\n' "PowerShell not found for post-commit hook." >&2
  exit 1
fi

printf '%s\n' "$OUTPUT" | while IFS= read -r line; do
  case "$line" in
    "declare -x "*) ;;
    *) printf '%s\n' "$line" ;;
  esac
done

exit $EXIT_CODE
'@
    [System.IO.File]::WriteAllText($hookFile, ($hookContent -replace "`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))
    try {
        git update-index --chmod=+x $hookFile 2>$null | Out-Null
    } catch {
        Write-Warn 'Could not set executable bit on post-commit hook (safe to ignore on Windows).'
    }
    Write-Ok 'Created .githooks/post-commit'
}

Set-Content -Path $markerFile -Value "enabled=true`n" -Encoding UTF8
Write-Ok 'Enabled marker created: .config/optional-post-commit.enabled'

git config core.hooksPath .githooks
Write-Ok 'Configured git hooks path: .githooks'

Write-Host "Optional post-commit automation is now enabled." -ForegroundColor Green
Write-Host "Disable anytime with: .\scripts\utilities\enable-optional-post-commit.ps1 -Disable" -ForegroundColor Cyan
