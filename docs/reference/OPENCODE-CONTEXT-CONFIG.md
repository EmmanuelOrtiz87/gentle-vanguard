# OpenCode Configuration for Gentle-Vanguard

## Context Optimization Setup

This repository includes optimized OpenCode configuration to minimize token consumption.

### Files Created

1. **opencode.json** - Server/runtime configuration
2. **tui.json** - TUI-specific settings

### Key Optimizations Applied

#### 1. Compaction (CRITICAL)

```json
{
  "compaction": {
    "auto": true, // Automatic compaction enabled (default)
    "prune": true, // ✅ ACTIVATED - Removes old tool outputs
    "keep": {
      "tokens": 15000 // Keep 15K tokens of recent context
    },
    "buffer": 20000 // 20K token safety buffer
  }
}
```

**Impact**: With `prune: true`, OpenCode will automatically:

- Remove old tool call outputs (saves 40K+ tokens per operation)
- Summarize conversation history when approaching context limits
- Retain only recent 15K tokens of actual conversation

**Expected savings**: 60-80% reduction in token consumption for long sessions.

#### 2. Model Selection

Using `opencode/deepseek-v4-flash` - free tier with good performance.

#### 3. Tool Permissions

All write operations require approval (`"ask"`):

- Prevents accidental large modifications
- Gives control over token-expensive operations

### Manual Compaction

If context grows too large, manually trigger compaction:

```bash
# In TUI, run:
/compact

# Or use keybind (default: <leader>c)
```

### Expected Behavior

With these settings:

- ✅ Automatic compaction triggers before overflow
- ✅ Old tool outputs are pruned (40K+ tokens saved)
- ✅ Conversation summarized when needed
- ✅ Session can continue indefinitely

### Without This Config (Default)

- ❌ `prune: false` - Tool outputs accumulate forever
- ❌ Context grows linearly with each tool call
- ❌ Eventually hits hard overflow errors
- ❌ Need to start fresh sessions frequently

### Verification

To verify compaction is working:

1. Start a long session with multiple tool calls
2. Watch for `/compact` indicator in TUI
3. Check context percentage in sidebar
4. Should stabilize around 60-80% instead of 100%

### Troubleshooting

**If still hitting limits:**

1. Reduce `keep.tokens` to 10000
2. Increase `buffer` to 25000
3. Manually run `/compact` more frequently
4. Consider upgrading model context size

### References

- [OpenCode Compaction Docs](https://opencode.ai/v2/docs/compaction)
- [Context Management](https://deepwiki.com/sst/opencode/2.4-context-management-and-compaction)
- [Configuration Options](https://opencode.ai/docs/config/)
