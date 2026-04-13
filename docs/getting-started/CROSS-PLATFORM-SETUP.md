# Cross-Platform Setup Guide

## Overview

The Gentleman Foundation stack now supports **all platforms** through orchestrator-coordinated shell routing:

- **Windows**: PowerShell 5.1+ or PowerShell Core (pwsh)
- **Linux**: Bash, sh, zsh
- **macOS**: Bash, zsh, sh
- **WSL**: Full support via bash

## Quick Start

### Windows (PowerShell)

```powershell
# First time setup
.\setup.ps1

# Then use workflow commands
.\wf.ps1 status
.\wf.ps1 health
```

### Linux / macOS / WSL

```bash
# First time setup
bash scripts/foundation/setup.sh
chmod +x scripts/foundation/setup.sh wf

# Then use workflow commands
./wf status
./wf health
```

## How It Works

### Platform Detection

The orchestrator automatically detects your platform and available shells:

```bash
# Detect OS
detect_os  # Returns: linux, macos, windows

# Detect shell
detect_shell  # Returns: bash, zsh, sh, powershell, pwsh
```

### Intelligent Routing

When you run `./wf`, the system:

1. Detects available shells (prioritizes: PowerShell → bash → sh)
2. Routes to appropriate implementation:
   - Windows + PowerShell available → runs `wf.ps1`
   - Linux/macOS + bash available → runs `wf.sh`
   - Fallback → uses `wf` wrapper script

### Unified Command Interface

Same commands work on **all platforms**:

```bash
# All these work the same way everywhere:
./wf status      # Show project status
./wf health      # Run health checks
./wf verify      # Verify configuration
./wf diagnose    # Detailed diagnostics
./wf init        # Initialize environment
```

## Scripts Provided

### Setup Scripts

| Script | Platform | Purpose |
|--------|----------|---------|
| `scripts/foundation/setup.sh` | Linux/macOS/WSL | Universal setup with platform detection |
| `setup.ps1` | Windows/PowerShell | Windows-specific initialization |
| `scripts/foundation/setup.sh` in `wf` wrapper | All | Auto-detects platform on execution |

### Diagnostic Scripts

| Script | Platform | Purpose |
|--------|----------|---------|
| `scripts/diagnostics/system-diagnostics.sh` | Linux/macOS/WSL | Check Go, Git, Engram, Node.js |
| `scripts/diagnostics/system-diagnostics.ps1` | Windows/PowerShell | Windows version of diagnostics |

### Initialization Scripts

| Script | Platform | Purpose |
|--------|----------|---------|
| `scripts/utilities/auto-init-dev-environment.sh` | Linux/macOS/WSL | Auto-detect and initialize stack |
| `scripts/utilities/auto-init-dev-environment.ps1` | Windows/PowerShell | Windows version with auto-install |

### Workflow CLI

| Script | Platform | Purpose |
|--------|----------|---------|
| `scripts/utilities/wf.sh` | Linux/macOS/WSL | Main workflow CLI (bash) |
| `scripts/utilities/wf.ps1` | Windows/PowerShell | Main workflow CLI (PowerShell) |
| `wf` (wrapper) | All | Smart router that detects shell |

## Command Reference

### status
Shows project information and installed tools:
```bash
./wf status
```

Output:
- Project root
- Operating system
- Current shell
- Installed tools (Go, Git, Node.js, Engram)
- Project-specific info

### health
Runs health checks and auto-installs missing tools:
```bash
./wf health
```

Actions:
- Checks Go, Git, Engram CLI
- Auto-installs Engram CLI via `go install`
- Initializes Engram data directory
- Auto-links orchestrator skill

### diagnose
Detailed system diagnostics (verbose):
```bash
./wf diagnose
```

Checks:
- Go compiler version
- Git version
- Node.js / npm (if applicable)
- Engram CLI version
- Engram data directory size
- Workspace configuration
- Orchestrator state
- Skills directory
- MCP server status

### verify
Quick environment verification:
```bash
./wf verify
```

Verifies:
- Critical tools installed
- Configuration files present
- Workspace readiness

### init
Full environment initialization:
```bash
./wf init
```

Actions:
- Runs diagnostics
- Installs Engram CLI if missing
- Initializes data directories
- Installs npm dependencies (dashboard)
- Seeds configurations

