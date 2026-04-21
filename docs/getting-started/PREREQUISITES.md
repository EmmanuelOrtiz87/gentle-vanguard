# System Prerequisites

Foundation - Development Stack requirements for development machines.

## Required

These are **required** for the foundation to work:

### Core

| Requirement | Version | Purpose |
|-------------|---------|---------|
| **git** | 2.30+ | Version control, hooks |
| **PowerShell** | 5.1+ | Scripts and automation |
| **PowerShell Core** | 7.0+ | Recommended for cross-platform |

### AI Agent (Required for AI features)

You need **one** of:

| Provider | Model Examples | Install |
|----------|---------------|---------|
| **OpenCode** | big-pickle, claude-3.5, gpt-4 | [opencode.ai](https://opencode.ai) |
| **Claude Desktop** | Claude 3.5 | [anthropic.com](https://anthropic.com) |
| **GitHub Copilot** | GPT-4 | VS Code extension |
| **Cursor** | claude-3.5 | [cursor.com](https://cursor.com) |
| **Windsurf** | Claude 3.5 | [codeium.com](https://codeium.com/windsurf) |

> **Note**: The foundation works with ANY AI agent. OpenCode is recommended for best integration.

## Optional

These enhance the foundation but are **not required**:

| Tool | Type | Purpose | Install |
|------|------|---------|---------|
| **engram** | opencode plugin | Persistent memory across sessions | Built into opencode |

## Quick Setup for New Developer

### 1. Minimal Setup (Required)

Windows:

```powershell
# Install git
winget install Git.Git

# Install PowerShell 7
winget install Microsoft.PowerShell

# Install AI Agent (choose one)
# - OpenCode (recommended): https://opencode.ai
# - Or use existing Claude Desktop/Copilot/etc.
```

Linux or macOS:

```bash
# Install git, PowerShell, and any required package managers using your platform standard.
# Then verify:
git --version
pwsh --version
```

### 2. Install Foundation - Development Stack

Windows PowerShell:

```powershell
# Clone foundation
git clone <foundation-repo-url> C:\path\to\foundation

# Install globally
cd C:\path\to\foundation
.\scripts\bootstrap-machine.ps1

# Verify
gf validate
```

Linux or macOS:

```bash
git clone <foundation-repo-url> ~/workspace-foundation
cd ~/workspace-foundation
pwsh -NoProfile -File ./scripts/foundation/bootstrap.ps1
gf validate
```

### 3. Optional: Additional Tooling

```powershell
# Optional external skills library
git clone https://github.com/Gentleman-Programming/Gentleman-Skills.git

# One-shot updater for all tools
.\scripts\utilities\wf.ps1 update-tools
```

Linux or macOS equivalent:

```bash
git clone https://github.com/Gentleman-Programming/Gentleman-Skills.git
pwsh -NoProfile -File ./scripts/utilities/wf.ps1 update-tools
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Windows 10/11 | [OK] Full | Canonical PowerShell entrypoint |
| macOS | [OK] Full | Use `pwsh` or the shell wrapper |
| Linux | [OK] Full | Use `pwsh` or the shell wrapper |

## Compatibility Notes

1. The workspace is platform-aware and reads platform-specific install metadata from `config/workspace.config.json`.
2. PowerShell is still the canonical runtime for automation scripts.
3. Bash is useful for shell-based helper tooling in cross-platform environments.
4. AI editor or provider choice is flexible; the foundation is not tied to a single IDE or AI agent.

## Verification

Run to check your setup:

```powershell
gf validate
gf check
```

## Troubleshooting

### "git not found"
```powershell
winget install Git.Git
```

### "PowerShell script blocked"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "AI agent not detected"
- Install opencode or configure your AI agent
- Foundation works without AI, but features are limited

## Requirements Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    MINIMUM REQUIREMENTS                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   [OK] git (any recent version)                                 │
│   [OK] PowerShell 5.1+                                         │
│   [OK] AI Agent (opencode, claude, copilot, etc.)             │
│                                                              │
│   Optional but recommended:                                  │
│   ⬜ engram (memory - built into opencode)                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

- Los hooks automáticos de Foundation - Development Stack validan seguridad, calidad, arquitectura, testing, API, documentación y gitflow antes de cada commit/push.
