---
created: 2026-08-19 00:51:05
tags: [engram, decision]
engram_id: 2877
type: decision
---

# Released v3.8.0 — SEA build fixes + public sync + auto-update verified

**What**: Released Gentle-Vanguard v3.8.0 (Content Operations Engine) end-to-end: fixed SEA build bugs, synced public repo, created releases, verified auto-update, closed PR #159.
**Why**: Complete the COE integration (PR #159) with real 15-day launch calendar (21 jobs), homologate main with develop, and ship v3.8.0 with working .exe auto-update.
**Where**: src/build-sea.ts, build/gentle-vanguard-3.8.0.exe, releases/latest-version.json (public repo), .github/workflows/auto-update.yml
**Learned**:
1. build-sea.ts had 3 bugs: (a) compileTS didn't verify esbuild actually regenerated the bundle — silent failure reused stale bundle with VERSION 3.3.3; (b) esbuild 0.28.1 emits `var import_meta = {};` + `createRequire(import_meta.url)` which throws ERR_INVALID_ARG_VALUE inside SEA binaries — must patch to `{ url: require("url").pathToFileURL(__filename).href }`; (c) shelling out to esbuild CLI via cmd.exe corrupts Windows paths (leading-space bug) — use esbuild JS API (buildSync) directly.
2. The auto-update.yml workflow only triggers on `release: published` (no workflow_dispatch) and failed because it ran before the .exe asset upload completed — the fix is to update releases/latest-version.json manually after creating the release.
3. check-version.ts reads the release from EmmanuelOrtiz87/gentle-vanguard-public (GENTLE_VANGUARD_GH_REPO override) and finds the .exe asset — verified UP_TO_DATE|3.8.0.
4. PAT_SYNC secret expired in CI — manual sync via GH_TOKEN local works (git clone public, run src/sync-to-public.ts --skip-push, commit, push).

---
*Imported from Engram on 2026-09-06*
