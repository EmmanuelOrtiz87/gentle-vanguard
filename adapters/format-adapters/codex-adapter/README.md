# Codex Adapter

Converts Foundation skills to OpenAI Codex function calling format.

---

## OpenAI Codex Format

Codex uses:

- **Function calling**: JSON Schema for tool definitions
- **Chat Completions API**: `/v1/chat/completions` endpoint
- **Tools array**: List of available functions

---

## Features

✅ Converts `SKILL.md` → OpenAI function format  
✅ Generates tools array (all Foundation skills)  
✅ Creates proxy server for Codex integration  
✅ Strict JSON Schema (no additional properties)

---

## Usage

### 1. Convert a Foundation Skill

```bash
node adapter.js convert-skill skills/react-19-skill/SKILL.md react-19.json
```

**Output**: OpenAI-compatible function definition.

### 2. Generate All Tools

```bash
node adapter.js generate-tools skills/ tools.json
```

Creates `tools.json` with all Foundation skills as OpenAI functions.

### 3. Generate Proxy Server

```bash
node adapter.js generate-proxy proxy.js
npm install express
node proxy.js
```

Creates a proxy that translates between Codex and Foundation.

---

## Function Format

```json
{
  "type": "function",
  "function": {
    "name": "react_19_skill",
    "description": "React 19 patterns with React Compiler",
    "parameters": {
      "type": "object",
      "properties": {
        "task": {
          "type": "string",
          "description": "The task to execute using this skill"
        }
      },
      "required": ["task"],
      "additionalProperties": false
    }
  }
}
```

---

## Integration with Foundation

1. **Detection**: `enhanced-detect.ps1` identifies Codex via `CODEX_SESSION` env var
2. **Pre-processing**: `pre-process-input.ps1` loads `tool-codex.json`
3. **Adapter path**: `adapters/format-adapters/codex-adapter/`

---

## Proxy Server

The proxy server allows Codex to use Foundation skills:

```bash
# Start proxy
node proxy.js

# Configure Codex to use proxy
export CODEX_API_BASE="http://localhost:3000/v1"
```

---

## Status

| Component               | Status   | Notes                      |
| ----------------------- | -------- | -------------------------- |
| Skill Converter         | ✅ Ready | SKILL.md → OpenAI function |
| Tools Generator         | ✅ Ready | Batch conversion           |
| Proxy Server            | ✅ Ready | Express-based proxy        |
| Detection Integration   | ✅ Ready | Uses `CODEX_SESSION` env   |
| Pre-process Integration | ✅ Ready | Loads `tool-codex.json`    |

---

## Next Steps

1. ✅ **Implement adapter** (completed)
2. ⏳ **Test with real Codex**
3. ⏳ **Add streaming support**
4. ⏳ **Support OpenAI SDK directly**

---

**Version**: 1.0.0  
**Status**: Ready for testing  
**Compatibility**: OpenAI Codex, OpenAI API
