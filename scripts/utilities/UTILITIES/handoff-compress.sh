#!/usr/bin/env bash
# handoff-compress.sh - Unix wrapper for handoff compression

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
    echo "Usage: $0 '<context>'"
    exit 1
fi

INPUT="$1"
pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/handoff-compress.ps1" -Input "$INPUT"