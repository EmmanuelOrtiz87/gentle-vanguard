# PowerShell Coding Standards

**Version:** 1.0.0  
**Last reviewed:** 2026-05-05  
**Enforced by:** `.github/workflows/ps-lint.yml` (PSScriptAnalyzer) + pre-commit hook

---

## 1. Overview

All `.ps1` files in this repository MUST pass PSScriptAnalyzer with **zero errors**.  
Warnings are annotated in PRs but do not block merge (unless promoted by team policy).

---

## 2. File Header Convention

Every script MUST begin with a documentation block:

```powershell
# script-name.ps1
# PURPOSE: One-sentence description of what this script does.
# USAGE: pwsh -File scripts/path/script-name.ps1 [-Param value]
# CALLED BY: gv command, hook name, or CI step name
```

---

## 3. Parameter Declarations

```powershell
# REQUIRED — always use param() block with types
param(
    [string]$Input,           # string params: always typed
    [switch]$Verbose,         # flags: use [switch] not [bool]
    [ValidateSet('a','b')]    # enums: use ValidateSet
    [string]$Mode = 'a'       # defaults: in param block, not body
)
```

Rules:

- **No positional parameters without explicit `[Parameter(Position=N)]`** in public-facing scripts.
- **No `$args`** — always use named params.
- Mandatory params use `[Parameter(Mandatory)]`, NOT validation in the body.

---

## 4. Error Handling

```powershell
$ErrorActionPreference = 'Continue'   # DEFAULT for scripts (not Stop — don't hide errors)

# For critical operations:
try {
    $result = Some-Operation -ErrorAction Stop
} catch {
    Write-Error "Operation failed: $_"
    exit 1
}
```

Rules:

- **Never use `$ErrorActionPreference = 'SilentlyContinue'`** at script scope.
- **Always check `$LASTEXITCODE`** after calling external executables.
- **Always `exit 1`** (not `throw`) when a script encounters a fatal condition; hooks and CI read
  exit codes.

---

## 5. Output

```powershell
# Preferred: use Write-Host for user-facing output (hooks, CLI, gv commands)
Write-Host "[OK] Done" -ForegroundColor Green

# For hook output: ALWAYS use Write-SafeHook (redacts secrets)
if (Get-Command Write-SafeHook -EA SilentlyContinue) {
    Write-SafeHook "message" -Color Green
} else {
    Write-Host "message" -ForegroundColor Green
}

# Machine-readable output: ConvertTo-Json or structured objects via pipeline
$result | ConvertTo-Json -Depth 5
```

Rules:

- **No `Write-Host` of environment variables, tokens, or API keys** — ever.
- **No `echo`** — use `Write-Host` or `Write-Output`.
- **No `Write-Verbose`** unless the script accepts a `-Verbose` switch.

---

## 6. Path Handling

```powershell
# CORRECT: use Join-Path, never string concatenation
$path = Join-Path $repoRoot 'scripts\utilities\gv.ps1'

# CORRECT: always resolve repo root from script location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..\..\..')).Path

# WRONG:
$path = "$repoRoot/scripts/utilities/gv.ps1"   # uses / which may fail on Windows
$path = "C:\hardcoded\path"                     # never hardcode absolute paths
```

---

## 7. Security Rules

| Rule                                                                       | Rationale           |
| -------------------------------------------------------------------------- | ------------------- |
| Never call `Invoke-Expression` on user input                               | Code injection      |
| Never call `[System.Reflection.Assembly]::Load` from user-supplied data    | DLL injection       |
| Always validate file paths before `Test-Path` / `Get-Content`              | Path traversal      |
| Never expand environment variables from external config without sanitizing | Injection           |
| Never store credentials in scripts — use `config/owner-auth.json` workflow | Credential exposure |

PSScriptAnalyzer rules enforced: `PSAvoidUsingInvokeExpression`,
`PSAvoidUsingConvertToSecureStringWithPlainText`.

---

## 8. Naming Conventions

| Element                         | Convention                      | Example                           |
| ------------------------------- | ------------------------------- | --------------------------------- |
| Functions                       | `Verb-Noun` (approved PS verbs) | `Get-PlatformInfo`, `Invoke-Gate` |
| Variables                       | `$camelCase`                    | `$repoRoot`, `$elapsedSec`        |
| Script-level constants          | `$UPPER_CASE`                   | `$MAX_RETRIES`                    |
| Parameters                      | `$PascalCase`                   | `$Mode`, `$TaskType`              |
| Private functions (module-only) | prefix `_`                      | `_WriteHeader`                    |

Use **approved PowerShell verbs** only. Run `Get-Verb` to check.

---

## 9. Compatibility

- **Minimum**: PowerShell 7.2+ (pwsh)
- **No `powershell.exe`** (Windows PowerShell 5.x) — use `pwsh` only.
- **No OS-specific code** without a platform guard:

```powershell
if ($IsWindows) { ... }
elseif ($IsMacOS) { ... }
else { ... }   # Linux
```

---

## 10. Script Size Limits

| Metric                             | Threshold | Action                                 |
| ---------------------------------- | --------- | -------------------------------------- |
| Lines per file                     | ≤ 500     | Refactor into sub-functions or modules |
| Functions per file                 | ≤ 20      | Extract to a dedicated module          |
| Cyclomatic complexity per function | ≤ 10      | Simplify or split                      |

Scripts exceeding these are **advisory** (not blocking) but must be addressed in the same sprint.

---

## 11. PSScriptAnalyzer Configuration

Excluded rules (documented justification required for each exclusion):

| Rule                                   | Reason                                              |
| -------------------------------------- | --------------------------------------------------- |
| `PSAvoidUsingWriteHost`                | Output scripts intentionally write to console       |
| `PSUseDeclaredVarsMoreThanAssignments` | PowerShell scoping produces false positives         |
| `PSAvoidGlobalVars`                    | Framework-level scripts need module-scope variables |
| `PSReviewUnusedParameter`              | Hook and CLI parameters may be optional by design   |

Any new exclusion must be added to **both** the CI workflow and this document with justification.
