#!/usr/bin/env bash
# wf.sh - Foundation - Development Stack Workflow CLI (bash/sh version)
# Works on: Linux, macOS, Windows (WSL, Git Bash)
# Mirror of wf.ps1 - all commands wrapped for shell compatibility

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/scripts/utilities"
DIAGNOSTICS_DIR="$PROJECT_ROOT/scripts/diagnostics"

# Logging functions
log_header() {
    echo -e "${CYAN}${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}${NC}"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Command: status
cmd_status() {
    log_header "Foundation - Development Stack - Status Report"
    
    echo ""
    log_info "Project Root: $PROJECT_ROOT"
    log_info "OS: $(uname -s)"
    log_info "Shell: ${SHELL##*/}"
    log_info ""
    
    # Check critical tools
    log_info "Critical Dependencies:"
    for tool in git go bash; do
        if command -v "$tool" &> /dev/null; then
            version=$(eval "$tool --version 2>/dev/null | head -n 1" || echo "unknown")
            log_success "$tool: $version"
        else
            log_error "$tool: NOT FOUND"
        fi
    done
    
    echo ""
    log_info "Optional Dependencies:"
    for tool in node npm engram; do
        if command -v "$tool" &> /dev/null; then
            version=$(eval "$tool --version 2>/dev/null | head -n 1" || echo "unknown")
            log_success "$tool: $version"
        else
            log_warn "$tool: not installed"
        fi
    done
    
    echo ""
}

# Command: health
cmd_health() {
    log_header "System Health Check & Tool Activation"
    
    echo ""
    
    # Run diagnostics
    if bash "$DIAGNOSTICS_DIR/system-diagnostics.sh"; then
        log_success "Health check passed"
    else
        log_error "Health check detected issues"
        return 1
    fi
    
    # Try to install missing Engram CLI
    if ! command -v engram &> /dev/null; then
        log_warn "Engram CLI missing. Installing..."
        if go install github.com/Gentleman-Programming/engram/cmd/engram@latest; then
            log_success "Engram CLI installed successfully"
        else
            log_error "Failed to install Engram CLI"
            return 1
        fi
    fi
    
    # Initialize Engram data directory
    export ENGRAM_DATA_DIR="$PROJECT_ROOT/.engram-data"
    mkdir -p "$ENGRAM_DATA_DIR"
    
    echo ""
    log_success "System ready!"
    echo ""
}

# Command: diagnose
cmd_diagnose() {
    log_header "Detailed System Diagnosis"
    
    bash "$DIAGNOSTICS_DIR/system-diagnostics.sh"
}

# Command: verify
cmd_verify() {
    log_header "Environment Verification"
    
    local issues=0
    
    log_info "Checking critical systems:"
    
    # Check Go
    if command -v go &> /dev/null; then
        log_success "Go compiler: OK"
    else
        log_error "Go compiler: NOT FOUND"
        issues=$((issues + 1))
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        log_success "Git: OK"
    else
        log_error "Git: NOT FOUND"
        issues=$((issues + 1))
    fi
    
    # Check config
    if [ -f "$PROJECT_ROOT/config/workspace.config.json" ]; then
        log_success "Workspace config: OK"
    else
        log_warn "Workspace config: MISSING"
    fi
    
    # Check orchestrator
    if [ -f "$PROJECT_ROOT/config/orchestrator.json" ]; then
        log_success "Orchestrator config: OK"
    else
        log_warn "Orchestrator config: MISSING"
    fi
    
    echo ""
    
    if [ $issues -eq 0 ]; then
        log_success "All systems verified"
        return 0
    else
        log_error "$issues issues found"
        return 1
    fi
}

# Command: init
cmd_init() {
    log_header "Initialize Development Environment"
    
    bash "$TOOLS_DIR/auto-init-dev-environment.sh" true false
}

# Command: help
cmd_help() {
    cat << 'EOF'

Foundation - Development Stack Workflow CLI (bash version)

USAGE:
    wf <command> [options]

COMMANDS:
    status          Show current project status and dependencies
    health          Run health checks and auto-install missing tools
    diagnose        Detailed system diagnostics
    verify          Verify environment is properly configured
    init            Initialize development environment
    help            Show this help message

EXAMPLES:
    ./wf status          # Show project status
    ./wf health          # Run health checks
    ./wf diagnose        # Detailed diagnostics
    ./wf verify          # Verify setup
    ./wf init            # Initialize environment

ENVIRONMENT VARIABLES:
    ENGRAM_DATA_DIR      Location of Engram data (default: ./.engram-data)

EOF
}

# Main
main() {
    local cmd="${1:-help}"
    
    case "$cmd" in
        status)     cmd_status;;
        health)     cmd_health;;
        diagnose)   cmd_diagnose;;
        verify)     cmd_verify;;
        init)       cmd_init;;
        help|-h|--help)  cmd_help;;
        *)
            log_error "Unknown command: $cmd"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
