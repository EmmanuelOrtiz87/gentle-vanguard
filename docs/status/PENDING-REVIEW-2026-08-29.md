# Pending Review - 2026-08-29

**Scope:** improvement and documentation tasks to resume after session start.
**Status:** verified snapshot, not a historical backlog dump.
**Primary sources:** git status, `docs/analytics/PENDING.md`, `docs/analytics/PROGRESS.md`,
`docs/analysis/PENDING-AUDIT.md`, `docs/tasks/`, `docs/backlog/items.json`, and presentation shell
checks.

## Current Baseline

- The stack session starts through `npm run session:autostart:detached`.
- Current branch is `main`, ahead of `origin/main` by 68 commits.
- Working tree already has local modifications in token/report/config files:
  - `assets/tokens.css`
  - `assets/tokens.json`
  - `docs/sessions/metrics/monthly/token-summary-2026-07.json`
  - `docs/sessions/metrics/monthly/token-summary-2026-07.md`
  - `opencode.json`
  - `reports/coverage-summary.json`
  - `reports/optimization/optimization-2026-08-29.json`
- No active Codex sibling tasks were found besides the current task.

## Closed Or Obsolete Backlog

- `docs/analytics/PENDING.md` is closed: P0, P1, P2, and P3 are marked 100% complete.
- `docs/tasks/PENDING-TASKS.md` is archived and should not be used as active backlog.
- `docs/backlog/items.json` contains only `done`, `resolved`, `deferred`, or `wont_fix` items.
- The old presentation backlog item "add CMS navigation link" is resolved: checked presentation HTML
  pages already link to `resources-index.html`.
- The old "CMS persistence" item is partly resolved: `docs/presentations/assets/js/asset-manager.js`
  provides IndexedDB-backed asset persistence and migration from localStorage.
- The old "unified export" item is partly resolved: `docs/presentations/assets/js/cms-exporter.js`
  exports project assets to ZIP and `resources-index.html` wires the exporter.

## Active Pending Work

### P0 - Make Pending State Canonical

Status: resumed in this session.

Problem: `docs/analysis/PENDING-AUDIT.md` is dated 2026-08-10 and now mixes live needs with resolved
items.

Actions taken:

- Added this current status note to separate:
  - verified active work,
  - resolved historical tasks,
  - future/product ideas.
- Linked this review from `docs/status/README.md` and the canonical status note.

Next actions:

- Keep `docs/analysis/PENDING-AUDIT.md` as historical unless a later cleanup archives it.

Acceptance:

- A reader can identify the live backlog without reading old reports.
- Resolved Analytics and presentation navigation work are not reintroduced as active tasks.

### P1 - Presentation Theme Toggle Wiring

Status: resumed in this session.

Problem found: `docs/presentations/assets/js/theme-toggle.js` existed, but no presentation HTML
loaded it, and the module returned early when no `#theme-toggle` button already existed.

Actions taken:

- `assets/js/gv.js` now lazy-loads `assets/js/theme-toggle.js`.
- `theme-toggle.js` now creates the toggle button when the page has a compatible `.navbar-nav`.
- `contract-viewer.html`, `image-studio.html`, `social-post.html`, and `video-studio.html` now load
  `assets/js/gv.js`.

Acceptance:

- Presentation pages expose a working light/dark toggle.
- Preference persists in `localStorage`.
- The change does not break the existing `gv.js` interaction layer.

Verification:

- `npm run presentations:validate -- --main` passes: 14 PASS / 0 FAIL.

### P1 - CMS Export And Persistence Verification

Status: resumed in this session.

Problem: persistence/export features exist, but the old audit predates them and there is no current
verification note for the full CMS flow.

Actions taken:

- Confirmed the exporter and asset manager are wired from `resources-index.html`.
- Fixed `AssetManager.cleanup()` by adding `getAllAssets()` and using it instead of
  `getAssetsByType('all')`.

Next actions:

- Verify generated image/video/social/contract data paths still match the exporter keys:
  - `imageStudioHistory`
  - `videoStudioProjects`
  - `socialPosts`
  - `customContracts`
- Add or update a lightweight CMS verification note after testing.

Acceptance:

- Export and persistence behavior is documented from current code, not from the August 10 audit.
- Any confirmed bug is either fixed or tracked in the active backlog.

Verification:

- `node --check docs/presentations/assets/js/asset-manager.js` passes.

### P2 - Presentation Coverage Gaps

Problem found: some newer HTML pages were not loaded through the same shared interaction script path
as the main presentation set.

Status: shell coverage gap resumed in this session.

Actions taken:

- Added `assets/js/gv.js?v=2.1` to the five pages that failed validation with `FALTA gv.js`.

Next actions:

- Keep the remaining full-validation i18n/content failures as a separate documentation cleanup lane.

Acceptance:

- Presentation shell coverage is intentional and documented.

### P2 - Gentle-AI v2.4.0 Alignment

Problem: `.session/gentle-ai-suggestions.md` lists high-priority alignment items.

Next actions:

- Review security improvement deltas.
- Review review-process deltas and decide whether `.opencode/skills/code-review-and-quality/` needs
  updates.
- Verify memory/persistence alignment through Engram update flow.
- Review CLI changes only if they map to existing stack scripts.

Acceptance:

- Each suggestion is either applied, explicitly deferred, or converted to a backlog item with owner
  and verification path.

## Recommended Resume Order

1. Finish canonical pending-state documentation and link it from status docs.
2. Clean up remaining presentation i18n/content validation failures.
3. Verify CMS persistence/export paths end-to-end in browser and write the CMS verification note.
4. Triage Gentle-AI v2.4.0 suggestions into applied/deferred/backlog.

## Verification Commands Used

```bash
npm run session:autostart:detached
git status --short --branch
rg --files docs/presentations
npm run backlog:list
npm run presentations:validate
npm run presentations:validate -- --main
node --check docs/presentations/assets/js/asset-manager.js
node --check docs/presentations/assets/js/gv.js
node --check docs/presentations/assets/js/theme-toggle.js
npm run graphify -- update .
```
