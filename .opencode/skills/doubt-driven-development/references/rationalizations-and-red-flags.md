# Common Rationalizations

| Rationalization                                      | Reality                                                                                                                                                               |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "I'm confident, skip the doubt step"                 | Confidence correlates poorly with correctness on novel problems. Moments of certainty are exactly when blind spots hide.                                              |
| "Spawning a reviewer is expensive"                   | Debugging a wrong commit in production is more expensive. The check is bounded; the bug isn't.                                                                        |
| "The reviewer will just nitpick"                     | Only if unscoped. Constrain the prompt to "issues that would make this fail under the contract."                                                                      |
| "I'll do doubt at the end with `/review`"            | `/review` is a final gate. Doubt-driven catches wrong directions early when course-correction is cheap. By PR time it's too late.                                     |
| "If I doubt every step I'll never ship"              | The skill applies to non-trivial decisions, not every keystroke. Re-read "When NOT to Use."                                                                           |
| "Two opinions are always better than one"            | Not when the second has less context and produces noise. Reconcile, don't defer.                                                                                      |
| "The reviewer disagreed so I was wrong"              | The reviewer lacks your context — disagreement is information, not verdict. Re-read the artifact, classify, then decide.                                              |
| "Cross-model is always better"                       | Cross-model catches blind spots a single model shares with itself, but it adds cost and tool fragility. Offer it every interactive doubt cycle — the user decides.    |
| "User said yes once, so I can keep invoking the CLI" | Each invocation is its own authorization. The artifact, the prompt, and the flags change between calls — re-confirm the exact command with the user before every run. |

# Red Flags

- Spawning a fresh-context reviewer for a one-line rename or formatting change
- Treating reviewer output as authoritative without re-reading the artifact text
- Looping >3 cycles without escalating to the user
- Prompting the reviewer with "is this good?" instead of "find issues"
- Skipping doubt under time pressure on a high-stakes decision
- Re-spawning fresh-context on an unchanged artifact (you'll get the same findings; you're stalling)
- **Doubt theater (checkable signal)**: across 2 or more cycles where the reviewer surfaced
  substantive findings, zero findings were classified as actionable. You are validating, not
  doubting. Stop and escalate.
- Doubting only after committing — that's `/review`, not doubt-driven development
- Hardcoding an external CLI invocation without confirming with the user that the tool exists, is
  configured, and accepts that exact syntax
- **Silently skipping cross-model in an interactive doubt cycle.** Even when not recommending it,
  the offer must be visible. Skipping is fine; silent skipping is not.
- Falling back silently when an external CLI errors or is missing — surface the failure and let the
  user redirect
- Stripping the contract from the reviewer's input
- Passing the CLAIM to the reviewer (biases toward agreement)
