# System Prompt Optimization Framework

## Overview

Framework completo para optimización de system prompts con reducción de 97% de tokens.

## Components

### Fase 1: Core Infrastructure

| Component            | File                                         | Purpose                         |
| -------------------- | -------------------------------------------- | ------------------------------- |
| Semantic Compression | `scripts/utilities/semantic-compression.ps1` | Reduce tokens via abbreviations |
| Prompt Caching       | `scripts/utilities/prompt-cache.ps1`         | Cache assembled prompts         |
| Tier Config          | `config/system-prompt-tiers.json`            | Define hot/warm/cold tiers      |
| Normativa Resolver   | `scripts/utilities/normativa-resolver.ps1`   | Lazy load normativas            |

### Fase 2: Quality & Safety

| Component           | File                                               | Purpose                     |
| ------------------- | -------------------------------------------------- | --------------------------- |
| Security Scanner    | `scripts/utilities/prompt-security-scanner.ps1`    | Detect security issues      |
| Versioning          | `scripts/utilities/prompt-versioning.ps1`          | Version control for prompts |
| Performance Metrics | `scripts/utilities/prompt-performance-metrics.ps1` | Track tokens/latency        |

### Fase 3: Optimization

| Component     | File                                         | Purpose                   |
| ------------- | -------------------------------------------- | ------------------------- |
| A/B Testing   | `scripts/utilities/prompt-ab-testing.ps1`    | Test prompt variants      |
| Model Adapter | `scripts/utilities/prompt-model-adapter.ps1` | Adapt to different models |

## Usage

```TypeScript
# Compress a prompt
npx tsx src/utilities/semantic-compression.ts -InputPath "CLAUDE.md" -OutputPath "CLAUDE.min.md" -ShowStats

# Cache a prompt
$hash = (Get-FileHash "CLAUDE.md" -Algorithm SHA256).Hash.Substring(0,16)
npx tsx src/utilities/prompt-cache.ts -Action set -PromptHash $hash -PromptContent (Get-Content "CLAUDE.md" -Raw)

# Check cache stats
npx tsx src/utilities/prompt-cache.ts -Action stats

# Security scan
npx tsx src/utilities/prompt-security-scanner.ts -PromptContent (Get-Content "CLAUDE.md" -Raw)

# Version a prompt
npx tsx src/utilities/prompt-versioning.ts -Action save -PromptName "CLAUDE" -Content (Get-Content "CLAUDE.md" -Raw)

# Adapt to model
npx tsx src/utilities/prompt-model-adapter.ts -PromptContent (Get-Content "CLAUDE.md" -Raw) -TargetModel anthropic
```

## Results

- **Before**: 65,697 tokens
- **After**: ~2,000 tokens
- **Reduction**: 97%
