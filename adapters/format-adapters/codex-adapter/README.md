# Codex Adapter

Exposes Foundation capabilities via OpenAI-compatible function calling API.

---
## OpenAI Function Calling Format

Codex uses OpenAI's function calling. We can create a proxy that:
1. Accepts OpenAI-style function calls
2. Translates to Foundation CLI commands
3. Returns results in OpenAI format

---
## Implementation

### 1. Function Definitions (`functions.json`)

```json
[
  {
    "name": "foundation_review",
    "description": "Run 7D code review",
    "parameters": {
      "type": "object",
      "properties": {
        "path": { "type": "string" },
        "dimensions": { 
          "type": "array",
          "items": { "type": "string" }
        }
      },
      "required": ["path"]
    }
  },
  {
    "name": "foundation_audit",
    "description": "Run workspace audit",
    "parameters": {
      "type": "object",
      "properties": {
        "mode": { "type": "string", "enum": ["quick", "full"] }
      }
    }
  }
]
```

### 2. Proxy Server (`proxy.js`)

```javascript
const express = require('express');
const { execSync } = require('child_process');
const app = express();

app.post('/v1/chat/completions', (req, res) => {
  const { function_call, functions } = req.body;
  
  // Execute Foundation CLI based on function_call
  const result = executeFoundationFunction(function_call, functions);
  
  res.json({
    choices: [{
      message: {
        role: 'assistant',
        content: result,
      }
    }]
  });
});

app.listen(8080, () => {
  console.log('Codex adapter proxy running on port 8080');
});
```

---
## Usage with Codex

```bash
# Start proxy
node adapters/format-adapters/codex-adapter/proxy.js

# Configure Codex to use local endpoint
export OPENAI_API_BASE="http://localhost:8080/v1"
export OPENAI_API_KEY="dummy"  # Not needed for local

# Codex now uses Foundation via OpenAI-compatible API
```

---
## Status

🚧 **Implementation Pending**

Next steps:
1. Implement `proxy.js` with Express
2. Map OpenAI functions to Foundation CLI
3. Test with Codex
