## Validation Matrix

After script changes, run this minimum validation:

1. Parser validation

- PowerShell parser check for every edited `.ps1`.

2. Direct execution

- Execute edited script with safe arguments.

3. Workflow smoke tests

- If hooks were touched: run `hooks/pre-commit.ps1` and `hooks/post-checkout.ps1`.
- If activation scripts were touched: run `scripts/utilities/gv.ps1 health`.

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
.\scripts\utilities\gv.ps1 health

# Hook smoke checks
.\hooks\pre-commit.ps1
.\hooks\post-checkout.ps1
```