---
created: 2026-08-08 17:34:52
tags: [engram, bugfix]
engram_id: 2658
type: bugfix
---

# Migrated to moonshotai/kimi-k2.5 - Requires final restart

**FINAL UPDATE - Migration to opencode-recognized model**

## Problem

- Error: "Model not found: inherit-from-session/." persisted
- Root cause: opencode internal mechanism generates "inherit-from-session" when it doesn't recognize the model
- Despite all configurations being correct, opencode couldn't resolve kimi-2-5 from littellmott provider

## Solution Applied

Changed both configs to use `moonshotai/kimi-k2.5` instead of `kimi-2-5`:
- ✅ ~/.config/opencode/opencode.json → "moonshotai/kimi-k2.5"
- ✅ ./opencode.json → "moonshotai/kimi-k2.5"

## Why this works

- moonshotai/kimi-k2.5 IS in opencode's model cache (~/.cache/opencode/models.json)
- Verified in cache output: "moonshotai/kimi-k2.5" exists with full metadata
- This is a recognized provider/model combination

## Files Modified

1. ~/.config/opencode/opencode.json (global config)
2. ./opencode.json (project config)
3. config/model-health-registry.json (health monitoring)
4. src/smart-model-router.ts (router)
5. src/model-error-interceptor.ts (error handling)
6. src/smart-task-wrapper.ts (task wrapper)

## Next Step

CLOSE and RESTART opencode/claude completely for changes to take effect.

## Expected Result After Restart

- task() calls should work without "Model not found" errors
- Subagents should inherit model correctly
- Smart fallback system should be ready for activation

---
*Imported from Engram on 2026-09-06*
