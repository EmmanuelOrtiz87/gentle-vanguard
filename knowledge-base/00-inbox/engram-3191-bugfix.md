---
created: 2026-08-27 18:35:12
tags: [engram, bugfix]
engram_id: 3191
type: bugfix
---

# Fixed CLI Guard in guardrail-orchestrator (Windows pathToFileURL)

**What**: Fixed the CLI guard in `src/guardrail-orchestrator.ts` — the broken pattern `import.meta.url === \`file://${process.argv[1]}\`` never matched on Windows, so `runCli()` never executed (exit 0 but no output). Changed to `import.meta.url === pathToFileURL(process.argv[1]).href` (imported `pathToFileURL` from 'url').
**Why**: The stack documents this exact broken pattern as the "CLI Guard" anti-regression check (see `src/auto-url-fix.ts`). On Windows, `process.argv[1]` is `C:\...` but `import.meta.url` is `file:///C:/...`, so they never match and the CLI silently does nothing.
**Where**: src/guardrail-orchestrator.ts (import + line ~505)
**Learned**: ALWAYS use `pathToFileURL(process.argv[1]).href` for CLI guards, never string interpolation `file://${process.argv[1]}`. This is the same pattern used by anti-loop-guard and 30+ other stack CLIs. Verified:`decide "ECONNREFUSED"` → network/retry, `classify "prompt injection detected"` → security, `stats` → learning output. Commit b0dff835.

---
*Imported from Engram on 2026-09-06*
