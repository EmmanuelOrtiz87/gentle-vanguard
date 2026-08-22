# Gentle-Vanguard Scripts

Scripts for installing and maintaining the gentle-vanguard.

> **Note**: The original PowerShell bootstrap/sync/profile scripts were removed in the PS1→TS
> migration. Their functionality now lives in TypeScript entry points under `src/`, run via npm
> scripts.

## Entry Points

| Command                               | Source                       | Description                                       |
| ------------------------------------- | ---------------------------- | ------------------------------------------------- |
| `./setup.sh`                          | `scripts/core/setup.sh`      | Cross-platform setup entrypoint (Linux/macOS/WSL) |
| `npm run bootstrap:machine`           | `src/bootstrap-machine.ts`   | Install gentle-vanguard globally on machine       |
| `npm run bootstrap:run`               | `src/bootstrap.ts`           | Bootstrap workspace                               |
| `npm run setup:complete`              | `src/setup-complete.ts`      | Full stack setup (tools, hooks, env, validation)  |
| `npx tsx src/setup-multi-machine.ts`  | `src/setup-multi-machine.ts` | Clone and bootstrap repos on a new PC             |

## PC Migration

See [PC Migration Guide](../../docs/guides/PC-MIGRATION.md) for the step-by-step procedure.

## Usage

```powershell
# Install gentle-vanguard globally (~/.gentle-vanguard/)
npm run bootstrap:machine

# Full stack setup
npm run setup:complete

# Update everything
npx tsx src/cli/gv.ts update-all
```
