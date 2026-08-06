# Temperature & Top-P Guidance

## What They Control

Both parameters control randomness in generation.

| Parameter       | Range     | Effect                                                                        |
| --------------- | --------- | ----------------------------------------------------------------------------- |
| Temperature     | 0.0 - 2.0 | Scales log probabilities. Lower = more deterministic, higher = more random    |
| Top-P (nucleus) | 0.0 - 1.0 | Cumulative probability threshold. Lower = more focused, higher = more diverse |

## Recommended Settings

| Task             | Temperature | Top-P     | Rationale                    |
| ---------------- | ----------- | --------- | ---------------------------- |
| Code generation  | 0.0 - 0.2   | 0.5 - 0.9 | Deterministic, correct code  |
| Factual QA       | 0.0 - 0.3   | 0.5 - 0.8 | Accuracy over creativity     |
| Data extraction  | 0.0 - 0.1   | 0.3 - 0.5 | Consistent structured output |
| Creative writing | 0.7 - 1.0   | 0.9 - 1.0 | Novelty and variety          |
| Brainstorming    | 0.8 - 1.2   | 0.9 - 1.0 | Generate diverse ideas       |
| Translation      | 0.1 - 0.3   | 0.5 - 0.7 | Accuracy and fluency         |

## Rule of Thumb

- **Don't adjust both at once**: Keep top-P at 1.0 and tune temperature first
- **For structured output, use low temperature**: JSON generation needs determinism
- **For creative tasks, raise temperature but set a max token limit** to prevent rambling
