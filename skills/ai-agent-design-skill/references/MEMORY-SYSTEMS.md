# Memory Systems

Without memory, every agent interaction is a fresh start. Memory enables personalization, continuity, and learning.

## Memory Types

### Short-Term Memory (STM)
- **What**: Current conversation or session context
- **Storage**: In-context (within the LLM's context window)
- **Duration**: Single session
- **Capacity**: Limited by context window (8K-200K tokens)
- **Implementation**: Conversation history as a list of messages

```python
class ShortTermMemory:
    def __init__(self, max_tokens: int = 8000):
        self.messages = []
        self.max_tokens = max_tokens
    def add(self, role: str, content: str):
        self.messages.append({"role": role, "content": content})
        self._trim()
    def _trim(self):
        total = sum(len(m["content"]) for m in self.messages)
        while total > self.max_tokens and len(self.messages) > 1:
            removed = self.messages.pop(0)
            total -= len(removed["content"])
    def get_context(self) -> list:
        return self.messages
```

### Long-Term Memory (LTM)
- **What**: Facts, preferences, knowledge from past sessions
- **Storage**: Vector databases, relational databases, key-value stores
- **Duration**: Permanent (until deleted)
- **Capacity**: Virtually unlimited
- **Implementation**: Embedding + retrieval

```python
import chromadb
class LongTermMemory:
    def __init__(self, collection_name: str = "agent_memory"):
        self.client = chromadb.Client()
        self.collection = self.client.get_or_create_collection(collection_name)
    def store(self, content: str, metadata: dict = None):
        self.collection.add(
            documents=[content],
            metadatas=[metadata or {}],
            ids=[f"mem_{hash(content)}"]
        )
    def recall(self, query: str, n: int = 5) -> list:
        results = self.collection.query(query_texts=[query], n_results=n)
        return [
            {"content": doc, "metadata": meta}
            for doc, meta in zip(results["documents"][0], results["metadatas"][0])
        ]
```

### Episodic Memory
- **What**: Record of past events, actions, and outcomes
- **Storage**: Time-series database or event log
- **Duration**: Configurable retention
- **Use case**: Learning from past mistakes, context for decision-making

```python
class EpisodicMemory:
    def __init__(self):
        self.episodes = []
    def record(self, action: str, context: dict, outcome: str, success: bool):
        self.episodes.append({
            "timestamp": datetime.now().isoformat(),
            "action": action, "context": context,
            "outcome": outcome, "success": success
        })
    def get_similar_episodes(self, action: str, n: int = 3) -> list:
        relevant = [e for e in self.episodes if e["action"] == action]
        return sorted(relevant, key=lambda x: x["timestamp"], reverse=True)[:n]
```

### Semantic Memory
- **What**: General knowledge, concepts, relationships
- **Storage**: Knowledge graphs, structured databases
- **Duration**: Persistent, updated over time
- **Use case**: Understanding domain concepts, entity relationships

## Retrieval Strategies

| Strategy | Description | Best For |
|---|---|---|
| **Last-N** | Keep the last N turns of conversation | Simple chatbots |
| **Sliding Window** | Keep most recent tokens up to a limit | General purpose |
| **Summarization** | Summarize older context to save tokens | Long conversations |
| **RAG** | Retrieve relevant context from vector store | Knowledge-heavy tasks |
| **Hybrid** | Combine multiple strategies | Production systems |
