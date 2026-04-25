---
name: documentation-strategist
description: >
  Strategic documentation generator - analyzes requests to determine audience,
  format, destination, and structure. Creates professional docs for executives,
  technical teams, repositories, Confluence, or Drive. Knows when to use diagrams,
  tables, prose, or images.
triggers:
  - "generar documentacion"
  - "create documentation"
  - "documento para gerencia"
  - "technical document"
  - "executive summary"
  - "confluence"
  - "drive"
  - "readme"
  - "architecture doc"
  - "api documentation"
  - "user guide"
  - "runbook"
  - "documentation strategy"
---

# DOCUMENTATION STRATEGIST SKILL

## Purpose

Intelligent documentation generation that:
1. **Analyzes the request** → identifies purpose and audience
2. **Selects optimal format** → diagram, table, prose, or hybrid
3. **Determines destination** → repo, Confluence, Drive, or multiple
4. **Structures content** → executive summary vs deep-dive
5. **Applies professional styling** → visual hierarchy, clarity, impact

## Decision Engine

### 1. Audience Detection

```
AUDIENCE DETECTION RULES:
├─ Executive/C-Level/gerencia
│  ├─ Keywords: "gerencia", "executive", "c-level", "ceo", "cfo", "directores"
│  ├─ Focus: ROI, impact, timeline, risks, recommendations
│  └─ Format: Executive summary + high-level visuals
│
├─ Technical/Engineering/desarrolladores
│  ├─ Keywords: "technical", "developer", "engineer", "api", "code", "implementation"
│  ├─ Focus: Architecture, implementation details, APIs, patterns
│  └─ Format: Deep-dive with code examples, diagrams, schemas
│
├─ Product/Product Managers
│  ├─ Keywords: "product", "feature", "requirement", "roadmap", "user story"
│  ├─ Focus: Features, benefits, user flows, dependencies
│  └─ Format: Feature specs, user journeys, mockups reference
│
├─ Operations/DevOps
│  ├─ Keywords: "deploy", "infrastructure", "runbook", "monitoring", "alerts"
│  ├─ Focus: Procedures, configurations, troubleshooting
│  └─ Format: Step-by-step procedures, config snippets
│
└─ General/Internal
   ├─ Keywords: "internal", "team", "process", "onboarding"
   └─ Format: Clear, concise, action-oriented
```

### 2. Format Selection Matrix

| Purpose | Best Format | When NOT to Use |
|---------|-------------|-----------------|
| Concepts, relationships | Diagram (Mermaid/PlantUML) | Simple lists |
| Comparisons, options | Tables | Single items |
| Procedures, steps | Numbered lists + code | Conceptual explanations |
| Architecture decisions | ADR format | Quick notes |
| API reference | OpenAPI/Swagger style | Human-readable guides |
| Executive decisions | Executive summary + 1-pager | Technical details |
| Onboarding | Structured guides | Reference docs |
| Troubleshooting | Flowchart + steps | Conceptual content |

### 3. Destination Selection

```
DESTINATION RULES:
├─ Repository (repo local)
│  ├─ README.md, ARCHITECTURE.md, CONTRIBUTING.md
│  ├─ docs/ folder for long-form
│  └─ Format: Markdown, GitHub-flavored
│
├─ Confluence
│  ├─ Long-form technical documentation
│  ├─ Team processes and runbooks
│  └─ Format: Confluence markup or Markdown → Confluence
│
├─ Google Drive
│  ├─ Executive presentations
│  ├─ Contracts, legal docs
│  ├─ External-facing materials
│  └─ Format: Google Docs/Sheets/Slides
│
├─ External/Client
│  ├─ Professional, polished
│  ├─ Brand-compliant
│  └─ Format: PDF-ready Markdown or direct
│
└─ Multiple
   └─ Primary in repo + summary links to others
```

### 4. Content Structure Templates

#### Executive Summary Template
```
## Executive Summary
[2-3 sentences: what, why, impact]

## Key Points
- Point 1: Impact
- Point 2: Timeline/Cost
- Point 3: Risks/Recommendations

## Next Steps
1. [Action]
2. [Action]

## Appendix
[Reference to detailed technical doc]
```

#### Technical Deep-Dive Template
```
## Overview
[What and why]

## Architecture
[Diagram + explanation]

## Implementation
[Code examples, key components]

## API Reference
[Endpoints, parameters, responses]

## Configuration
[Settings, env vars, etc.]

## Troubleshooting
[Common issues + solutions]
```

#### Runbook Template
```
## Purpose
[What this runbook solves]

## Prerequisites
[What's needed before starting]

## Procedure
1. Step one
2. Step two
3. ...

## Verification
[How to confirm success]

## Rollback
[What to do if things go wrong]

## Monitoring
[Alerts to watch]
```

