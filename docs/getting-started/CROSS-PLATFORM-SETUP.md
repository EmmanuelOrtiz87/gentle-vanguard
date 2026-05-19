# Cross-Platform Setup Guide

## Overview

The Gentle-Vanguard - Development Stack now supports **all platforms** through
orchestrator-coordinated shell routing:

- **Windows**: PowerShell 5.1+ or PowerShell Core (pwsh)
- **Linux**: Bash, sh, zsh
- **macOS**: Bash, zsh, sh
- **WSL**: Full support via bash

## Support Model

1. The workspace is platform-aware for Windows, Linux, macOS, and WSL.
2. The wrapper commands are shell-aware and route to the correct entrypoint.
3. The tool activation and update scripts are PowerShell-based, but they now resolve
   platform-specific paths, home directories, and install metadata dynamically.
4. This means the stack is highly portable across OSes, while PowerShell remains the canonical
   implementation runtime for automation.

## Quick Start

### Windows (PowerShell)

```powershell
# First time setup
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gentle-vanguard\bootstrap.ps1

# Then use workflow commands
.\scripts\utilities\gv.ps1 status
.\scripts\utilities\gv.ps1 health
```

### Linux / macOS / WSL

```bash
# First time setup
bash scripts/gentle-vanguard/setup.sh
chmod +x scripts/gentle-vanguard/setup.sh gv

# Then use workflow commands
./gv status
./gv health
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

When you run `./gv`, the system:

1. Detects available shells (prioritizes: PowerShell bash sh)
2. Routes to appropriate implementation:
   - Windows + PowerShell available runs `gv.ps1`
   - Linux/macOS + bash available runs `gv.sh`
   - Fallback uses `gv` wrapper script

### Unified Command Interface

Same commands work on **all platforms**:

```bash
# All these work the same way everywhere:
./gv status      # Show project status
./gv health      # Run health checks
./gv verify      # Verify configuration
./gv diagnose    # Detailed diagnostics
./gv init        # Initialize environment
```

## Scripts Provided

### Setup Scripts

| Script                                  | Platform           | Purpose                                   |
| --------------------------------------- | ------------------ | ----------------------------------------- |
| `scripts/gentle-vanguard/setup.sh`      | Linux/macOS/WSL    | Universal setup with platform detection   |
| `scripts/gentle-vanguard/bootstrap.ps1` | Windows/PowerShell | Canonical PowerShell bootstrap entrypoint |
| `gv` wrapper + `scripts/utilities/gv.*` | All                | Auto-detects platform on execution        |

### Diagnostic Scripts

| Script                                       | Platform           | Purpose                                             |
| -------------------------------------------- | ------------------ | --------------------------------------------------- |
| `scripts/diagnostics/system-diagnostics.sh`  | Linux/macOS/WSL    | Check Go, Git, Engram, Node.js                      |
| `scripts/diagnostics/system-diagnostics.ps1` | Windows/PowerShell | PowerShell diagnostics entrypoint for Windows hosts |

### Initialization Scripts

| Script                                            | Platform           | Purpose                                                   |
| ------------------------------------------------- | ------------------ | --------------------------------------------------------- |
| `scripts/utilities/auto-init-dev-environment.sh`  | Linux/macOS/WSL    | Auto-detect and initialize stack                          |
| `scripts/utilities/auto-init-dev-environment.ps1` | Windows/PowerShell | PowerShell auto-init entrypoint with auto-install support |

### Workflow CLI

| Script                     | Platform           | Purpose                         |
| -------------------------- | ------------------ | ------------------------------- |
| `scripts/utilities/gv.sh`  | Linux/macOS/WSL    | Main workflow CLI (bash)        |
| `scripts/utilities/gv.ps1` | Windows/PowerShell | Main workflow CLI (PowerShell)  |
| `gv` (wrapper)             | All                | Smart router that detects shell |

## Command Reference

### status

Shows project information and installed tools:

```bash
./gv status
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
./gv health
```

Actions:

- Checks Go, Git, Engram CLI
- Auto-installs Engram CLI via `go install`
- Initializes Engram data directory
- Auto-links orchestrator skill

Additional behavior:

- Resolves system dependency installation metadata per platform from `config/workspace.config.json`
- Detects `bash` as a cross-platform capability for shell-based helper tooling
- Uses platform-aware PATH refresh logic after installation attempts

### diagnose

Detailed system diagnostics (verbose):

```bash
./gv diagnose
```

Checks:

- Go compiler versión
- Git versión
- Node.js / npm (if applicable)
- Engram CLI versión
- Engram data directory size
- Workspace configuration
- Orchestrator state
- Skills directory
- MCP server status

### verify

Quick environment verification:

```bash
./gv verify
```

Verifies:

- Critical tools installed
- Configuration files present
- Workspace readiness

### init

Full environment initialization:

```bash
./gv init
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
  "communication_response_mode": "simple",
  "supported_shells": ["powershell", "pwsh", "bash", "sh"],
  "shell_routing": {
    "windows": ["powershell", "pwsh"],
    "linux": ["bash", "sh"],
    "macos": ["bash", "zsh", "sh"]
  },
  "bootstrap": {
    "primary_entry": "scripts/gentle-vanguard/setup.sh",
    "fallback_entry": "scripts/gentle-vanguard/bootstrap.ps1"
  }
}
```

### Commands

The orchestrator maps commands to platform-specific implementations:

```json
{
  "commands": {
    "status": "gv.sh status",
    "health": "gv.sh health",
    "verify": "gv.sh verify"
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
& .\hooks\post-checkout.ps1
```

### Pre-Commit Hook

Before each commit:

- Verifies environment state
- Checks critical tools
- Aborts commit if configuration is broken

## Troubleshooting

## Compatibility Notes

1. `gv.ps1`, `ensure-tools-active.ps1`, and `update-tools.ps1` are the canonical automation scripts.
2. On Linux or macOS, prefer `pwsh` when invoking the PowerShell scripts directly.
3. Bash support is recommended when using shell-based helper tooling.
4. AI tooling is configurable and optional; the workspace does not require a single IDE or AI
   provider to be hardcoded.

### Problem: "Setup scripts not executable"

**Linux/macOS:**

```bash
chmod +x scripts/gentle-vanguard/setup.sh gv
chmod +x scripts/utilities/*.sh
chmod +x scripts/diagnostics/*.sh
chmod +x scripts/git-hooks/*
```

**Windows:** Already executable (PowerShell scripts handle execution)

### Problem: "Go not found"

Install Go: https://go.dev/dl/

### Problem: "Engram CLI won't install"

Check Go installation:

```bash
go versión
go env GOPATH
```

Manually install:

```bash
go install github.com/gentle-vanguard/engram/cmd/engram@latest
```

### Problem: "Wrong shell detected"

Explicitly use desired shell:

```bash
# Force bash
bash scripts/utilities/gv.sh status

# Force PowerShell
powershell -File scripts\utilities\gv.ps1 status
```

## Development

### Adding New Commands

1. Add function in `gv.sh` and `gv.ps1`:

```bash
# scripts/utilities/gv.sh
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
    "mycommand": "gv.sh mycommand"
  },
  "communication_response_mode": "simple"
}
```

## File Structure

```
project-root/
 scripts/gentle-vanguard/setup.sh       # Universal setup entry point (bash)
 scripts/gentle-vanguard/bootstrap.ps1  # PowerShell bootstrap entry point
 gv                                # Universal wrapper (any shell)
 config/
    orchestrator.json             # Platform routing config
    workspace.config.json         # Workspace configuration
 scripts/
    utilities/
       gv.sh                     # Bash/sh workflow CLI
       gv.ps1                    # PowerShell workflow CLI
       auto-init-dev-environment.sh
       auto-init-dev-environment.ps1
       ...
    diagnostics/
       system-diagnostics.sh
       system-diagnostics.ps1
       ...
    hooks/
        post-checkout.sh
        post-checkout.ps1
        ...
 .engram-data/                     # Engram CLI data directory
```

## Performance Notes

- **First setup**: ~30-60 seconds (depends on Engram installation)
- **Health checks**: ~2 seconds
- **Auto-initialization**: ~5-10 seconds (includes npm install for dashboard)
- **Diagnostics**: ~1 second

## What's Next

1. Run setup: `bash scripts/gentle-vanguard/setup.sh` (Linux/macOS) or
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gentle-vanguard\bootstrap.ps1`
   (Windows)
2. Verify installation: `./gv health` or `.\scripts\utilities\gv.ps1 health`
3. Start development: See project-specific README
4. Monitor via orchestrator: `engram status`

- Los hooks automticos de Gentle-Vanguard - Development Stack ejecutan chequeos de seguridad,
  calidad, arquitectura, testing, API, documentacin y gitflow en cada commit/push. Ver
  REVIEW-INDEX.md.
