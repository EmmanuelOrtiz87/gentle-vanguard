---
name: shellcheck-standards
description: >
  Shell script quality and portability standards. Trigger: "bash", "shell", "shellcheck", "bash
  script"
metadata:
  source: GV-native
---

# Shell Script Standards

## Purpose

Maintain shell script quality and portability across bash/PowerShell runtimes.

## Running Linters

```powershell
# PowerShell
Invoke-ScriptAnalyzer -Path .\scripts\

# Bash
shellcheck -x bin/* lib/*.sh
```

## PowerShell Standards

### Variables

```powershell
# GOOD  use $ for variables
$name = "value"
$env:PATH += ";$customPath"

# GOOD  local scope
function Get-Value {
    $result = Get-Something
    return $result
}
```

### Parameters

```powershell
# GOOD  typed parameters
param(
    [string]$Name,
    [int]$Count = 10,
    [switch]$Force
)
```

### Error Handling

```powershell
# GOOD  use ErrorAction
Invoke-Something -ErrorAction Stop
$ErrorActionPreference = 'Stop'
```

## Bash Standards

### Quoting

```bash
# GOOD  always quote
echo "$var"
"$cmd" "$arg"

# BAD  unquoted
echo $var
```

### Conditionals

```bash
# GOOD  use [[ ]]
[[ "$var" == "value" ]]
[[ -f "$file" ]]

# BAD  use [ ] only for POSIX
```

### Functions

```bash
# GOOD  local variables
my_function() {
    local result
    result="something"
}
```

## Cross-Platform

### Paths

```powershell
# GOOD  Join-Path
$path = Join-Path $dir $file

# GOOD  forward slashes work on all platforms
$uri = "https://example.com/path"
```

### Line Endings

```bash
# Set in .gitattributes
*.ps1 text eol=crlf
*.sh text eol=lf
```

## Common Fixes

| Issue                    | Fix                               |
| ------------------------ | --------------------------------- |
| `$var` unquoted          | Add `"$var"`                      |
| `$?` without check       | Use `if command; then`            |
| Global vars in functions | Add `local` keyword               |
| eval usage               | Use arrays or parameter expansion |
