#!/bin/sh
# pre-commit-review.sh
# Unified pre-commit hook for Code Review Orchestrator (Unix)

WF_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
SKILL_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
REVIEW_SCRIPT="$SKILL_DIR/code-review.ps1"
MARKER_FILE=".hooks/pre-commit.marker"

if [ -z "$WF_ROOT" ]; then
    echo "[SKIP] Not in a git repository."
    exit 0
fi

cd "$WF_ROOT"

if [ -f "$MARKER_FILE" ]; then
    echo "[SKIP] Reentrant hook detected. Skipping nested execution."
    exit 0
fi

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
    echo "[OK] No files staged for commit."
    exit 0
fi

if [ ! -f "$REVIEW_SCRIPT" ]; then
    echo "[SKIP] Code Review Orchestrator not found."
    exit 0
fi

echo ""
echo "========================================"
echo " Code Review - Pre-commit Scan"
echo "========================================"
echo ""

touch "$MARKER_FILE"

trap 'rm -f "$MARKER_FILE"' EXIT INT TERM

echo "Scanning staged files for critical issues..." >&2

CRITICAL_FOUND=0
HIGH_FOUND=0

CRITICAL_PATTERNS="AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|-----BEGIN.*PRIVATE KEY-----|sk_live_[0-9a-zA-Z]{24,}|SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}"

for file in $STAGED_FILES; do
    CONTENT=$(git show ":0:$file" 2>/dev/null)
    
    if echo "$CONTENT" | grep -Eq "$CRITICAL_PATTERNS"; then
        echo "  [CRITICAL] $file - Secret detected" >&2
        CRITICAL_FOUND=1
    fi
done

if [ $CRITICAL_FOUND -eq 1 ]; then
    echo ""
    echo "========================================"
    echo " BLOCKED - Critical issues detected!"
    echo "========================================"
    echo ""
    echo "Critical secrets detected in staged files."
    echo "Remove or secure credentials before committing."
    echo ""
    exit 1
fi

if command -v pwsh >/dev/null 2>&1; then
    pwsh -ExecutionPolicy Bypass -File "$REVIEW_SCRIPT" -Scope quick -Path "$WF_ROOT" 2>/dev/null
else
    echo "[WARN] PowerShell not available. Skipping full scan."
fi

exit_code=$?

echo ""
echo "========================================"
echo " Scan completed"
echo "========================================"
echo ""

if [ $exit_code -eq 1 ]; then
    echo "Run 'wf review' for detailed report." >&2
fi

exit $exit_code
