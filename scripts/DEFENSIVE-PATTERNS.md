# Defensive Patterns for PowerShell Scripts

Living reference of established patterns and anti-patterns discovered and fixed
during the gentle-vanguard audit.

## RepoRoot Resolution

### Standard Pattern (Preferred)

```powershell
if ($env:GENTLE_VANGUARD_BASE_DIR) {
    $repoRoot = $env:GENTLE_VANGUARD_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
```

### Anti-Pattern: Hard-coded relative paths

```powershell
# BAD: Breaks if script is moved or called from different depth
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# BAD: Uses MyInvocation instead of $PSScriptRoot
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
```

## PSCustomObject Property Assignment

### Rule: Use `Add-Member -Force` for adding properties to PSCustomObject

```powershell
# GOOD: Add new property
$obj | Add-Member -MemberType NoteProperty -Name 'newProp' -Value 'val' -Force

# BAD: Direct assignment on non-existent property throws
$obj.newProp = 'val'
```

### Rule: Direct assignment is OK for existing properties

```powershell
# GOOD: Property already exists from ConvertFrom-Json
$obj.existingProp = 'newValue'
```

### Rule: Reconstruction is an alternative

```powershell
# GOOD: Reconstruct when adding multiple properties
$obj = [pscustomobject]@{
    ExistingProp = $obj.ExistingProp
    NewProp      = 'val'
}
```

## Hashtable Keys

### Rule: Quote all keys containing hyphens

```powershell
# GOOD
$hashtable = @{
    'session-close' = 'value'
    'auto-start'    = 'value'
}

# BAD: Parses as subtraction
$hashtable = @{
    session-close = 'value'
}
```

## Encoding

### Rule: No BOM in PowerShell scripts

```powershell
# GOOD: Write without BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)

# GOOD: PowerShell 7+
Set-Content -Path $path -Value $content -Encoding UTF8NoBOM

# BAD: Adds BOM in PowerShell 5.1
Out-File -FilePath $path -Encoding UTF8
Set-Content -Path $path -Value $content -Encoding UTF8
```

### Rule: ASCII-only in scripts

```powershell
# GOOD
Write-Host "[OK] Success"
Write-Host "[FAIL] Error"
Write-Host "->"

# BAD: Unicode characters
Write-Host "[OK] Success"
Write-Host "[FAIL] Error"
Write-Host "->"
```

## Error Handling

### Rule: Always set `$ErrorActionPreference`

```powershell
# GOOD: At the top of every script
$ErrorActionPreference = 'Stop'
```

### Rule: `$VerbosePreference` is ActionPreference, not boolean

```powershell
# GOOD: Cast for SwitchParameter parameters
[switch]$VerboseParam = $VerbosePreference -eq 'Continue'

# BAD: Direct boolean coercion
[switch]$VerboseParam = $VerbosePreference  # Always $true
```

## Path Construction

### Rule: Use `Join-Path` and `$repoRoot` for all paths

```powershell
# GOOD
$configPath = Join-Path $repoRoot 'config\orchestrator.json'

# BAD: String concatenation
$configPath = "$repoRoot\config\orchestrator.json"

# BAD: Relative from script location
$configPath = Join-Path $PSScriptRoot '..\..\config\orchestrator.json'
```

## Variable Scope

### Rule: Never reference `$repoRoot` inside `param()` blocks

```powershell
# GOOD: Define $repoRoot AFTER param()
param([string]$Name)
$repoRoot = ...

# BAD: Referenced before definition
param([string]$Path = (Join-Path $repoRoot 'config'))  # $repoRoot undefined
```

## HTTP Status Codes

### Rule: HTTP 403 on private repos is expected, not an error

```powershell
# GOOD: Separate expected 403 from real failures
$response = Invoke-WebRequest -Uri $url -ErrorAction Stop
# vs
try {
    $response = Invoke-WebRequest -Uri $url
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "[SKIP] Private repo -- expected"
    } else {
        throw
    }
}
```

## File Integrity

### Rule: SHA256 baseline for security-critical config files

```powershell
$baselineHash = Get-Content (Join-Path $repoRoot 'config\owner-auth.json.integrity') -Raw
$currentHash = (Get-FileHash (Join-Path $repoRoot 'config\owner-auth.json') -Algorithm SHA256).Hash
if ($currentHash -ne $baselineHash.Trim()) {
    throw "Integrity violation: owner-auth.json has been modified"
}
```

---

## Known Gaps (Future Work)

- **40+ scripts** still use `$PSScriptRoot '..\..'` fragile path pattern -- migrate to
  `$env:GENTLE_VANGUARD_BASE_DIR` + recursive search as scripts are touched
- **Non-ASCII characters** in ~30 scripts (emojis, Spanish accented chars in comments,
  em-dashes in heredocs) -- sanitize selectively as scripts are touched
- **BOM cleanup** completed for all 32 BOM-bearing scripts (2026-05-11)
