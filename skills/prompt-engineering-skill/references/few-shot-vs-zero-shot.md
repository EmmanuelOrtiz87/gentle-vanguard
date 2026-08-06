# Few-Shot vs Zero-Shot

## Zero-Shot Prompting

The model receives only the instruction with no examples.

**Best for**: Simple, well-understood tasks; creative work; when examples might bias the output.

```
Translate to French: "Hello, how are you?"
```

## Few-Shot Prompting

The model receives 2-5 examples demonstrating the desired pattern before the actual query.

**Best for**: Complex formatting; tasks with edge cases; domain-specific terminology; when you need
consistent output structure.

```
English: "I love programming"
French: "J'adore programmer"

English: "The weather is nice today"
French: "Il fait beau aujourd'hui"

English: "Can you help me with this?"
French:
```

## Guidelines for Few-Shot Selection

1. **Quality over quantity**: 3 excellent examples beat 10 mediocre ones
2. **Cover edge cases**: Include examples that show how to handle tricky inputs
3. **Mirror your target**: Examples should match the complexity and style of your actual use case
4. **Randomize order**: If examples are in predictable order, the model may learn a pattern you
   don't want

## When to Choose Which

| Scenario              | Recommend | Rationale                      |
| --------------------- | --------- | ------------------------------ |
| Translation           | Few-shot  | Helps with style and register  |
| Summarization         | Zero-shot | Less bias, more faithful       |
| Classification        | Few-shot  | Handles ambiguous cases        |
| Code generation       | Few-shot  | Establishes style and patterns |
| Creative writing      | Zero-shot | More original output           |
| Structured extraction | Few-shot  | Precise format control         |
