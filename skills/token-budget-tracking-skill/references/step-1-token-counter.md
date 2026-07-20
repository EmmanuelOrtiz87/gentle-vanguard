# Step 1: Token Counter

Thread-safe token usage tracking with per-agent-task attribution and monetary cost calculation.

```python
from dataclasses import dataclass, field
from collections import defaultdict
import time
import threading

@dataclass
class TokenUsage:
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0

    def __add__(self, other: "TokenUsage"):
        return TokenUsage(
            prompt_tokens=self.prompt_tokens + other.prompt_tokens,
            completion_tokens=self.completion_tokens + other.completion_tokens,
            total_tokens=self.total_tokens + other.total_tokens
        )

class TokenCounter:
    """Tracks token usage across all agents with attribution."""

    def __init__(self):
        self.usage: dict[str, dict[str, TokenUsage]] = defaultdict(
            lambda: defaultdict(TokenUsage)
        )
        self._lock = threading.Lock()

    def record(self, agent_name: str, task_id: str,
               prompt_tokens: int, completion_tokens: int):
        """Record token usage for an agent-task pair."""
        with self._lock:
            usage = TokenUsage(
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=prompt_tokens + completion_tokens
            )
            self.usage[agent_name][task_id] = usage

    def agent_total(self, agent_name: str) -> TokenUsage:
        """Get total tokens for an agent."""
        with self._lock:
            total = TokenUsage()
            for task_usage in self.usage[agent_name].values():
                total += task_usage
            return total

    def task_cost(self, agent_name: str, task_id: str,
                  input_rate: float, output_rate: float) -> float:
        """Calculate monetary cost for a specific task."""
        usage = self.usage[agent_name].get(task_id)
        if not usage:
            return 0.0
        return (
            usage.prompt_tokens * input_rate / 1_000_000 +
            usage.completion_tokens * output_rate / 1_000_000
        )

    def top_agents(self, n: int = 10) -> list[tuple[str, TokenUsage]]:
        """Get the n highest-consuming agents."""
        with self._lock:
            totals = [
                (agent, self.agent_total(agent))
                for agent in self.usage
            ]
            totals.sort(key=lambda x: x[1].total_tokens, reverse=True)
            return totals[:n]
```
