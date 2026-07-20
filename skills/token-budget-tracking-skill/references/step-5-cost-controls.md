# Step 5: Proactive Cost Controls

Usage-ratio-driven context compression and cost-effective model selection.

```python
class CostController:
    """Proactive cost optimization controls."""

    def __init__(self, optimizer: TokenOptimizer, budgets: TokenBudget):
        self.optimizer = optimizer
        self.budgets = budgets

    async def optimize_request(self, agent_name: str,
                                 messages: list[dict]) -> list[dict]:
        """Optimize a request before sending to LLM."""

        # Apply optimizations based on agent's budget status
        agent_usage = self.budgets.counter.agent_total(agent_name)
        agent_limit = self.budgets.agent_limits.get(agent_name, float('inf'))

        usage_ratio = agent_usage.total_tokens / agent_limit if agent_limit else 0

        if usage_ratio > 0.9:
            # Critical: aggressive compression
            return await self.optimizer.compress_context(
                messages, max_tokens=2000
            )
        elif usage_ratio > 0.7:
            # Warning: moderate compression
            return await self.optimizer.compress_context(
                messages, max_tokens=4000
            )

        return messages  # Within budget, no optimization needed

    def model_selection(self, task_difficulty: str,
                         available_budget: float) -> str:
        """Select the most cost-effective model for the task."""
        models = {
            "easy": {"model": "gpt-4o-mini", "cost_per_1k": 0.00015},
            "medium": {"model": "gpt-4o", "cost_per_1k": 0.0025},
            "hard": {"model": "gpt-4o", "cost_per_1k": 0.0025},
        }

        recommended = models.get(task_difficulty, models["medium"])

        # If budget is very tight, downgrade
        if available_budget < recommended["cost_per_1k"] * 100:
            return models["easy"]["model"]

        return recommended["model"]
```
