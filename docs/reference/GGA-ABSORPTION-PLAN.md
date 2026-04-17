# GGA Native Integration - Absorption Plan

## Objective
Absorb all Gentleman Guardian Angel (GGA) functionalities into Foundation as native capabilities.

## GGA Core Capabilities

### Already in Foundation (Absorbed)
| GGA Feature | Foundation Equivalent | Status |
|------------|----------------------|--------|
| Pre-commit hook | hooks/pre-commit.ps1 | ✅ Partial |
| Code review | code-review-orchestrator-skill | ✅ Partial (7 dimensions) |
| Conventional commits | github-pr-skill | ✅ Partial |
| Agent instructions | AGENTS.md | ✅ Native |

### To Migrate (Gaps)
| GGA Feature | Description | Priority |
|------------|-------------|----------|
| Multi-provider support | Claude, OpenAI, Ollama, Gemini, GitHub Models | HIGH |
| Smart caching | Skip unchanged files across commits | HIGH |
| PR review mode | Full PR review with diffs | HIGH |
| Config hierarchy | Env > Project > Global precedence | HIGH |
| Commit msg validation | Hook for conventional commits | MEDIUM |
| Strict mode | Fail on ambiguous AI responses | MEDIUM |
| Shell standards | bashcheck standards | LOW |

## Migration Strategy

### Phase 1: Core Script (HIGH)
Create `invoke-ai-review.ps1` with:
- Multi-provider AI calls
- Smart file caching
- Config hierarchy (env/project/global)
- Strict JSON mode for automation

### Phase 2: PR Mode (HIGH)
Extend to:
- Fetch PR diffs
- Review all changed files
- Generate PR comment

### Phase 3: Commit Validation (MEDIUM)
Add:
- commit-msg hook integration
- Conventional commit regex validation
- Issue reference checking

### Phase 4: Skills Migration (LOW)
Migrate GGA skills:
- commit-hygiene
- docs-alignment
- shellcheck-standards
- testing-coverage

## File Structure

```
workspace-foundation/
├── scripts/
│   └── utilities/
│       ├── invoke-ai-review.ps1    # NEW: Native GGA replacement
│       └── invoke-judgment.ps1      # Existing
├── hooks/
│   ├── pre-commit-gga.ps1          # Migrate from GGA
│   ├── pre-commit-review.ps1       # Existing
│   └── pre-tool-format.ps1         # Existing
├── skills/
│   ├── commit-hygiene-skill/      # NEW: From GGA
│   ├── docs-alignment-skill/       # NEW: From GGA
│   ├── shellcheck-standards/       # NEW: From GGA
│   └── testing-coverage-skill/      # NEW: From GGA
├── config/
│   └── ai-review.json              # NEW: Config for native review
└── docs/
    └── guides/
        └── AI-REVIEW-GUIDE.md      # NEW: Documentation
```

## Configuration

### New config: `config/ai-review.json`
```json
{
  "provider": "openai",
  "filePatterns": ["*.ps1", "*.ts", "*.js", "*.py"],
  "excludePatterns": ["*.test.ps1", "*.spec.ts"],
  "rulesFile": "AGENTS.md",
  "strictMode": true,
  "timeout": 300,
  "cache": {
    "enabled": true,
    "ttl": 86400
  },
  "providers": {
    "openai": { "envVar": "OPENAI_API_KEY" },
    "anthropic": { "envVar": "ANTHROPIC_API_KEY" },
    "ollama": { "endpoint": "http://localhost:11434" }
  }
}
```

## Commands

```powershell
# Initialize review config
.\scripts\utilities\wf.ps1 review init

# Run review (like gga run)
.\scripts\utilities\wf.ps1 review run

# Run with PR mode (like gga run --pr-mode)
.\scripts\utilities\wf.ps1 review run --pr-mode

# Install hooks
.\scripts\utilities\wf.ps1 review install

# Config
.\scripts\utilities\wf.ps1 review config

# Cache management
.\scripts\utilities\wf.ps1 review cache status
.\scripts\utilities\wf.ps1 review cache clear
```

## Provider Support

| Provider | Env Variable | Status |
|----------|--------------|--------|
| Claude | ANTHROPIC_API_KEY | Planned |
| OpenAI | OPENAI_API_KEY | Planned |
| Gemini | GEMINI_API_KEY | Planned |
| Ollama | None (local) | Planned |
| GitHub Models | GH_TOKEN | Planned |
| AWS Bedrock | AWS_* | Planned |

## Coexistence

After absorption:
- GGA remains available as standalone tool
- Foundation uses native implementation
- Users can choose: GGA external or Foundation native
- Migration is seamless: same commands, better integration
