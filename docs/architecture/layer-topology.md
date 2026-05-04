# 5-Layer Topology Architecture

## Overview

The workspace-foundation implements a 5-layer topology for AI agent tooling, designed to be fully agnostic across agents, operating systems, tools, plugins, and programming languages.

## Layer Architecture

```

  Layer 5: Agentes (Agents)                        
  Abstract layer for AI agents executing tasks      

                          
                          

  Layer 4: Comandos (Commands/Tools)                
  Executable operations (bash, read, write, etc.)   

                          
                          

  Layer 3: MCP (Model Context Protocol)              
  Standardized tool/service integration protocol     

                          
                          

  Layer 2: Skills                                    
  Domain-specific knowledge and patterns              

                          
                          

  Layer 1: Memoria (Memory)                          
  Persistent state and context management            

```

## Layer Details

### Layer 1: Memoria (Memory)

**Purpose**: Persistent state and context management across sessions.

**Agnostic Principle**: Any memory system can be plugged in (Engram, files, databases, vector stores).

**Current Implementation**:
- Engram persistent memory system
- Session tracking (`session-YYYY-MM-DD-XX`)
- Observations with types: bugfix, decisión, architecture, discovery, pattern, config, preference
- Topic keys for evolving decisións

**Key Files**:
- `engram_*` tools in agent config
- Session management in `tools/session-*`

### Layer 2: Skills

**Purpose**: Domain-specific knowledge, patterns, and reusable instructions for AI agents.

**Agnostic Principle**: Skills are declarative markdown with triggers - any agent can interpret them.

**Current Implementation**:
- 50+ skills in `.claude/skills/` and `.config/opencode/skills/`
- Skill registry via `skill-registry` skill
- Triggers based on context (Angular, React, Go, etc.)
- Adaptive skill loading

**Structure**:
```
skills/
 angular-spa-skill/SKILL.md
 golang-api-skill/SKILL.md
 sdd-*/SKILL.md (SDD workflow)
 ...
```

### Layer 3: MCP (Model Context Protocol)

**Purpose**: Standardized protocol for tools, resources, and prompts between AI models and external systems.

**Agnostic Principle**: Any MCP-compliant server can be integrated regardless of language or platform.

**Current Implementation**:
- `mcp-skill` for MCP patterns
- MCP server configurations
- Tool/resource/prompt abstractions

**Key Patterns**:
- MCP servers expose tools, resources, prompts
- Agents call MCP tools via standard interface
- No dependency on server implementation language

### Layer 4: Comandos (Commands/Tools)

**Purpose**: Executable operations that agents can invoke.

**Agnostic Principle**: Tools are defined by interface, not implementation. Any tool with matching signature works.

**Current Implementation**:
- Bash execution (cross-platform via pwsh)
- File operations (read, write, edit, glob, grep)
- Web operations (fetch, search)
- Delegation (subagent task execution)
- Code search (Context7, Exa)

**Tool Categories**:
1. **Execution**: bash, delegate
2. **File System**: read, write, edit, glob, grep
3. **Web**: webfetch, websearch
4. **Code Intelligence**: codesearch, context7_*
5. **Memory**: engram_*

### Layer 5: Agentes (Agents)

**Purpose**: AI agents that orchestrate and execute tasks using lower layers.

**Agnostic Principle**: Any AI agent (Claude, GPT, local models) can use this topology if it supports the tool interface.

**Current Implementation**:
- Multiple agent types: `explore`, `general`, `orchestrator`, `sdd-*`
- Subagent delegation via `task` tool
- Session-based execution
- Context window management

**Agent Types**:
- `default`: Manual invocation
- `explore`: Fast codebase exploration
- `general`: Multi-step task execution
- `orchestrator`: SDD workflow coordination
- `sdd-*`: Specialized SDD phases

## Agnosticity Principles

### 1. Interface Over Implementation
Each layer defines WHAT it does, not HOW. Layer 5 doesn't care if Layer 4 uses bash or PowerShell.

### 2. Pluggable Components
Any component can be replaced:
- Swap Engram for another memory system (Layer 1)
- Add new skills without changing agents (Layer 2)
- Integrate any MCP server (Layer 3)
- Extend tools via standard interfaces (Layer 4)

### 3. No Cross-Layer Dependencies
Layers only depend on the layer directly below them:
- Layer 5  Layer 4  Layer 3  Layer 2  Layer 1
- No Layer 5  Layer 2 shortcuts

### 4. OS/Agent/Language Agnostic
- No Windows-specific paths in skill logic
- No Claude-specific assumptions in architecture
- No Python/Go/TS dependencies in core topology

## Orchestrator Role

The orchestrator (Layer 5 coordinator) must:

1. **Understand all layers** - Know capabilities and limitations of each layer
2. **Route efficiently** - Choose optimal layer for each task
3. **Maintain agnosticity** - Don't hardcode agent-specific or OS-specific behavior
4. **Optimize token usage** - Use appropriate layers for context management
5. **Verify homogeneity** - Ensure all components follow the topology

## Validation Checklist

- [ ] Layer 1: Memory persists across agent restarts
- [ ] Layer 2: Skills load based on triggers, not agent type
- [ ] Layer 3: MCP tools accessible via standard interface
- [ ] Layer 4: Tools work cross-platform (Windows/Linux/macOS)
- [ ] Layer 5: Agents can be swapped without changing lower layers
- [ ] No hardcoded paths, agent names, or OS-specific logic in core layers
- [ ] Each layer has clear input/output contracts

## Benefits

1. **Modularity**: Replace any layer without rewriting others
2. **Scalability**: Add new tools/skills/agents independently
3. **Testability**: Test each layer in isolation
4. **Maintainability**: Clear boundaries reduce coupling
5. **Agnosticity**: Works with any agent, OS, or language
6. **Extensibility**: New capabilities fit into existing layers

## Evolution

When adding new capabilities:
1. Identify which layer it belongs to
2. Ensure it follows the agnosticity principles
3. Document its interface, not implementation
4. Update orchestrator knowledge
5. Verify no cross-layer violations
