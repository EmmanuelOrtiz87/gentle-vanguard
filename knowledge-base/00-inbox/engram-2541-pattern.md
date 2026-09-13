---
created: 2026-08-04 23:23:25
tags: [engram, pattern]
engram_id: 2541
type: pattern
---

# Compaction Monitoring System

**What**: Created src/compaction-monitor.ts - Context size monitoring with thresholds
**Why**: Kimi2-5 incompatible with auto-compaction; need manual monitoring
**Where**: src/compaction-monitor.ts

**Thresholds**:
- SOFT: 15,000 tokens (WARN) - Suggest manual compaction
- HARD: 25,000 tokens (CRITICAL) - Recommend session close
- MAX: 30,000 tokens (OVERFLOW) - Force action

**Usage**:

```bash
npx tsx src/compaction-monitor.ts --status  # Show status table
npx tsx src/compaction-monitor.ts --check   # JSON output
npx tsx src/compaction-monitor.ts --alert    # Alert only if threshold
```

**Configuration Required**:

```json
// opencode.json
"compaction": { "auto": false, "prune": false }

// config/context-efficiency.json
"compactionPolicy": { "enabled": false }
```

**Manual Compaction**:
Use skill context-engineering when monitor shows WARN/CRITICAL:

```bash
skill load context-engineering
```

**Learned**: Kimi2-5 via littellmott cannot handle auto-compaction. Must monitor manually and use skill-based compaction.

---
*Imported from Engram on 2026-09-06*
