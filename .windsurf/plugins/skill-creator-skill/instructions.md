# skill-creator-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Skill Creator

Create new skills and iteratively improve them.

## Process Overview

1. Capture intent — what should the skill do? When should it trigger?
2. Write draft SKILL.md (name, description, instructions)
3. Create test prompts, save to `evals/evals.json`
4. Run test cases — spawn with-skill AND baseline subagents in parallel
5. While runs run, draft quantitative assertions
6. Grade, aggregate into benchmark, launch viewer
7. User reviews feedback; improve the skill
8. Repeat until satisfied (or no meaningful progress)
9. Optimize description for triggering accuracy
10. Package final `.skill` file

## Communication

Adjust language to user's familiarity. "Evaluation" and "benchmark" are borderline; explain "JSON" and "assertion" unless the user shows familiarity. Brief definitions are OK when unsure.

## Detailed Instructions

Read the relevant reference file:

- `references/creating-a-skill.md` — Capture intent, interview, skill anatomy, writing patterns, test cases
- `references/running-evaluations.md` — Full 5-step eval cycle: spawn, draft assertions, grade, aggregate, launch viewer
- `references/improving-the-skill.md` — Generalize from feedback, keep lean, explain the why, bundle repeated work
- `references/blind-comparison.md` — Optional A/B comparison between versions
- `references/description-optimization.md` — Generate trigger evals, review, run optimization loop
- `references/platform-guide.md` — Claude.ai and Cowork-specific adaptations
- `references/package-and-present.md` — Package final `.skill` file

## Reference Files

- `agents/grader.md` — Evaluate assertions against outputs
- `agents/comparator.md` — Blind A/B comparison
- `agents/analyzer.md` — Analyze benchmark results

## Core Loop

- Figure out what the skill is about
- Draft or edit the skill
- Run with-skill on test prompts
- Evaluate with user: create benchmark, run viewer
- Repeat until satisfied
- Package the final skill

Add steps to TodoList to track progress. Good luck!
