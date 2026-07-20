# Chain-of-Thought (CoT) Prompting

## What It Is

Chain-of-thought prompting instructs the model to reason step-by-step before arriving at an answer.
This dramatically improves performance on arithmetic, logic, and multi-step reasoning tasks.

## Why It Works

LLMs are autoregressive — they predict the next token based on previous tokens. By generating
intermediate reasoning steps, the model builds a logical scaffold that leads to more accurate
conclusions.

## Zero-Shot CoT

Simply append "Let's think step by step." to your prompt.

```
Prompt: A bat and a ball cost $1.10 in total. The bat costs $1.00 more than the ball. How much does the ball cost? Let's think step by step.

Response: Let's denote the ball's cost as x. Then the bat costs x + $1.00. Together: x + (x + 1.00) = 1.10. So 2x = 0.10, x = 0.05. The ball costs $0.05.
```

## Few-Shot CoT

Provide 2-3 examples of reasoning chains before asking your question.

```
Prompt: Q: Roger has 5 tennis balls. He buys 2 more cans of tennis balls. Each can has 3 balls. How many does he have now?
A: Roger starts with 5 balls. 2 cans of 3 each = 6 balls. 5 + 6 = 11. The answer is 11.

Q: The cafeteria had 23 apples. They used 20 to make lunch and bought 6 more. How many apples do they have?
A: They had 23. Used 20 → 23 - 20 = 3 left. Bought 6 → 3 + 6 = 9. The answer is 9.

Q: {your question}
A:
```

## When to Use Chain-of-Thought

| Task Type | CoT Recommended? | Notes |
| --------- | ---------------- | ----- |
| Arithmetic/Math | ✅ Yes | Essential for multi-step |
| Logic Puzzles | ✅ Yes | Dramatically improves accuracy |
| Code Generation | ⚠️ Sometimes | Useful for complex algorithms |
| Creative Writing | ❌ No | Can feel mechanical |
| Factual Recall | ❌ No | Adds unnecessary verbosity |
