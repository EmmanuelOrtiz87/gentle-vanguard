---
created: 2026-08-29 07:16:35
tags: [engram, architecture]
engram_id: 3236
type: architecture
---

# Humanizer split into per-domain modules (F2.5)

**What**: Split `src/humanize/humanizer.ts` (~1114 lines) into a `src/humanize/humanizer/` directory of 5 per-domain modules, keeping `humanizer.ts` as a thin barrel re-exporting everything. Zero behavior changes.
**Why**: Mechanical refactor (F2.5) to reduce the monolithic file.
**Where**:
- `src/humanize/humanizer/data.ts` (450) — Tone type + all data constants (GENERIC_PHRASES, DISCOURSE_ADVERBS, FORMAL_TRANSITIONS, TRANSITION_WORDS, HEDGES, PERSONAL_MARKERS, CONTRACTION_MAP, TONE_CONTRACTION_PHRASES, FILLER_REPLACEMENTS, TRANSITION_VARIETY, SENTENCE_INITIAL_ADVERBS, PASSIVE_RE, IRREGULAR_PAST)
- `src/humanize/humanizer/metrics.ts` (248) — TextMetrics, clamp/round/mean/stdDev, MaskedText/maskCode/restoreCode, splitSentences/wordCount/countMatches/countContractions, computeMetrics/computeAiScore/computeVariety/detectVoice
- `src/humanize/humanizer/patterns.ts` (115) — PatternMatch, activeVerb/objectCase, PASSIVE_BY_RE, buildPatterns
- `src/humanize/humanizer/transform.ts` (159) — HumanizeOptions, TONE_INDEX, replacePhrases/varyTransitions/convertPassiveToActive/applyContractions/humanizeSentenceInitialAdverbs/splitLongSentences, humanizeText
- `src/humanize/humanizer/analyze.ts` (145) — AnalysisResult, HumanizationScore, analyzeText, buildSuggestions, scoreHumanization
- `src/humanize/humanizer.ts` (37) — barrel: `export * from './humanizer/data.js'` etc. + top doc comment
**Learned**:
- Dependency DAG is data → metrics → patterns → transform → analyze (no cycles). To avoid a metrics↔patterns cycle, `PASSIVE_RE` was placed in data.ts (not patterns.ts as the task suggested) because computeMetrics (metrics) uses PASSIVE_RE while buildPatterns (patterns) uses countContractions/countMatches (metrics).
- Importers unchanged: test uses `../../src/humanize/humanizer.ts` (with .ts), CLI uses `./humanizer.js` (with .js). Barrel uses `.js` specifiers (TS5097-safe).
- Prettier reformatted data.ts/metrics.ts (line-wrapping only, no semantic change).
- NOTE: repo has a PRE-EXISTING unrelated in-progress refactor `src/tokens/token-ingest.ts` → `src/tokens/token-ingest/` that causes `npx tsc --noEmit` to fail with TS2459/TS2304 errors. These are NOT caused by the humanizer work; humanizer files produce zero tsc errors.

---
*Imported from Engram on 2026-09-06*
