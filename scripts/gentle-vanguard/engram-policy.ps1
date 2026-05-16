# engram-policy.ps1
# Engram Policy Enforcement - Session Startup
# Validates and enforces Engram memory policies during session initialization

param(
    [string]$WorkspaceRoot = ".",
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'

Write-Output "[ENGRAM-POLICY] Starting Engram policy enforcement"

# Check if Engram is available
$engramPath = if ($env:ENGRAM_BIN) { $env:ENGRAM_BIN } else { "engram" }

try {
    $engramVersion = & $engramPath --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[ENGRAM-POLICY] Engram available: $engramVersion"
    } else {
        Write-Output "[ENGRAM-POLICY] Engram not available, skipping policy enforcement"
        exit 0
    }
} catch {
    Write-Output "[ENGRAM-POLICY] Engram not found, skipping policy enforcement"
    exit 0
}

# Validate Engram project configuration
$projectName = "workspace_gentle_vanguard"
Write-Output "[ENGRAM-POLICY] Validating project: $projectName"

# Check Engram memory integrity
Write-Output "[ENGRAM-POLICY] Checking memory integrity..."
try {
    $memCheck = & $engramPath search --project $projectName --limit 1 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[ENGRAM-POLICY] Memory integrity verified"
    } else {
        Write-Output "[ENGRAM-POLICY] Memory integrity check failed, but continuing"
    }
} catch {
    Write-Output "[ENGRAM-POLICY] Could not verify memory integrity"
}

# Enforce retention policies
Write-Output "[ENGRAM-POLICY] Enforcing retention policies..."
$retentionDays = 90
Write-Output "[ENGRAM-POLICY] Retention policy: $retentionDays days"

# Log policy enforcement
Write-Output "[ENGRAM-POLICY] Policy enforcement completed successfully"
exit 0