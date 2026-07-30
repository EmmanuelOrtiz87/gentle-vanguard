---
name: validate-stack
description: Validate the full Gentle-Vanguard stack. Run verification steps for pre-process-input, session pipeline, hooks, and tool detection.
triggers:
  - validate
  - stack verify
  - verify stack
  - check stack
  - validation
---

# Validate Stack

Run these verifications in order after any fix to session, hashline, or pre-process-input files.
Report the result of each step. Fail on first error — do not continue.

## 1. Parse validation

```
pwsh -NoProfile -File scripts/editing/hashline.ps1 -Action status
```

Expected output: database path, file count, line count. No error messages.

## 2. Pre-process-input: "inicia sesion" triggers SESSION

```
pwsh -NoProfile -File scripts/utilities/pre-process-input.ps1 -UserInput "inicia sesion"
```

Expected output: `HasMatch=True`, `AgentCode=SESSION`, `Skill=session-workflow-skill`,
`PlanMode=False`

## 3. All 5 hashline actions

```
pwsh -NoProfile -Command "& 'scripts/editing/hashline.ps1' -Action status 2>&1"
pwsh -NoProfile -Command "& 'scripts/editing/hashline.ps1' -Action init -Path scripts/editing/hashline.ps1 -Quiet 2>&1"
pwsh -NoProfile -Command "& 'scripts/editing/hashline.ps1' -Action update -Path scripts/editing/hashline.ps1 -Quiet 2>&1"
pwsh -NoProfile -Command "& 'scripts/editing/hashline.ps1' -Action verify -Path scripts/editing/hashline.ps1 2>&1"
pwsh -NoProfile -Command "& 'scripts/editing/hashline.ps1' -Action prune -Quiet 2>&1"
```

Expected: status shows db data; init/update/prune silent (Quiet); verify shows `[HASHLINE] OK`.

## 4. Session autostart: no Wait-Job warning

```
pwsh -NoProfile -File scripts/utilities/session/session-start-optimized.ps1 2>&1 | Select-String -Pattern 'WARN|error|Error|ERROR|warning'
```

Expected output: empty (no matches).

## 5. Parse hashline.ps1 for syntax errors

```
pwsh -NoProfile -Command "$errors = $null; $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content scripts/editing/hashline.ps1 -Raw), [ref]$null, [ref]$errors); if ($errors) { Write-Host 'PARSE ERRORS:' $errors.Count; $errors | ForEach-Object { Write-Host ('Line {0}: {1}' -f $_.Extent.StartLineNumber, $_.Message) } } else { Write-Host 'PARSE OK: 0 errors' }"
```

Expected: `PARSE OK: 0 errors`

## 6. Working tree status

```
git status --short
```

Expected: clean (no output), or only expected staged/unstaged files matching the current task.