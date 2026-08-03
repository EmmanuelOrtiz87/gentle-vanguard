# Improving the Skill

This is the heart of the loop. Run test cases, get user feedback, make the skill better.

## How to Think About Improvements

1. **Generalize from feedback.** You're iterating on a few examples, but the skill needs to work across many prompts. Don't add fiddly overfitty changes or oppressively constrictive MUSTs. If there's a stubborn issue, try different metaphors or patterns.

2. **Keep the prompt lean.** Remove things not pulling their weight. Read transcripts, not just final outputs — if the skill wastes time on unproductive tasks, remove those parts.

3. **Explain the why.** LLMs are smart and have good theory of mind. Transmit understanding into instructions. ALL-CAPS ALWAYS/NEVER is a yellow flag — reframe with reasoning instead.

4. **Look for repeated work across test cases.** If multiple test case subagents independently wrote similar helper scripts (`create_docx.py`, `build_chart.py`), bundle that script into `scripts/`. Write it once, save every future invocation from reinventing the wheel.

Take your time and mull things over. Write a draft revision, look at it anew, improve it.

## The Iteration Loop

After improving the skill:

1. Apply improvements to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for user review
5. Read new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- Feedback is all empty (everything looks good)
- You're not making meaningful progress
