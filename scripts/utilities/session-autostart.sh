#!/usr/bin/env bash
# ============================================================
# Session Autostart (Linux/macOS/WSL)
# Location: scripts/utilities/session-autostart.sh
# Resolves workspace root: scripts/utilities/ -> ./ (2 levels up)
# Mirrors session-autostart.cmd phases for cross-platform parity
# ============================================================
set -euo pipefail

# === Phase 0: Workspace Detection ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UTILS_DIR="$WORKSPACE_ROOT/scripts/utilities"

echo ""
echo "=== Session Autostart ==="
echo "Workspace: $WORKSPACE_ROOT"
echo ""

# === Pre-flight Health Check ===
HEALTH_CRITICAL=true

if [ ! -d "$WORKSPACE_ROOT/.git" ]; then
    echo "[CRITICAL] Not a git repository: $WORKSPACE_ROOT"
    HEALTH_CRITICAL=false
else
    echo "[PASS] Git repository"
fi

if [ ! -f "$WORKSPACE_ROOT/config/auto-delegation.json" ]; then
    echo "[CRITICAL] Missing routing config: config/auto-delegation.json"
    HEALTH_CRITICAL=false
else
    echo "[PASS] Routing config"
fi

if [ ! -f "$UTILS_DIR/session-manager.ps1" ]; then
    echo "[CRITICAL] Missing session-manager.ps1"
    HEALTH_CRITICAL=false
else
    echo "[PASS] Session manager"
fi

if [ ! -f "$WORKSPACE_ROOT/opencode.json" ]; then
    echo "[WARN] Missing opencode.json - AI config may be incomplete"
fi

if [ ! -f "$UTILS_DIR/token-guard.ps1" ]; then
    echo "[WARN] Missing token-guard.ps1 - token limits not enforced"
fi

echo ""
if [ "$HEALTH_CRITICAL" = false ]; then
    echo "[ABORTED] Health check failed. Resolve critical issues and retry."
    exit 1
fi
echo "[HEALTH] All critical checks passed."
echo ""

# === Phase 0.5: Tool Detection ===
echo "[1/16] Detecting tool/plugin..."
TOOL_DETECTION="$UTILS_DIR/detect-tool.ps1"
if [ -f "$TOOL_DETECTION" ]; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$TOOL_DETECTION" -AsJson 2>/dev/null | head -5 || true
    echo "[OK] Tool detected and configuration loaded"
else
    echo "[WARN] detect-tool.ps1 not found - using default configuration"
fi

# === Phase 0.75: Orphan Session Cleanup ===
echo "[2/16] Checking for orphaned sessions..."
pwsh -NoProfile -ExecutionPolicy Bypass -Command "
  \$stateFile='$WORKSPACE_ROOT/.session/state.json';
  \$activeFile='$WORKSPACE_ROOT/logs/.session-active';
  \$dayEnd='$WORKSPACE_ROOT/scripts/utilities/UTILITIES/day-end-closure.ps1';
  \$orphan=\$false;
  \$sid='';
  if (Test-Path \$stateFile) { try { \$d=Get-Content \$stateFile -Raw|ConvertFrom-Json; if (\$d.status -eq 'active') { \$orphan=\$true; \$sid=\$d.sessionId } } catch {} };
  if (-not \$orphan -and (Test-Path \$activeFile)) { \$orphan=\$true; try { \$d=Get-Content \$activeFile -Raw|ConvertFrom-Json; \$sid=\$d.SessionId } catch {} };
  if (\$orphan) { Write-Host '[WARN] Orphaned session detected: ' -NoNewline -ForegroundColor Yellow; if (\$sid) { Write-Host \$sid -ForegroundColor Yellow } else { Write-Host 'unknown' -ForegroundColor Yellow }; Write-Host '[INFO] Auto-closing orphan before new start...' -ForegroundColor Cyan; if (Test-Path \$dayEnd) { & \$dayEnd -SessionId \$sid -Force -SkipValidation -SkipRotation -Quiet; Write-Host '[OK] Orphan session closed' -ForegroundColor Green } } else { Write-Host '[OK] No orphaned sessions found' -ForegroundColor Green }
"
echo "[OK] Orphan check complete"

# === Phase 1: Session Manager ===
echo "[3/16] Initializing session manager..."
WF_DIR="$WORKSPACE_ROOT/scripts/utilities/WORKFLOW-ORCHESTRATION"
if [ -d "$WF_DIR" ]; then
    export PATH="$WF_DIR:$PATH"
fi

if pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/session-manager.ps1" -Mode AutoStart; then
    echo "[OK] Session initialized"
else
    echo "[ERROR] session-manager.ps1 failed"
    if [ -f "$WF_DIR/wf.ps1" ]; then
        echo "[FALLBACK] Attempting wf.ps1..."
        pwsh -NoProfile -ExecutionPolicy Bypass -File "$WF_DIR/wf.ps1" start-session
    else
        echo "[FATAL] No fallback available. Aborting."
        exit 1
    fi
fi

