param(
    [switch]$RequireValidatedStatus,
    [switch]$FailOnAdvisory
)

$ErrorActionPreference = 'Stop'

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

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Add-GitHubAnnotation {
    param(
        [ValidateSet('error', 'warning', 'notice')]
        [string]$Level,
        [string]$Message
    )

    if ($env:GITHUB_ACTIONS -eq 'true') {
        Write-Host "::$Level::$Message"
    }
}

function Get-ChangedFiles {
    param(
        [string]$BaseRef,
        [string]$HeadRef
    )

    $files = @()

    try {
        git fetch origin $BaseRef --depth=1 2>$null | Out-Null
        $files = @(git diff --name-only "origin/$BaseRef...$HeadRef" 2>$null)
    } catch {
        $files = @()
    }

    if ($files.Count -eq 0) {
        # In shallow CI checkouts, HEAD~1 may not exist; guard before diffing.
        git rev-parse --verify HEAD~1 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            try {
                $files = @(git diff --name-only HEAD~1..HEAD 2>$null)
            } catch {
                $files = @()
            }
        } else {
            $files = @()
        }
    }

    return @($files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

Write-Step 'SDD governance validation'

$isCi = $env:CI -eq 'true' -or $env:GITHUB_ACTIONS -eq 'true'
if (-not $isCi) {
    Write-Ok 'Local run detected. Validation is CI-oriented; no blocking checks applied.'
    exit 0
}

if ([string]::IsNullOrWhiteSpace($env:GITHUB_EVENT_PATH) -or -not (Test-Path $env:GITHUB_EVENT_PATH)) {
    Write-Ok 'No GitHub event payload found. Skipping SDD PR gate.'
    exit 0
}

$event = Get-Content -Path $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json
$eventName = $env:GITHUB_EVENT_NAME

if ($eventName -ne 'pull_request') {
    Write-Ok "Event '$eventName' is not pull_request. Skipping SDD PR gate."
    exit 0
}

$baseRef = if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_BASE_REF)) { $env:GITHUB_BASE_REF } else { 'develop' }
$headRef = if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_HEAD_REF)) { $env:GITHUB_HEAD_REF } else { 'HEAD' }
$prBody = if ($event.pull_request -and $event.pull_request.body) { [string]$event.pull_request.body } else { '' }

Write-Host "PR base: $baseRef"
Write-Host "PR head: $headRef"

$changedFiles = Get-ChangedFiles -BaseRef $baseRef -HeadRef 'HEAD'
if ($changedFiles.Count -eq 0) {
    Write-Warn 'No changed files detected for PR diff. Skipping enforcement to avoid false negatives.'
    Add-GitHubAnnotation -Level warning -Message 'SDD gate skipped: no changed files detected from PR diff.'
    exit 0
}

$specFilesChanged = @(
    $changedFiles |
    Where-Object { $_ -like 'docs/specs/*.md' } |
    Where-Object { $_ -ne 'docs/specs/README.md' -and $_ -ne 'docs/specs/SPEC-TEMPLATE.md' }
)

$behaviorChangeCandidates = @(
    $changedFiles |
    Where-Object {
        $_ -match '^(cmd/|internal/|web/|mcp/|scripts/|skills/|templates/|config/|\.github/workflows/)'
    }
)

$hasExemptionFlag = $prBody -match '(?im)^\s*SDD-EXEMPT\s*:\s*true\s*$'
$hasExemptionReason = $prBody -match '(?im)^\s*SDD-EXEMPT-REASON\s*:\s*.+$'

$isFeatureBranch = $headRef -match '^(feature|feat)/'
$forceRequiredByBody = $prBody -match '(?im)^\s*SDD-REQUIRED\s*:\s*true\s*$'
$sddRequired = $isFeatureBranch -or $forceRequiredByBody

if ($hasExemptionFlag) {
    if (-not $hasExemptionReason) {
        Write-Fail 'SDD exemption declared without SDD-EXEMPT-REASON.'
        Add-GitHubAnnotation -Level error -Message 'SDD exemption requires SDD-EXEMPT-REASON in PR body.'
        exit 1
    }

    Write-Warn 'SDD exemption path in use (documented in PR body).'
    Add-GitHubAnnotation -Level notice -Message 'SDD exemption accepted because reason was provided in PR body.'
    exit 0
}

if (-not $sddRequired) {
    if ($behaviorChangeCandidates.Count -gt 0 -and $specFilesChanged.Count -eq 0) {
        $message = 'Advisory: behavior-related files changed without docs/specs update. Use SDD-REQUIRED: true or add a spec when behavior changes.'
        Write-Warn $message
        Add-GitHubAnnotation -Level warning -Message $message
        if ($FailOnAdvisory) {
            Write-Fail 'FailOnAdvisory enabled and advisory condition met.'
            exit 1
        }
    }

    Write-Ok 'SDD mandatory gate not required for this PR branch profile.'
    exit 0
}

if ($specFilesChanged.Count -eq 0) {
    Write-Fail 'SDD is required for this PR but no docs/specs/*.md file was changed.'
    Add-GitHubAnnotation -Level error -Message 'SDD required: add/update a spec under docs/specs/ or declare documented exemption.'
    exit 1
}

$allowedStatuses = if ($RequireValidatedStatus) {
    @('validated', 'done')
} else {
    @('reviewed', 'implementing', 'validated', 'done')
}

$statusRegex = '^\*\*Status\*\*\s*:\s*(.+)$'
$statusFailures = @()

foreach ($specPath in $specFilesChanged) {
    if (-not (Test-Path $specPath)) {
        $statusFailures += "$specPath (file missing in workspace checkout)"
        continue
    }

    $statusLine = Select-String -Path $specPath -Pattern $statusRegex -CaseSensitive:$false | Select-Object -First 1
    if (-not $statusLine) {
        $statusFailures += "$specPath (missing **Status** header)"
        continue
    }

    $rawValue = ($statusLine.Matches[0].Groups[1].Value).Trim()
    $normalized = $rawValue.ToLowerInvariant()
    if ($allowedStatuses -notcontains $normalized) {
        $statusFailures += "$specPath (status '$rawValue' not allowed for this gate)"
    }
}

if ($statusFailures.Count -gt 0) {
    Write-Fail 'SDD status validation failed:'
    foreach ($issue in $statusFailures) {
        Write-Fail " - $issue"
    }
    Add-GitHubAnnotation -Level error -Message 'SDD required: spec status is missing or invalid for this PR.'
    exit 1
}

Write-Ok "SDD governance gate passed with $($specFilesChanged.Count) spec file(s)."
exit 0
