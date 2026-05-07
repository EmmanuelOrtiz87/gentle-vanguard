# Foundation Build Scripts

Scripts and tools for encrypting, compiling, and distributing Foundation.

## Quick Rebuild (Recommended)

To rebuild the entire protected distribution and installer:

```powershell
# 1. Encrypt all protected scripts
pwsh -NoProfile -ExecutionPolicy Bypass -File "build\protect-foundation.ps1"

# 2. Build the NSIS installer (requires NSIS installed)
pwsh -NoProfile -ExecutionPolicy Bypass -File "build\create-installer.ps1"

# Installer output: dist\Foundation-Setup.exe
```

## Prerequisites

| Tool | Purpose | Download |
|------|---------|----------|
| PowerShell 7+ | Script execution | Microsoft |
| NSIS 3+ | Compile .exe installer | https://nsis.sourceforge.io/ |
| PS2EXE (optional) | Compile PS1 to standalone .exe | `Install-Module ps2exe` |

## File Reference

| File | Purpose |
|------|---------|
| `protect-foundation.ps1` | Encrypts core scripts with AES-256, generates `loader.ps1` |
| `create-installer.ps1` | Generates NSIS script and compiles `dist\Foundation-Setup.exe` |
| `foundation-installer.nsi` | NSIS installer definition (used by create-installer.ps1) |
| `Foundation-Launcher.ps1` | Smart launcher v2.0 with AES decryption + key fallback |
| `loader.ps1` | Generated simple launcher (by protect-foundation.ps1) |
| `Foundation-Installer-v4.ps1` | Self-contained PowerShell installer v4 |
| `Foundation-Simple-Installer.ps1` | Lightweight installer (no NSIS required) |

## Important Notes

1. **`dist/Foundation-Setup.exe` is a pre-compiled binary** — it must be rebuilt after any changes to `Foundation-Launcher.ps1` or encrypted scripts
2. **`master.key` is NEVER distributed** — users must obtain it from the private repo
3. **`build/` is in `.gitignore`** except for `Foundation-Launcher.ps1` which is force-tracked
4. After modifying the launcher, always run steps 1 + 2 above and commit the new `dist/Foundation-Setup.exe`

## Encryption Format

Protected scripts use AES-256 encryption:
- **Key**: 32-byte random key stored in `keys/master.key`
- **Format**: `Base64(IV[16 bytes] + encrypted_data)`
- **Decryption**: Use raw AES (NOT `ConvertTo-SecureString` which causes Windows credential popups)
