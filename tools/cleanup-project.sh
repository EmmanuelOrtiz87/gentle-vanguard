#!/bin/bash

################################################################################
# Project Cleanup - Removes temporary files and optimizes project structure
################################################################################

set -e

CLEANUP_VERSION="1.0.0"
MODE="${1:-safe}"
PROJECT_ROOT="${2:-.}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    local level="$1"
    local message="$2"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] [$level] $message"
}

get_cleanup_targets() {
    log "INFO" "Scanning for cleanup targets..."
    
    local temp_count=0
    local log_count=0
    local cache_count=0
    
    # Count temporary files
    temp_count=$(find "$PROJECT_ROOT" -type f \( -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" \) 2>/dev/null | wc -l)
    
    # Count log files (except in docs/judgment)
    log_count=$(find "$PROJECT_ROOT" -type f -name "*.log" ! -path "*/docs/judgment/*" 2>/dev/null | wc -l)
    
    # Count cache directories
    cache_count=$(find "$PROJECT_ROOT" -type d -name "*cache*" 2>/dev/null | wc -l)
    
    log "INFO" "Found: $temp_count temp, $log_count logs, $cache_count caches"
}

show_cleanup_plan() {
    log "INFO" "=== CLEANUP PLAN ==="
    
    # Show temporary files
    local temp_files=$(find "$PROJECT_ROOT" -type f \( -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" \) 2>/dev/null)
    if [ -n "$temp_files" ]; then
        log "INFO" "Temporary Files:"
        echo "$temp_files" | while read file; do
            log "DEBUG" "  - $file"
        done
    fi
    
    # Show log files
    local log_files=$(find "$PROJECT_ROOT" -type f -name "*.log" ! -path "*/docs/judgment/*" 2>/dev/null)
    if [ -n "$log_files" ]; then
        log "INFO" "Log Files:"
        echo "$log_files" | while read file; do
            log "DEBUG" "  - $file"
        done
    fi
    
    # Show cache directories
    local cache_dirs=$(find "$PROJECT_ROOT" -type d -name "*cache*" 2>/dev/null)
    if [ -n "$cache_dirs" ]; then
        log "INFO" "Cache Directories:"
        echo "$cache_dirs" | while read dir; do
            log "DEBUG" "  - $dir"
        done
    fi
}

execute_cleanup() {
    local cleaned=0
    
    if [ "$MODE" = "dry-run" ]; then
        log "WARN" "DRY-RUN MODE: No files will be deleted"
        show_cleanup_plan
        return 0
    fi
    
    # Clean temporary files
    find "$PROJECT_ROOT" -type f \( -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" \) -delete 2>/dev/null
    cleaned=$((cleaned + 1))
    log "INFO" "Deleted temporary files"
    
    # Clean log files (only if full mode)
    if [ "$MODE" = "full" ]; then
        find "$PROJECT_ROOT" -type f -name "*.log" ! -path "*/docs/judgment/*" -delete 2>/dev/null
        cleaned=$((cleaned + 1))
        log "INFO" "Deleted log files"
    fi
    
    # Clean cache directories
    find "$PROJECT_ROOT" -type d -name "*cache*" -exec rm -rf {} + 2>/dev/null
    cleaned=$((cleaned + 1))
    log "INFO" "Deleted cache directories"
    
    return $cleaned
}

verify_project_integrity() {
    log "INFO" "Verifying project integrity..."
    
    local required_dirs=("config" "tools" "docs" "skills" "demos")
    local required_files=("AGENTS.md" "README.md")
    
    local all_good=true
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            log "ERROR" "Missing directory: $dir"
            all_good=false
        fi
    done
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            log "ERROR" "Missing file: $file"
            all_good=false
        fi
    done
    
    if [ "$all_good" = true ]; then
        log "INFO" "Project integrity verified"
        return 0
    else
        log "ERROR" "Project integrity check failed"
        return 1
    fi
}

main() {
    log "INFO" "Project Cleanup v$CLEANUP_VERSION"
    log "INFO" "Mode: $MODE"
    
    # Get cleanup targets
    get_cleanup_targets
    
    # Show plan
    show_cleanup_plan
    
    # Execute cleanup
    execute_cleanup
    local cleaned=$?
    
    log "INFO" "Cleanup completed: $cleaned items processed"
    
    # Verify integrity
    verify_project_integrity
    
    if [ $? -eq 0 ]; then
        log "INFO" "✓ Project is clean and ready"
        return 0
    else
        log "ERROR" "✗ Project integrity issues detected"
        return 1
    fi
}

main