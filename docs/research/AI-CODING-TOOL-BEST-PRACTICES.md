# AI Coding Tool Configuration Best Practices — Research Report

> **Date**: 2026-05-28 | **Scope**: OpenCode, Claude Code, Cursor, Windsurf, Cline
> **Status**: Consolidated findings with actionable recommendations for gentle-vanguard

---

## Table of Contents

1. [Configuration Management](#1-configuration-management)
2. [Prompt Optimization](#2-prompt-optimization)
3. [Validation Gates](#3-validation-gates)
4. [Safety Patterns](#4-safety-patterns)
5. [Testing AI Tool Configs](#5-testing-ai-tool-configs)
6. [Schema-Driven Development](#6-schema-driven-development)
7. [Actionable Recommendations for gentle-vanguard](#7-actionable-recommendations-for-gentle-vanguard)

---

## 1. Configuration Management

### 1.1 Industry Config File Formats

| Tool | Config File | Format | Schema | Validation |
|------|------------|--------|--------|------------|
| **OpenCode** | `opencode.json` | JSON | `https://opencode.ai/config.json` (Draft 2020-12) | Strict: `additionalProperties: false`, variable substitution `{env:VAR}`, `{file:path}` |
| **Claude Code** | `.claude/settings.json` | JSON | `https://json.schemastore.org/claude-code-settings.json` | Managed drop-in: `managed-settings.d/*.json` with deep-merge |
| **Cursor** | `.cursor/rules/*.mdc` | MD + YAML frontmatter | Implicit (editor-enforced) | Frontmatter fields: `description`, `globs`, `alwaysApply` |
| **Windsurf** | `.windsurf/config.json` | JSON | Implicit (rejects unknown props at runtime) | No custom properties allowed — tool errors on unknown keys |
| **Cline** | `.clinerules` | Markdown | N/A | Free-form markdown, no structural validation |

### 1.2 Config Layering Pattern (All Tools)

Every major tool uses a **multi-layered config** approach:

```
Managed/Org  →  Global/User  →  Project  →  Local (gitignored)
   (highest precedence)              (lowest precedence, but overrides on merge)
```

**Key differences**:
- **Claude Code** has the richest layering: `managed > CLI flags > local > project > user`, plus managed drop-in directory (`managed-settings.d/*.json` deep-merged alphabetically) and MDM/GPO for enterprise
- **OpenCode** uses `project/AGENTS.md > global/AGENTS.md > CLAUDE.md fallback` with env-var toggles for Claude Code compatibility
- **Cursor** uses `project/.cursor/rules/*.mdc > global settings (Cmd+Shift+P)`
- **Windsurf** uses single `.windsurf/config.json` with sections

### 1.3 Custom Config vs Tool Config — Separation Pattern

**Industry consensus**: NEVER add custom properties to tool configs. Tools reject unknown props at startup (OpenCode's `additionalProperties: false`, Windsurf's runtime rejection).

**Standard pattern** (observed across all major tools):

```
config/
  tool-opencode.json       # OpenCode-specific orchestration config
  tool-claude-code.json    # Claude Code-specific config
  workspace.config.json    # Project workspace metadata
  opencode.schema.json     # Schema for opencode.json validation
  orchestrator.json        # Cross-tool orchestration (own schema)
```

**gentle-vanguard already implements this** — tool configs live in `config/tool-*.json`, each scoped to a single tool. The `opencode.schema.json` is the validation gate.

### 1.4 Variable Substitution (OpenCode-specific)

OpenCode supports two substitution types in `opencode.json`:
- `{env:VARIABLE_NAME}` — environment variable
- `{file:path/to/file}` — file contents (relative or absolute)

This is unique among the tools — Claude Code uses `.claude/settings.json` with no variable substitution. Cursor/Windsurf/Cline don't support it either.

### 1.5 Permission Models Comparison

| Tool | Granularity | Wildcards | Default Deny | Agent-scoped |
|------|-------------|-----------|--------------|--------------|
| **OpenCode** | Per-tool (`read`, `edit`, `bash`, `grep`, etc.) | `*`, `?` | `.env` files | ✅ via `agent.{name}.permission` |
| **Claude Code** | Per-tool (allow/deny/ask lists) | Full glob | Partial | ❌ |
| **Cursor** | Implicit (editor trust model) | — | ❌ | ❌ |
| **Windsurf** | Per-tool (deny/allow/ask) | — | Can disable web | ❌ |
| **Cline** | VS Code approval mode | — | Via autoApprovalMode | ❌ |

---

## 2. Prompt Optimization

### 2.1 Semantic Compression

**Industry best practice**: Compress system prompts to maximize useful context. Observed patterns:

| Technique | Reduction | Tool Implementation |
|-----------|-----------|-------------------|
| Abbreviation dictionaries | 97% | gentle-vanguard `semantic-compression.ps1`: `impl/fn/cfg/req/opt/ref/std/perf/sec/dev/prod/env/db/app/svc/repo` |
| Response profiles | Varies | `orchestrator.json#response_profiles`: `ultra`/`lite`/`lleno` tiers |
| Layer-based context | 60-95% | `TOKEN-EFFICIENCY-PACK.md`: Layer A (objective+files) → B (snippets) → C (architecture) |

**OpenCode-specific**: System prompt managed via `AGENTS.md` + skills system. Skills auto-load based on task matching. The `/init` command generates AGENTS.md from repo scan.

### 2.2 Prompt Caching

| Tool | Caching Strategy | TTL | Key |
|------|-----------------|-----|-----|
| **OpenCode** | `setCacheKey: true` in `opencode.json#compaction` | Session | SHA256 of instructions |
| **gentle-vanguard** | `pre-process-input.ps1` SHA256 cache | 30 min | Prompt + config hash |
| **Claude Code** | Built-in Anthropic prompt caching | Per-context | Automatic |

**Best practice** (from gentle-vanguard's `prompt-cache.ps1`):
```powershell
# Cache by SHA256 hash of prompt content
$hash = (Get-FileHash "CLAUDE.md" -Algorithm SHA256).Hash.Substring(0,16)
prompt-cache.ps1 -Action set -PromptHash $hash -PromptContent $content

# Check stats
prompt-cache.ps1 -Action stats
```

### 2.3 Token Budget Management

**5-tier budget system** (from `TOKEN-CONTEXT-STANDARDS.md`):

| Tier | Total Budget | System Prompt | Use Case |
|------|-------------|---------------|----------|
| Minimal | 5,000 | 500 (10%) | Quick responses |
| Standard | 15,000 | 1,500 (10%) | Normal dev tasks |
| Extended | 50,000 | 5,000 (10%) | Complex analysis |
| Maximum | 100,000 | 10,000 (10%) | Project-wide tasks |
| Unlimited | 200,000 | 20,000 (10%) | Claude Opus only |

The 10% system-prompt-to-total-budget ratio is a consistent pattern.

### 2.4 Versioning Strategy

**Semantic versioning for prompts** (`rules/NORMATIVAS-CONFIG.md`):
- Breaking changes → increment major
- New options → increment minor
- Bug fixes → increment patch

**Prompt versioning script** (`prompt-versioning.ps1`):
```powershell
prompt-versioning.ps1 -Action save -PromptName "CLAUDE" -Content (Get-Content "CLAUDE.md" -Raw)
```

### 2.5 Context Compaction

**OpenCode built-in**: `opencode.json#compaction` controls context compaction behavior. Configurable thresholds and retention policies.

**gentle-vanguard**: Auto-compaction at ~15k tokens with 90% retention. Preserved items: FIXME, TODO, BUG, decisions, RESULT. Implemented via `pre-compact-hook.ps1`.

---

## 3. Validation Gates

### 3.1 Pre-Config-Change Validation

**Pattern**: Before ANY modification to tool configs (`opencode.json`, `.claude/settings.json`, `.cursor/rules/*.mdc`, `.windsurf/config.json`, `.clinerules`):

```
1. Read current config
2. Validate against schema (JSON Schema or allowlist)
3. Stage changes
4. Validate final config
5. Run startup simulation (dry-run)
```

### 3.2 Allowlist Validation (gentle-vanguard pattern)

`scripts/utilities/CONFIG/validate-opencode-config.ps1` uses a strict **allowlist**:

```powershell
$validProps = @(
    '$schema', 'agent', 'attachment', 'autoshare', 'autoupdate',
    'command', 'compaction', 'default_agent',
    'disabled_providers', 'enabled_providers', 'enterprise', 'experimental',
    'formatter', 'instructions', 'layout', 'logLevel', 'lsp',
    'mcp', 'mode', 'model',
    'permission', 'plugin', 'provider',
    'reference', 'server', 'share', 'shell', 'skills',
    'small_model', 'snapshot',
    'tools', 'tool_output',
    'username', 'watcher'
)
```

Any property not in the list → FAIL + exit 1. Optional `-Fix` flag strips unknown properties.

### 3.3 JSON Structural Validation

`rules/NORMATIVAS-JSON-CONSTRUCTION.md` mandates a **2-second mental check** before every tool call with JSON params:

1. Quotes `"`: must be EVEN
2. Braces `{` and `}`: must be EQUAL
3. Brackets `[` and `]`: must be EQUAL
4. Last character must be `}` or `]`
5. No trailing commas

Auto-validation hook available:
```powershell
pwsh -NoProfile -File hooks/pre-tool-call-validate.ps1 `
  -ToolName "<tool>" -JsonPayload '<json>' -AutoFix
```

### 3.4 Startup Validation Checklist

From `CONFIGURATION-VALIDATION-CHECKLIST.md`, the startup chain validates:

1. **Core configs exist**: `opencode.json`, `context-efficiency-config.json`, `session-autostart.config.json`, `hooks-config.json`
2. **Directory structure**: `docs/`, `config/`, `.github/workflows/`, `.session/logs/`
3. **Hook scripts present and executable**
4. **Comprehensive validation**: `comprehensive-validation.ps1` → 100% pass rate
5. **Cross-workspace validation**: `cross-workspace-validator.ps1` → no conflicts

### 3.5 CI/CD Validation Gates

**Recommended pipeline**: Validate every config against its schema on every PR:

```yaml
# .github/workflows/validate-config.yml
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate configs against schemas
        run: |
          npm install ajv ajv-formats
          node -e "
            const Ajv = require('ajv');
            const addFormats = require('ajv-formats');
            const ajv = new Ajv();
            addFormats(ajv);
            const schema = require('./config/opencode.schema.json');
            const validate = ajv.compile(schema);
            const configs = ['tool-opencode.json'];
            configs.forEach(f => {
              const cfg = require('./config/' + f);
              if (!validate(cfg)) {
                console.error(f, JSON.stringify(validate.errors, null, 2));
                process.exit(1);
              }
            });
          "
```

---

## 4. Safety Patterns

### 4.1 The "Don't Break the Tool" Triple Guard

**gentle-vanguard's triple blindaje** (`docs/AGENTS.md#Hard-Rules--Config-Safety`):

1. **NO custom props in tool configs** — validate before deploy
2. **Separate config per concern** — prompt optimization goes in `config/system-prompt-optimization.json`, never inline in tool configs
3. **Validate script MUST run before any change to `opencode.json`**

### 4.2 Fallback Chain Pattern

`config/orchestrator.json` implements a multi-level fallback:

```json
{
  "fallbackTool": "opencode",
  "fallbackPromptFile": "CLAUDE.md",
  "canonicalEntryPoint": "docs/AGENTS.md",
  "preProcessing": { "fallbackBehavior": "continue", "fallbackStrategy": "clarify-ba" }
}
```

**Applies to all config layers**: Tool detection → Prompt file → Pre-processing → Behavioral fallback.

### 4.3 Break Glass Override

`orchestrator.json#break_glass` triggers auto-override when:
- User reports incomplete task
- Same task extends 3+ turns
- Loop detected
- Output truncated/insufficient

Override direction: `ultra/chat-compact` → `lleno/chat-balanced`. Abuse prevention: max 3/session, 2/hour, cooldown 5 turns.

### 4.4 Constraint Optimization (Adaptive Trust)

`orchestrator.json#subagent_orchestration.constraint_optimization`:
- Tracks constraint retention per agent
- After 3 passes with compliance → constraints auto-removed
- Reset on failure
- Strategy: `soft_drop` (notify on drop = false)

### 4.5 Token Guard (Operational Safety)

From `TOKEN_GUARD_IMPLEMENTATION.md`:

| Threshold | Action |
|-----------|--------|
| 70% (soft) | WARN — log and continue |
| 90% (hard) | BLOCK — refuse dispatch |
| 95% | Auto-pause via `Pause-Dispatch` |

Budget: 30,000 tokens/day, 750/agent, fragmented into 5 rounds of 25,600 tokens.

### 4.6 Security Model Comparison

| Tool | .env Protection | External Dir Control | Doom Loop Detect | MDM/GPO |
|------|----------------|---------------------|------------------|---------|
| **OpenCode** | ✅ Denied by default | ✅ `external_directory` permission | ✅ 3× identical tool call | ❌ |
| **Claude Code** | ✅ | ✅ Sandbox mode | ❌ Native | ✅ Full MDM + managed-settings |
| **Cursor** | ❌ | ❌ | ❌ | ❌ |
| **Windsurf** | ❌ | ✅ `allowExternalTools` | ❌ | ❌ |
| **Cline** | ❌ | ❌ | ❌ | ❌ |

---

## 5. Testing AI Tool Configs

### 5.1 Config Validation Tests

**Pattern**: Test config loading the same way the tool loads it at startup.

```javascript
// test/config-validation.test.js
const Ajv = require('ajv')
const addFormats = require('ajv-formats')
const schema = require('../config/opencode.schema.json')

describe('Config validation', () => {
  let ajv, validate

  beforeAll(() => {
    ajv = new Ajv()
    addFormats(ajv)
    validate = ajv.compile(schema)
  })

  it('tool-opencode.json is valid', () => {
    const cfg = require('../config/tool-opencode.json')
    const valid = validate(cfg)
    expect(valid).toBe(true)
  })

  it('rejects unknown properties', () => {
    const bad = { ...require('../config/tool-opencode.json'), unknownProp: 'test' }
    expect(validate(bad)).toBe(false)
  })
})
```

### 5.2 Property-Based Testing

Using `fast-check` for combinatorial config testing:

```javascript
const fc = require('fast-check')

describe('config robustness', () => {
  it('accepts all valid logLevel values', () => {
    fc.assert(fc.property(
      fc.constantFrom('DEBUG', 'INFO', 'WARN', 'ERROR'),
      (level) => {
        const cfg = { logLevel: level, mode: 'plan' }
        return ajv.validate(schema, cfg)
      }
    ))
  })
})
```

### 5.3 Integration Test: Full Load Pipeline

Test the complete config loading chain:
1. Read file from disk
2. Parse JSON
3. Validate against schema
4. Apply defaults
5. Verify tool can consume the config

```javascript
it('loads and validates complete config pipeline', () => {
  const raw = fs.readFileSync('config/tool-opencode.json', 'utf8')
  const parsed = JSON.parse(raw)
  const valid = ajv.validate(schema, parsed)
  expect(valid).toBe(true)
  expect(() => tool.initialize(parsed)).not.toThrow()
})
```

### 5.4 Cross-Tool Config Consistency Tests

Verify that configs referencing the same concept across tools are consistent:

```javascript
it('tool configs reference valid script paths', () => {
  ['tool-opencode.json', 'tool-claude-code.json', 'tool-cursor.json'].forEach(f => {
    const cfg = require(`../config/${f}`)
    if (cfg.hooks?.preToolCall) {
      expect(fs.existsSync(cfg.hooks.preToolCall)).toBe(true)
    }
  })
})
```

---

## 6. Schema-Driven Development

### 6.1 JSON Schema Best Practices for Dev Tools

**Standard template** (from opencode.schema.json and Ajv best practices):

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Config Schema Title",
  "description": "Human-readable description",
  "type": "object",
  "properties": {
    "key": { "type": "string", "description": "Purpose of this key" },
    "constrained": { "type": "string", "enum": ["value1", "value2"] }
  },
  "required": ["key"],
  "additionalProperties": false
}
```

**Critical rules**:
1. **Always** set `additionalProperties: false` — prevents silent drift from typos
2. **Always** set `$schema` — enables editor autocomplete + validation
3. **Always** use `enum` instead of open `string` for constrained values
4. **Always** add `description` on every property — doubles as documentation

### 6.2 Schema Composition Patterns

| Keyword | Logic | Use Case |
|---------|-------|----------|
| `allOf` | AND | Merge constraints from multiple schemas |
| `anyOf` | OR | Alternative formats |
| `oneOf` | XOR | Discriminated unions (exactly one match) |
| `not` | NOT | Exclusion rules |

**Reusable fragment pattern** (`$defs` + `$ref`):

```json
{
  "$defs": {
    "name": { "type": "string", "pattern": "^[a-z0-9-]+$" }
  },
  "properties": {
    "tool": { "$ref": "#/$defs/name" },
    "displayName": { "$ref": "#/$defs/name" }
  }
}
```

### 6.3 Schema → TypeScript Code Generation

```bash
npx json2ts config/opencode.schema.json > src/types/config.ts
```

Generates TypeScript interfaces that stay in sync with the schema. This is used by webpack, Nx, and Alibaba LowCode Engine.

### 6.4 Preventing Config Drift

**Drift prevention matrix**:

| Drift Scenario | Prevention | Tool Support |
|---------------|------------|-------------|
| Typo in property name | `additionalProperties: false` | Schema validation |
| Removed required field | CI gating + schema version check | CI pipeline |
| Optional → Required migration | Never remove fields; add optional only | Schema governance |
| Env-specific divergence | Single source of truth + CI validation | `workspace.config.json` |
| Outdated schema | `$schema` URL + version field | `config/orchestrator.json#version` |

### 6.5 Compound Schema Documents (Draft 2020-12+)

Multiple versions in one file using `$id`:
```json
{
  "$id": "https://my-org/schemas/tool-config",
  "$defs": {
    "v1": { ... },
    "v2": { ... }
  }
}
```

### 6.6 gentle-vanguard's Current Schema Maturity

| Aspect | Status | Assessment |
|--------|--------|------------|
| Config schema | ✅ `opencode.schema.json` | Well-structured, Draft 07 |
| Schema-to-types generation | ❌ Not implemented | Should add `json2ts` |
| CI schema validation | ❌ Not implemented | Should add GitHub Action |
| Cross-tool consistency | ✅ `config/orchestrator.json` | Versioned, validated |
| Plugin schema | ✅ `plugin-manifest-schema.json` | Uses `oneOf` for polymorphic commands |
| Tool configs per tool | ✅ `config/tool-*.json` | Follows separation pattern |
| Validate script | ✅ `validate-opencode-config.ps1` | Allowlist-based |
| JSON construction rules | ✅ `NORMATIVAS-JSON-CONSTRUCTION.md` | Agent-enforced |

---

## 7. Actionable Recommendations for gentle-vanguard

### Priority: High (Implement Now)

1. **Add CI config validation** — Create `.github/workflows/validate-config.yml` that runs `ajv` against `opencode.schema.json` for all config files on every PR.

2. **Generate TypeScript types from schemas** — Add `npx json2ts` step to generate `src/types/config.ts` from `opencode.schema.json` and `plugin-manifest-schema.json`.

3. **Extend validate-opencode-config.ps1 to all tool configs** — Currently validates only `opencode.json`. Extend to check `.claude/settings.json`, `.cursor/rules/*.mdc`, `.windsurf/config.json`, `.clinerules` against their respective schemas.

4. **Startup dry-run test** — Create `test/config-validation.test.js` that validates ALL config files can be parsed, validated, and consumed without errors.

### Priority: Medium (Next Sprint)

5. **Schema versioning** — Bump `opencode.schema.json` to Draft 2020-12 for compound schema support. Add `version` field to all schemas.

6. **Property-based config tests** — Add `fast-check` to test combinatorial config validity across valid value ranges.

7. **Cross-tool consistency CI** — Verify that `hooks` script paths in `config/tool-*.json` resolve to existing files.

8. **Add `$schema` to all tool-specific configs** — Ensure `config/tool-*.json` files reference their schema.

### Priority: Low (Backlog)

9. **Config documentation generator** — Auto-generate config docs from `description` fields in schemas.

10. **Config drift dashboard** — Track schema version vs config file age; flag outdated configs.

11. **Managed drop-in support** — Implement `managed-settings.d/*.json` pattern (Claude Code) for enterprise config override.

### Critical Rules Summary

```
┌─────────────────────────────────────────────────────────────┐
│ 1. NO custom props in tool configs                          │
│ 2. Validate configs before change, at startup, and in CI    │
│ 3. Keep prompt context under 10% of total budget            │
│ 4. Use separate config files per concern (tool/custom/beh)   │
│ 5. Always set additionalProperties: false in schemas        │
│ 6. Fallback chain for every config layer                    │
│ 7. Version all schemas and prompts semantically             │
│ 8. Test config loading the same way the tool loads it       │
│ 9. Cache prompts by SHA256 hash with TTL                    │
│ 10. Break glass must have cooldown to prevent abuse         │
└─────────────────────────────────────────────────────────────┘
```

---

## References

- OpenCode Docs: https://opencode.ai/docs/config/ | https://opencode.ai/docs/rules/ | https://opencode.ai/docs/permissions/
- OpenCode Schema: `config/opencode.schema.json`
- Orchestrator Config: `config/orchestrator.json`
- Validate Script: `scripts/utilities/CONFIG/validate-opencode-config.ps1`
- JSON Normative: `rules/NORMATIVAS-JSON-CONSTRUCTION.md`
- Token Standards: `docs/guides/TOKEN-CONTEXT-STANDARDS.md`
- Efficiency Pack: `docs/supplementary/TOKEN-EFFICIENCY-PACK.md`
- Validation Checklist: `docs/CONFIGURATION-VALIDATION-CHECKLIST.md`
- Token Guard: `docs/reference/TOKEN_GUARD_IMPLEMENTATION.md`
- Ajv docs: https://ajv.js.org/guide/managing-schemas.html
- JSON Schema: https://json-schema.org/understanding-json-schema
