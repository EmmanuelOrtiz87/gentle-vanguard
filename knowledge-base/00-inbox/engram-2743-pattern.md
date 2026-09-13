---
created: 2026-08-11 00:58:43
tags: [engram, pattern]
engram_id: 2743
type: pattern
---

# Presentation info-triggers added to 4 HTML pages + i18n keys

**What**: Added 42 `info-trigger` elements across 4 presentation pages with 36 new `tip_*` i18n keys (en + es). autonomy.html: 18 (12 executive systems + Executive Overview header + 4 performance cards + diagram header). dashboard.html: 12 (section 1 header, 7 section cards, alerts header, i18n header, watchdog card, hero budget). memory-knowledge.html: 6 (Engram, CodeGraph, Graphify, Nexus DB, ML Embeddings, Knowledge Base Manager). patterns-conventions.html: 6 (hero brand, Karpathy, SDD lifecycle, slop detection, architecture patterns, dev standards/docs).

**Why**: User asked to add info-triggers (hover "i" badges) to the remaining presentation pages with i18n title keys.

**Where**: docs/presentations/{autonomy,dashboard,memory-knowledge,patterns-conventions}.html, docs/presentations/assets/js/i18n.js

**Learned**:
1. Prettier gotcha: i18n.js and the 4 HTML pages were already prettier-non-compliant before edits (pre-existing repo state). Only i18n.js was broken by my edits; running `pnpm prettier --write` on each file reformats ONLY my additions (verified via diff hunks) — safe to run on HTML pages even with pre-existing non-compliance.
2. Key coverage must be verified with `(?m)^\s*key:` multiline regex on both en and es blocks — PowerShell `-match` without `(?m)` anchor fails on substring blocks.
3. i18n.js has 3 sections: en, es, 'pt-BR' (pt-BR may not have all keys — falls back to en/es).

---
*Imported from Engram on 2026-09-06*
