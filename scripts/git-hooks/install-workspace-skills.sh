#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DOCS_SCRIPT="$ROOT_DIR/scripts/install-documentation-governance-skill.sh"
ARCH_SCRIPT="$ROOT_DIR/scripts/install-architecture-governance-skill.sh"

if [ ! -x "$DOCS_SCRIPT" ]; then
  echo "Missing installer: $DOCS_SCRIPT" >&2
  exit 1
fi
if [ ! -x "$ARCH_SCRIPT" ]; then
  echo "Missing installer: $ARCH_SCRIPT" >&2
  exit 1
fi

"$DOCS_SCRIPT"
"$ARCH_SCRIPT"

echo "Installed workspace skills. Restart Codex to pick up the new skills."
