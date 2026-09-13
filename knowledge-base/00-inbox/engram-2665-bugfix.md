---
created: 2026-08-08 18:25:25
tags: [engram, bugfix]
engram_id: 2665
type: bugfix
---

# Bedrock Compatibility - Fixes Applied

**What**: Fixed Bedrock compatibility errors for kimi-2.5 and claude-haiku-4-5 models

**Why**: Errors when using Kilocode in VSCode with Bedrock provider:
1. "provider: Extra inputs are not permitted" (claude-haiku-4-5)
2. "bedrock does not support parameters: ['reasoning_effort']" (kimi-2.5)

**Where**:
- `opencode.json` - Added litellm_settings.drop_params to 15 agents (ops-agent through sia-agent)
- `.runtime/metrics.json` - Reset token counters to 0
- `config/token-budget-guard.json` - Verified config correct

**Fix Applied**:
- Added `"litellm_settings": { "drop_params": true }` to ALL 21 agents
- Only first 6 had it before, causing errors on delegation to other agents
- Token budget now shows 0/5M daily, 0/3M session (was 553%)

**Learned**:
- `drop_params: true` automatically discards unsupported params per provider
- Makes code provider-agnostic (Bedrock, OpenAI, Anthropic, etc.)
- Existing guards: correction-rules.json, model-health.json auto-detect and fix
- Health status: 88 PASS / 1 WARN / 0 FAIL
- Watchtower: All 89 checks passed

---
*Imported from Engram on 2026-09-06*
