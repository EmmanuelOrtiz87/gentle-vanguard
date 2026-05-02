# Engram Update Procedure - Official Documentation

## Problem Identified

When updating engram while an MCP client (OpenCode) is running, the binary on disk is updated but the in-memory MCP subprocess remains the old version. This causes:
- Locked file (cannot overwrite)
- Outdated version even though disk file is new
- Inconsistent behavior

## Official Procedure (from Engram README.md)

### Step 1: Stop the MCP Client
Before updating, completely close OpenCode (or any client using engram).

### Step 2: Update the Binary

**Option A (recommended - go install):**
```powershell
go install github.com/Gentleman-Programming/engram/cmd/engram@latest
```
Binary goes to `%USERPROFILE%\go\bin\engram.exe`

**Option B (copy from workspace tools):**
```powershell
Copy-Item "C:\Workspace_local\workspace-foundation\tools\engram.exe" "C:\Users\emman\bin\engram.exe"
```

**Option C (download release):**
- Go to: https://github.com/Gentleman-Programming/engram/releases
- Download `engram_<version>_windows_amd64.zip`
- Extract `engram.exe` to `C:\Users\emman\bin\`

### Step 3: Reconfigure the Agent
```powershell
engram setup opencode
```
This updates:
- `~/.config/opencode/plugins/engram.ts` (session tracking)
- `opencode.json` (MCP server)
- `tui.json` or `tui.jsonc` (sub-agent status)

### Step 4: Restart the MCP Client
Open OpenCode (or your MCP client). It will automatically load the new engram.exe binary.

### Step 5: Verify
```powershell
engram --version
# Should show new version (e.g., 1.15.1)
```

## Automatic Update Script

See: `tools/update-engram.ps1`

## Important Notes

1. **Copying .exe alone is NOT enough** - the in-memory process must restart
2. **Engram in PATH** (`C:\Users\emman\bin\`) vs **Engram in tools/** (`workspace-foundation/tools/`)
   - tools/ is used for internal updates
   - PATH is what the system and MCP agents use
3. **OpenCode on Windows** uses `~/.config/opencode/` (not `%APPDATA%\opencode\`)
4. **Data** is stored in `%USERPROFILE%\.engram\engram.db`

## References

- https://github.com/Gentleman-Programming/engram/blob/main/README.md
- https://github.com/Gentleman-Programming/engram/blob/main/docs/INSTALLATION.md
- https://github.com/Gentleman-Programming/engram/blob/main/docs/AGENT-SETUP.md

## Key Quote from Official README

> **After upgrading `engram` while an MCP client is already running:**
> 
> `engram setup opencode`
> 
> Then restart Claude Code so it reloads the Engram MCP subprocess and refreshed hook/config files. **Updating the `engram` binary on disk does NOT replace an already-running stdio MCP process.**

This is exactly what was causing our repeated issues.
