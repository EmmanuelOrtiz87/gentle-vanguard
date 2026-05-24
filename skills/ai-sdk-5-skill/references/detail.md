    }
  },
});

if (result.toolCalls) {
  for (const call of result.toolCalls) {
    if (call.toolName === 'getWeather') {
      const weather = await getWeather(call.args.city);
      // Continue with weather data
    }
  }
}
```

## Vercel AI SDK UI

```tsx
import { useChat } from 'ai/react';

export function Chat() {
  const { messages, input, handleInputChange, handleSubmit } = useChat();

  return (
    <div>
      {messages.map((m) => (
        <div key={m.id}>
          <strong>{m.role}:</strong> {m.content}
        </div>
      ))}

      <form onSubmit={handleSubmit}>
        <input value={input} onChange={handleInputChange} placeholder="Type a message..." />
        <button type="submit">Send</button>
      </form>
    </div>
  );
}
```

## Provider Configuration

```typescript
import { createAI } from 'ai-sdk';
import { openai } from '@ai-sdk/openai';
import { anthropic } from '@ai-sdk/anthropic';

// Custom provider configuration
const customOpenAI = openai('gpt-4o', {
  baseURL: 'https://api.openai.com/v1',
  apiKey: process.env.OPENAI_API_KEY,
});

export const ai = createAI({
  providers: [
    { provider: customOpenAI, id: 'openai' },
    { provider: anthropic('claude-3-5-sonnet'), id: 'anthropic' },
  ],
  defaultId: 'openai',
});
```

## Error Handling

```typescript
import { generateText, AI SDKError } from 'ai';

try {
  const result = await generateText({
    model: openai('gpt-4o'),
    prompt: 'Hello',
    maxTokens: 100,
  });
} catch (error) {
  if (error instanceof AI SDKError) {
    switch (error.code) {
      case 'invalid_api_key':
        // Handle invalid API key
        break;
      case 'rate_limit_exceeded':
        // Handle rate limit
        break;
      case 'context_length_exceeded':
        // Handle context length
        break;
    }
  }
}
```

## Quick Reference

| Pattern    | Code                              |
| ---------- | --------------------------------- |
| Non-stream | `generateText({ model, prompt })` |
| Streaming  | `streamText({ model, prompt })`   |
| Messages   | `messages: [{role, content}]`     |
| Tools      | `tools: [{ tool, parameters }]`   |
| React UI   | `useChat()` from 'ai/react'       |
| Response   | `result.toDataStreamResponse()`   |