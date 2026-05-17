# Gentle-Vanguard Installation Guide

## Prerequisites

- **PowerShell 7+** — required for all scripts
- **Git 2.30+** — for version control and updates
- **Windows 10/11, macOS 13+, or Linux (Ubuntu 22.04+)**

## Install via Executable (Recommended)

1. Download [`Gentle-Vanguard.exe`](Gentle-Vanguard.exe) directly from the repo root
2. Run as Administrator
3. Follow the NSIS installer wizard
4. Open a new terminal and run: `gv health`

Download also available from [Releases](https://github.com/EmmanuelOrtiz87/gentle-vanguard-public/releases).

## Install via Git Clone

```powershell
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard-public.git
cd gentle-vanguard-public
pwsh -File scripts/gentle-vanguard/bootstrap.ps1
```

## Verify Installation

```powershell
gv health
```

## Updates

```powershell
gv update
```

## Troubleshooting

See [docs/getting-started/](docs/getting-started/) for platform-specific setup guides.
