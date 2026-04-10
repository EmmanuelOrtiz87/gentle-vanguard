#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BOOTSTRAP="$SCRIPT_DIR/bootstrap-workspace.ps1"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$BOOTSTRAP" "$@"
fi

printf '%s\n' "pwsh is required to run this bootstrap. Install PowerShell 7 first."
exit 1
