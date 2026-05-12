# Tools Directory

This directory contains build and runtime dependencies that are NOT tracked by git (see .gitignore: *.exe, *.dll, *.lib).

## Required Tools

| Tool | Version | Source | File |
|------|---------|--------|------|
| Cairo DLL | 1.17.2 | [preshing/cairo-windows](https://github.com/preshing/cairo-windows/releases) | `cairo.dll` |
| Cairo LIB | 1.17.2 | [preshing/cairo-windows](https://github.com/preshing/cairo-windows/releases) | `cairo.lib` |
| Engram CLI | 1.15.10 | [Gentleman-Programming/engram](https://github.com/Gentleman-Programming/engram/releases) | `engram.exe` |

## Setup

Run `scripts\utilities\install-prerequisites.ps1` or install manually:

```powershell
# Cairo (SVG -> PNG conversion)
Invoke-WebRequest -Uri 'https://github.com/preshing/cairo-windows/releases/download/with-tee/cairo-windows-1.17.2.zip' -OutFile 'cairo.zip'
Expand-Archive -Path 'cairo.zip' -DestinationPath 'cairo-temp'
Copy-Item 'cairo-temp\cairo-windows-1.17.2\lib\x64\cairo.dll' 'tools\cairo.dll'
Copy-Item 'cairo-temp\cairo-windows-1.17.2\lib\x64\cairo.lib' 'tools\cairo.lib'

# Engram (persistent memory CLI)
Invoke-WebRequest -Uri 'https://github.com/Gentleman-Programming/engram/releases/download/v1.15.10/engram_1.15.10_windows_amd64.zip' -OutFile 'engram.zip'
Expand-Archive -Path 'engram.zip' -DestinationPath 'engram-temp'
Copy-Item 'engram-temp\engram.exe' 'tools\engram.exe'
```

## Also Available in PATH

| Tool | Location | Purpose |
|------|----------|---------|
| PS2EXE | PowerShell Module | Compile .ps1 to .exe |
| PSScriptAnalyzer | PowerShell Module | Linting |
| Trufflehog | scoop | Secret detection |
| Lefthook | scoop | Git hooks manager |
| NSIS 3.12 | Program Files (x86) | Installer compilation |
| Go 1.26 | Program Files | Engram build, Go tools |