# Step 3: Token Optimization

Context compression, summarization, and truncation strategies.

```python
class TokenOptimizer:
    """Apply optimization strategies to reduce token consumption."""

    def __init__(self, llm):
        self.llm = llm

    async def compress_context(self, messages: list[dict],
                                max_tokens: int) -> list[dict]:
        """Compress conversation history to fit within token budget."""
        total = self._count_tokens(messages)

        if total <= max_tokens:
            return messages  # No compression needed

        # Strategy 1: Remove low-signal turns
        messages = self._remove_greetings(messages)

        # Strategy 2: Summarize older messages
        if self._count_tokens(messages) > max_tokens:
            messages = await self._summarize_older(messages)

        # Strategy 3: Truncate long messages
        if self._count_tokens(messages) > max_tokens:
            messages = self._truncate_longest(messages, max_tokens)

        return messages

    def _remove_greetings(self, messages: list[dict]) -> list[dict]:
        """Remove low-value greetings and acknowledgments."""
        greetings = {"hi", "hello", "thanks", "okay", "sure", "got it"}
        return [
            m for m in messages
            if not (m["role"] == "assistant" and
                    m["content"].strip().lower() in greetings)
        ]

    async def _summarize_older(self, messages: list[dict]) -> list[dict]:
        """Summarize messages beyond a threshold."""
        keep_recent = messages[-4:]  # Keep last 4 exchanges verbatim
        to_summarize = messages[:-4]

        if not to_summarize:
            return messages

        text = "\n".join(
            f"[{m['role']}]: {m['content'][:500]}"
            for m in to_summarize
        )

        summary = await self.llm.generate(
            f"Summarize this conversation history concisely while preserving "
            f"all key facts, decisions, and user preferences:\n\n{text}",
            max_tokens=200
        )

        return [
            {"role": "system", "content": f"[Summarized Context]: {summary}"}
        ] + keep_recent

    def _truncate_longest(self, messages: list[dict],
                           max_tokens: int) -> list[dict]:
        """Truncate the longest messages to fit budget."""
        while self._count_tokens(messages) > max_tokens:
            longest = max(
                messages,
                key=lambda m: len(m["content"].split())
            )
            # Truncate by half
            words = longest["content"].split()
            longest["content"] = " ".join(words[:len(words)//2])

        return messages

    def _count_tokens(self, messages: list[dict]) -> int:
        """Rough token estimation (4 chars ≈ 1 token)."""
        total = sum(len(m["content"]) for m in messages)
        return total // 4
```
