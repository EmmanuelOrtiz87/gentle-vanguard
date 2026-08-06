# content-output-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Content Output Skill (v3.0)

## Purpose

Unified skill for generating all types of content output from Gentle-Vanguard:

- **Technical Docs**: API docs, README, guides, references
- **Internal Reports**: Session metrics, costs, performance
- **External Communication**: Marketing, social media, presentations
- **Speeches**: Conferences, workshops, demos

Part of the workflow: Input Processing Output (Docs + Communication)

## Content Types

| Type            | Platform      | Format             | Purpose                        |
| --------------- | ------------- | ------------------ | ------------------------------ |
| **Tweet/X**     | Twitter/X     | 280 chars + thread | Quick announcement, engagement |
| **LinkedIn**    | LinkedIn      | 3000 chars + media | Professional reach, B2B        |
| **Instagram**   | Instagram     | Caption + hashtags | Visual brand                   |
| **Reddit**      | Reddit        | Text + links       | Community discussion, feedback |
| **Discord**     | Discord       | Embed + CTA        | Community engagement           |
| **WhatsApp**    | WhatsApp      | Broadcast message  | Direct reach, groups           |
| **Blog Post**   | Web           | MD HTML            | SEO, deep content              |
| **Demo Script** | Video         | 2-3 min            | Product demo                   |
| **Speech**      | Presentations | 5-30 min           | Conferences, workshops         |

---

## TECHNICAL DOCUMENTATION

### Types (from `documentation-skill`)

| Type          | Purpose                  | Output                |
| ------------- | ------------------------ | --------------------- |
| **README**    | Project entry point      | `README.md`           |
| **API Docs**  | Auto-generated from code | OpenAPI/Swagger       |
| **Guides**    | How-to tutorials         | `docs/guides/*.md`    |
| **Reference** | Technical specs          | `docs/reference/*.md` |
| **Changelog** | versión history          | `CHANGELOG.md`        |

### Documentation Standards

```
REQUIRE:
- All public APIs require docstrings
- README minimum: description + quick start
- Changelog for all releases

PREFER:
- Usage examples inline
- Code comments for complex logic
- Diagrams for architecture
```

### See Also

- `skills/documentation-governance/SKILL.md` - Full governance rules
- `docs/TOKEN-CONTEXT-STANDARDS.md` - Detailed standards

---

## INTERNAL REPORTS

### Types

| Type               | Trigger               | Output                   |
| ------------------ | --------------------- | ------------------------ |
| **Session Report** | "informe sesiónes"    | `docs/sessions/metrics/` |
| **Cost Report**    | "informe costos"      | Token usage, USD         |
| **Performance**    | "informe performance" | Velocity metrics         |
| **Executive**      | "resumen ejecutivo"   | Board-ready summary      |

### Quick Commands

```powershell
# Session metrics
.\scripts\utilities\session-metrics-collector.ps1 -Period 7days


---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
