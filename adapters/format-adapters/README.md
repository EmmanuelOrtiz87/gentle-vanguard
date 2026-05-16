# Format Adapters

Translate between Gentle-Vanguard's standard format and tool-specific formats for tools that don't
support MCP.

---

## Why Format Adapters?

While **MCP Bridge** is the optimal solution (covers all MCP-compatible tools), some tools have
their own plugin systems:

| Tool             | Protocol                  | Solution                   |
| ---------------- | ------------------------- | -------------------------- |
| **Windsurf**     | Proprietary plugin format | `windsurf-adapter/`        |
| **Codex**        | OpenAI function calling   | `codex-adapter/`           |
| **Antigravity**  | Mission Control API       | `antigravity-adapter/`     |
| **Any MCP tool** | MCP (standard)            | Use **MCP Bridge** instead |

---

## Adapter Structure

Each adapter follows the same pattern:

```
format-adapters/
 windsurf-adapter/
    SKILL.md           # Converted skill (Windsurf format)
    adapter.js          # Translation script
    README.md         # Adapter documentation
 codex-adapter/
    functions.json     # OpenAI function definitions
    proxy.js           # HTTP proxy to Gentle-Vanguard
    README.md
 antigravity-adapter/
    mission-control.json # Mission Control config
    adapter.js
    README.md
 README.md (this file)
```

---

## Usage

### Windsurf Adapter

```bash
# Convert Gentle-Vanguard skills to Windsurf format
node adapters/format-adapters/windsurf-adapter/adapter.js \
  --input skills/react-19-skill/SKILL.md \
  --output ~/.windsurf/skills/react-19.md
```

### Codex Adapter

```bash
# Start proxy server (OpenAI-compatible endpoint)
node adapters/format-adapters/codex-adapter/proxy.js \
  --port 8080 \
  --gentle-vanguard-root /path/to/gentle-vanguard

# Codex can now call: POST http://localhost:8080/v1/functions
```

### Antigravity Adapter

```bash
# Generate Mission Control config
node adapters/format-adapters/antigravity-adapter/adapter.js \
  --gentle-vanguard-root /path/to/gentle-vanguard \
  --output ~/.antigravity/mission-control.json
```

---

## Translation Process

```

  Gentle-Vanguard        Format           Tool-Specific
  SKILL.md              Adapter               Format
  (Standard)            (Translate)           (Windsurf/
            Codex/etc.)

```

---

## Implementation Status

| Adapter     | Status  | Priority | Notes                           |
| ----------- | ------- | -------- | ------------------------------- |
| Windsurf    | Pending | HIGH     | Research Windsurf plugin format |
| Codex       | Pending | MEDIUM   | OpenAI-compatible endpoint      |
| Antigravity | Pending | LOW      | Mission Control API research    |

---

## Adding a New Adapter

1. Create directory: `adapters/format-adapters/{tool}-adapter/`
2. Research the tool's plugin/extension format
3. Create adapter script that translates:
   - **From**: Gentle-Vanguard SKILL.md format
   - **To**: Tool-specific format
4. Document in `README.md`
5. Add to compatibility matrix in `adapters/docs/COMPATIBILITY-MATRIX.md`

---

**Note**: Prefer **MCP Bridge** when possible - it's more maintainable and future-proof.

