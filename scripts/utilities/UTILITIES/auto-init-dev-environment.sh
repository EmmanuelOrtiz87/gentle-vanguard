#!/usr/bin/env bash
# auto-init-dev-environment.sh - Universal auto-initialization
# Works on: Linux, macOS, Windows (WSL, Git Bash)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
AUTO_START=${1:-false}
QUIET=${2:-false}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ "$QUIET" != "true" ]; then
    log_info ""
    log_info "    Auto-Initialize Development Environment"
    log_info ""
fi

# Step 1: Run diagnostics
if [ "$QUIET" != "true" ]; then
    log_info "Running system diagnostics..."
fi

if ! bash "$SCRIPT_DIR/system-diagnostics.sh" > /dev/null 2>&1; then
    if [ "$QUIET" != "true" ]; then
        log_error "System diagnostics failed"
    fi
    exit 1
fi

# Step 2: Check Engram CLI
if [ "$QUIET" != "true" ]; then
    log_info "Checking Engram CLI..."
fi

if ! command -v engram &> /dev/null; then
    if [ "$AUTO_START" = "true" ]; then
        if [ "$QUIET" != "true" ]; then
            log_info "Installing Engram CLI..."
        fi
        
        if go install github.com/Gentleman-Programming/engram/cmd/engram@latest; then
            if [ "$QUIET" != "true" ]; then
                log_success "Engram CLI installed"
            fi
        else
            if [ "$QUIET" != "true" ]; then
                log_error "Failed to install Engram CLI"
            fi
            exit 1
        fi
    else
        if [ "$QUIET" != "true" ]; then
            log_error "Engram CLI not found. Run with -AutoStart to install automatically"
        fi
        exit 1
    fi
fi

# Step 3: Initialize Engram data directory
if [ "$QUIET" != "true" ]; then
    log_info "Initializing Engram data directory..."
fi

export ENGRAM_DATA_DIR="$PROJECT_ROOT/.engram-data"
mkdir -p "$ENGRAM_DATA_DIR"

# Step 4: Link orchestrator skill if available
if [ "$QUIET" != "true" ]; then
    log_info "Linking orchestrator skill..."
fi

if [ -d "$PROJECT_ROOT/skills/project-orchestrator-skill" ]; then
    if command -v engram &> /dev/null; then
        engram skill add "$PROJECT_ROOT/skills/project-orchestrator-skill" 2>/dev/null || true
    fi
fi

# Step 5: Verify environment
if [ "$QUIET" != "true" ]; then
    log_info "Verifying environment..."
fi

if bash "$SCRIPT_DIR/system-diagnostics.sh" > /dev/null 2>&1; then
    if [ "$QUIET" != "true" ]; then
        log_success ""
        log_success "    Environment Ready!"
        log_success ""
        log_info ""
        log_info "Next steps:"
        log_info "  1. cd $(basename "$PROJECT_ROOT")"
        log_info "  2. ./wf status"
        log_info "  3. Start coding!"
        log_info ""
    fi
    exit 0
else
    if [ "$QUIET" != "true" ]; then
        log_error "Environment verification failed"
    fi
    exit 1
fi
