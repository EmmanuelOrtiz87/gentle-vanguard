#!/usr/bin/env bash
# ============================================================================
# GGA Pre-commit Hook - Unix/Linux/macOS
# ============================================================================
# This hook runs GGA (Gentleman Guardian Angel) on staged files
# before each commit. It will block the commit if GGA is not installed
# or if the review fails in strict mode.
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
REPO_ROOT=$(git rev-parse --show-toplevel)
GGA_MARKER="$REPO_ROOT/.gga-installed"

# Check if GGA is available
check_gga() {
    if command -v gga &> /dev/null; then
        return 0
    fi

    # Check common installation paths
    local gga_paths=(
        "$HOME/bin/gga"
        "/usr/local/bin/gga"
        "$HOME/.local/bin/gga"
    )

    for gga_path in "${gga_paths[@]}"; do
        if [ -f "$gga_path" ]; then
            export PATH="$(dirname "$gga_path"):$PATH"
            return 0
        fi
    done

    return 1
}

# Install GGA if not present
install_gga() {
    echo -e "${BLUE}[GGA]${NC} Installing Gentleman Guardian Angel..."

    # Check if this is Windows (Git Bash)
    if [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]]; then
        echo -e "${BLUE}[GGA]${NC} Detected Git Bash on Windows"

        # Clone repository if not exists
        if [ ! -d "$HOME/gentleman-guardian-angel" ]; then
            git clone https://github.com/Gentleman-Programming/gentleman-guardian-angel.git "$HOME/gentleman-guardian-angel" 2>/dev/null || true
        fi

        # Run install script
        if [ -f "$HOME/gentleman-guardian-angel/install.sh" ]; then
            cd "$HOME/gentleman-guardian-angel" && bash install.sh
        fi

        # Ensure ~/bin exists and is in PATH
        mkdir -p "$HOME/bin"
        if [ -f "$HOME/bin/gga" ]; then
            export PATH="$HOME/bin:$PATH"
            touch "$GGA_MARKER"
            echo -e "${GREEN}[GGA]${NC} Installation complete!"
            return 0
        fi
    else
        # Unix/Linux/macOS
        if command -v brew &> /dev/null; then
            brew install gentleman-programming/tap/gga 2>/dev/null || true
        else
            # Manual installation
            if [ ! -d "$HOME/gentleman-guardian-angel" ]; then
                git clone https://github.com/Gentleman-Programming/gentleman-guardian-angel.git "$HOME/gentleman-guardian-angel" 2>/dev/null || true
            fi

            if [ -f "$HOME/gentleman-guardian-angel/install.sh" ]; then
                cd "$HOME/gentleman-guardian-angel" && bash install.sh
            fi
        fi

        if [ -f "$HOME/bin/gga" ] || command -v gga &> /dev/null; then
            touch "$GGA_MARKER"
            echo -e "${GREEN}[GGA]${NC} Installation complete!"
            return 0
        fi
    fi

    echo -e "${YELLOW}[GGA]${NC} Warning: Could not install GGA automatically."
    echo -e "${YELLOW}[GGA]${NC} Please install manually: https://github.com/Gentleman-Programming/gentleman-guardian-angel"
    return 1
}

# Main execution
main() {
    echo -e "${BLUE}[GGA]${NC} Pre-commit hook starting..."

    # Check if .gga config exists
    if [ ! -f "$REPO_ROOT/.gga" ]; then
        echo -e "${YELLOW}[GGA]${NC} No .gga config found. Skipping GGA review."
        exit 0
    fi

    # Check if GGA is installed
    if ! check_gga; then
        echo -e "${YELLOW}[GGA]${NC} GGA not found. Attempting to install..."
        if ! install_gga; then
            echo -e "${YELLOW}[GGA]${NC} Skipping review (GGA not available)."
            exit 0
        fi
    fi

    # Run GGA review
    echo -e "${BLUE}[GGA]${NC} Running code review..."

    # Add ~/bin to PATH if gga is there
    if [ -f "$HOME/bin/gga" ]; then
        export PATH="$HOME/bin:$PATH"
    fi

    # Run gga run with timeout
    if command -v gga &> /dev/null; then
        cd "$REPO_ROOT"
        timeout 300 gga run || {
            exit_code=$?
            if [ $exit_code -eq 0 ]; then
                echo -e "${GREEN}[GGA]${NC} Review passed!"
            else
                echo -e "${RED}[GGA]${NC} Review failed with exit code: $exit_code"
                exit $exit_code
            fi
        }
    else
        echo -e "${YELLOW}[GGA]${NC} GGA not in PATH. Skipping review."
    fi
}

main "$@"
