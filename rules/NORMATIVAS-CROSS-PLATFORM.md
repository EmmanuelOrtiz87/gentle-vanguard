# Cross-Platform Normatives — Gentle-Vanguard

Canonical standards for Windows, Linux, macOS, and WSL compatibility.
Last updated: 2026-05-12 | Version: 1.0.0

---

## 1. Platform Support Matrix

| Platform | Min Version | Shell | Status | Notes |
|----------|-------------|-------|--------|-------|
| **Windows** | 10 (21H2) | PowerShell 7.4+ | ✅ Primary | All scripts tested |
| **Linux** | Ubuntu 22.04 LTS | Bash 5.1, PowerShell 7.4+ | ✅ Supported | GitHub Actions CI/CD |
| **macOS** | 13 (Ventura) | Bash 5+, PowerShell 7.4+ | ✅ Supported | GitHub Actions CI/CD |
| **WSL 2** | Ubuntu 22.04 | Bash 5.1, PowerShell 7.4+ | ✅ Supported | Same as Linux |

**REQUIREMENT**: All scripts MUST run on all platforms or explicitly document platform-specific code.

---

## 2. PowerShell Core (7.4+) — Mandatory

- **Windows**: Download from [powershell.github.io](https://github.com/PowerShell/PowerShell)
- **Linux/macOS**: Install via `brew`, `apt`, `yum`, or `snap`
- **WSL 2**: Same as Linux

PowerShell Core has these advantages over Windows PowerShell 5.1:
- Native Linux/macOS support
- Unicode handling (UTF-8)
- Cross-platform modules
- Faster performance

---

## 3. Path Handling (CRITICAL)

### Problem: Platform-Specific Path Separators

```powershell
# ❌ WRONG (Windows-only):
$path = "C:\Workspace_local\gentle-vanguard\scripts"

# ✅ CORRECT (Cross-platform):
$path = Join-Path $PSScriptRoot ".." "scripts"
$path = Resolve-Path $path
```

### Rule 1: Use `Join-Path` ALWAYS

```powershell
# ❌ String concatenation (FORBIDDEN):
$file = "$home\.config/myapp.json"

# ✅ Join-Path (REQUIRED):
$file = Join-Path $home ".config" "myapp.json"
```

### Rule 2: Normalize Paths

```powershell
function Get-CrossPlatformPath {
    param([string]$Path)
    
    # Resolve to absolute, normalize separators
    $resolved = Resolve-Path -LiteralPath $Path
    return $resolved.ProviderPath
}
```

### Rule 3: Environment Variables

```powershell
# ❌ WRONG (Windows-specific):
$configDir = $env:APPDATA  # Only on Windows

# ✅ CORRECT (Cross-platform):
$configDir = if ($IsWindows) {
    $env:APPDATA
} elseif ($IsLinux -or $IsMacOS) {
    Join-Path $env:HOME ".config"
}
```

---

## 4. Line Endings (LF vs CRLF)

### Git Configuration (MANDATORY)

```bash
# Disable Git's line-ending conversion (keep LF)
git config --global core.autocrlf false
git config --global core.safecrlf warn

# Check current setting:
git config core.autocrlf
# Output: false
```

### .gitattributes (Required)

```
# gentle-vanguard/.gitattributes
* text eol=lf
*.ps1 text eol=lf
*.sh text eol=lf
*.md text eol=lf
*.json text eol=lf
*.yml text eol=lf

# Binary files
*.png binary
*.jpg binary
*.exe binary
```

### Code Standards

```powershell
# PowerShell: Always use LF
# Windows text editors (VS Code):
# Settings → Files: End of Line → \n

# Pester test verification:
It "uses LF line endings" {
    $file = Get-Content "script.ps1" -Raw
    $file -notmatch "`r`n" | Should Be $true
}
```

---

## 5. Temporary Directory Handling

### ❌ WRONG

```powershell
$tempDir = "$env:TEMP\myapp"  # Windows-specific
$logFile = "C:\logs\app.log"  # Windows-only path
```

### ✅ CORRECT

```powershell
# Use system temp directory (cross-platform)
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "gentle-vanguard-session"

# Use standard locations
$logDir = if ($IsWindows) {
    Join-Path $env:ProgramData "gentle-vanguard" "logs"
} else {
    Join-Path "/var" "log" "gentle-vanguard"
}

# Create if doesn't exist
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
```

---

## 6. Environment Variables

### Standard Cross-Platform Variables

| Variable | Windows | Linux/macOS | PowerShell |
|----------|---------|-------------|------------|
| Home directory | `$env:USERPROFILE` | `$env:HOME` | `$HOME` |
| Temp directory | `$env:TEMP` | `$TMPDIR` | `[System.IO.Path]::GetTempPath()` |
| System root | `$env:SystemRoot` | `/` | `$env:SystemRoot` (PS Core handles) |
| User shell | N/A | `$env:SHELL` | Auto-detected |

### Portable Code

```powershell
# Portable home directory
$homeDir = $HOME  # Works on all platforms with PowerShell Core

# Portable temp
$tempDir = [System.IO.Path]::GetTempPath()

# Portable configuration
$configDir = if ($IsWindows) {
    Join-Path $env:APPDATA "gentle-vanguard"
} else {
    Join-Path $env:HOME ".config" "gentle-vanguard"
}
```

---

## 7. Shell Script Handling

### Bash Compatibility (Linux/macOS)

```bash
#!/usr/bin/env bash
# Use #!/usr/bin/env (portable), NOT #!/bin/bash

set -euo pipefail  # Exit on error, undefined var, pipe failure

# Use portable commands:
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Avoid GNU-specific options
# ❌ WRONG: sed -i --backup (GNU-only)
# ✅ CORRECT: sed -i '' (POSIX)
```

### PowerShell Core (All Platforms)

```powershell
#!/usr/bin/env pwsh
# Use this shebang for GitHub Actions

[CmdletBinding()]
param()

# Script body

# Test execution
./script.ps1  # Runs on Windows
pwsh ./script.ps1  # Runs on Linux/macOS
```

---

## 8. Testing on All Platforms

### GitHub Actions Matrix

```yaml
# .github/workflows/cross-platform-tests.yml
name: Cross-Platform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        pwsh-version: [7.3, 7.4]
    
    steps:
      - uses: actions/checkout@v4
      - uses: PowerShell/setup-powershell@v2
        with:
          powershell-version: ${{ matrix.pwsh-version }}
      
      - name: Run Pester tests
        run: pwsh -Command 'Invoke-Pester tests/ -CI'
```

### Local Testing

```bash
# Linux/macOS:
pwsh -Command "Invoke-Pester tests/ -CI"

# Or run in Docker (consistent Windows simulation):
docker run -rm -v $(pwd):/work mcr.microsoft.com/powershell:7.4 `
  pwsh -Command "Invoke-Pester /work/tests/ -CI"
```

---

## 9. Common Pitfalls

### Pitfall 1: Hardcoded Paths

```powershell
# ❌ WRONG:
$config = Get-Content "C:\Users\$env:USERNAME\AppData\Local\gentle-vanguard\config.json"

# ✅ CORRECT:
$appDataPath = if ($IsWindows) { $env:APPDATA } else { Join-Path $HOME ".config" }
$configPath = Join-Path $appDataPath "gentle-vanguard" "config.json"
$config = Get-Content $configPath
```

### Pitfall 2: Drive Letters

```powershell
# ❌ WRONG (Windows-only):
if ($PWD -like "C:\*") { ... }

# ✅ CORRECT:
if (Test-Path -Path $PWD -PathType Container) { ... }
```

### Pitfall 3: Command Availability

```powershell
# ❌ WRONG (assumes command exists):
git log --oneline

# ✅ CORRECT:
if (Get-Command git -ErrorAction SilentlyContinue) {
    git log --oneline
} else {
    Write-Error "Git not found in PATH"
}
```

### Pitfall 4: Exit Codes

```powershell
# ❌ WRONG:
$result = Invoke-Expression "some-command"
if ($LASTEXITCODE -eq 0) { ... }

# ✅ CORRECT:
try {
    $result = & some-command -ErrorAction Stop
    # Success
} catch {
    Write-Error "Command failed: $_"
}
```

---

## 10. pwsh Availability Check & Fallback

### Problem
All gentle-vanguard scripts require PowerShell 7+ (pwsh). On Linux/macOS, pwsh may not be installed.
Without a fallback, the agent wastes tokens attempting to run scripts that fail with "command not found".

### Mandatory Check — Before Any Script Execution

```powershell
# Check pwsh availability before running gentle-vanguard scripts
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Error "PowerShell 7+ (pwsh) is required. Install from: https://github.com/PowerShell/PowerShell"
    exit 1
}
```

### Fallback Behavior

| Platform | pwsh installed? | Behavior |
|----------|----------------|----------|
| **Windows** | Always (shipped with tool) | Run `.cmd`/`.ps1` directly |
| **Linux** | ✅ Yes | Run `pwsh ./script.ps1` |
| **Linux** | ❌ No | **BLOCK**: report error with install instructions. No bash-native fallback exists |
| **macOS** | ✅ Yes | Run `pwsh ./script.ps1` |
| **macOS** | ❌ No | **BLOCK**: report error with `brew install powershell`. No zsh-native fallback exists |

### Detection at Startup

```powershell
# In detect-tool.ps1 or session-autostart:
$hasPwsh = [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
if (-not $hasPwsh -and -not $IsWindows) {
    Write-Error "[GENTLE_VANGUARD] PowerShell 7+ required. Run: brew install powershell (macOS) or see https://aka.ms/powershell"
    exit 1
}
```

### What If pwsh Is Missing?
1. Agent MUST NOT attempt to run any .ps1/.cmd script
2. Agent MUST report the missing dependency to user
3. Agent MUST provide install command: `brew install powershell` (macOS) or `https://aka.ms/powershell`
4. Agent MUST NOT fall back to bash — stack is PowerShell-native

---

## 11. Utility Functions (Cross-Platform)

### Portable Path Resolution

```powershell
function Get-PortablePath {
    param([string]$Path)
    [System.IO.Path]::GetFullPath(
        [System.IO.Path]::Combine($PSScriptRoot, $Path)
    )
}

# Usage:
$config = Get-Content (Get-PortablePath "../config.json")
```

### Portable Home Directory

```powershell
function Get-HomeDirectory {
    if ($IsWindows) {
        $env:USERPROFILE
    } else {
        $env:HOME
    }
}
```

### Portable Process Management

```powershell
function Invoke-CrossPlatformCommand {
    param(
        [string]$Command,
        [string[]]$Arguments
    )
    
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $Command
    $pinfo.Arguments = $Arguments -join ' '
    $pinfo.UseShellExecute = $false
    $pinfo.RedirectStandardOutput = $true
    
    $p = [System.Diagnostics.Process]::Start($pinfo)
    $output = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()
    
    return @{
        ExitCode = $p.ExitCode
        Output = $output
    }
}
```

---

## 12. CI/CD Cross-Platform

### GitHub Actions

```yaml
name: Cross-Platform CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    
    steps:
      - uses: actions/checkout@v4
      - uses: PowerShell/setup-powershell@v2
      
      - name: Run tests
        run: pwsh ./scripts/run-tests.ps1
```

### Docker (Consistent Environment)

```dockerfile
# Dockerfile
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

WORKDIR /app
COPY . .

RUN pwsh -Command 'Invoke-Pester tests/ -CI'
```

---

## 13. Documentation Requirements

### README Platform-Specific Sections

```markdown
# Gentle-Vanguard — Installation

## Prerequisites

- PowerShell 7.4+
- Git 2.40+

### Windows
- Windows 10 (21H2) or later
- No additional setup required

### Linux/macOS
- Linux: Ubuntu 22.04 LTS or later
- macOS: 13 (Ventura) or later
- Install PowerShell: `brew install powershell`

## Setup (All Platforms)

\`\`\`bash
git clone https://github.com/...
cd gentle-vanguard
pwsh ./scripts/setup.ps1
\`\`\`
```

---

## 14. Compliance Checklist

- [ ] All PowerShell scripts use `Join-Path` for paths
- [ ] `.gitattributes` configured with `eol=lf`
- [ ] Temp directory uses `[System.IO.Path]::GetTempPath()`
- [ ] Environment variable handling is portable
- [ ] No hardcoded drive letters or `/home/user` paths
- [ ] GitHub Actions matrix includes 3 OS: ubuntu, macos, windows
- [ ] All scripts tested on Windows, Linux, macOS
- [ ] Documentation includes platform-specific sections
- [ ] BASH scripts use `#!/usr/bin/env bash`
- [ ] PowerShell Core 7.4+ required in docs

---

## References

- [PowerShell Core Docs](https://learn.microsoft.com/en-us/powershell/)
- [POSIX Compliance](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [GitHub Actions: Strategy Matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- Project: [.github/workflows/](../.github/workflows/)

