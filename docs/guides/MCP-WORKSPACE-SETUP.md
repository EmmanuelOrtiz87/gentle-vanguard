# MCP Workspace Setup Guide

**Purpose**: Secure isolated environment for Model Context Protocol (MCP) server dependencies  
**Version**: 1.0.0  
**Date**: May 13, 2026  
**Status**: REQUIRED FOR PRODUCTION

---

## Overview

The MCP workspace (`$HOME\mcp-workspace`) is a **local machine artifact** (not git-tracked) that
provides:

✅ Pre-vetted package versions with locked dependencies  
✅ Offline-only execution (no live registry fetches)  
✅ Supply-chain attack mitigation via `--offline --no --workspace` flags  
✅ Conscious update procedures with security review gates

**Location**: `C:\Users\<username>\mcp-workspace`  
**Isolation**: External to the gentle-vanguard repository (local machine only)

---

## Prerequisites

- PowerShell 7.x or Windows PowerShell 5.1+
- npm 8.0+ (comes with Node.js 16+)
- Git (for optional version control of workspace)

**Check versions**:

```powershell
pwsh --version
npm --version
git --version
```

---

## Initial Setup

### Step 1: Create Workspace Directory

```powershell
# Create isolated directory
mkdir $HOME\mcp-workspace
cd $HOME\mcp-workspace
```

**Verify**:

```powershell
Get-Item $HOME\mcp-workspace  # Should show directory exists
```

### Step 2: Initialize NPM

```powershell
npm init -y
```

**Result**: Creates `package.json`

```json
{
  "name": "mcp-workspace",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

### Step 3: Install MCP Servers

**Install with exact version pinning**:

```powershell
npm install @modelcontextprotocol/server-filesystem@2026.1.14 --save-exact
```

**What happens**:

- Downloads and installs exact version from npm registry
- Creates `package-lock.json` with full dependency tree
- Creates `node_modules/@modelcontextprotocol/server-filesystem/`

### Step 4: Verify Installation

```powershell
# Check package installed
npm list @modelcontextprotocol/server-filesystem

# Verify lockfile exists
Test-Path package-lock.json
# Should return: True

# Verify node_modules populated
Test-Path "node_modules/@modelcontextprotocol/server-filesystem"
# Should return: True

# Check for vulnerabilities
npm audit
# Should return: 0 vulnerabilities
```

**Expected output for Step 3 + Step 4**:

```
> npm list @modelcontextprotocol/server-filesystem
mcp-workspace@1.0.0 C:\Users\<username>\mcp-workspace
└── @modelcontextprotocol/server-filesystem@2026.1.14

up to date
0 vulnerabilities
```

---

## Integration with gentle-vanguard

### How MCP Workspace is Used

In `config/mcp-servers.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "--include-workspace-root",
        "--workspace",
        "%USERPROFILE%\\mcp-workspace",
        "--no",
        "--offline",
        "@modelcontextprotocol/server-filesystem",
        "."
      ]
    }
  }
}
```

**What each flag does**:

| Flag                                      | Purpose                             |
| ----------------------------------------- | ----------------------------------- |
| `--workspace %USERPROFILE%\mcp-workspace` | Point to pre-vetted workspace       |
| `--offline`                               | Block ALL registry network requests |
| `--no`                                    | Refuse to auto-download packages    |
| `--include-workspace-root`                | Enable workspace mode resolution    |

### Testing MCP Integration

```powershell
# From gentle-vanguard root:
cd C:\Workspace_local\gentle-vanguard

# Verify MCP config is valid JSON
Get-Content config/mcp-servers.json | ConvertFrom-Json | Out-Null
# Should return without errors

# Test npx offline execution (will show version if successful)
npx --include-workspace-root --workspace $HOME\mcp-workspace --no --offline @modelcontextprotocol/server-filesystem --version
```

---

## Updating MCP Packages

### Decision Flowchart

```
┌─── Want to update MCP package? ───┐
│                                    │
├─ YES ─> Run: npm audit            │
│         Review: vulnerabilities    │
│         ↓                          │
│         npm update @pkg --save-exact
│         ↓
│         REVIEW: package-lock.json changes
│         ↓
│         DECISION: safe to commit?
│            ├─ YES ─> git commit
│            └─ NO  ─> REVERT & investigate
│
└─ NO  ─> Nothing to do           ─┘
```

### Conscious Update Procedure

**Step 1: Check current status**

```powershell
cd $HOME\mcp-workspace

# What's currently installed?
npm list @modelcontextprotocol/server-filesystem

# Are there any vulnerabilities?
npm audit
```

**Step 2: Review available updates**

```powershell
# Check what versions are available
npm view @modelcontextprotocol/server-filesystem versions --json | ConvertFrom-Json | Select-Object -Last 10
```

**Step 3: Decide on update version**

Consider:

- **Security patches** (e.g., 2026.1.14 → 2026.1.15) — RECOMMENDED
- **Minor updates** (e.g., 2026.1.14 → 2026.2.0) — REVIEW CHANGELOG
- **Major updates** (e.g., 2026.1.14 → 2027.0.0) — THOROUGH TESTING

**Step 4: Perform update**

```powershell
# Update to specific version
npm update @modelcontextprotocol/server-filesystem@<NEW_VERSION> --save-exact

