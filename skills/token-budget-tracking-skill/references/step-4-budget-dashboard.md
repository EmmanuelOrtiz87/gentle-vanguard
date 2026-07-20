# Step 4: Real-Time Budget Dashboard

Live budget status with per-agent percent-used and budget alerts.

```python
class BudgetDashboard:
    """Real-time token budget monitoring."""

    def __init__(self, counter: TokenCounter, budgets: TokenBudget):
        self.counter = counter
        self.budgets = budgets

    def current_status(self) -> dict:
        """Get current budget status for all agents."""
        agents = {}
        for agent_name in self.counter.usage:
            usage = self.counter.agent_total(agent_name)
            limit = self.budgets.agent_limits.get(agent_name, float('inf'))
            agents[agent_name] = {
                "total_tokens": usage.total_tokens,
                "prompt_tokens": usage.prompt_tokens,
                "completion_tokens": usage.completion_tokens,
                "budget_limit": limit,
                "percent_used": (usage.total_tokens / limit * 100) if limit != float('inf') else 0,
                "estimated_cost": self._estimate_cost(usage),
            }

        return {
            "agents": agents,
            "global": {
                "total_tokens": sum(a["total_tokens"] for a in agents.values()),
                "total_cost": sum(a["estimated_cost"] for a in agents.values()),
            },
            "period_usage": dict(self.budgets.period_usage)
        }

    def _estimate_cost(self, usage: TokenUsage) -> float:
        """Estimate cost at blended rate ($0.003/1K tokens)."""
        return usage.total_tokens * 0.003 / 1000

    def budget_alert(self, threshold: float = 0.8) -> list[str]:
        """Get alerts for agents approaching budget limits."""
        alerts = []
        for agent_name, info in self.current_status()["agents"].items():
            if info["percent_used"] > threshold * 100:
                alerts.append(
                    f"{agent_name}: {info['percent_used']:.0f}% of budget used "
                    f"({info['total_tokens']:,} tokens)"
                )
        return alerts
```
