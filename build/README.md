# Gentle-Vanguard Build Scripts

Scripts and tools for encrypting, compiling, and distributing Gentle-Vanguard.
All build tools are **TypeScript** — run via `npx tsx`.

## Quick Build

### Single command — build Gentle-Vanguard.exe

```powershell
# Full build (encrypt + compile installer)
npx tsx src/cli/create-installer.ts

# Skip encryption (if build/protected/ already exists)
npx tsx src/cli/create-installer.ts --skip-encrypt

# Output: dist\Gentle-Vanguard.exe (~31 MB, NSIS installer, AES-256-GCM encrypted)
```

This is the **only** distribution format. `Gentle-Vanguard.exe` is a professional NSIS installer wizard that:

1. Installs to `C:\Program Files\Gentle-Vanguard\`
2. Deploys encrypted scripts (`protected/`) and skill stubs (`public/`)
3. Installs compiled launcher (`Gentle-Vanguard-Launcher.exe`)
4. Creates Desktop and Start Menu shortcuts
5. User provides `master.key` on first launch to decrypt and run

## Prerequisites

| Tool | Purpose | Install Location | Download |
|------|---------|------------------|----------|
| Node.js 20+ | Script execution | System PATH | https://nodejs.org/ |
| pnpm 11+ | Package management | System PATH | `npm install -g pnpm` |
| NSIS 3+ | Compile .exe installer | `C:\Program Files (x86)\NSIS\Bin\makensis.exe` | https://nsis.sourceforge.io/ |
| `keys/master.key` | AES-256-GCM encryption key | `keys/master.key` (32 bytes) | Generate via: `npx tsx src/cli/protect.ts` |

> **NSIS location**: `C:\Program Files (x86)\NSIS\Bin\makensis.exe` (v3.12). The build script auto-detects it.

## Build Pipeline

```
src/cli/protect.ts                          src/cli/create-installer.ts
       |                                            |
  AES-256-GCM encrypt                        Generate .nsi dynamically
  + integrity manifest                      + compile launcher (npx tsx)
       |                                     + NSIS compile (makensis)
       |                                            |
 build/protected/                            dist/Gentle-Vanguard.exe
 build/public/                              (NSIS installer, AES-256-GCM,
 build/integrity-manifest.json               all-in-one, professional wizard)
 build/Gentle-Vanguard-Launcher.ts          (TS setup wizard)
```

## Scripts Reference

| Script | Purpose | npm Command |
|--------|---------|-------------|
| `src/cli/protect.ts` | AES-256-GCM encrypt source files | `npm run gv:protect` |
| `src/cli/create-installer.ts` | Build NSIS installer | `npm run gv:installer` |
| `build/Gentle-Vanguard-Launcher.ts` | Interactive setup wizard | `npm run gv:launcher` |
| `src/cli/gentle-vanguard.ts` | Main CLI entry point | `npm run gv:main` |

## Key File

The `keys/master.key` file must be **32 bytes** (binary). Keep this key secure — it is required to decrypt the protected scripts during installation.

## Distribution Format

Only `dist/Gentle-Vanguard.exe` is distributed. It is a self-contained NSIS installer with:
- Embedded encrypted archive (AES-256-GCM, all source files)
- Compiled launcher
- Skill stubs (public SKILL.md files for discoverability)
- Integrity manifest (SHA-256)

## Version

Current version: **3.3.3**
Version source: `package.json` (single source of truth)
