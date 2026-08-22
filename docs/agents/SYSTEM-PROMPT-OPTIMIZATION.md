# System Prompt Optimization Framework

## Overview

Framework completo para optimización de system prompts con reducción de 97% de tokens.

## Components

### Fase 1: Core Infrastructure

| Component            | File                                         | Purpose                         |
| -------------------- | -------------------------------------------- | ------------------------------- |
| Semantic Compression | `scripts/utilities/semantic-compression.ps1` | Reduce tokens via abbreviations |

<!-- REF-OBSOLETA: scripts/utilities/semantic-compression.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Prompt Caching | `scripts/utilities/prompt-cache.ps1` | Cache assembled prompts |
<!-- REF-OBSOLETA: scripts/utilities/prompt-cache.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Tier Config | `config/system-prompt-tiers.json` | Define hot/warm/cold tiers | | Normativa
Resolver | `scripts/utilities/normativa-resolver.ps1` | Lazy load normativas |
<!-- REF-OBSOLETA: scripts/utilities/normativa-resolver.ps1 no tiene equivalente TS (migración PS1→TS) -->

### Fase 2: Quality & Safety

| Component        | File                                            | Purpose                |
| ---------------- | ----------------------------------------------- | ---------------------- |
| Security Scanner | `scripts/utilities/prompt-security-scanner.ps1` | Detect security issues |

<!-- REF-OBSOLETA: scripts/utilities/prompt-security-scanner.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Versioning | `scripts/utilities/prompt-versioning.ps1` | Version control for prompts |
<!-- REF-OBSOLETA: scripts/utilities/prompt-versioning.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Performance Metrics | `scripts/utilities/prompt-performance-metrics.ps1` | Track tokens/latency |
<!-- REF-OBSOLETA: scripts/utilities/prompt-performance-metrics.ps1 no tiene equivalente TS (migración PS1→TS) -->

### Fase 3: Optimization

| Component   | File                                      | Purpose              |
| ----------- | ----------------------------------------- | -------------------- |
| A/B Testing | `scripts/utilities/prompt-ab-testing.ps1` | Test prompt variants |

<!-- REF-OBSOLETA: scripts/utilities/prompt-ab-testing.ps1 no tiene equivalente TS (migración PS1→TS) -->

| Model Adapter | `scripts/utilities/prompt-model-adapter.ps1` | Adapt to different models |
<!-- REF-OBSOLETA: scripts/utilities/prompt-model-adapter.ps1 no tiene equivalente TS (migración PS1→TS) -->

## Usage

```TypeScript
# Compress a prompt
npx tsx src/utilities/semantic-compression.ts -InputPath "CLAUDE.md" -OutputPath "CLAUDE.min.md" -ShowStats
<!-- REF-OBSOLETA: src/utilities/semantic-compression.ts no existe (ruta migrada o eliminada) -->

# Cache a prompt
$hash = (Get-FileHash "CLAUDE.md" -Algorithm SHA256).Hash.Substring(0,16)
npx tsx src/utilities/prompt-cache.ts -Action set -PromptHash $hash -PromptContent (Get-Content "CLAUDE.md" -Raw)
<!-- REF-OBSOLETA: src/utilities/prompt-cache.ts no existe (ruta migrada o eliminada) -->

# Check cache stats
npx tsx src/utilities/prompt-cache.ts -Action stats
<!-- REF-OBSOLETA: src/utilities/prompt-cache.ts no existe (ruta migrada o eliminada) -->

# Security scan
npx tsx src/utilities/prompt-security-scanner.ts -PromptContent (Get-Content "CLAUDE.md" -Raw)
<!-- REF-OBSOLETA: src/utilities/prompt-security-scanner.ts no existe (ruta migrada o eliminada) -->

# Version a prompt
npx tsx src/utilities/prompt-versioning.ts -Action save -PromptName "CLAUDE" -Content (Get-Content "CLAUDE.md" -Raw)
<!-- REF-OBSOLETA: src/utilities/prompt-versioning.ts no existe (ruta migrada o eliminada) -->

# Adapt to model
npx tsx src/utilities/prompt-model-adapter.ts -PromptContent (Get-Content "CLAUDE.md" -Raw) -TargetModel anthropic
<!-- REF-OBSOLETA: src/utilities/prompt-model-adapter.ts no existe (ruta migrada o eliminada) -->
```

## Results

- **Before**: 65,697 tokens
- **After**: ~2,000 tokens
- **Reduction**: 97%
