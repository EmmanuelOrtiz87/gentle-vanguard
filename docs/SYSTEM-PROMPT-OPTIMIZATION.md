# System Prompt Optimization Framework

## Overview

Framework completo para optimización de system prompts con reducción de 97% de tokens.

## Components

### Fase 1: Core Infrastructure

| Component | File | Purpose |
|-----------|------|---------|
| Semantic Compression | `scripts/utilities/semantic-compression.ps1` | Reduce tokens via abbreviations |
| Prompt Caching | `scripts/utilities/prompt-cache.ps1` | Cache assembled prompts |
| Tier Config | `config/system-prompt-tiers.json` | Define hot/warm/cold tiers |
| Normativa Resolver | `scripts/utilities/normativa-resolver.ps1` | Lazy load normativas |

### Fase 2: Quality & Safety

| Component | File | Purpose |
|-----------|------|---------|
| Security Scanner | `scripts/utilities/prompt-security-scanner.ps1` | Detect security issues |
| Versioning | `scripts/utilities/prompt-versioning.ps1` | Version control for prompts |
| Performance Metrics | `scripts/utilities/prompt-performance-metrics.ps1` | Track tokens/latency |

### Fase 3: Optimization

| Component | File | Purpose |
|-----------|------|---------|
| A/B Testing | `scripts/utilities/prompt-ab-testing.ps1` | Test prompt variants |
| Model Adapter | `scripts/utilities/prompt-model-adapter.ps1` | Adapt to different models |

## Usage

```powershell
# Compress a prompt
pwsh -File scripts/utilities/semantic-compression.ps1 -InputPath "CLAUDE.md" -OutputPath "CLAUDE.min.md" -ShowStats

# Cache a prompt
$hash = (Get-FileHash "CLAUDE.md" -Algorithm SHA256).Hash.Substring(0,16)
pwsh -File scripts/utilities/prompt-cache.ps1 -Action set -PromptHash $hash -PromptContent (Get-Content "CLAUDE.md" -Raw)

# Check cache stats
pwsh -File scripts/utilities/prompt-cache.ps1 -Action stats

# Security scan
pwsh -File scripts/utilities/prompt-security-scanner.ps1 -PromptContent (Get-Content "CLAUDE.md" -Raw)

# Version a prompt
pwsh -File scripts/utilities/prompt-versioning.ps1 -Action save -PromptName "CLAUDE" -Content (Get-Content "CLAUDE.md" -Raw)

# Adapt to model
pwsh -File scripts/utilities/prompt-model-adapter.ps1 -PromptContent (Get-Content "CLAUDE.md" -Raw) -TargetModel anthropic
```

## Results

- **Before**: 65,697 tokens
- **After**: ~2,000 tokens
- **Reduction**: 97%
