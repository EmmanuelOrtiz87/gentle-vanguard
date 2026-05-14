# generate-session-review.ps1 (Foundation Core)
# Agnostic session review generator for AI-assisted change control.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $projectRoot

# Verify if the directory is a Git repository before proceeding
git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[INFO] No Git repository detected. Skipping session report generation." -ForegroundColor Gray
    exit 0
}

$headRef = git show-ref --head HEAD 2>$null
if ($headRef) {
    $lastCommit = git rev-parse HEAD 2>$null
} else {
    Write-Host "No previous commit detected. Initializing initial session report."
    $lastCommit = "Initial"
}

# Capture current changes (staged and unstaged) for the session report
$changedFilesOutput = git status --porcelain 2>$null
$changedFiles = $changedFilesOutput | ForEach-Object { 
    if ($_.Length -gt 3) { $_.Substring(3) }
} | Where-Object { $_ -ne "" }

if ($changedFiles.Count -eq 0 -and $lastCommit -ne "Initial") {
    Write-Host "No changes detected to report in this session."
    exit 0
}

$date = Get-Date -Format "yyyy-MM-dd"
$fullDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$dateTag = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$reviewDir = Join-Path $projectRoot "docs/code-reviews"
if (-not (Test-Path $reviewDir)) {
    New-Item -ItemType Directory -Path $reviewDir -Force | Out-Null
}

$sessionId = $env:WFS_SESSION_ID
$sessionActive = -not [string]::IsNullOrWhiteSpace($sessionId)

if (-not $sessionActive) {
    Write-Host "[WARN] No active session detected (WFS_SESSION_ID not set)." -ForegroundColor Yellow
    $forceOverride = Read-Host "Proceed without active session? This will be logged in audit. (yes/no)"
    if ($forceOverride -notmatch '^(y|yes|si|s)$') {
        Write-Host "[INFO] Operation cancelled. Please start a session with '.\scripts\utilities\start-session.ps1' first." -ForegroundColor Cyan
        exit 0
    }
}

$sessionId = $env:WFS_SESSION_ID
$sessionActive = -not [string]::IsNullOrWhiteSpace($sessionId)

if (-not $sessionActive) {
    Write-Host "[WARN] No active session detected (WFS_SESSION_ID not set)." -ForegroundColor Yellow
    $forceOverride = Read-Host "Proceed without active session? This will be logged in audit. (yes/no)"
    if ($forceOverride -notmatch '^(y|yes|si|s)$') {
        Write-Host "[INFO] Operation cancelled. Please start a session with '.\scripts\utilities\start-session.ps1' first." -ForegroundColor Cyan
        exit 0
    }
}

$sessionId = $env:WFS_SESSION_ID
$sessionActive = -not [string]::IsNullOrWhiteSpace($sessionId)

if (-not $sessionActive) {
    Write-Host "[WARN] No active session detected (WFS_SESSION_ID not set)." -ForegroundColor Yellow
    $forceOverride = Read-Host "Proceed without active session? This will be logged in audit. (yes/no)"
    if ($forceOverride -notmatch '^(y|yes|si|s)$') {
        Write-Host "[INFO] Operation cancelled. Please start a session with '.\scripts\utilities\start-session.ps1' first." -ForegroundColor Cyan
        exit 0
    }
}

$gitUser = git config user.name 2>$null
if ([string]::IsNullOrWhiteSpace($gitUser)) {
    $gitUser = $env:USERNAME
}
$safeUser = $gitUser -replace '[^a-zA-Z0-9_-]', ''
if ([string]::IsNullOrWhiteSpace($safeUser)) {
    $safeUser = "unknown"
}
$reviewFile = Join-Path $reviewDir "${safeUser}-${dateTag}-session-review.md"
$templateFile = Join-Path $projectRoot "config/session-review.template.md"

if (Test-Path $templateFile) {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $filesList = ($changedFiles | ForEach-Object { "- $_" }) -join "`n"
    if ([string]::IsNullOrWhiteSpace($filesList)) { $filesList = "- No modified files" }
    
    $specsPath = Join-Path $projectRoot "docs/sdd"
    $specLink = "None found"
    $specStatus = "N/A (Optional)"
    if (Test-Path $specsPath) {
        $specFiles = Get-ChildItem -Path $specsPath -File
        if ($specFiles.Count -gt 0) {
            $specLink = "docs/sdd/$($specFiles[0].Name)"
            $specStatus = "Pending AI/Manual Review"
        }
    }

    $content = Get-Content $templateFile -Raw
    $content = $content.Replace("{{DATE}}", $date)
    $content = $content.Replace("{{FULL_DATE}}", $fullDate)
    $content = $content.Replace("{{GIT_USER}}", $gitUser)
    $content = $content.Replace("{{BRANCH}}", $branch)
    $content = $content.Replace("{{CHANGED_FILES}}", $filesList)
    $content = $content.Replace("{{SPEC_LINK}}", $specLink)
    $content = $content.Replace("{{SPEC_STATUS}}", $specStatus)

    if (-not $sessionActive) {
        $auditNote = "`n> [!WARNING]`n> This review was generated WITHOUT an active session by explicit user override.`n> **Owner:** $gitUser`n> **Timestamp:** $fullDate`n"
        $content = $auditNote + "`n" + $content
    }

    $content | Out-File -FilePath $reviewFile -Encoding UTF8BOM
    Write-Host "[OK] Session review generated from template at: $reviewFile" -ForegroundColor Green
} else {
    Write-Error "Session review template not found at $templateFile"
}
Write-Host "[OK] Session review generated at: $reviewFile" -ForegroundColor Green