# Or: update to latest (respects min-release-age)
npm update @modelcontextprotocol/server-filesystem --save-exact
```

**Step 5: Review changes**

```powershell
# See what changed in lockfile (example if using git)
git diff package-lock.json

# OR: manually inspect
notepad package-lock.json
# Look for: version numbers, new dependencies, hash changes
```

**Step 6: Test updated package**

```powershell
# Quick test
npm list @modelcontextprotocol/server-filesystem
npm audit

# Integration test
npx --include-workspace-root --workspace $HOME\mcp-workspace --no --offline @modelcontextprotocol/server-filesystem --version
```

**Step 7: Commit change (if using git in workspace)**

```powershell
# If tracking workspace in git
git add package.json package-lock.json
git commit -m "chore(mcp): update @modelcontextprotocol/server-filesystem to v2026.X.X

Changes reviewed: [describe what changed]
Security audit: [0 vulnerabilities|X vulnerabilities reviewed]
Testing: [manual verification completed]
"
```

---

## Global NPM Security Policy

The `.npmrc` file in the gentle-vanguard root provides additional hardening:

```ini
# ~/.npmrc (global) AND gentle-vanguard/.npmrc (project)

# Disable post-install scripts (prevents malicious package code)
ignore-scripts=true

# Minimum release age: require 3 days before new package version
# Gives community time to detect compromised packages
min-release-age=3

# Block git-based dependencies (common attack vector)
allow-git=none
```

**Verify these are active**:

```powershell
npm config get ignore-scripts
# Should return: true

npm config get min-release-age
# Should return: 3

npm config get allow-git
# Should return: none
```

---

## Troubleshooting

### Issue: `npm install` fails with permission error

**Solution**:

```powershell
# Run terminal as Administrator
# OR: change npm cache directory
npm config set cache $HOME\.npm-cache --global

# Retry install
npm install @modelcontextprotocol/server-filesystem@2026.1.14 --save-exact
```

### Issue: npx offline mode says "package not found"

**Solution**: Verify package is actually installed

```powershell
# Check that files exist
Test-Path "$HOME\mcp-workspace\node_modules\@modelcontextprotocol\server-filesystem"
# Must be True

# Re-install if missing
cd $HOME\mcp-workspace
npm install @modelcontextprotocol/server-filesystem@2026.1.14 --save-exact
```

### Issue: `.npmrc` rules not applying

**Solution**: Check precedence and reload

```powershell
# Check which .npmrc files are being read
npm config list --all | findstr /i npmrc

# Reload npm config
npm cache clean --force

# Verify settings
npm config get ignore-scripts
npm config get min-release-age
```

### Issue: "min-release-age" blocking legitimate updates

**Solution**: Temporarily allow or use different version

```powershell
# Option 1: Wait 3+ days after package release

# Option 2: Force install (not recommended for production)
npm install @modelcontextprotocol/server-filesystem@<VERSION> --save-exact --legacy-peer-deps

# Option 3: Change policy temporarily
npm config set min-release-age 0
npm update @modelcontextprotocol/server-filesystem --save-exact
npm config set min-release-age 3  # Restore
```

---

## Security Checklist

Before considering MCP workspace setup complete:

- [ ] Directory created at `$HOME\mcp-workspace`
- [ ] `npm init -y` run (package.json exists)
- [ ] `@modelcontextprotocol/server-filesystem@2026.1.14` installed
- [ ] `package-lock.json` exists and checked
- [ ] `npm audit` returns 0 vulnerabilities
- [ ] `config/mcp-servers.json` points to `%USERPROFILE%\mcp-workspace`
- [ ] `.npmrc` policy file in gentle-vanguard root with 3 settings
- [ ] npx offline test passes (shows version without network)
- [ ] Documentation reviewed (this file)

---

## Reference

**Related Documentation**:

- [SECURITY-HARDENING.md](SECURITY-HARDENING.md#5-npx-supply-chain-hardening) — NPX hardening
  details
- [config/mcp-servers.json](../../config/mcp-servers.json) — MCP configuration
- [.npmrc](../../.npmrc) — npm security policy

**External References**:

- [npm-security-best-practices](https://github.com/lirantal/npm-security-best-practices) — Supply
  chain threat model
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit) — Vulnerability scanning
- [Model Context Protocol](https://modelcontextprotocol.io) — MCP standards

---

## Support

**New developer?** Follow steps 1-4 of "Initial Setup" above.

**Updating packages?** Use "Updating MCP Packages" procedure with conscious review.

**Issues?** Check "Troubleshooting" section or reach out to security team.

**Questions?** See [SECURITY-HARDENING.md](SECURITY-HARDENING.md#5-npx-supply-chain-hardening) for
threat model details.

---

**Last Updated**: May 13, 2026  
**Status**: PRODUCTION READY
