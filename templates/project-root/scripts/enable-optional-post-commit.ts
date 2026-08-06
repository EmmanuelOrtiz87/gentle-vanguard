#!/usr/bin/env node

/**
 * enable-optional-post-commit.ts — Git post-commit hook management for template projects
 *
 * Enables/disables an optional post-commit hook that saves commit info to Engram
 * and optionally generates session reviews.
 *
 * Usage:
 *   npx tsx templates/project-root/scripts/enable-optional-post-commit.ts
 *   npx tsx templates/project-root/scripts/enable-optional-post-commit.ts --disable
 *   npx tsx templates/project-root/scripts/enable-optional-post-commit.ts --force
 */

import { existsSync, mkdirSync, rmSync, writeFileSync } from 'fs';
import { join, resolve } from 'path';
import { execSync } from 'child_process';

const REPO_ROOT = resolve(join(__dirname, '..'));

const args = process.argv.slice(2);
const disable = args.includes('--disable') || args.includes('-Disable');
const force = args.includes('--force') || args.includes('-Force');

function step(msg: string): void {
  console.log(`\n=== ${msg} ===`);
}
function ok(msg: string): void {
  console.log(`[OK] ${msg}`);
}
function warn(msg: string): void {
  console.log(`[WARN] ${msg}`);
}

const configDir = join(REPO_ROOT, '.config');
const hooksDir = join(REPO_ROOT, '.githooks');
const scriptsProjectDir = join(REPO_ROOT, 'scripts', 'project');
const markerFile = join(configDir, 'optional-post-commit.enabled');
const hookFile = join(hooksDir, 'post-commit');
const postCommitScript = join(scriptsProjectDir, 'project-post-commit.ps1');

const postCommitContent = `$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..\\..")
Set-Location $projectRoot

$markerPath = Join-Path $projectRoot '.config/optional-post-commit.enabled'
if (-not (Test-Path $markerPath)) {
    exit 0
}

$powershell = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $powershell) {
    $powershell = Get-Command powershell -ErrorAction SilentlyContinue
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    exit 0
}

if (-not (Get-Command engram -ErrorAction SilentlyContinue)) {
    Write-Host '[WARN] engram not found; skipping post-commit memory sync.' -ForegroundColor Yellow
    exit 0
}

$commitHash = git rev-parse --short HEAD 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commitHash)) {
    exit 0
}

$projectName = Split-Path $projectRoot -Leaf
$commitMessage = git log -1 --pretty=%B HEAD
$changedFiles = git diff-tree --no-commit-id --name-only -r HEAD | Out-String
$title = "Auto-save commit $commitHash"
$body = @"
Commit message:
$commitMessage

Changed files:
$changedFiles
"@

try {
    & engram save "$title" "$body" --type decision --project $projectName --scope project --topic "commit/$commitHash"
} catch {
    Write-Host "[WARN] failed to save commit memory: $_" -ForegroundColor Yellow
}

$reviewScript = Join-Path $projectRoot 'scripts\\utilities\\generate-session-review.ps1'
if ($env:AUTO_SESSION_REVIEW_ON_COMMIT -eq '1' -and (Test-Path $reviewScript)) {
    try {
        if ($powershell) {
            & $powershell.Source -NoProfile -ExecutionPolicy Bypass -File $reviewScript
        } else {
            & $reviewScript
        }
    } catch {
        Write-Host "[WARN] failed to generate session review: $_" -ForegroundColor Yellow
    }
}
`;

const hookContent = `#!/bin/sh
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
HOOK_SCRIPT="$REPO_ROOT/scripts/project/project-post-commit.ps1"
MARKER_FILE="$REPO_ROOT/.config/optional-post-commit.enabled"

if [ -z "$REPO_ROOT" ] || [ ! -f "$HOOK_SCRIPT" ]; then
  exit 0
fi

if [ ! -f "$MARKER_FILE" ]; then
  exit 0
fi

if command -v pwsh >/dev/null 2>&1; then
  OUTPUT="$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOOK_SCRIPT" 2>&1)"
  EXIT_CODE=$?
elif command -v powershell >/dev/null 2>&1; then
    OUTPUT="$(powershell -NoProfile -ExecutionPolicy Bypass -File "$HOOK_SCRIPT" 2>&1)"
  EXIT_CODE=$?
else
  printf '%s\n' "PowerShell not found for post-commit hook." >&2
  exit 1
fi

printf '%s\n' "$OUTPUT" | while IFS= read -r line; do
  case "$line" in
    "declare -x "*) ;;
    *) printf '%s\n' "$line" ;;
  esac
done

exit $EXIT_CODE
`;

if (disable) {
  step('Disabling optional post-commit automation');
  if (existsSync(markerFile)) {
    rmSync(markerFile, { force: true });
    ok('Disabled marker removed.');
  } else {
    warn('Optional post-commit marker was already absent.');
  }
  console.log(
    'To re-enable, run: npx tsx templates/project-root/scripts/enable-optional-post-commit.ts',
  );
  process.exit(0);
}

step('Enabling optional post-commit automation');
if (!existsSync(configDir)) mkdirSync(configDir, { recursive: true });
if (!existsSync(hooksDir)) mkdirSync(hooksDir, { recursive: true });
if (!existsSync(scriptsProjectDir)) mkdirSync(scriptsProjectDir, { recursive: true });

if (existsSync(postCommitScript) && !force) {
  warn(
    'project-post-commit.ps1 already exists; preserving current file (use --force to overwrite).',
  );
} else {
  writeFileSync(postCommitScript, postCommitContent, 'utf-8');
  ok('Created scripts/project/project-post-commit.ps1');
}

if (existsSync(hookFile) && !force) {
  warn('.githooks/post-commit already exists; preserving current file (use --force to overwrite).');
} else {
  writeFileSync(hookFile, hookContent, 'utf-8');
  try {
    execSync(`git update-index --chmod=+x "${hookFile}"`, { stdio: 'pipe', timeout: 5000 });
  } catch {
    warn('Could not set executable bit on post-commit hook (safe to ignore on Windows).');
  }
  ok('Created .githooks/post-commit');
}

writeFileSync(markerFile, 'enabled=true\n', 'utf-8');
ok('Enabled marker created: .config/optional-post-commit.enabled');

try {
  execSync('git config core.hooksPath .githooks', { stdio: 'pipe', timeout: 5000 });
  ok('Configured git hooks path: .githooks');
} catch {
  warn('Could not set git hooks path.');
}

console.log('Optional post-commit automation is now enabled.');
console.log(
  'Disable anytime with: npx tsx templates/project-root/scripts/enable-optional-post-commit.ts --disable',
);
