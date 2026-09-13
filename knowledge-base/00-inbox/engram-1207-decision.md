---
created: 2026-05-29 03:57:31
tags: [engram, decision]
engram_id: 1207
type: decision
---

# pnpm --ignore-scripts policy

**What**: Adopted pnpm as exclusive package manager with mandatory --ignore-scripts flag. Created rules/NORMATIVA-PNPM-SECURITY.md with 5 hard rules. package.json declares engines.pnpm >= 11.0.0, packageManager: pnpm@11.1.1. All npm artifacts (package-lock.json) removed from repo.

**Why**: Supply-chain attacks via postinstall scripts are a known vector. pnpm is faster, disk-efficient, and --ignore-scripts prevents arbitrary code execution during dependency installation.

**Where**: rules/NORMATIVA-PNPM-SECURITY.md, package.json, opencode.json validation scripts

**Learned**:
- pnpm v11.1.1 available and working
- All devDependencies installed cleanly with --ignore-scripts
- build:mcp script added to postinstall but NOT auto-executed (postinstall disabled by --ignore-scripts on future installs). Must run explicitly: pnpm build:mcp

---
*Imported from Engram on 2026-09-06*
