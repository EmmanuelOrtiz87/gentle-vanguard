#!/usr/bin/env bash
# ============================================================
# Session Autostart (Linux/macOS/WSL)
# Location: scripts/utilities/session-autostart.sh
# Resolves workspace root: scripts/utilities/ -> ./ (2 levels up)
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

# === Phase 1: Session Manager ===
echo "[1/8] Initializing session manager..."
if pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/session-manager.ps1" -Mode AutoStart; then
    echo "[OK] Session initialized"
else
    echo "[ERROR] session-manager.ps1 failed"
    if [ -f "$UTILS_DIR/wf.ps1" ]; then
        echo "[FALLBACK] Attempting wf.ps1..."
        pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/wf.ps1" start-session
    else
        echo "[FATAL] No fallback available. Aborting."
        exit 1
    fi
fi

# === Phase 2: Notifications ===
echo "[2/8] Time-based notifications..."
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
echo "[3/8] Resolving session ID..."
SESSION_ID=$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$UTILS_DIR/get-session-id.ps1" 2>/dev/null || true)
if [ -n "$SESSION_ID" ]; then
    echo "[OK] Session ID: $SESSION_ID"
else
    echo "[WARN] Could not resolve session ID"
fi

# === Phase 4: Engram Policy Enforcement ===
echo "[4/8] Engram policy enforcement..."
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
echo "[5/8] Engram optimization..."
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
echo "[6/8] Cross-workspace validation..."
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
echo "[7/8] Security orchestrator..."
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
echo "[8/8] Skill router..."
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

echo ""
echo "=== Session Autostart Complete ==="
echo "[READY] Workspace ready for operations"
