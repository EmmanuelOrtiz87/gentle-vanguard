# Configuration Drift Detector

## Description

Detects unauthorized or unexpected changes to configuration files.

## Commands

```bash
# Create baseline
npx tsx src/tools/config-drift-detector.ts --baseline
<!-- REF-OBSOLETA: src/tools/config-drift-detector.ts no existe (ruta migrada o eliminada) -->

# Check for drift
npx tsx src/tools/config-drift-detector.ts
<!-- REF-OBSOLETA: src/tools/config-drift-detector.ts no existe (ruta migrada o eliminada) -->
```

## Drift Types

- **MODIFIED**: Files changed since baseline
- **NEW**: New config files
- **MISSING**: Files removed

## Files Tracked

- All `.json`, `.yaml`, `.yml`, `.toml`, `.ini` files
- `.config.js`, `.config.ts` files

## Baseline

- Location: `.runtime/config-baseline.json`
- Run `--baseline` to update after intentional changes
