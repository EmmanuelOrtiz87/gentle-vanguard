# System Prerequisites

Gentleman Foundation requirements for development machines.

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
| **gga** | CLI | AI-powered code review | `go install github.com/gentleman-programming/gentleman-guardian-angel/cmd/gga@latest` |
| **gentle-ai** | CLI | Ecosystem configurator | `go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest` |

## Quick Setup for New Developer

### 1. Minimal Setup (Required)

```powershell
# Install git
winget install Git.Git

# Install PowerShell 7
winget install Microsoft.PowerShell

# Install AI Agent (choose one)
# - OpenCode (recommended): https://opencode.ai
# - Or use existing Claude Desktop/Copilot/etc.
```

### 2. Install Gentleman Foundation

```powershell
# Clone foundation
git clone <foundation-repo-url> C:\path\to\foundation

# Install globally
cd C:\path\to\foundation
.\scripts\bootstrap-machine.ps1

# Verify
gf validate
```

### 3. Optional: Additional Tools

```powershell
# AI Code Review
go install github.com/gentleman-programming/gentleman-guardian-angel/cmd/gga@latest

# Ecosystem Configurator
go install github.com/gentleman-programming/gentle-ai/cmd/gentle-ai@latest
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Windows 10/11 | [OK] Full | Primary platform |
| macOS | [OK] Full | Use PowerShell Core |
| Linux | [OK] Full | Use PowerShell Core |

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
│   ⬜ gga (AI code review)                                   │
│   ⬜ engram (memory - built into opencode)                  │
│   ⬜ gentle-ai (ecosystem config)                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```
