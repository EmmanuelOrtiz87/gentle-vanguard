#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NEW_PROJECT_SCRIPT="$SCRIPT_DIR/new-project.ps1"

if command -v pwsh >/dev/null 2>&1; then
exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$NEW_PROJECT_SCRIPT" "$@"
fi

if command -v powershell.exe >/dev/null 2>&1; then
  exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$NEW_PROJECT_SCRIPT" "$@"
fi

printf '%s\n' "PowerShell is required to create a new project."
exit 1
