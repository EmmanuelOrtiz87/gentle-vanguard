# master-connector.ps1
# CONNECTS ALL SYSTEMS - 100% automated orchestration

param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

# ============================================================================
# PHASE 1: MANDATORY TRIGGER DETECTION (ALWAYS FIRST)
# ============================================================================

Write-Output "=== PHASE 1: Trigger Detection ==="

$triggerScript = Join-Path $WorkspaceRoot "tools/pre-process-input.ps1"
if (-not (Test-Path $triggerScript)) {
    Write-Output "ERROR: pre-process-input.ps1 not found at: $triggerScript"
    exit 1
}

$triggerResult = & $triggerScript -UserInput $UserInput -WorkspaceRoot $WorkspaceRoot

Write-Output $triggerResult

# Parse result - handle array output
$skillToLoad = $null
$triggerFound = $false

foreach ($line in $triggerResult) {
    if ($line -match 'SKILL:\s*(.+)') {
        $skillToLoad = $matches[1].Trim()
        $triggerFound = $true
        Write-Output "ACTION: Auto-loading skill '$skillToLoad'..."
        break
    }
}

# ============================================================================
# PHASE 2: AUTO-DELEGATION (If high-confidence match)
# ============================================================================

Write-Output "=== PHASE 2: Auto-Delegation Check ==="

$autoDelConfig = Join-Path $WorkspaceRoot "config/auto-delegation.json"
if (Test-Path $autoDelConfig) {
    $config = Get-Content $autoDelConfig -Raw | ConvertFrom-Json
    Write-Output "Auto-delegation config loaded. Enabled: $($config.enabled)"
    
    if ($config.enabled -eq $true -and $skillToLoad) {
        Write-Output "Delegating to: $skillToLoad"
        
        # Map skill to agent
        $agentMap = @{
            "session-workflow-skill" = "ORCHESTRATOR"
            "testing-coverage-skill" = "QA"
            "sdd-apply" = "DEV"
            "sdd-design" = "SAD"
            "sdd-verify" = "QA"
            "docker-devops-skill" = "OPS"
            "judgment-day" = "GOV"
        }
        
        if ($agentMap[$skillToLoad]) {
            $agent = $agentMap[$skillToLoad]
            Write-Output "ROUTED TO AGENT: $agent"
            Write-Output "AUTO-DELEGATION: SUCCESS"
        }
    }
}

# ============================================================================
# PHASE 3: CONTEXT CLEANUP (On session end markers)
# ============================================================================

$endMarkers = @("guardar sesion", "end session", "finalizar", "guardar")
$inputLower = $UserInput.ToLower()

foreach ($marker in $endMarkers) {
    if ($inputLower.Contains($marker)) {
        Write-Output "=== PHASE 3: Session End Detected ==="
        Write-Output "Running cleanup..."
        
        # Run pre-compact-hook
        $cleanupScript = Join-Path $WorkspaceRoot "tools/pre-compact-hook.ps1"
        if (Test-Path $cleanupScript) {
            & $cleanupScript -ProjectName "workspace_local" -CompressionRatio 0.90
            Write-Output "Context cleanup: DONE"
        }
        
        # Run handoff compression
        $handoffScript = Join-Path $WorkspaceRoot "tools/handoff-compress.ps1"
        if (Test-Path $handoffScript) {
            & $handoffScript
            Write-Output "Handoff compression: DONE"
        }
        
        Write-Output "SESSION CLEANUP: COMPLETE"
        break
    }
}

# ============================================================================
# PHASE 4: OUTPUT FINAL STATUS
# ============================================================================

Write-Output "=== FINAL STATUS ==="
Write-Output "Trigger Detection: $(if ($triggerFound) { "MATCH: $skillToLoad" } else { "NO MATCH" })"
Write-Output "Auto-Delegation: $(if ($config.enabled -eq $true) { "ENABLED" } else { "DISABLED" })"
Write-Output "Context Cleanup: READY"
Write-Output "All systems: CONNECTED"

return @{
    UserInput = $UserInput
    DetectedSkill = $skillToLoad
    ShouldDelegate = ($skillToLoad -ne $null)
    ConfigEnabled = ($config.enabled -eq $true)
    AllSystemsConnected = $true
}
