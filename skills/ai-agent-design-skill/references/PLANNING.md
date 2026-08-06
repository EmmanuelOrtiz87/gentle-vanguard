# Planning Strategies

## ReAct (Reasoning + Acting)

The agent alternates between reasoning (thinking about what to do) and acting (calling tools).

```
Thought: I need to find the latest sales data. Let me check the database.
Action: query_database({"query": "SELECT * FROM sales ORDER BY date DESC LIMIT 10"})
Observation: [{"date": "2024-01-15", "revenue": 45000}, ...]
Thought: Revenue has increased 12% month-over-month.
Answer: Sales revenue has grown 12% month-over-month, reaching $45,000 in January.
```

```python
class ReActAgent:
    def __init__(self, llm, tools):
        self.llm = llm
        self.tools = {t.name: t for t in tools}
    async def run(self, task: str, max_steps: int = 10):
        messages = [{"role": "user", "content": task}]
        for step in range(max_steps):
            response = await self.llm.generate(messages)
            action = self._parse_action(response)
            if not action:
                return response
            tool = self.tools.get(action["name"])
            if not tool:
                return f"Error: Unknown tool {action['name']}"
            result = await tool.execute(**action["parameters"])
            messages.append({"role": "assistant", "content": response})
            messages.append({"role": "tool", "content": result})
        return "Reached maximum steps without resolution."
```

## Plan-and-Execute

The agent creates a complete plan first, then executes each step.

```
Plan:
1. Query database for Q4 sales data
2. Calculate year-over-year growth
3. Identify top-performing regions
4. Generate summary report
5. Schedule email to stakeholders
```

**When to use**: Tasks with clear sequential dependencies, long-running workflows where intermediate
results matter, when verification is needed before executing.

## ReAct vs Plan-and-Execute

| Aspect        | ReAct                      | Plan-and-Execute              |
| ------------- | -------------------------- | ----------------------------- |
| Flexibility   | High (adapts mid-task)     | Low (follows plan)            |
| Reliability   | Lower (can go off-track)   | Higher (structured)           |
| Speed         | Faster for simple tasks    | Faster for complex tasks      |
| Observability | Step-by-step visible       | Full plan visible upfront     |
| Best for      | Exploratory, dynamic tasks | Well-understood, stable tasks |
