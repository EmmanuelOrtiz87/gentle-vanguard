param(
    [switch]$Quiet,
    [switch]$EnforcePrBase,
    [string]$PrBase
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repoRoot

function Write-Ok { param([string]$Message) if (-not $Quiet) { Write-Host "[OK] $Message" -ForegroundColor Green } }
function Write-Warn { param([string]$Message) if (-not $Quiet) { Write-Host "[WARN] $Message" -ForegroundColor Yellow } }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ([string]::IsNullOrWhiteSpace($branch)) {
    Write-Fail 'Unable to detect current git branch.'
    exit 1
}

# Direct pushes to protected branches are disallowed unless explicitly overridden.
$allowProtectedPush = ($env:GITFLOW_ALLOW_PROTECTED_PUSH -eq '1')
if (($branch -eq 'main' -or $branch -eq 'develop') -and -not $allowProtectedPush) {
    Write-Fail "Direct push from protected branch '$branch' is blocked by GitFlow policy. Use feature/bugfix/chore/hotfix/release branches and PR workflow."
    exit 1
}

$kind = 'unknown'
if ($branch -match '^feature/.+') { $kind = 'feature' }
elseif ($branch -match '^bugfix/.+') { $kind = 'bugfix' }
elseif ($branch -match '^chore/.+') { $kind = 'chore' }
elseif ($branch -match '^hotfix/.+') { $kind = 'hotfix' }
elseif ($branch -match '^release/.+') { $kind = 'release' }
elseif ($branch -eq 'main' -or $branch -eq 'develop') { $kind = 'protected' }

if ($kind -eq 'unknown') {
    Write-Fail "Branch '$branch' does not match allowed GitFlow naming (feature/*, bugfix/*, chore/*, hotfix/*, release/*)."
    exit 1
}

$expectedBase = if ($kind -in @('feature', 'bugfix', 'chore')) { 'develop' } elseif ($kind -in @('hotfix', 'release')) { 'main' } else { $branch }
Write-Ok "Branch '$branch' classified as '$kind' (expected PR base: $expectedBase)."

if ($EnforcePrBase) {
    if ([string]::IsNullOrWhiteSpace($PrBase)) {
        Write-Fail 'PR base validation requested but PrBase was not provided.'
        exit 1
    }

    if ($PrBase -ne $expectedBase) {
        Write-Fail "PR base '$PrBase' violates GitFlow for branch '$branch'. Expected base: '$expectedBase'."
        exit 1
    }

    Write-Ok "PR base '$PrBase' matches GitFlow expectation."
}

if ($allowProtectedPush -and ($branch -eq 'main' -or $branch -eq 'develop')) {
    Write-Warn "Protected branch override active via GITFLOW_ALLOW_PROTECTED_PUSH=1."
}

exit 0
