# Context Optimization Guide — Gentle-Vanguard

> **Why**: Each conversation turn sends the FULL history to the LLM. The "fix" must come from the tool (opencode), not from our stack. We can only mitigate.

## The Problem

| Metric | Expected | Current Reality |
|--------|----------|-----------------|
| Avg tokens per turn | 2-5K | 37K+ (18x over) |
| Context ratio (I:O) | 5:1 | 100:1 (20x over) |
| Sessions over limit | <5% | >60% |

**Root cause**: opencode sends all conversation history with each turn. Our prompt-compression only compresses the CURRENT message, not the full history.

## What We Can Control

### ✅ Implemented in Stack

1. **prompt-compression.ts** — Compresses individual messages
2. **output-compression.ts** — Compresses assistant responses
3. **structural-compression.ts** — Compresses structured data
4. **chat-level-enforcer.ts** — Limits response length (200-4000 tokens)

### ❌ What We Cannot Control

- Total context window sent by opencode
- Conversation history accumulation
- Tool result caching between turns

## Solution Patterns

### Pattern 1: Sliding Window Truncation
```typescript
// Truncate to last N turns
const last10 = messages.slice(-10);
const summary = summarize(messages.slice(0, -10));
```

**Status**: Requires tool-level support (opencode doesn't expose this)

### Pattern 2: Summarization Middleware
```typescript
// Every 10 turns, summarize and reset
if (messages.length > 20) {
  const summary = await summarize(messages);
  messages = [system, summary, ...last5];
}
```

**Status**: Partially implemented in context-truncator.ts

### Pattern 3: Session Boundaries
```bash
# Create new session every ~15 turns
# Manual: Close "Unable to edit..." → New Session
# Expected savings: 60-80% tokens
```

**Status**: Documented recommendation

### Pattern 4: Checkpoint & Restart
```bash
# Create checkpoint before long task
npx tsx src/checkpoint-manager.ts create --label "before-long-task"

# If context grows too large, restore checkpoint and continue
npx tsx src/checkpoint-manager.ts restore --id <checkpoint-id>
```

**Status**: Fully implemented

## Current Mitigations

| Strategy | File | Status | Impact |
|----------|------|--------|--------|
| Input compression | prompt-compression.ts | ✅ | 40-60% per message |
| Output compression | output-compression.ts | ✅ | 50-70% per response |
| Structural compression | structural-compression.ts | ✅ | 30-50% data |
| Chat levels | chat-level-enforcer.ts | ✅ | Hard limits (chat-compact) |
| Context monitoring | context-truncator.ts | ✅ | Alerts at 15k tokens |
| Session warning | token-budget-guard.ts | ✅ | Alerts at 70/90% budget |

## Recommendations

### For Users

1. **Create new session** every 15-20 turns or when slow
2. **Use checkpoints** before long, multi-step tasks
3. **Watch for warnings**: "HARD LIMIT alcanzado — compactar o cerrar sesión"

### For Implementation

The real fix requires opencode/cursor/claude to implement:
- `maxContextTurns` setting
- Automatic summarization after N turns
- Conversation pruning strategies

## Until Then

Our stack provides **local optimization** of individual messages, but cannot control the **global context** that opencode sends.

**Track**: token-ingest logs now show full context analysis at session close.

---

*This is a known limitation of all current LLM IDE tools (opencode, cursor, claude-code, etc.).*
