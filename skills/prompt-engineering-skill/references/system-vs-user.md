# System vs User Prompts

## System Prompt

Sets the overall behavior, constraints, and context. Applied once at the start of a conversation.

```
System: You are a helpful coding assistant. You write clean, documented code.
You always include type hints in Python. You favor readability over cleverness.
When you're unsure about something, you say so rather than guessing.
```

**Best for**: Persistent behavior that should apply across all turns.

## User Prompt

Contains the specific task or query for the current turn.

```
User: Write a function that calculates the Fibonacci sequence up to n terms.
```

## Best Practices for System Prompts

1. **Be authoritative**: Use imperative language ("You must...", "Always...")
2. **Include guardrails**: "Never execute code or make API calls"
3. **Define refusal behavior**: "If asked something harmful, explain why you can't"
4. **Keep it lean**: System prompts waste context window — only include what's necessary

## Combining System + User

```
System: You are a data analyst. Always respond with JSON. Use null for missing values.
Never fabricate data.

User: Analyze this CSV data and return summary statistics...
```
