---
created: 2026-08-09 00:51:07
tags: [engram, decision]
engram_id: 2677
type: decision
---

# SDD Subagent Model Inheritance - Root Cause Found

**What**: Discovered that model inheritance via `inherit_model: true` does NOT work in OpenCode framework. All 4 SDD subagents (sdd-explore, sdd-design, sdd-apply, sdd-verify) fail with "Model not found: inherit-from-session" when using `inherit_model: true`.

**Why**: The OpenCode framework passes literal string "inherit-from-session" as the model name to subagents instead of resolving the actual model from the orchestrator. This is a framework limitation, not a configuration issue.

**Where**:
- `.opencode/agents/sdd-*.md` - Reverted to explicit `model:` instead of `inherit_model:`
- `opencode.json` - Removed `no_inherit_model: true` from sdd-apply (was incorrectly set)
- All subagents now use explicit model: `opencode/deepseek-v4-flash-free`

**Learned**:
- Model inheritance with `inherit_model: true` is NOT supported by OpenCode framework
- Must use explicit `model:` in subagent frontmatter
- Steps allocation via `adaptive-steps.ts` works correctly (38, 30, 52, 36 steps respectively)
- Health check: 88 PASS, 2 WARN, 0 FAIL
- TypeScript and lint pass (0 errors)

---
*Imported from Engram on 2026-09-06*
