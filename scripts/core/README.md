# Gentle-Vanguard Scripts

Scripts for installing and maintaining the gentle-vanguard.

## Scripts

| Script                    | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `setup.sh`                | Cross-platform gentle-vanguard setup entrypoint (Linux/macOS/WSL) |
| `bootstrap-machine.ps1`   | Install gentle-vanguard globally on machine                       |
| `bootstrap-workspace.ps1` | Bootstrap workspace with skills and tools                    |
| `bootstrap.ps1`           | Main bootstrap script                                        |
| `sync-skills.ps1`         | Sync skills from source to global                            |
| `gv.ps1`                  | Main CLI entry point (alias: gv)                             |
| `export-profile.ps1`      | Export user profile (engram, opencode, binarios, master.key) to ZIP for PC migration |
| `import-profile.ps1`      | Import user profile from ZIP on a new PC                    |
| `setup-multi-machine.ps1` | Clone and bootstrap repos on a new PC                        |

## Related Scripts

These scripts live in `scripts/utilities/` but are commonly used with the above:

| Script                    | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `verify-tools.ps1`        | Hash-based tool validation with 7-day cache TTL            |
| `install-cairo.ps1`      | Install GTK3 Runtime for Cairo (SVG to PNG export)          |
| `install-prerequisites.ps1` | Install all required tools (Node, Go, Git, etc.)          |

## PC Migration

See [PC Migration Guide](../../docs/guides/PC-MIGRATION.md) for the complete step-by-step procedure.

**Quick start:**
```powershell
# Export (current PC)
.\scripts\gentle-vanguard\export-profile.ps1 -ExternalDisk D

# Import (new PC)
.\scripts\gentle-vanguard\import-profile.ps1 -ExternalDisk D

# Verify tools
.\scripts\utilities\verify-tools.ps1

# Install Cairo for PNG diagram export
.\scripts\utilities\install-cairo.ps1
```

## Usage

```powershell
# Install gentle-vanguard globally (~/.gentleman/)
.\bootstrap-machine.ps1

# Sync skills to global installation
.\sync-skills.ps1 -Force

# Update everything
.\scripts\validation\update-all.ps1
```


