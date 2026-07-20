# Agent Orchestration

## Single-Agent Architecture

One agent handles everything: reasoning, tool selection, execution, and response.

```
[User] → [LLM + Tools + Memory] → [Response]
```

**Pros**: Simple, easy to debug, low latency
**Cons**: Single point of failure, limited specialization, context window pressure

## Multi-Agent Architecture

Multiple specialized agents collaborate on a task.

```
                    [Supervisor Agent]
                    /        |        \
            [Research]  [Analysis]  [Writing]
            Agent        Agent        Agent
```

**Pros**: Specialization, parallel execution, modular design
**Cons**: Coordination overhead, increased latency, harder to debug

## Supervisor Pattern

One agent (supervisor) delegates tasks to worker agents and synthesizes results.

```python
class SupervisorAgent:
    def __init__(self):
        self.workers = {
            "researcher": ResearchAgent(),
            "analyst": AnalysisAgent(),
            "writer": WritingAgent()
        }
    async def process(self, task: str) -> str:
        plan = await self._create_plan(task)
        results = {}
        for step in plan["steps"]:
            worker = self.workers[step["agent"]]
            results[step["id"]] = await worker.execute(step["instruction"])
        return await self._synthesize(plan, results)
```

## Routing Pattern

A router agent classifies the input and sends it to the appropriate handler.

```python
class Router:
    def __init__(self):
        self.routes = {
            "technical_support": TechnicalSupportAgent(),
            "billing": BillingAgent(),
            "general": GeneralAgent()
        }
    async def route(self, user_input: str):
        intent = await self._classify_intent(user_input)
        agent = self.routes.get(intent, self.routes["general"])
        return await agent.handle(user_input)
```

## Decision Matrix

| Factor | Single-Agent | Multi-Agent | Supervisor | Routing |
|---|---|---|---|---|
| Complexity | Low | High | Medium | Medium |
| Latency | Low | High | Medium | Low |
| Modularity | Low | High | High | Medium |
| Debugging | Easy | Hard | Medium | Easy |
| Context Usage | Efficient | Expensive | Moderate | Efficient |
