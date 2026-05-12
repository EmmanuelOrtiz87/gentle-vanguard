---
name: script-runtime-engineering-skill
description: >
  Runtime-safe patterns for Bash and PowerShell scripts: quoting, escaping, cross-platform
  execution, parser checks, and smoke validation. Trigger: "bash script", "shell script",
  "powershell script", "hook", "script parse error", "cross-platform script", "wf script".
license: Apache-2.0
metadata:
  author: foundation
  versión: '1.0'
---

## When to Use

Use this skill when:

1. Creating or editing `.sh` or `.ps1` scripts.
2. Building wrappers that route between Bash and PowerShell.
3. Fixing parser/runtime errors caused by quoting, escaping, or encoding.
4. Updating git hooks (`pre-commit`, `post-checkout`, and similar automation scripts).
5. Validating script behavior across Windows, Linux, macOS, WSL, or mixed shells.

## Critical Patterns

1. Keep script files ASCII-safe by default.
2. Prefer direct script invocation over shell relaunching where possible.
3. Never hardcode host-specific command names when a portable alias exists.
4. Avoid reserved/automatic PowerShell variable names for local assignments.
5. Make non-critical checks warn instead of hard-failing startup workflows.

## PowerShell Rules

1. Use stable quoting:

- Single quotes for literals.
- Double quotes only when interpolation is required.

2. Avoid parser-fragile string templates:

- Build command strings with `-f` formatting or explicit concatenation.
- Use `${var}` delimiters when variable boundaries can be ambiguous.

3. Prefer helper invocation wrappers:

- Example: `Invoke-LocalPowerShellScript -ScriptPath <path> -ScriptArgs @(...)`
- This avoids hardcoding `powershell.exe` relaunches.

4. Validate script syntax after edits:

```powershell
$null = $tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  '.\scripts\utilities\example.ps1',
  [ref]$tokens,
  [ref]$errors
) | Out-Null
$errors
```

5. For PowerShell 5.1 compatibility:

- Avoid modern-only constructs.
- Keep messages and separators ASCII when possible.

## Bash Rules

1. Start scripts with:

```bash
#!/usr/bin/env sh
set -eu
```

or for bash-specific logic:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

2. Quote variable expansions unless intentionally word-splitting.
3. Use `command -v <tool>` for capability detection.
4. Keep wrappers small and deterministic:

- Resolve script path.
- Try preferred runtime.
- Fallback once.
- Emit clear error and exit non-zero.

## Cross-Shell Wrapper Pattern

Use this routing order in `.sh` wrappers that invoke `.ps1` scripts:

1. `pwsh`
2. `powershell`
3. fail with actionable message

```sh
if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT" "$@"
fi

printf '%s\n' "PowerShell is required to run this workflow."
exit 1
```

## Validation Matrix

After script changes, run this minimum validation:

1. Parser validation

- PowerShell parser check for every edited `.ps1`.

2. Direct execution

- Execute edited script with safe arguments.

3. Workflow smoke tests

- If hooks were touched: run `hooks/pre-commit.ps1` and `hooks/post-checkout.ps1`.
- If activation scripts were touched: run `scripts/utilities/wf.ps1 health`.

4. Output contract checks

- Ensure `-Quiet` mode is still quiet.
- Ensure JSON mode remains parseable when applicable.

## Done Criteria

A script change is done only when:

1. Parser checks are clean.
2. Runtime smoke tests pass.
3. No new hardcoded platform-only paths were introduced.
4. Docs/help text was updated when behavior changed.
5. `git diff --stat` and `git status` are reviewed before commit.

## Commands

```powershell
# Parse check for edited .ps1 file
$null = $tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile('.\path\file.ps1',[ref]$tokens,[ref]$errors) | Out-Null
if ($errors.Count -eq 0) { 'PARSE_OK' } else { $errors }

# Canonical workflow health check
.\scripts\utilities\wf.ps1 health

# Hook smoke checks
.\hooks\pre-commit.ps1
.\hooks\post-checkout.ps1
```
