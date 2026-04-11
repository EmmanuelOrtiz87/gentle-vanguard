#!/usr/bin/env bash
# setup.sh - Universal Gentleman Foundation Stack Setup
# Works on: Linux, macOS, Windows (WSL, Git Bash, MSYS2)
# No dependencies except bash, git, and go

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        MINGW*|MSYS*|CYGWIN*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Detect shell
detect_shell() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        echo "zsh"
    elif [ -n "${BASH_VERSION:-}" ]; then
        echo "bash"
    elif [ -n "${KSH_VERSION:-}" ]; then
        echo "ksh"
    elif [ -n "${FCEDIT:-}" ]; then
        echo "ksh"
    else
        echo "sh"
    fi
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
OS=$(detect_os)
SHELL_NAME=$(detect_shell)

log_info "═════════════════════════════════════════════════════════"
log_info "    Gentleman Foundation - Universal Stack Setup"
log_info "═════════════════════════════════════════════════════════"
log_info "OS: $OS"
log_info "Shell: $SHELL_NAME"
log_info "Root: $PROJECT_ROOT"
log_info ""

# Check critical dependencies
check_dependencies() {
    log_info "Checking critical dependencies..."
    
    local missing=0
    
    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git not found. Install from https://git-scm.com/"
        missing=$((missing + 1))
    else
        log_success "Git: $(git --version)"
    fi
    
    # Check Go
    if ! command -v go &> /dev/null; then
        log_error "Go not found. Install from https://go.dev/"
        missing=$((missing + 1))
    else
        log_success "Go: $(go version)"
    fi
    
    # Check Bash (for scripts)
    if ! command -v bash &> /dev/null; then
        log_warn "Bash not found (current shell: $SHELL_NAME). Some scripts may not work."
    else
        log_success "Bash: $(bash --version | head -n 1)"
    fi
    
    if [ $missing -gt 0 ]; then
        log_error "$missing critical dependencies missing!"
        return 1
    fi
    
    return 0
}

# Detect project type
detect_project_type() {
    if [ -f "$PROJECT_ROOT/go.mod" ] && [ -f "$PROJECT_ROOT/angular.json" ]; then
        echo "bitbucket-dashboard"
    elif [ -f "$PROJECT_ROOT/scripts/foundation/bootstrap.ps1" ]; then
        echo "workspace-foundation"
    else
        echo "unknown"
    fi
}

# Initialize workspace config
init_config() {
    log_info "Initializing workspace configuration..."
    
    local config_dir="$PROJECT_ROOT/config"
    local config_file="$config_dir/workspace.config.json"
    
    mkdir -p "$config_dir"
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
{
  "workspaceRoot": "{workspaceRoot}",
  "dataRoot": "{dataRoot}",
  "toolsRoot": "{toolsRoot}",
  "projectsRoot": "{projectsRoot}",
  "aiModelSettings": {
    "provider": "generic",
    "model": "default",
    "protocol": "mcp"
  },
  "environment": {
    "OS": "{OS}",
    "shell": "{SHELL}"
  }
}
EOF
        
        # Simple templating (bash-compatible)
        sed -i "s|{workspaceRoot}|$PROJECT_ROOT|g" "$config_file" 2>/dev/null || \
            sed -i "" "s|{workspaceRoot}|$PROJECT_ROOT|g" "$config_file"
        sed -i "s|{dataRoot}|$PROJECT_ROOT/.engram-data|g" "$config_file" 2>/dev/null || \
            sed -i "" "s|{dataRoot}|$PROJECT_ROOT/.engram-data|g" "$config_file"
        sed -i "s|{toolsRoot}|$PROJECT_ROOT/tools|g" "$config_file" 2>/dev/null || \
            sed -i "" "s|{toolsRoot}|$PROJECT_ROOT/tools|g" "$config_file"
        sed -i "s|{projectsRoot}|$PROJECT_ROOT/projects|g" "$config_file" 2>/dev/null || \
            sed -i "" "s|{projectsRoot}|$PROJECT_ROOT/projects|g" "$config_file"
        sed -i "s|{OS}|$OS|g" "$config_file" 2>/dev/null || \
            sed -i "" "s|{OS}|$OS|g" "$config_file"
        sed -i "s|{SHELL}|$SHELL_NAME|g" "$config_file" 2>/dev/null || \
            sed -i "" "s|{SHELL}|$SHELL_NAME|g" "$config_file"
        
        log_success "Config created: $config_file"
    else
        log_success "Config already exists: $config_file"
    fi
}

