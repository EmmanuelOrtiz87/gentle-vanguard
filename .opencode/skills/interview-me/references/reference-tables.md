# Reference Tables

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The ask is clear enough" | If you can't write the desired outcome in one sentence, the ask isn't clear. Run Step 1. |
| "Asking too many questions wastes their time" | 4–6 targeted questions is negligible. Building the wrong thing wastes enormous time — and the user bears that cost. |
| "I'll figure it out as I build" | Switching costs after code exists are 10x what they are now. Discovery during implementation is rework. |
| "They said 'whatever you think' so I should decide" | That's delegation, not decision. Re-ask with two concrete options as a choice. |
| "I should give them several options to pick from" | Options work when they know what they want. They don't yet. Listing options widens the search; asking narrows it. |
| "If I attach my guess, I'm leading them" | Leading is the point. Reacting is faster than generating from scratch. Mitigate sycophancy by being visibly willing to be wrong. |
| "We've talked enough, I get it" | Test it: can you predict their reaction to the next three questions? If not, you don't get it yet. |
| "The user said yes, we're done" | If the yes followed a vague restate or "sounds good," it's hollow. Restate concretely and re-confirm. |

## Red Flags

- Three or more questions in a single message — that's batching, not interviewing
- A question without your hypothesis attached — that's surveying, not committing
- Accepting "whatever you think is best" as a terminal answer
- Producing a spec, plan, or task list before the user has explicitly confirmed your restate
- Questions framed as "what would be best practice?" instead of "what do you actually want?"
- Accepting sophistication-signaling answers ("scalable", "clean", "modern") without probing
- Three or more rounds without confidence visibly rising — you're asking the wrong questions, step back
- A confidence number below ~70% with no reason attached — the user can't close the gap if they don't know what's missing
- Saving the intent doc before the user has confirmed (the doc implies a yes the user didn't give)
- Skipping the "Out of scope" line in the restate (silent disagreement about non-goals is half of misalignment)

## Verification Checklist

After applying interview-me:

- [ ] Explicit hypothesis with a confidence number stated in the first turn
- [ ] Every confidence number below ~70% accompanied by a one-line reason
- [ ] Questions asked one at a time, each with the agent's guess attached
- [ ] At least one "what would you actually want if you didn't have to justify it?" probe when the user gave a sophistication-signaling answer
- [ ] Concrete restate (Outcome / User / Why now / Success / Constraint / Out of scope) written back to the user
- [ ] User confirmed the restate with an explicit yes (not "whatever you think," "sounds good," or silence)
- [ ] At the stop point, the agent could predict reactions to the next three questions
- [ ] Any handoff to a downstream skill was framed in terms of the confirmed intent, not the original underspecified ask
