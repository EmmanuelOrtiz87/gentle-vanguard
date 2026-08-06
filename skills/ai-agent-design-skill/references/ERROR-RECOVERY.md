# Error Recovery

## Common Failure Modes

| Failure           | Symptom                      | Recovery Strategy                          |
| ----------------- | ---------------------------- | ------------------------------------------ |
| Tool call failure | Invalid parameters, timeout  | Retry with validated params, fallback tool |
| Hallucination     | Plausible but incorrect info | Cross-reference, ask for citations         |
| Loop              | Repeated same action         | Max step limit, novelty detection          |
| Context overflow  | Lost early information       | Summarization, sliding window              |
| Wrong tool choice | Inappropriate action         | Confirmation step for critical tools       |

## Recovery Implementation

```python
class ErrorRecovery:
    MAX_RETRIES = 3
    async def execute_with_recovery(self, tool, params):
        for attempt in range(self.MAX_RETRIES):
            try:
                return await tool.execute(**params)
            except ValidationError as e:
                params = self._fix_params(e, params)
                continue
            except TimeoutError:
                await asyncio.sleep(2 ** attempt)
                continue
            except PermissionError:
                return {"error": "permission_denied", "action": "escalate"}
        return {"error": "max_retries_exceeded", "action": "ask_human"}
```

## Human-in-the-Loop Escalation

```python
class EscalationHandler:
    async def should_escalate(self, error: dict, confidence: float) -> bool:
        return (
            error.get("action") == "escalate" or
            confidence < 0.3 or
            error.get("type") in ["security_violation", "permission_denied"]
        )
    async def escalate(self, context: dict, error: dict):
        ticket = {
            "agent_id": context["agent_id"],
            "task": context["task"],
            "error": error,
            "conversation_history": context["history"][-10:],
            "timestamp": datetime.now().isoformat()
        }
        await notification_service.send_to_human(ticket)
        return "Escalated to human operator. They will review shortly."
```
