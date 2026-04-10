#!/bin/sh
# pre-commit-security.sh
# Security pre-commit hook
# This hook runs before each commit to scan for security issues

WF_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SCAN_SCRIPT="$SKILL_DIR/security-scan.ps1"
REPORT_FILE="$WF_ROOT/docs/security-review.md"

# Colors for output (if terminal supports)
if [ -t 1 ]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'
else
    RED=''
    YELLOW=''
    GREEN=''
    NC=''
fi

echo ""
echo "=========================================="
echo " Security Expert - Pre-commit Scan"
echo "=========================================="
echo ""

# Check if security skill is installed
if [ ! -f "$SCAN_SCRIPT" ]; then
    echo "${YELLOW}[SKIP]${NC} Security skill not found. Run 'wf skills --install' to install."
    exit 0
fi

# Detect staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "${GREEN}[OK]${NC} No files staged for commit."
    exit 0
fi

echo "Scanning staged files for security issues..."
echo ""

# Check for obvious secrets in staged files before running full scan
SECRET_FOUND=0

# AWS Keys
if echo "$STAGED_FILES" | xargs git diff --cached --name-only | xargs -I{} sh -c 'git show ":0:{}" 2>/dev/null' | grep -E 'AKIA[0-9A-Z]{16}' >/dev/null 2>&1; then
    echo "${RED}[CRITICAL]${NC} Potential AWS Access Key detected in staged files!"
    SECRET_FOUND=1
fi

# GitHub Tokens
if echo "$STAGED_FILES" | xargs git diff --cached --name-only | xargs -I{} sh -c 'git show ":0:{}" 2>/dev/null' | grep -E 'ghp_[A-Za-z0-9]{36}' >/dev/null 2>&1; then
    echo "${RED}[CRITICAL]${NC} Potential GitHub Token detected in staged files!"
    SECRET_FOUND=1
fi

# Private Keys
if echo "$STAGED_FILES" | xargs git diff --cached --name-only | xargs -I{} sh -c 'git show ":0:{}" 2>/dev/null' | grep -E '-----BEGIN.*PRIVATE KEY-----' >/dev/null 2>&1; then
    echo "${RED}[CRITICAL]${NC} Potential Private Key detected in staged files!"
    SECRET_FOUND=1
fi

# Generic API Keys
if echo "$STAGED_FILES" | xargs git diff --cached --name-only | xargs -I{} sh -c 'git show ":0:{}" 2>/dev/null' | grep -iE '(api[_-]?key|apikey)["\s]*[=:]["\s]*["\x27][A-Za-z0-9]{20,}["\x27]' >/dev/null 2>&1; then
    echo "${RED}[CRITICAL]${NC} Potential API Key detected in staged files!"
    SECRET_FOUND=1
fi

# Database URLs with credentials
if echo "$STAGED_FILES" | xargs git diff --cached --name-only | xargs -I{} sh -c 'git show ":0:{}" 2>/dev/null' | grep -iE '(mysql|postgres|mongodb)://[^:]+:[^@]+@' >/dev/null 2>&1; then
    echo "${RED}[CRITICAL]${NC} Database URL with credentials detected!"
    SECRET_FOUND=1
fi

if [ $SECRET_FOUND -eq 1 ]; then
    echo ""
    echo "${RED}=========================================="
    echo " COMMIT BLOCKED - Secrets detected!"
    echo "==========================================${NC}"
    echo ""
    echo "Remove secrets from staged files or use environment variables."
    echo "See: docs/security-best-practices.md"
    echo ""
    exit 1
fi

# Run PowerShell scanner if available
if command -v pwsh >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
    SCANNER_CMD="pwsh"
    if ! command -v pwsh >/dev/null 2>&1; then
        SCANNER_CMD="powershell"
    fi
    
    $SCANNER_CMD -ExecutionPolicy Bypass -File "$SCAN_SCRIPT" -Path "$WF_ROOT" -Verbose 2>/dev/null
    
    SCAN_RESULT=$?
    
    if [ $SCAN_RESULT -eq 1 ]; then
        echo ""
        echo "${RED}=========================================="
        echo " COMMIT BLOCKED - Security issues found!"
        echo "==========================================${NC}"
        echo ""
        echo "Run 'wf security audit' for detailed report."
        echo "Run 'wf security scan --interactive' to review and fix issues."
        echo ""
        exit 1
    fi
else
    echo "${YELLOW}[WARN]${NC} PowerShell not available. Skipping detailed scan."
    echo "Install PowerShell Core for full security scanning."
fi

echo ""
echo "${GREEN}[OK]${NC} Security scan passed!"
echo ""

exit 0
