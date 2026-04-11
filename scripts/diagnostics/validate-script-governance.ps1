param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Write-Step { param([string]$Message) if (-not $Quiet) { Write-Host "`n=== $Message ===" -ForegroundColor Cyan } }
function Write-Ok { param([string]$Message) if (-not $Quiet) { Write-Host "[OK] $Message" -ForegroundColor Green } }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

$failures = 0

$requiredPaths = @(
    "docs/reference/script-registry.md",
    "scripts/utilities/detect-ide-session.ps1",
    "scripts/utilities/auto-init-dev-environment.ps1",
    "scripts/utilities/ensure-tools-active.ps1",
    "scripts/utilities/wf.ps1",
    "scripts/utilities/stack-on-demand.ps1",
    "scripts/utilities/orchestrator-status.ps1"
)

Write-Step "Validating required scripts and registry"
foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (Test-Path $fullPath) {
        Write-Ok "$relativePath"
    } else {
        Write-Fail "Missing: $relativePath"
        $failures++
    }
}

Write-Step "Running smoke checks"

$wfScript = Join-Path $repoRoot "scripts/utilities/wf.ps1"
$autoInitScript = Join-Path $repoRoot "scripts/utilities/auto-init-dev-environment.ps1"

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $wfScript ide-status | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "wf ide-status" } else { throw "wf ide-status failed" }
} catch {
    Write-Fail "wf ide-status check failed"
    $failures++
}

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $autoInitScript -Quiet | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Ok "auto-init quiet" } else { throw "auto-init quiet failed" }
} catch {
    Write-Fail "auto-init quiet check failed"
    $failures++
}

Write-Step "Result"
if ($failures -gt 0) {
    Write-Fail "Script governance validation failed with $failures issue(s)."
    exit 1
}

Write-Ok "Script governance validation passed"
exit 0
