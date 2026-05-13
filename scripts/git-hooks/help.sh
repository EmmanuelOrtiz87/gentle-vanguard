#!/usr/bin/env sh
set -eu

cat <<'EOF'
Foundation

Quick start:
  scripts/init-workspace.sh
  scripts/validate-workspace.sh
  scripts/new-project.sh -Name <project> -Kind service|cli|library
  scripts/new-project.sh -Name <project> -Preset dashboard -Architecture clean -Profile web
  scripts/new-project.sh -Name <project> -AiModelMode none|local|cloud -AiModelProvider <provider> -AiModelName <model> -AiModelEndpoint <endpoint>
  scripts/new-project.sh -Name <project> -AiModelNotes <notes>
  scripts/run-engram.sh
  scripts/clean-runtime.sh
  scripts/install-workspace-skills.sh

Project kinds:
  service   backend apps, APIs, workers, dashboards
  cli       command line tools and automation entrypoints
  library   reusable packages and SDK-style codebases

Scaffold defaults:
  Defaults are safe. Use parameters only when the structure is already known.
  If you are unsure, keep defaults and resolve the details with the user or AI helper.
  Project context is written to docs/project-context.md and records architecture plus AI choices.

Workspace config:
  config/workspace.config.json
  config/workspace.portable.example.json

Tools are external and not vendored.
The workspace skills are shipped inside the kit and installed separately into Codex.
Use docs/installation.md for the full step-by-step guide.
EOF
