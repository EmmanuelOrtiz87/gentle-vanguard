---
created: 2026-07-28 05:47:39
tags: [engram, bugfix]
engram_id: 2148
type: bugfix
---

# Fixed npm warnings — removed deprecated overrides from .npmrc

**What**: Eliminated the persistent "npm warn Unknown project config overrides.@hono/node-server" and "overrides.brace-expansion" warnings that appeared on every npm/pnpm/tsc command.

**Why**: The `.npmrc` file at the project root contained `overrides.@hono/node-server=">=2.0.5"` and `overrides.brace-expansion=">=5.0.8"` in a deprecated format that npm v11 no longer supports. These overrides were also duplicated in `pnpm-workspace.yaml` (the correct location for pnpm v11).

**Where**:
- `.npmrc` — removed the 2 override lines, replaced with comment explaining they moved to pnpm-workspace.yaml
- `pnpm-workspace.yaml` — overrides already configured correctly (from previous fix)

**Learned**: npm v11.15 warns about "Unknown project config" when `.npmrc` contains `overrides.KEY="value"` format. In pnpm v11, all overrides go in `pnpm-workspace.yaml` under both `overrides` and `resolutions` keys. The `.npmrc` file should not contain any override directives if using pnpm.

---
*Imported from Engram on 2026-09-06*
