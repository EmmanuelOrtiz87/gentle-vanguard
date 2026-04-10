#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VALIDATE_SCRIPT="$SCRIPT_DIR/validate-workspace.ps1"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$VALIDATE_SCRIPT" "$@"
fi

if command -v powershell.exe >/dev/null 2>&1; then
  exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$VALIDATE_SCRIPT" "$@"
fi

printf '%s\n' "PowerShell is required to validate the workspace."
exit 1
