# Common Mistakes

### 1. Over-Autonomy
Giving the agent too much freedom too quickly. **Fix**: Start with human-in-the-loop, gradually increase autonomy as reliability improves.

### 2. Ignoring Context Window Limits
Letting conversation history grow unbounded. **Fix**: Implement summarization or sliding windows. Monitor token usage.

### 3. Poor Tool Descriptions
Vague tool descriptions that confuse the model. **Fix**: Be explicit about when to use each tool.

```python
# Bad
"name": "search"
# Good
"name": "search_knowledge_base",
"description": "Search internal documentation for product information."
```

### 4. No Error Recovery
Assuming tools always succeed. **Fix**: Every tool call must have: retry logic, timeout, fallback, escalation.

### 5. Flat Memory Design
Using a single memory store for everything. **Fix**: Separate STM (conversation), LTM (facts), episodic (events), semantic (knowledge).

### 6. Ignoring Latency
Chaining many LLM calls without considering UX. **Fix**: Use streaming, parallel execution, set timeouts.

### 7. No Observability
Not logging agent decisions, tool calls, reasoning. **Fix**: Log every input, thought, tool call (with params), result, and output.

### 8. Single Point of Failure
One agent handles everything with no fallback. **Fix**: Implement routing patterns, fallback agent, circuit breakers.

### 9. Prompt Injection in Tool Results
Tool results containing instructions that override agent behavior. **Fix**: Treat all tool results as data, not instructions.

```python
# Dangerous
system_prompt += f"\nHere's additional context: {tool_result}"
# Safe
context = f"According to the database: {tool_result}"
```

### 10. Assuming Determinism
Expecting the same output every time. **Fix**: Temperature 0 for critical paths, validate outputs, idempotent tools.
