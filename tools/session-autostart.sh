#!/bin/bash
# Session Autostart Script for Linux/macOS/WSL
# Starts engram server for workspace-foundation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/session-autostart.config.json"
ENGAM_EXE="$SCRIPT_DIR/engram.exe"

# Check if engram exists
if [ ! -f "$ENGAM_EXE" ]; then
    echo "[WARNING] engram.exe not found at $ENGAM_EXE"
    exit 0
fi

# Check if engram server is already running
if netstat -ano 2>/dev/null | grep -q ":7437"; then
    echo "[INFO] Engram server already running on port 7437"
    exit 0
fi

# Start engram server in background
echo "[INFO] Starting engram server..."
nohup "$ENGAM_EXE" serve > /dev/null 2>&1 &

echo "[INFO] Engram server started"
