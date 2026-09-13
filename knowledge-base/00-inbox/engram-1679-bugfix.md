---
created: 2026-07-15 00:55:37
tags: [engram, bugfix]
engram_id: 1679
type: bugfix
---

# Stack fixes: engram-auto-sync guard + opencode-config-validate allowlist + artifact cleanup

**What**: Fixed 2 runtime failures + cleaned 7 accidentally tracked artifacts

**Why**: engram-auto-sync crashed with "Verification after sync failed" because .engram-data/engram.db doesn't exist and syncChecksums() had no guard. opencode-config-validate failed because $validProps had 'reference' (singular) but missing 'references' (plural) which is a valid OpenCode property. 7 files were tracked despite being in .gitignore (.engram-data/, .runtime/).

**Where**: src/engram-auto-sync.ts:115-119 (added existsSync guard), scripts/utilities/config/validate-opencode-config.ps1:14 (added 'references' to allowlist), .codex/config.toml, .engram/checksums.sha256, .windsurf/config.json, .runtime/telemetry/ (deletions)

**Learned**:
- syncChecksums() must guard against missing DB same as checkSynchronization() does
- OpenCode's 'references' (plural) is a legitimate config property, not a typo of 'reference'
- .runtime/ is gitignored but files can still be accidentally committed with git add -f
- auto-code-review.ps1 errors on deleted staged files (non-blocking warnings)
- Prettier pre-commit check catches .windsurf/config.json formatting — always run prettier before commit

---
*Imported from Engram on 2026-09-06*