## Generation Workflow

```
1. ANALYZE REQUEST
   ├─ Extract purpose (explain, document, decide, onboard, troubleshoot)
   ├─ Identify audience (executive, technical, product, ops, general)
   ├─ Determine scope (single feature, full system, process, API)
   └─ Identify destination preference

2. SELECT STRATEGY
   ├─ Choose format based on audience + purpose
   ├─ Determine structure (template or custom)
   └─ Plan visual elements (diagrams, tables, code blocks)

3. GENERATE CONTENT
   ├─ Apply appropriate template
   ├─ Include visual elements
   ├─ Add navigation aids (TOC, breadcrumbs)
   └─ Ensure consistency with existing docs

4. VALIDATE
   ├─ Check audience appropriateness
   ├─ Verify format matches content type
   └─ Ensure destination compatibility

5. OUTPUT
   ├─ Markdown for repo
   ├─ Confluence markup if needed
   ├─ Link to Drive if applicable
   └─ Summary comments for context
```

## Skill Integration

### With Auto-Delegation Router

This skill should be auto-triggered when:
- Task contains "documentation" keywords
- PR requires documentation updates
- New feature needs docs
- Architecture decisions need recording

### With Documentation Governance

The strategist works WITH `documentation-governance`:
- Governance provides standards (English, naming, structure)
- Strategist provides strategy (audience, format, destination)
- Together: consistent AND appropriate documentation

### With Other Skills

| Skill | Collaboration |
|-------|---------------|
| architecture-governance | Capture ADRs, architecture diagrams |
| sdd-spec | Generate specs in correct format |
| github-pr | Auto-suggest documentation for PRs |
| code-review | Flag missing documentation |
| skill-creator | Document new skills properly |

## Auto-Improvement Protocol

This skill should ALSO improve existing documentation skills:

1. **Scan existing skills** → Identify documentation patterns
2. **Extract best practices** → What works for each audience
3. **Recommend improvements** → Missing docs, outdated content
4. **Generate missing documentation** → README, guides, runbooks
5. **Validate against templates** → Ensure consistency

```
AUTO-IMPROVEMENT TRIGGERS:
├─ New skill created → Auto-generate SKILL.md
├─ New script added → Auto-generate docs
├─ Architecture change → Update ADRs
├─ PR merged → Check doc coverage
└─ Weekly sweep → Identify gaps
```

## Usage Examples

### Example 1: Executive Document
```
User: "Genera un documento para gerencia sobre el nuevo feature de pagos"

→ Audience: Executive
→ Format: Executive summary + 1-pager
→ Destination: Drive + link in repo
→ Content: ROI, timeline, risks, recommendation
```

### Example 2: Technical Documentation
```
User: "Documenta la nueva API de autenticación"

→ Audience: Technical
→ Format: API reference + architecture diagram
→ Destination: Repo docs/ + Confluence
→ Content: Endpoints, schemas, flows, examples
```

### Example 3: Runbook
```
User: "Crea un runbook para desplegar el servicio"

→ Audience: Operations
→ Format: Step-by-step procedure
→ Destination: Confluence + repo docs/
→ Content: Prerequisites, steps, verification, rollback
```

### Example 4: Auto-Improve Existing
```
User: "Mejora la documentación del proyecto"

→ Scan existing docs
→ Identify gaps (missing README, outdated API docs)
→ Generate missing pieces
→ Validate consistency
→ Report improvements
```

## Quality Checklist

Before delivering documentation:
- [ ] Audience is clearly identified
- [ ] Format matches content type
- [ ] Destination is clear
- [ ] Structure follows appropriate template
- [ ] Visual elements (diagrams, tables) used appropriately
- [ ] Language matches audience (exec: business focus, tech: details)
- [ ] Links are valid
- [ ] Consistent with existing documentation
- [ ] Actionable (reader knows what to do next)

## Commands

```powershell
# Generate documentation with strategy
.\scripts\utilities\wf.ps1 doc-strategist generate "tu request"

# Analyze existing docs
.\scripts\utilities\wf.ps1 doc-strategist analyze

# Auto-improve project documentation
.\scripts\utilities\wf.ps1 doc-strategist improve

# Preview what would be generated
.\scripts\utilities\wf.ps1 doc-strategist preview "tu request"
```

## References

- Documentation Governance: [tools/skills/documentation-governance/SKILL.md](../documentation-governance/SKILL.md)
- Auto-Delegation Router: [skills/auto-delegation-router/SKILL.md](../auto-delegation-router/SKILL.md)
- Architecture Governance: [tools/skills/architecture-governance/SKILL.md](../architecture-governance/SKILL.md)