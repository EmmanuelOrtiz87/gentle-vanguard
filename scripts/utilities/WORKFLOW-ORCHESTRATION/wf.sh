#!/usr/bin/env bash
# gv.sh - Gentle-Vanguard - Development Stack Workflow CLI (bash/sh version)
# Works on: Linux, macOS, Windows (WSL, Git Bash)
# Mirror of gv.ps1 - all commands wrapped for shell compatibility

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
    log_header "Gentle-Vanguard - Development Stack - Status Report"
    
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

# Helper: run a PS1 script via pwsh if available
run_pwsh() {
    local script="$1"; shift
    if command -v pwsh &> /dev/null; then
        pwsh -NoProfile -ExecutionPolicy Bypass -File "$script" "$@"
    else
        log_warn "pwsh not found. Install PowerShell Core: https://aka.ms/install-powershell"
        return 1
    fi
}

# Command: agent-verify
cmd_verify_full() {
    log_header "Agent Self-Verification (agent-verify.ps1)"
    run_pwsh "$TOOLS_DIR/agent-verify.ps1" "$@"
}

# Command: dashboard (static HTML from telemetry)
cmd_dashboard() {
    log_header "Generate HTML Dashboard"
    local out="$PROJECT_ROOT/reports/dashboard.html"
    if run_pwsh "$TOOLS_DIR/TELEMETRY-METRICS/generate-dashboard.ps1" -OutputPath "$out"; then
        log_success "Dashboard generated: $out"
        # Open if xdg-open / open available
        if command -v xdg-open &> /dev/null; then xdg-open "$out" 2>/dev/null &
        elif command -v open &> /dev/null; then open "$out" 2>/dev/null &
        fi
    fi
}

# Command: mq (message queue adapter)
cmd_mq() {
    local action="${1:-status}"; shift || true
    log_header "MQ Adapter ($action)"
    run_pwsh "$TOOLS_DIR/WORKFLOW-ORCHESTRATION/mq-adapter.ps1" -Action "$action" "$@"
}

# Command: export-metrics
cmd_export_metrics() {
    log_header "Export Metrics"
    run_pwsh "$TOOLS_DIR/TELEMETRY-METRICS/export-metrics.ps1" "$@"
}

# Command: events
cmd_events() {
    local action="${1:-list}"; shift || true
    run_pwsh "$TOOLS_DIR/WORKFLOW-ORCHESTRATION/event-bus.ps1" -Action "$action" "$@"
}

# Command: help
cmd_help() {
    cat << 'EOF'

Gentle-Vanguard - Development Stack Workflow CLI (bash version)
Works on Linux, macOS, Windows (WSL/Git Bash). Requires pwsh for PS1 features.

USAGE:
    gv <command> [options]

COMMANDS:
    status           Show current project status and dependencies
    health           Run health checks and auto-install missing tools
    diagnose         Detailed system diagnostics
    verify           Verify environment (basic bash checks)
    verify-full      Full agent self-verification via agent-verify.ps1 (needs pwsh)
    init             Initialize development environment
    dashboard        Generate static HTML dashboard from telemetry JSON
    mq [action]      Message queue adapter: status | publish | consume | test
    export-metrics   Export metrics to CSV/JSONL/SQLite store
    events [action]  Event bus: list | emit | history | subscribe
    help             Show this help message

EXAMPLES:
    ./gv status                  # Show project status
    ./gv health                  # Run health checks
    ./gv verify-full             # Full PS1-based verification (needs pwsh)
    ./gv dashboard               # Generate dashboard.html and open it
    ./gv mq status               # Check MQ adapter connectivity
    ./gv mq test                 # Test all MQ adapters
    ./gv export-metrics          # Export metrics to reports/metrics-export.csv
    ./gv events list             # List standard events

ENVIRONMENT VARIABLES:
    ENGRAM_DATA_DIR      Location of Engram data (default: ./.engram-data)

PWSH NOTE:
    Commands marked (needs pwsh) require PowerShell Core (pwsh).
    Install: https://aka.ms/install-powershell

EOF
}

# Main
main() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        status)          cmd_status;;
        health)          cmd_health;;
        diagnose)        cmd_diagnose;;
        verify)          cmd_verify;;
        verify-full)     cmd_verify_full "$@";;
        init)            cmd_init;;
        dashboard)       cmd_dashboard "$@";;
        mq)              cmd_mq "$@";;
        export-metrics)  cmd_export_metrics "$@";;
        events)          cmd_events "$@";;
        help|-h|--help)  cmd_help;;
        *)
            log_error "Unknown command: $cmd"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"

