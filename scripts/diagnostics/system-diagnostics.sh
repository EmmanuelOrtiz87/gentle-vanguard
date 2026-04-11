#!/usr/bin/env bash
# system-diagnostics.sh - Universal system diagnostics
# Works on: Linux, macOS, Windows (WSL, Git Bash)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_check() {
    echo -ne "${CYAN}[CHECK]${NC} $1"
}

log_ok() {
    echo -e " ${GREEN}✓${NC}"
}

log_missing() {
    echo -e " ${RED}✗${NC}"
}

log_warn() {
    echo -e " ${YELLOW}⚠${NC}"
}

# Get config value from JSON (simple grep-based parser)
get_config_value() {
    local file="$1"
    local key="$2"
    grep "\"$key\"" "$file" | head -n 1 | sed 's/.*: "\(.*\)".*/\1/'
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        *)          echo "unknown";;
    esac
}

# Main diagnostics
main() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/../.." && pwd)"
    
    echo ""
    echo "═════════════════════════════════════════════════════════"
    echo "         System Diagnostics & Health Check"
    echo "═════════════════════════════════════════════════════════"
    echo ""
    
    local status=0
    
    # Check Go
    log_check "Go compiler"
    if command -v go &> /dev/null; then
        go_version=$(go version | awk '{print $3}')
        echo " $go_version"
        log_ok
    else
        log_missing
        status=$((status + 1))
    fi
    
    # Check Git
    log_check "Git"
    if command -v git &> /dev/null; then
        git_version=$(git --version | awk '{print $3}')
        echo " $git_version"
        log_ok
    else
        log_missing
        status=$((status + 1))
    fi
    
    # Check Engram CLI
    log_check "Engram CLI"
    if command -v engram &> /dev/null; then
        engram_version=$(engram version 2>/dev/null || echo "unknown")
        echo " $engram_version"
        log_ok
    else
        log_missing
    fi
    
    # Check Engram data directory
    local engram_data="${ENGRAM_DATA_DIR:-$project_root/.engram-data}"
    log_check "Engram data directory"
    if [ -d "$engram_data" ]; then
        local size=$(du -sh "$engram_data" 2>/dev/null | awk '{print $1}' || echo "N/A")
        echo " ($size)"
        log_ok
    else
        log_warn
    fi
    
    # Check Node.js/npm (for dashboard projects)
    if grep -q "angular.json" "$project_root" 2>/dev/null || [ -f "$project_root/package.json" ]; then
        log_check "Node.js/npm"
        if command -v node &> /dev/null; then
            node_version=$(node --version)
            echo " $node_version"
            log_ok
        else
            log_missing
            status=$((status + 1))
        fi
    fi
    
    # Check workspace config
    log_check "Workspace configuration"
    if [ -f "$project_root/config/workspace.config.json" ]; then
        echo ""
        log_ok
    else
        echo ""
        log_warn
    fi
    
    # Check orchestrator state
    log_check "Orchestrator state"
    if [ -f "$project_root/config/orchestrator.json" ]; then
        local active=$(grep -o '"active": [^,}]*' "$project_root/config/orchestrator.json" | cut -d' ' -f2)
        echo " (active=$active)"
        log_ok
    else
        echo ""
        log_warn
    fi
    
    # Check skills directory
    log_check "Skills directory"
    if [ -d "$project_root/skills" ]; then
        local skill_count=$(find "$project_root/skills" -maxdepth 1 -type d | wc -l)
        echo " ($((skill_count - 1)) skills)"
        log_ok
    else
        echo ""
        log_warn
    fi
    
    echo ""
    echo "═════════════════════════════════════════════════════════"
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}All critical systems operational${NC}"
    else
        echo -e "${YELLOW}$status issues detected${NC}"
    fi
    
    echo ""
    
    return $status
}

main "$@"
