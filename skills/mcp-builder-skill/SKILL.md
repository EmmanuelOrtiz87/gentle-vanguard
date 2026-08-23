---
name: mcp-builder-skill
description: >
  Guide for creating high-quality MCP servers that enable LLMs to interact with external services
  through well-designed tools. Use when building MCP servers in Python (FastMCP) or Node/TypeScript
  (MCP SDK).
metadata:
  source: anthropic-skills
  original-name: mcp-builder
  related: mcp-skill (GV-native, general MCP overview)
---

# MCP Server Development Guide

## Overview

Create MCP servers that enable LLMs to interact with external services. Quality is measured by how
well tools enable LLMs to accomplish real tasks.

---

# Process

## High-Level Workflow

### Phase 1: Deep Research and Planning

1. [Design Philosophy](./reference/design-philosophy.md) — API coverage vs workflow tools, naming,
   context mgmt, error messages
2. **MCP Protocol**: Start at `https://modelcontextprotocol.io/sitemap.xml`, fetch `.md` pages for
   spec details
3. **Recommended stack**: TypeScript + Streamable HTTP (remote) or stdio (local)
4. **Plan implementation**: Review API docs, list endpoints, prioritize coverage

### Phase 2: Implementation

1. [Core Implementation Patterns](./reference/implementation-core.md) — infra, schemas, annotations
2. Language guides:
   - [TypeScript](./reference/node_mcp_server.md) — project structure, Zod, registerTool
   - [Python](./reference/python_mcp_server.md) — module org, Pydantic, @mcp.tool
3. Build shared: API client, auth, error handling, pagination
4. Per tool: input/output schema, description, async impl, annotations

### Phase 3: Review and Test

- Check: DRY, consistent errors, full types, clear descriptions
- TypeScript: `npm run build` + `npx @modelcontextprotocol/inspector`
- Python: `python -m py_compile server.py` + MCP Inspector

### Phase 4: Create Evaluations

1. Inspect available tools
2. Explore data with READ-ONLY operations
3. Create 10 complex, independent, verifiable questions
4. Verify answers yourself
5. Format as XML `<evaluation>` with `<qa_pair>` entries

See [Evaluation Guide](./reference/evaluation.md) for full details.

---

# Reference Files

| File                                                      | When to Load                                      |
| --------------------------------------------------------- | ------------------------------------------------- |
| [Best Practices](./reference/mcp_best_practices.md)       | Phase 1 — naming, pagination, transport, security |
| [Design Philosophy](./reference/design-philosophy.md)     | Phase 1 — coverage vs workflow, naming, context   |
| [Core Implementation](./reference/implementation-core.md) | Phase 2 — infra, schemas, annotations             |
| [TypeScript Guide](./reference/node_mcp_server.md)        | Phase 2 — full TS patterns and examples           |
| [Python Guide](./reference/python_mcp_server.md)          | Phase 2 — full Python/FastMCP patterns            |
| [Evaluation Guide](./reference/evaluation.md)             | Phase 4 — question creation, XML format, running  |
| MCP SDK READMEs                                           | Phase 1/2 — fetch from GitHub raw URLs            |

## Usage

Use **mcp-builder-skill** when a task matches its triggers (mcp-builder-skill).

Purpose: Guide for creating high-quality MCP servers that enable LLMs to interact with external services through well-designed tools.

## Examples

**Input:** a task matching `mcp-builder-skill` triggers.
**Action:** apply the workflow described above.
**Expected result:** Guide for creating high-quality MCP servers that enable LLMs to interact with external services through well-designed tools.
