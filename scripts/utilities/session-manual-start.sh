#!/usr/bin/env bash
# ============================================================
# Session Manual Start (Linux/macOS/WSL)
# Location: scripts/utilities/session-manual-start.sh
# ============================================================
set -euo pipefail

echo ""
echo "=== Session Manual Start ==="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v pwsh &>/dev/null; then
    echo "[ERROR] PowerShell (pwsh) not found in PATH"
    exit 1
fi

# Pre-start: engram optimization
OPTIMIZE_SCRIPT="$REPO_ROOT/scripts/utilities/PERFORMANCE-OPTIMIZATION/optimize-engram-usage.ps1"
if [ -f "$OPTIMIZE_SCRIPT" ]; then
    echo "[INFO] Running pre-session Engram optimization..."
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$OPTIMIZE_SCRIPT" -ProjectName "workspace_local"
fi

# Main start flow via wf.ps1
WF_SCRIPT="$REPO_ROOT/scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1"
if [ ! -f "$WF_SCRIPT" ]; then
    echo "[ERROR] wf.ps1 not found"
    exit 1
fi

echo "[INFO] Starting session..."
if pwsh -NoProfile -ExecutionPolicy Bypass -File "$WF_SCRIPT" start-session; then
    echo "[SUCCESS] Session started successfully"
    exit 0
else
    echo "[ERROR] Session start failed"
    exit 1
fi
