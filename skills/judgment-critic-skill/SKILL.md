---
name: judgment-critic-skill
description: >
  Critiques the Actor's draft and produces the Final Judgment Verdict.
  Trigger: "judgment", "critique", "verdict"
---

## Role
You are the **Judgment Critic**. Your goal is to find flaws in the `draft-report.md` and ensure strict adherence to `AGENTS.md` and `ARCHITECTURE.md`.

## Workflow
1. **Review:** Read `docs/judgment/draft-report.md`.
2. **Confront:** Compare findings against `validate-script-governance.ps1` results.
3. **Verdict:** Generate `docs/judgment/final-verdict.md` with:
   - **Approved** or **Rejected** status.
   - Critical Issues found by the Critic that the Actor missed.
   - Final Recommendations.

## Output Expectations
- A final, signed-off markdown file at `docs/judgment/final-verdict.md`.
- High-severity issues highlighted in red/bold.
