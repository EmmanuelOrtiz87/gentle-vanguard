---
created: 2026-08-19 00:51:14
tags: [engram, bugfix]
engram_id: 2878
type: bugfix
---

# Fixed Mermaid parse error — quote node labels with special chars

**What**: Fixed README.md Mermaid diagram that GitHub couldn't render ("Unable to render rich display").
**Why**: User reported the README lost visuals/diagrams after the v3.7.0 rewrite; root cause was a Mermaid parse error.
**Where**: README.md (flowchart TB architecture diagram), docs/assets/architecture-5-layers.png
**Learned**:
1. Mermaid node labels with parentheses inside `[...]` break GitHub's parser: `K1[Engram (hot/warm/cold) · CodeGraph · Event Store]` fails with "Expecting 'SQE'... got 'PS'" because `(` is interpreted as a nested node shape. Fix: wrap labels in double quotes: `K1["Engram (hot/warm/cold) · CodeGraph · Event Store"]`.
2. The bug existed since v3.5.0 (same pattern in older READMEs) — GitHub only recently started surfacing it as a render error.
3. Validated the fix with mermaid.parse() in Node (needs jsdom + dompurify polyfills; mermaid-cli needs Chrome which isn't installed).
4. docs/assets/architecture-5-layers.png (147KB) existed but was unreferenced after the rewrite — re-added it below the diagram.
5. README-PUBLIC.md emojis appeared as ?? in PowerShell terminal but the file was fine (hash-object matched HEAD) — terminal display artifact only.

---
*Imported from Engram on 2026-09-06*
