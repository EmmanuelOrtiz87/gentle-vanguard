---
created: 2026-08-11 00:19:56
tags: [engram, decision]
engram_id: 2738
type: decision
---

# GGA (Guardian Angel) - AI Provider Switcher Implementation

**What**: Implemented GGA (Guardian Angel) - AI Provider Switcher system inspired by gentle-ai's GGA component

**Why**: Subagents were failing with "Free usage exceeded, subscribe to Go" errors without automatic fallback mechanism. The [INHERITED_MODEL_CONFIG] approach didn't work with OpenCode's native task() system.

**Where**:
- Core: src/gga.ts (697 lines)
- Wrapper: src/orchestrator-task-wrapper.ts
- Docs: docs/gga-system.md
- Tests: tests/gga-comprehensive.test.ts

**Learned**:
- gentle-ai uses GGA (Gentleman Guardian Angel) component for provider switching
- Windows spawn() needs shell:true for npx commands
- Must avoid duplicate exports in TypeScript
- State persistence in .runtime/gga-state.json works well

**Architecture**:
- Orchestrator (kimi-2-5) → orchestrator-task-wrapper.ts → GGA → Agent delegator
- Fallback chain: kimi-2-5 → claude-haiku-4-5 → opencode/deepseek-v4-flash-free → ollama local

**Commands**:

```bash
npm run gga:status     # Check provider status
npm run gga:reset      # Reset exhausted providers
npm run gga:delegate   # Delegate with auto-fallback
```

**Integration**: Replace `import { task } from 'opencode'` with `import { task } from './orchestrator-task-wrapper.js'`

---
*Imported from Engram on 2026-09-06*
