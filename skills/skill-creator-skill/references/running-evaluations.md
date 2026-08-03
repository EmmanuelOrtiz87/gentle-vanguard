# Running and Evaluating Test Cases

This is one continuous sequence. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Create directories as you go.

## Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents simultaneously — one with the skill, one without.

**With-skill run:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Baseline run:**
- **Creating a new skill**: no skill. Save to `without_skill/outputs/`.
- **Improving an existing skill**: snapshot first (`cp -r <skill-path> <workspace>/skill-snapshot/`), point baseline at snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case (assertions empty for now). Use descriptive names.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

## Step 2: While runs are in progress, draft assertions

Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them.

Good assertions are objectively verifiable with descriptive names. Subjective skills are better evaluated qualitatively — don't force assertions onto things needing human judgment.

Update `eval_metadata.json` and `evals/evals.json` with assertions once drafted.

## Step 3: As runs complete, capture timing data

When each subagent task completes, save `total_tokens` and `duration_ms` to `timing.json`:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

Process each notification as it arrives — this data isn't persisted elsewhere.

## Step 4: Grade, aggregate, and launch the viewer

1. **Grade each run** — spawn a grader subagent (or grade inline) that reads `agents/grader.md` and evaluates each assertion against outputs. Save to `grading.json`. The expectations array must use `text`, `passed`, and `evidence` fields. For programmatic assertions, write and run a script.

2. **Aggregate into benchmark**:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens. Put with_skill before baseline counterparts.

3. **Do an analyst pass** — read benchmark data and surface patterns. See `agents/analyzer.md` for what to look for: non-discriminating assertions, high-variance evals, time/token tradeoffs.

4. **Launch the viewer**:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.
   In headless environments, use `--static <output_path>` instead.
   Use `generate_review.py` — don't write custom HTML.

5. **Tell the user**: "I've opened the results in your browser. 'Outputs' tab lets you click through each test case and leave feedback, 'Benchmark' shows quantitative comparison. Come back when done."

### What the user sees

**Outputs tab**: Prompt, Output, Previous Output (iteration 2+), Formal Grades, Feedback textbox (auto-saves), Previous Feedback (iteration 2+). Navigation via prev/next or arrow keys. "Submit All Reviews" saves feedback to `feedback.json`.

**Benchmark tab**: Pass rates, timing, token usage, per-eval breakdowns, analyst observations.

## Step 5: Read the feedback

```json
{
  "reviews": [
    { "run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..." },
    { "run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..." }
  ],
  "status": "complete"
}
```

Empty feedback means it was fine. Focus improvements on test cases with specific complaints. Kill the viewer: `kill $VIEWER_PID 2>/dev/null`
