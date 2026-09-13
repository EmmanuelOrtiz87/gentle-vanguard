---
created: 2026-08-13 05:09:42
tags: [engram, bugfix]
engram_id: 2793
type: bugfix
---

# CRITICAL: Root cause massive token consumption (722M tokens)

**What**: Identified catastrophic token consumption in the stack. Nexus shows 722M total input tokens vs 7M output tokens (100:1 ratio - should be ~5:1). Top session consumed 64M input tokens alone.

**Why**: Multiple system failures:
1. **Context accumulation**: No truncation/sliding window for conversation history - each turn sends full context
2. **Orquestrator consumes 95.66%**: Subagents only 4.34% - indicates context is not being managed between turns
3. **Zero compression savings**: prompt-compression.ts exists but logs show `0 ahorros compresión`
4. **Cache writes without reads**: 1.3B cache_read tokens exist but they're not reducing input tokens effectively

**Root Cause**: The opencode tool (or our pre-processing) is not truncating conversation history. Each assistant/user message exchange adds to context exponentially.

**Where**:
- token_transactions table shows 394 sessions, top 15 sessions >15M input each
- All sessions are agent='orchestrator', not subagents
- No evidence of sliding window, context compaction, or automatic truncation

**Evidence**:
- ses_057428b52ffej0gThqwdp2qJzr: 64M input / 465 transactions = 138K avg per turn
- ses_032ab08e0ffeKQlGiaWDFdxsfc: 49.6M input / 341 transactions = 145K avg per turn
- Ratio 100:1 should be 5:1 means context grows ~20x larger than expected

**Fix Required**:
1. Implement hard limit on context window (e.g., last 10 turns / 8000 tokens)
2. Activate prompt compression pipeline (currently installed but not saving tokens)
3. Enable auto-compaction triggers
4. Add chat-level enforcement (chat-compact mode logs show zero compression)

---
*Imported from Engram on 2026-09-06*