## Orchestrator Integration

### Configuration

The orchestrator is configured in `config/orchestrator.json`:

```json
{
  "platform_aware": true,
  "cross_platform_routing": true,
  "supported_shells": ["powershell", "pwsh", "bash", "sh"],
  "shell_routing": {
    "windows": ["powershell", "pwsh"],
    "linux": ["bash", "sh"],
    "macos": ["bash", "zsh", "sh"]
  },
  "bootstrap": {
    "primary_entry": "scripts/foundation/setup.sh",
    "fallback_entry": "setup.ps1"
  }
}
```

### Commands

The orchestrator maps commands to platform-specific implementations:

```json
{
  "commands": {
    "status": "wf.sh status",
    "health": "wf.sh health",
    "verify": "wf.sh verify"
  }
}
```

## Git Hooks

Post-checkout and pre-commit hooks automatically manage environment state:

### Post-Checkout Hook

On each branch checkout, automatically:
- Runs diagnostics
- Detects missing dependencies
- Offers to auto-install Engram CLI
- Re-initializes environment if needed

```bash
# Git will automatically run this after checkout:
# (For Linux/macOS)
.git/hooks/post-checkout

# (For Windows - calls via orchestrator)
& .\s scripts\hooks\post-checkout.ps1
```

### Pre-Commit Hook

Before each commit:
- Verifies environment state
- Checks critical tools
- Aborts commit if configuration is broken

## Troubleshooting

### Problem: "Setup scripts not executable"

**Linux/macOS:**
```bash
chmod +x scripts/foundation/setup.sh wf
chmod +x scripts/utilities/*.sh
chmod +x scripts/diagnostics/*.sh
chmod +x scripts/hooks/*.sh
```

**Windows:** Already executable (PowerShell scripts handle execution)

### Problem: "Go not found"

Install Go: https://go.dev/dl/

### Problem: "Engram CLI won't install"

Check Go installation:
```bash
go version
go env GOPATH
```

Manually install:
```bash
go install github.com/Gentleman-Programming/engram/cmd/engram@latest
```

### Problem: "Wrong shell detected"

Explicitly use desired shell:
```bash
# Force bash
bash scripts/utilities/wf.sh status

# Force PowerShell (Windows)
powershell.exe -File scripts\utilities\wf.ps1 status
```

## Development

### Adding New Commands

1. Add function in `wf.sh` and `wf.ps1`:

```bash
# scripts/utilities/wf.sh
cmd_mycommand() {
    log_header "My Command"
    log_info "Doing something..."
    log_success "Done!"
}
```

2. Add to command router:

```bash
case "$cmd" in
    ...
    mycommand) cmd_mycommand;;
    ...
esac
```

3. Update orchestrator config in `config/orchestrator.json`:

```json
{
  "commands": {
    "mycommand": "wf.sh mycommand"
  }
}
```

## File Structure

```
project-root/
├── scripts/foundation/setup.sh       # Universal setup entry point
├── setup.ps1                         # Windows setup (legacy)
├── wf                                # Universal wrapper (any shell)
├── config/
│   ├── orchestrator.json             # Platform routing config
│   └── workspace.config.json         # Workspace configuration
├── scripts/
│   ├── utilities/
│   │   ├── wf.sh                     # Bash/sh workflow CLI
│   │   ├── wf.ps1                    # PowerShell workflow CLI
│   │   ├── auto-init-dev-environment.sh
│   │   ├── auto-init-dev-environment.ps1
│   │   └── ...
│   ├── diagnostics/
│   │   ├── system-diagnostics.sh
│   │   ├── system-diagnostics.ps1
│   │   └── ...
│   └── hooks/
│       ├── post-checkout.sh
│       ├── post-checkout.ps1
│       └── ...
└── .engram-data/                     # Engram CLI data directory
```

## Performance Notes

- **First setup**: ~30-60 seconds (depends on Engram installation)
- **Health checks**: ~2 seconds
- **Auto-initialization**: ~5-10 seconds (includes npm install for dashboard)
- **Diagnostics**: ~1 second

## What's Next

1. Run setup: `bash scripts/foundation/setup.sh` (Linux/macOS) or `.\setup.ps1` (Windows)
2. Verify installation: `./wf health`
3. Start development: See project-specific README
4. Monitor via orchestrator: `engram status`
