# Core Implementation Patterns

## Shared Infrastructure

Create shared utilities:

- API client with authentication
- Error handling helpers
- Response formatting (JSON/Markdown)
- Pagination support

## Input Schema

- Use Zod (TypeScript) or Pydantic (Python)
- Include constraints and clear descriptions
- Add examples in field descriptions

## Output Schema

- Define `outputSchema` where possible for structured data
- Use `structuredContent` in tool responses (TypeScript SDK feature)
- Helps clients understand and process tool outputs

## Tool Description

- Concise summary of functionality
- Parameter descriptions
- Return type schema

## Implementation

- Async/await for I/O operations
- Proper error handling with actionable messages
- Support pagination where applicable
- Return both text content and structured data when using modern SDKs

## Annotations

| Annotation        | Type    | Default | Description                                             |
| ----------------- | ------- | ------- | ------------------------------------------------------- |
| `readOnlyHint`    | boolean | false   | Tool does not modify its environment                    |
| `destructiveHint` | boolean | true    | Tool may perform destructive updates                    |
| `idempotentHint`  | boolean | false   | Repeated calls with same args have no additional effect |
| `openWorldHint`   | boolean | true    | Tool interacts with external entities                   |
