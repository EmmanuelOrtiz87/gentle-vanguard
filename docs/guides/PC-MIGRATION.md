# PC Migration Guide

Complete guide for migrating Foundation workspace to a new machine.

## Prerequisites (New Machine)

Before importing, install these on the new machine:

| Tool | Install Command | Required |
|------|----------------|----------|
| Git | `winget install Git.Git` | Yes |
| Node.js (LTS) | `winget install OpenJS.NodeJS.LTS` | Yes |
| Go | `winget install GoLang.Go` | Yes |
| PowerShell 7 | `winget install Microsoft.PowerShell` | Yes |
| Bun | `powershell -c "irm bun.sh/install.ps1 \| iex"` | Yes |

> Run `.\scripts\utilities\install-prerequisites.ps1 -CheckOnly` to verify.

## Export (Current PC)

```powershell
# Export to Downloads folder
.\scripts\foundation\export-profile.ps1

# Or export directly to external disk (e.g. D:)
.\scripts\foundation\export-profile.ps1 -ExternalDisk D

# Specify custom repo root (default: auto-detected)
.\scripts\foundation\export-profile.ps1 -ExternalDisk D -RepoRoot C:\Workspace_local\workspace-foundation
```

### What Gets Exported

| Component | Location | Contents |
|-----------|----------|----------|
| Engram DB | `~/.engram/` | `engram.db`, WAL files, `global/`, `instances.json` |
| Master Key | `keys/master.key` | AES-256 key for decrypting protected scripts |
| OpenCode Config | `~/.config/opencode/` | `opencode.json`, `tui.json`, `plugins/` |
| Binaries | `~/bin/` | `engram.exe`, `opencode`, `gga`, `lib/` |
| Go Binaries | `~/go/bin/` | `engram.exe` (Go build) |
| PS Profile | `~/Documents/PowerShell/` | `Microsoft.PowerShell_profile.ps1` |
| Manifest | Generated | `manifest.json` with timestamp and metadata |

## Import (New PC)

```powershell
# 1. Clone the Foundation repo first
git clone https://github.com/EmmanuelOrtiz87/foundation.git C:\Workspace_local\workspace-foundation
cd C:\Workspace_local\workspace-foundation

# 2. Import profile from external disk
.\scripts\foundation\import-profile.ps1 -ExternalDisk D

# 3. Run setup (repos + bootstrap)
.\scripts\foundation\setup-multi-machine.ps1

# 4. Restart terminal for PATH changes to take effect
```

### What Import Does

1. Restores Engram DB to `~/.engram/`
2. Restores `master.key` to `<repo>/keys/` (backs up existing)
3. Restores OpenCode config to `~/.config/opencode/`
4. Restores binaries to `~/bin/` and `~/go/bin/`
5. Restores PowerShell profile
6. Adds `~/bin` and `~/go/bin` to user PATH
7. Clones repos + runs bootstrap (if `-SkipBootstrap` not set)

## Post-Import Verification

```powershell
# Verify Engram
engram health

# Verify OpenCode
opencode --version

# Verify tools
.\scripts\utilities\install-prerequisites.ps1 -CheckOnly

# Verify Foundation
.\wf.ps1 health
```

## Updating Engram

Engram can be updated after migration or anytime:

```powershell
# Via wf CLI
.\scripts\utilities\wf.ps1 install-engram

# Or directly
go install github.com/workspace-foundation/engram/cmd/engram@latest
```

## Syncing to Foundation-Public

After changes to the private repo that need to be reflected in the public repo:

```powershell
# Build protected scripts + sync to public
.\scripts\utilities\DEPLOYMENT\sync-to-public.ps1

# Or skip git push (dry-run)
.\scripts\utilities\DEPLOYMENT\sync-to-public.ps1 -skipPush
```

This copies:
- Bootstrap scripts (plain text)
- Public documentation
- Encrypted `protected/` artifacts
- Public skill stubs
- Compiled executables (`Foundation-Launcher.exe`, `Foundation-Setup.exe`)
- Example configs (no secrets)

## Updating Foundation Itself

```powershell
# Pull latest changes
git pull origin develop

# Re-run bootstrap if needed
.\scripts\foundation\bootstrap.ps1

# Update prerequisites
.\scripts\utilities\install-prerequisites.ps1

# Verify all tools
.\scripts\utilities\wf.ps1 health
```

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `engram health` fails | Run `engram serve` to start the Engram server |
| `master.key` not found after import | Check `<repo>/keys/master.key` — re-run import with correct ZIP |
| Protected scripts won't decrypt | Verify `master.key` matches the one used to encrypt |
| PATH not updated | Restart terminal or run `$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + $env:Path` |
| OpenCode can't find engram | Verify `~/bin/engram.exe` exists and PATH includes `~/bin` |