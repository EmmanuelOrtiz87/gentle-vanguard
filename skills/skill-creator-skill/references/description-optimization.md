# Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism for skill triggering. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

## Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  { "query": "the user prompt", "should_trigger": true },
  { "query": "another prompt", "should_trigger": false }
]
```

Queries must be realistic — concrete, specific, with file paths, personal context, company names, URLs. Include lowercase, abbreviations, typos, casual speech. Focus on edge cases.

**Bad:** `"Format this data"`, `"Extract text from PDF"`

**Good:** `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage"`

**Should-trigger (8-10):** Different phrasings of the same intent — formal, casual. Include cases where user doesn't explicitly name the skill. Throw in uncommon use cases and competitive triggers.

**Should-not-trigger (8-10):** Near-misses — queries sharing keywords but needing something different. Adjacent domains, ambiguous phrasing. Avoid obviously irrelevant queries.

## Step 2: Review with user

1. Read the template from `assets/eval_review.html`
2. Replace `__EVAL_DATA_PLACEHOLDER__` (JSON array), `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`
3. Write to temp file and open it
4. User edits queries, toggles should-trigger, adds/removes entries, clicks "Export Eval Set"
5. File downloads to `~/Downloads/eval_set.json`

## Step 3: Run the optimization loop

Save eval set to workspace, then run:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt. While it runs, periodically tail the output and give the user updates.

The loop splits 60/40 train/test, evaluates the current description (3 runs per query), calls Claude to propose improvements, re-evaluates, iterates up to 5 times. Opens an HTML report and returns `best_description` selected by test score.

### How skill triggering works

Skills appear in `available_skills` with name+description. Claude decides whether to consult a skill based on that description. Simple, one-step queries may not trigger even with perfect description — Claude handles them directly. Complex, multi-step, or specialized queries reliably trigger when the description matches. Make eval queries substantive enough that Claude would benefit from consulting a skill.

## Step 4: Apply the result

Take `best_description` and update the skill's SKILL.md frontmatter. Show the user before/after and report scores.
