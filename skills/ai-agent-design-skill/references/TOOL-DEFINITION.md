# Tool Definition Patterns

## Function Calling / Tool Use

Modern LLMs support "function calling" — the model outputs a structured request to invoke a tool, and the runtime executes it and returns the result.

## Tool Schema Pattern (OpenAI-style)

```json
{
  "type": "function",
  "function": {
    "name": "search_knowledge_base",
    "description": "Search the internal knowledge base for relevant documents",
    "parameters": {
      "type": "object",
      "properties": {
        "query": {
          "type": "string",
          "description": "The search query string"
        },
        "max_results": {
          "type": "integer",
          "description": "Maximum number of results to return (1-20)",
          "minimum": 1,
          "maximum": 20
        }
      },
      "required": ["query"]
    }
  }
}
```

## Best Practices

1. **Descriptions are critical** — Be explicit about when to use each tool
2. **Validate parameters** — Use JSON Schema constraints (minimum, maximum, enum, pattern)
3. **Return structured data** — Tool results should return JSON for model reasoning
4. **Include error information** — Return clear error messages the model can act on

## Implementation Pattern

```python
from typing import Any
import json

class AgentTool:
    """Base class for agent tools."""
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
    def get_schema(self) -> dict:
        raise NotImplementedError
    async def execute(self, **kwargs) -> Any:
        raise NotImplementedError

class SearchTool(AgentTool):
    def __init__(self):
        super().__init__(name="search", description="Search documents by query string")
    def get_schema(self):
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string"},
                        "limit": {"type": "integer", "default": 5}
                    },
                    "required": ["query"]
                }
            }
        }
    async def execute(self, query: str, limit: int = 5):
        results = await database.search(query, limit=limit)
        return json.dumps({"results": results, "count": len(results)})
```

## Tool Categories

| Category | Examples | When to Use |
|---|---|---|
| **Retrieval** | Search, SQL query, vector search | Agent needs external information |
| **Computation** | Calculator, code interpreter, stats | Agent needs to compute or analyze |
| **Action** | Email send, API call, file write | Agent needs to affect the world |
| **Communication** | Slack message, notification | Agent needs to inform humans |
| **Validation** | Spell check, safety check, lint | Agent needs to verify its work |