# Install Engram CLI
install_engram() {
    log_info "Checking Engram CLI..."
    
    if command -v engram &> /dev/null; then
        log_success "Engram CLI already installed"
        return 0
    fi
    
    log_warn "Engram CLI not found. Installing..."
    if go install github.com/Gentleman-Programming/engram/cmd/engram@latest; then
        log_success "Engram CLI installed successfully"
        return 0
    else
        log_error "Failed to install Engram CLI"
        return 1
    fi
}

# Initialize data directories
init_directories() {
    log_info "Initializing data directories..."
    
    mkdir -p "$PROJECT_ROOT/.engram-data"
    mkdir -p "$PROJECT_ROOT/tools"
    mkdir -p "$PROJECT_ROOT/projects"
    mkdir -p "$PROJECT_ROOT/config"
    
    log_success "Data directories ready"
}

# Configure Git hooks
configure_git_hooks() {
    log_info "Configuring Git hooks..."
    
    if [ -d "$PROJECT_ROOT/.git" ]; then
        if [ -d "$PROJECT_ROOT/hooks" ]; then
            git -C "$PROJECT_ROOT" config core.hooksPath hooks
            log_success "Git hooks configured"
        else
            log_warn "Hooks directory not found, skipping git hook configuration"
        fi
    else
        log_info "Not a Git repository, skipping hook configuration"
    fi
}

# Create universal shell wrapper
create_shell_wrapper() {
    log_info "Creating universal shell wrappers..."
    
    # Create wf wrapper that works with any shell
    local wf_wrapper="$PROJECT_ROOT/wf"
    
    cat > "$wf_wrapper" << 'EOF'
#!/usr/bin/env bash
# Universal Gentleman Foundation Workflow CLI
# Detects available shell and routes to appropriate implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Detect what we're running with
if command -v powershell &> /dev/null && [ -f "$PROJECT_ROOT/scripts/utilities/wf.ps1" ]; then
    # Try PowerShell if available
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PROJECT_ROOT/scripts/utilities/wf.ps1" "$@"
elif [ -f "$PROJECT_ROOT/scripts/utilities/wf.sh" ]; then
    # Fall back to bash version
    bash "$PROJECT_ROOT/scripts/utilities/wf.sh" "$@"
else
    echo "Error: Neither PowerShell nor bash workflow CLI found"
    exit 1
fi
EOF
    
    chmod +x "$wf_wrapper"
    log_success "Shell wrapper created at $wf_wrapper"
}

# Orchestrator integration
orchestrator_notify() {
    local action="$1"
    local status="$2"
    
    # If engram is available, notify orchestrator
    if command -v engram &> /dev/null; then
        export ENGRAM_DATA_DIR="$PROJECT_ROOT/.engram-data"
        # Try to notify orchestrator session
        engram note "setup: $action - $status" 2>/dev/null || true
    fi
}

# Main setup flow
main() {
    log_info ""
    
    # Notify orchestrator: setup started
    orchestrator_notify "setup" "started"
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Setup cannot continue without critical dependencies"
        orchestrator_notify "setup" "failed - missing dependencies"
        exit 1
    fi
    
    log_info ""
    
    # Initialize directories
    init_directories
    
    # Initialize config
    init_config
    
    # Configure Git
    configure_git_hooks
    
    # Install optional dependencies
    if [ "$OS" != "windows" ] || command -v bash &> /dev/null; then
        install_engram || true
    fi
    
    # Create wrappers
    create_shell_wrapper
    
    # Notify orchestrator: setup completed
    orchestrator_notify "setup" "completed"
    
    log_info ""
    log_success "═════════════════════════════════════════════════════════"
    log_success "    Stack Setup Complete!"
    log_success "═════════════════════════════════════════════════════════"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Run: ./wf status"
    log_info "  2. Run: ./wf health"
    log_info "  3. Start coding!"
    log_info ""
    log_info "Type: $(detect_project_type)"
    log_info "OS: $OS"
    log_info "Shell: $SHELL_NAME"
    log_info ""
}

# Run main
main "$@"
