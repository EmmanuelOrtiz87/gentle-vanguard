# Budget Planning Reference

## Model Pricing (per 1M tokens)

| Model             | Input ($/1M tokens) | Output ($/1M tokens) | Cost per 100K tasks (4K avg) |
| ----------------- | ------------------- | -------------------- | ---------------------------- |
| GPT-4o            | $2.50               | $10.00               | ~$1,250                      |
| Claude 3.5 Sonnet | $3.00               | $15.00               | ~$1,800                      |
| GPT-4o-mini       | $0.15               | $0.60                | ~$75                         |
| Claude 3 Haiku    | $0.25               | $1.25                | ~$150                        |

## Optimization Impact

| Strategy                      | Typical Savings | Quality Impact                |
| ----------------------------- | --------------- | ----------------------------- |
| Shorter system prompts        | 15-30%          | Low (with good editing)       |
| Context compression           | 20-40%          | Medium (summarization loss)   |
| Cheaper models for easy tasks | 40-60%          | Low (task-dependent)          |
| Fewer reasoning steps         | 10-25%          | Medium (may reduce quality)   |
| Caching common responses      | 5-15%           | None (exact cache hits)       |
| Limiting conversation history | 30-50%          | Low (recent context suffices) |
