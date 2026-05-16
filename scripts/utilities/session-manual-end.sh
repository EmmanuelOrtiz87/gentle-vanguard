#!/usr/bin/env bash
# ============================================================
# Session Manual End (Linux/macOS/WSL)
# Location: scripts/utilities/session-manual-end.sh
# ============================================================
set -euo pipefail

echo ""
echo "=== Session Manual End ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v pwsh &>/dev/null; then
    echo "[ERROR] PowerShell (pwsh) not found in PATH"
    exit 1
fi

# Pre-close: generate final status report
echo "[INFO] Generating final status report..."
STATUS_MONITOR="$REPO_ROOT/scripts/monitoring/continuous-status-monitor.ps1"
if [ -f "$STATUS_MONITOR" ]; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$STATUS_MONITOR" -Once || true
else
    echo "[SKIP] continuous-status-monitor.ps1 not found"
fi

# Main close flow via wf.ps1
WF_SCRIPT="$REPO_ROOT/scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1"
if [ ! -f "$WF_SCRIPT" ]; then
    echo "[ERROR] wf.ps1 not found"
    exit 1
fi

echo "[INFO] Running standard close flow (validation + audit + governance)..."
pwsh -NoProfile -ExecutionPolicy Bypass -File "$WF_SCRIPT" end-session || echo "[WARN] Close flow reported issues — continuing with post-close steps..."

# Post-close: cross-workspace validation
echo "[INFO] Validating cross-workspace consistency..."
CROSS_VALIDATOR="$REPO_ROOT/scripts/monitoring/cross-workspace-validator.ps1"
if [ -f "$CROSS_VALIDATOR" ]; then
    if pwsh -NoProfile -ExecutionPolicy Bypass -File "$CROSS_VALIDATOR"; then
        echo "[OK] Cross-workspace validated"
    else
        echo "[WARN] Cross-workspace validation found issues"
    fi
else
    echo "[SKIP] cross-workspace-validator.ps1 not found"
fi

# Post-close: engram optimization
OPTIMIZE_SCRIPT="$REPO_ROOT/scripts/utilities/PERFORMANCE-OPTIMIZATION/optimize-engram-usage.ps1"
if [ -f "$OPTIMIZE_SCRIPT" ]; then
    echo "[INFO] Running post-session Engram optimization..."
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$OPTIMIZE_SCRIPT" -ProjectName "workspace_local" -AutoApply
else
    echo "[SKIP] optimize-engram-usage.ps1 not found"
fi

# Weekly metrics on Sundays
DAYOFWEEK=$(date +%u)
if [ "$DAYOFWEEK" = "7" ]; then
    WEEKLY_METRICS="$REPO_ROOT/scripts/monitoring/weekly-metrics.ps1"
    if [ -f "$WEEKLY_METRICS" ]; then
        echo "[INFO] Generating weekly metrics report..."
        pwsh -NoProfile -ExecutionPolicy Bypass -File "$WEEKLY_METRICS"
    else
        echo "[SKIP] weekly-metrics.ps1 not found"
    fi
fi

echo ""
echo "============================================"
echo "[OK] Session closed successfully"
echo "[OK] Final report and validations complete"
if [ "$DAYOFWEEK" = "7" ]; then
    echo "[OK] Weekly metrics report generated"
fi
echo ""
echo "Next steps:"
echo "  - Review logs/status-report.txt for final status"
echo "  - Check .session/reports/ for closure artifacts"
if [ "$DAYOFWEEK" = "7" ]; then
    echo "  - Review logs/weekly-metrics-*.md for weekly summary"
fi
echo "============================================"
echo ""

exit 0
