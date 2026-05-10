# Antigravity Mission Control Adapter

Converts Foundation skills and workflows to Antigravity Mission Control format.

---

## Antigravity Mission Control Format

Antigravity uses:

- **Mission Control**: Multi-agent orchestration dashboard
- **AGENTS.md**: Agent configuration (cross-tool compatible with Cursor, Claude Code)
- **AgentKit 2.0**: Framework for building specialized agents
- **mission.yaml**: Task definition for multi-agent workflows

---

## Features

✅ Converts Foundation `SKILL.md` → Antigravity Mission Control JSON  
✅ Generates cross-tool `AGENTS.md` from Foundation skills  
✅ Creates `mission.yaml` for multi-agent workflows  
✅ Maps Foundation skills to AgentKit 2.0 agent roles  
✅ Supports parallel and sequential execution patterns

---

## Installation

```bash
cd adapters/format-adapters/antigravity-adapter
# No external dependencies needed (uses built-in Node.js modules)
```

---

## Usage

### 1. Convert a Foundation Skill

```bash
node adapter.js convert-skill skills/react-19-skill/SKILL.md output/react-19.json
```

**Output**: Antigravity-compatible JSON with agent configuration.

### 2. Generate AGENTS.md

```bash
node adapter.js generate-agents-md skills/ AGENTS.md
```

Creates cross-tool compatible `AGENTS.md` that works with:

- ✅ Antigravity Mission Control
- ✅ Cursor
- ✅ Claude Code / OpenCode

### 3. Generate mission.yaml

```bash
node adapter.js generate-mission '[{"name":"dev","instructions":"Implement feature"}]' mission.yaml
```

---

## Agent Role Mapping

| Foundation Skill          | Antigravity Agent Role |
| ------------------------- | ---------------------- |
| react-19-skill            | frontend               |
| angular-spa-skill         | frontend               |
| go-api / django-drf-skill | backend                |
| docker-devops-skill       | devops                 |
| testing-skill             | tester                 |
| security-skill            | security               |
| documentation-governance  | writer                 |

---

## Integration with Foundation

The adapter integrates with Foundation's detection system:

1. **Detection**: `enhanced-detect.ps1` identifies Antigravity via `ANTIGRAVITY_SESSION` env var
2. **Pre-processing**: `pre-process-input.ps1` loads `tool-antigravity.json`
3. **Adapter path**: `adapters/format-adapters/antigravity-adapter/`

---

## Example: Multi-Agent Workflow

```yaml
# mission.yaml (generated)
mission:
  name: 'E-commerce Platform Build'
  max_agents: 5
  timeout: 7200

agents:
  - role: orchestrator
    model: gemini-3-pro
    instructions: 'Coordinate development using Foundation skills'

  - role: frontend
    model: gemini-3-pro
    instructions: 'Build UI with react-19-skill'
    depends_on: [orchestrator]

  - role: backend
    model: gemini-3-pro
    instructions: 'Build API with go-api skill'
    depends_on: [orchestrator]

  - role: tester
    model: gemini-3-flash
    instructions: 'Test with testing-skill'
    depends_on: [frontend, backend]
```

---

## Status

| Component               | Status   | Notes                                    |
| ----------------------- | -------- | ---------------------------------------- |
| Skill Converter         | ✅ Ready | Converts SKILL.md → Mission Control JSON |
| AGENTS.md Generator     | ✅ Ready | Cross-tool compatible                    |
| Mission YAML Generator  | ✅ Ready | Multi-agent workflows                    |
| Detection Integration   | ✅ Ready | Uses `ANTIGRAVITY_SESSION` env           |
| Pre-process Integration | ✅ Ready | Loads `tool-antigravity.json`            |

---

## Next Steps

1. ✅ **Implement adapter** (completed)
2. ⏳ **Test with real Antigravity Mission Control**
3. ⏳ **Add more agent role mappings**
4. ⏳ **Support AgentKit 2.0 specialized agents** (16 agents)

---

**Version**: 1.0.0  
**Status**: Ready for testing  
**Compatibility**: Antigravity Mission Control, AgentKit 2.0
