---
created: 2026-07-12 06:32:40
tags: [engram, bugfix]
engram_id: 1590
type: bugfix
---

# Comprehensive codebase hardening — ESM, broken refs, cascading duplication

**What**: Comprehensive codebase hardening — fixed all broken PS1 references, ESM require() calls, MCP DEP0190 warning, cascading duplication corruption, and updated 8 test files to reference TS versions

**Why**: Multiple systemic issues from Phase 1 cleanup: deleted PS1 scripts still referenced by tests/detectors, require() calls in ESM modules causing crashes, shell:true with args triggering Node.js deprecation warnings, and cascading duplication corruption in PS1 files

**Where**:
- src/engram-integrity-check.ts, event-sourcing.ts, tracing-instrument.ts, correction-rules-engine.ts: require() → ESM imports
- src/mcp-gateway.ts: shell:true with args → concatenated command string
- 8 test files under tests/unit/ and tests/integration/: session-autostart.ps1 → session-autostart.ts
- detect-tool.ps1, bootstrap.ps1, token-budget-guard.ps1: broken refs to deleted scripts
- token-usage-auto.ps1: 1221→68 lines (cascading duplication reconstruction)
- generate-management-report.ps1: 859→215 lines (cascading duplication reconstruction)
- build/loader.ps1: deprecated (dead code)

**Learned**: The cascading duplication pattern is: `catch { Write-Debug "Exception caught: param(` or `catch { Write-Debug "Exception caught: #` — the unclosed string literal swallows the entire file as a string, creating fractal duplication. The file should be reconstructed by keeping: (1) the clean header/param section before the first corruption, and (2) the unique logic section after the last corruption boundary. The duplicated sections between corruptions are pure copies.

**Verified**:
- Engram integrity: 5/5 PASS (was failing with require error)
- MCP gateway: no DEP0190 warnings
- TypeScript typecheck: clean
- Config tests: 21/21 pass
- Pipeline: 30/30 steps OK
- Commit: 464cfcea (18 files, +113 -1898 lines)

---
*Imported from Engram on 2026-09-06*
