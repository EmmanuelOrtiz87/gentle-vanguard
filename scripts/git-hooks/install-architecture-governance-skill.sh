#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SKILL_NAME="architecture-governance"
SOURCE_DIR="$ROOT_DIR/skills/$SKILL_NAME"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR="$CODEX_HOME_DIR/skills/$SKILL_NAME"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Skill source not found: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$(dirname -- "$DEST_DIR")"
rm -rf "$DEST_DIR"
cp -R "$SOURCE_DIR" "$DEST_DIR"

echo "Installed $SKILL_NAME to $DEST_DIR"
echo "Restart Codex to pick up the new skill."
