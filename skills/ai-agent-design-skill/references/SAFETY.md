# Safety Guardrails

## Critical Safety Patterns

### 1. Input Validation

```python
class InputGuardrail:
    BLOCKED_PATTERNS = [
        r"ignore all previous instructions",
        r"you are now .*",
        r"system prompt",
        r"jailbreak",
    ]
    def check(self, user_input: str) -> tuple[bool, str]:
        for pattern in self.BLOCKED_PATTERNS:
            if re.search(pattern, user_input, re.IGNORECASE):
                return False, f"Input blocked: pattern '{pattern}' detected"
        return True, ""
```

### 2. Output Validation

```python
class OutputGuardrail:
    def check(self, output: str) -> tuple[bool, str]:
        if "system:" in output.lower() and "instruction" in output.lower():
            return False, "Output contains internal instructions"
        if contains_harmful_content(output):
            return False, "Output flagged by safety classifier"
        return True, ""
```

### 3. Action Authorization

```python
class ActionGuardrail:
    HIGH_RISK_ACTIONS = {
        "send_email", "delete_record", "modify_permissions",
        "transfer_funds", "execute_code"
    }
    async def authorize(self, action: str, params: dict) -> bool:
        if action in self.HIGH_RISK_ACTIONS:
            return await self._ask_human(f"Confirm {action} with params: {params}")
        return True
```

## Guardrail Architecture

```
[User Input] → [Input Guardrail] → [Agent] → [Output Guardrail] → [Action Guardrail] → [Execute]
                      |                  |            |                    |
                  Blocked/Pass       +Tool       Blocked/Pass       Confirm/Deny
                                   Results
```

## Safety Rules for Production

1. **Never execute code from user input** unless sandboxed
2. **Never expose internal prompts or tool schemas** to end users
3. **Rate limit all agent calls** to prevent abuse
4. **Log everything** — every input, output, tool call, and decision
5. **Have a kill switch** — escalation path that bypasses the agent entirely
