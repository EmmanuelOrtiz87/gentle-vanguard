# Windsurf Adapter

Converts Foundation skills to Windsurf plugin format.

---

## Windsurf Plugin Format

Windsurf uses a plugin system with:

- **plugin.json**: Manifest with triggers and metadata
- **instructions.md**: AI context and instructions
- **Auto-loading**: Plugins load based on trigger patterns

---

## Features

✅ Converts `SKILL.md` → Windsurf plugin structure  
✅ Generates `plugin.json` manifest  
✅ Creates `instructions.md` for AI context  
✅ Generates project-level `windsurf.json` config  
✅ Preserves triggers and instructions

---

## Usage

### 1. Convert a Foundation Skill

```bash
node adapter.js convert-skill skills/react-19-skill/SKILL.md .windsurf/plugins
```

**Output**:

```
.windsurf/plugins/react-19-skill/
  ├── plugin.json
  └── instructions.md
```

### 2. Generate Project Config

```bash
node adapter.js generate-config skills/ .windsurf/windsurf.json
```

Creates `.windsurf/windsurf.json` with all available plugins.

---

## Plugin Structure

### plugin.json

```json
{
  "name": "react-19-skill",
  "version": "1.0.0",
  "description": "React 19 patterns with React Compiler",
  "triggers": ["React 19", "React Compiler", "useActionState"],
  "author": "Foundation",
  "foundation": true
}
```

### instructions.md

```markdown
# react-19-skill

> Foundation Skill (converted for Windsurf)

## Description

React 19 patterns with React Compiler

## Triggers

- React 19
- React Compiler
- useActionState

## Instructions

[Full skill content...]
```

---

## Integration with Foundation

1. **Detection**: `enhanced-detect.ps1` identifies Windsurf via `WINDSURF_CHAT_MODE` env var
2. **Pre-processing**: `pre-process-input.ps1` loads `tool-windsurf.json`
3. **Adapter path**: `adapters/format-adapters/windsurf-adapter/`

---

## Status

| Component               | Status      | Notes                       |
| ----------------------- | ----------- | --------------------------- |
| Skill Converter         | ✅ Ready    | SKILL.md → plugin structure |
| Config Generator        | ✅ Ready    | Generates windsurf.json     |
| Documentation           | ✅ Complete | This README                 |
| Detection Integration   | ✅ Ready    | Uses `WINDSURF_CHAT_MODE`   |
| Pre-process Integration | ✅ Ready    | Loads `tool-windsurf.json`  |

---

## Next Steps

1. ✅ **Implement adapter** (completed)
2. ⏳ **Test with real Windsurf IDE**
3. ⏳ **Add more plugin features** (custom UI, settings)
4. ⏳ **Support hot-reload** of skills

---

**Version**: 1.0.0  
**Status**: Ready for testing  
**Compatibility**: Windsurf IDE