# === Phase 2: Notifications ===
echo "[4/16] Time-based notifications..."
if [ -f "$UTILS_DIR/session-notification.ps1" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/session-notification.ps1" -TimeZone "America/Argentina/Buenos_Aires" -PeakStart 9 -PeakEnd 15 -Region "Argentina"; then
        echo "[OK] Notifications checked"
    else
        echo "[WARN] Notification check had warnings"
    fi
else
    echo "[SKIP] session-notification.ps1 not found"
fi

# === Phase 3: Session ID ===
echo "[5/16] Resolving session ID..."
SESSION_ID=$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/get-session-id.ps1" 2>/dev/null || true)
if [ -n "$SESSION_ID" ]; then
    export FOUNDATION_SESSION_ID="$SESSION_ID"
    export WFS_SESSION_ID="$SESSION_ID"
    echo "[OK] Session ID: $SESSION_ID"
else
    echo "[WARN] Could not resolve session ID"
fi

# === Phase 3.5: Session Metrics Start ===
echo "[6/16] Starting session metrics tracking..."
METRICS_SCRIPT="$UTILS_DIR/session-metrics-tracker.ps1"
if [ -f "$METRICS_SCRIPT" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$METRICS_SCRIPT" -Action start -SessionId "$SESSION_ID" -Silent; then
        echo "[OK] Session metrics active"
    else
        echo "[WARN] Metrics tracking start had warnings"
    fi
else
    echo "[SKIP] session-metrics-tracker.ps1 not found"
fi

# === Phase 4: Engram Policy Enforcement ===
echo "[7/16] Engram policy enforcement..."
ENGRAM_POLICY="$WORKSPACE_ROOT/scripts/foundation/engram-policy.ps1"
if [ -f "$ENGRAM_POLICY" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$ENGRAM_POLICY" -Action enforce; then
        echo "[OK] Engram policy enforced"
    else
        echo "[WARN] Engram policy issues detected"
        if [ -f "$UTILS_DIR/engram-orchestrator.ps1" ]; then
            pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/engram-orchestrator.ps1" -Action orchestrate
        fi
    fi
else
    echo "[SKIP] engram-policy.ps1 not found"
fi

# === Phase 5: Engram Optimization ===
echo "[8/16] Engram optimization..."
OPTIMIZE_SCRIPT="$WORKSPACE_ROOT/scripts/utilities/PERFORMANCE-OPTIMIZATION/optimize-engram-usage.ps1"
if [ -f "$OPTIMIZE_SCRIPT" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$OPTIMIZE_SCRIPT" -ProjectName "workspace_local"; then
        echo "[OK] Engram optimized"
    else
        echo "[WARN] Optimization had warnings"
    fi
else
    echo "[SKIP] optimize-engram-usage.ps1 not found"
fi

# === Phase 6: Cross-Workspace Validation ===
echo "[9/16] Cross-workspace validation..."
CROSS_VALIDATOR="$WORKSPACE_ROOT/scripts/monitoring/cross-workspace-validator.ps1"
if [ -f "$CROSS_VALIDATOR" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$CROSS_VALIDATOR" -Detailed; then
        echo "[OK] Cross-workspace validated"
    else
        echo "[WARN] Validation found issues"
    fi
else
    echo "[SKIP] cross-workspace-validator.ps1 not found"
fi

# === Phase 7: Security Orchestrator ===
echo "[10/16] Security orchestrator..."
SECURITY_SCRIPT="$WORKSPACE_ROOT/scripts/security/security-orchestrator.ps1"
if [ -f "$SECURITY_SCRIPT" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$SECURITY_SCRIPT" -Action init -AsJson; then
        echo "[OK] Security initialized"
    else
        echo "[WARN] Security init had warnings"
    fi
else
    echo "[SKIP] security-orchestrator.ps1 not found"
fi

# === Phase 8: Skill Router ===
echo "[11/16] Skill router..."
SKILL_ROUTER="$UTILS_DIR/skill-router.ps1"
if [ -f "$SKILL_ROUTER" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$SKILL_ROUTER" -Query "session-start"; then
        echo "[OK] Skill router active"
    else
        echo "[WARN] Skill router validation issue"
    fi
else
    echo "[SKIP] skill-router.ps1 not found"
fi

# === Phase 8.5: Skill Registry Build ===
echo "[12/16] Building skill registry..."
SKILL_REGISTRY="$UTILS_DIR/build-skill-registry.ps1"
if [ -f "$SKILL_REGISTRY" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$SKILL_REGISTRY" -Quiet; then
        echo "[OK] Skill registry built"
    else
        echo "[WARN] Skill registry build had issues"
    fi
else
    echo "[SKIP] build-skill-registry.ps1 not found"
fi

# === Phase 9: Post-Autostart Summary ===
echo "[13/16] Generating startup summary..."
POST_SUMMARY="$UTILS_DIR/post-autostart-summary.ps1"
if [ -f "$POST_SUMMARY" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$POST_SUMMARY"; then
        echo "[OK] Startup summary saved"
    else
        echo "[WARN] Summary generation had warnings"
    fi
else
    echo "[SKIP] post-autostart-summary.ps1 not found"
fi

# === Phase 9.5: Workspace State Warning ===
echo "[14/16] Checking workspace state..."
WORKSPACE_STATE=$(cd "$WORKSPACE_ROOT" && git status --porcelain 2>/dev/null || true)
if [ -n "$WORKSPACE_STATE" ]; then
    echo "[WARN] ====================================================================="
    echo "[WARN]  Workspace has uncommitted changes from a previous session."
    echo "[WARN]  Run 'git status' to review, or 'git stash' to shelve them."
    echo "[WARN] ====================================================================="
else
    echo "[OK] Workspace is clean"
fi

# === Phase 10: Watchtower Quick Check ===
echo "[15/16] Watchtower quick health check..."
WATCHTOWER_SCRIPT="$UTILS_DIR/watchtower.ps1"
if [ -f "$WATCHTOWER_SCRIPT" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$WATCHTOWER_SCRIPT" -Quiet; then
        echo "[OK] Watchtower all clear"
    else
        echo "[WARN] Watchtower detected issues - run 'pwsh $WATCHTOWER_SCRIPT' for details"
    fi
else
    echo "[SKIP] watchtower.ps1 not found"
fi

echo ""
echo "[16/16] === Session Autostart Complete ==="
echo "[READY] Workspace ready for operations"
