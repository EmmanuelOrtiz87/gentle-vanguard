# Step 6: Budget Alerting Rules

YAML-based rules for daily budget, spikes, runaway detection, and forecasts.

```yaml
# budget-alerts.yaml
budget_rules:
  - name: daily_budget_exceeded
    condition: daily_tokens > daily_limit
    severity: P1
    action: pause_all_noncritical_agents
    message: 'Daily token budget exceeded: {used}/{limit}'

  - name: agent_spike
    condition: agent_hourly_tokens > agent_hourly_limit * 2
    severity: P2
    action: investigate_agent
    message: 'Agent {name} token usage spiked: {hourly_used}/hr'

  - name: runaway_detected
    condition: agent_tokens_per_task > task_limit * 3
    severity: P1
    action: kill_agent_task
    message: 'Agent {name} may be looping: {tokens_per_task} tokens/task'

  - name: budget_forecast
    condition: projected_daily_tokens > daily_limit * 0.9
    severity: P3
    action: notify_team
    message: 'On track to exceed daily budget by {overshoot}%'
```
