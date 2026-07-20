# Step 2: Budget Enforcement

Per-agent and global period budget enforcement with pre-flight checks.

```python
class TokenBudget:
    """Enforce per-agent and global token budgets."""

    def __init__(self, counter: TokenCounter):
        self.counter = counter
        self.agent_limits: dict[str, int] = {}  # agent -> max tokens
        self.period_limits: dict[str, int] = {}  # period -> max tokens

        # Current period tracking
        self.period_start = time.time()
        self.period_usage: dict[str, int] = defaultdict(int)

    def set_agent_limit(self, agent_name: str, max_tokens: int):
        """Set a per-agent token budget."""
        self.agent_limits[agent_name] = max_tokens

    def set_period_limit(self, period_name: str, max_tokens: int):
        """Set a global period budget (e.g., daily, weekly)."""
        self.period_limits[period_name] = max_tokens

    async def check_and_apply_budget(self, agent_name: str,
                                       estimated_tokens: int) -> bool:
        """Check if this request would exceed any budget. Returns True if allowed."""

        # 1. Check per-agent limit
        agent_limit = self.agent_limits.get(agent_name)
        if agent_limit:
            current = self.counter.agent_total(agent_name).total_tokens
            if current + estimated_tokens > agent_limit:
                return False  # Agent budget exceeded

        # 2. Check period limits
        current_period = self._current_period()
        for period, limit in self.period_limits.items():
            if self.period_usage[period] + estimated_tokens > limit:
                return False  # Global period budget exceeded

        # 3. Reserve tokens
        self.period_usage[current_period] += estimated_tokens
        return True

    def _current_period(self) -> str:
        """Get the current period label (e.g., 'daily:2024-01-15')."""
        now = datetime.now()
        return f"daily:{now.strftime('%Y-%m-%d')}"

    def reset_period(self):
        """Reset period tracking (call daily, weekly)."""
        self.period_start = time.time()
        self.period_usage.clear()
```
