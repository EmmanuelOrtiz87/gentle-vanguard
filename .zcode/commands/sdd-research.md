---
name: sdd-research
description: Run the SDD research lane — versioned external-evidence artifact bound to an SDD change (search + BM25 grading, persisted to .sdd/<feature>/RESEARCH/)
argument-hint: <feature> :: <question1; question2; ...>
---

Research lane for SDD case "$ARGUMENTS":

1. Parse arguments as `<feature> :: <questions>` (questions `;`-separated).
   The feature MUST already exist under `.sdd/<feature>/` (created by
   INIT/EXPLORE) — the lane is fail-closed without a case.
2. Run the deterministic base:
   `npm run sdd:research -- run -f <feature> -q "<questions>" --deep`
   (uses the stack web-crawler + CRAG BM25 grader; no LLM, reproducible).
3. Read the generated artifact (`.sdd/<feature>/RESEARCH/artifact.md`) and
   FILL the agent-layer scaffolds: `## Mapeo claim → fuente` (each claim the
   proposal will use must cite a source URL from the artifact) and
   `## Contradicciones` (conflicting sources and how they are resolved).
   Questions flagged `⚠️ baja confianza` must be resolved or explicitly
   downgraded before PROPOSE.
4. Verify with `npm run sdd:research -- show -f <feature>`.

The PROPOSE phase (sdd-pipeline) automatically surfaces the research summary
in its artifact. Non-authoritative product choices stay in the artifact, never
in the spec.
