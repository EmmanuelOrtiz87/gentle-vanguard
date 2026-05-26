---
name: ai-sdk-5-skill
description: >
  Vercel AI SDK 5 patterns: streaming, AI objects, tools, messages. Trigger: "AI SDK", "AI SDK 5",
  "streamText", "generateText", "AI provider".
---

## When to Use

- Building AI chat features
- Streaming responses
- Tool use with AI
- Multi-provider AI integration

## Basic Setup

```typescript
import { createAI } from 'ai-sdk';
import { openai } from '@ai-sdk/openai';
import { anthropic } from '@ai-sdk/anthropic';

export const ai = createAI({
  providers: [openai('gpt-4o'), anthropic('claude-3-5-sonnet')],
  defaultId: 'openai',
});
```

## generateText (Non-Streaming)

```typescript
import { generateText } from 'ai';

const { text, usage, finishReason } = await generateText({
  model: openai('gpt-4o'),
  prompt: 'Explain quantum computing in simple terms.',
});

console.log(text);
console.log(usage);
// { promptTokens: 10, completionTokens: 150, totalTokens: 160 }
```

## streamText (Streaming)

```typescript
import { streamText } from 'ai';

const result = await streamText({
  model: openai('gpt-4o'),
  prompt: 'Write a poem about AI.',
});

// In API route / streaming response
export async function POST(req: Request) {
  const { prompt } = await req.json();

  const result = await streamText({
    model: openai('gpt-4o'),
    prompt,
  });

  return result.toDataStreamResponse();
}
```

## Messages Format

```typescript
import { generateText } from 'ai';

const { text } = await generateText({
  model: openai('gpt-4o'),
  messages: [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'Hello!' },
    { role: 'assistant', content: 'How can I help you?' },
    { role: 'user', content: 'What is 2+2?' },
  ],
});
```

## Tools

```typescript
import { generateText, tool } from 'ai';
import { z } from 'zod';

const result = await generateText({
  model: openai('gpt-4o'),
  messages: [{ role: 'user', content: 'What is the weather in Tokyo?' }],
  tools: [
    {
      tool: 'getWeather',
      description: 'Get weather for a city',
      parameters: z.object({
        city: z.string(),
        unit: z.enum(['celsius', 'fahrenheit']).optional(),
      }),
    },
  ],
  onStepFinish: ({ toolCalls }) => {
    // Handle tool calls
    if (toolCalls?.toolCalls) {
      for (const call of toolCalls.toolCalls) {
        console.log(call.toolName, call.args);
      }

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
