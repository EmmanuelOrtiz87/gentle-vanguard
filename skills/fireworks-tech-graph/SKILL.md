---
name: fireworks-tech-graph
description: >-
  Use when the user wants to create any technical diagram - architecture, data flow, flowchart,
  sequence, agent/memory, or concept map - and export as SVG+PNG. Trigger on: "画图" "帮我画"
  "生成图" "做个图" "架构图" "流程图" "可视化一下" "出图" "generate diagram" "draw diagram"
  "visualize" or any system/flow description the user wants illustrated.
metadata:
  source: GV-native
---

# Fireworks Tech Graph

Generate production-quality SVG technical diagrams exported as PNG via `cairosvg` (recommended),
`rsvg-convert`, or `puppeteer`.

## Install Source

Install this skill from GitHub:

```bash
npx skills add yizhiyanhua-ai/fireworks-tech-graph
```

Public package page:

```text
https://www.npmjs.com/package/@yizhiyanhua-ai/fireworks-tech-graph
```

Do not pass `@yizhiyanhua-ai/fireworks-tech-graph` directly to `skills add`, because the CLI expects
a GitHub or local repository source.

Update command:

```bash
npx skills add yizhiyanhua-ai/fireworks-tech-graph --force -g -y
```

## Helper Scripts (Recommended)

Four helper scripts in `scripts/` directory provide stable SVG generation and validation:

### 1. `generate-diagram.sh` - Validate SVG + export PNG

```bash
./scripts/generate-diagram.sh -t architecture -s 1 -o ./output/arch.svg
```

- Validates an existing SVG file
- Exports PNG after validation
- Example: `./scripts/generate-diagram.sh -t architecture -s 1 -o ./output/arch.svg`

### 2. `generate-from-template.py` - Create starter SVG from template

```bash
python3 ./scripts/generate-from-template.py architecture ./output/arch.svg '{"title":"My Diagram","nodes":[],"arrows":[]}'
```

- Loads a built-in SVG template
- Renders nodes, arrows, and legend entries from JSON input
- Escapes text content to keep output XML-valid

### 3. `validate-svg.sh` - Validate SVG syntax

```bash
./scripts/validate-svg.sh <svg-file>
```

- Checks XML syntax
- Verifies tag balance
- Validates marker references
- Checks attribute completeness
- Validates path data

### 4. `test-all-styles.sh` - Batch test all styles

```bash
./scripts/test-all-styles.sh
```

- Tests multiple diagram sizes
- Validates all generated SVGs
- Generates test report

**When to use scripts:**

- Use scripts when generating complex SVGs to avoid syntax errors
- Scripts provide automatic validation and error reporting
- Recommended for production diagrams

**When to generate SVG directly:**

- Simple diagrams with few elements
- Quick prototypes
- When you need full control over SVG structure

## Workflow (Always Follow This Order)

1. **Classify** the diagram type (see Diagram Types below)
2. **Extract structure** — identify layers, nodes, edges, flows, and semantic groups from user
   description
3. **Plan layout** — apply the layout rules for the diagram type
4. **Load style reference** — always load `references/style-1-flat-icon.md` unless user specifies
   another; load the matching `references/style-N.md` for exact color tokens and SVG patterns
5. **Map nodes to shapes** — use Shape Vocabulary below
6. **Check icon needs** — load `references/icons.md` for known products
7. **Write SVG** with adaptive strategy (see SVG Generation Strategy below)
8. **Validate**: Run `python3 -c "import xml.etree.ElementTree as ET; ET.parse('file.svg')"` to
   check XML syntax

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
