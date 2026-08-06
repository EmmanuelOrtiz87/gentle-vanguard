# document-analysis-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
## Activation Contract

Triggered when user provides a requirements document (PDF, DOCX, XLSX, PPTX, MD, TXT) and requests
analysis, estimation, or impact assessment.

## Hard Rules

- MUST extract full text content from any supported document format
- MUST detect technologies, design patterns, and architecture from requirements
- MUST identify specialists/areas based on detected tech stack
- MUST identify cross-team dependencies
- MUST produce time estimate (hours/days/weeks) + cost estimate (USD)
- MUST NOT modify source files during analysis
- MUST generate report at docs/requirements-analysis/
- MUST use LLM real (opencode) for semantic analysis, not stub
- MUST fallback to regex patterns if LLM is unavailable

## Decision Gates

| Gate   | Options                           | Rule                               |
| ------ | --------------------------------- | ---------------------------------- |
| Scope  | full, quick, tech-only, cost-only | full = all dimensions              |
| Source | document, jira, confluence, all   | all = document + jira + confluence |
| Output | markdown, pdf, docx, xlsx         | markdown default                   |

## Execution Steps

1. Receive document path + optional Jira/Confluence context
2. Invoke sidecar Python to extract text + metadata + tables
3. Chunk document (with overlap) for LLM context windows
4. Call opencode LLM (real) for: a. Technology detection (languages, frameworks, tools) b. Design
   pattern identification c. Specialist/area matching from Confluence data d. Cross-team dependency
   analysis e. Time estimation (hours per phase) f. Cost estimation (USD based on rates per
   specialist)
5. Optionally query Jira for related tickets/history
6. Optionally query Confluence for team/specialist info
7. Generate structured report with all findings
8. Store analysis in .session/document-analysis/

## Output Contract

Return JSON with: technologies[], design_patterns[], specialists[], areas[], dependencies[],
time_estimate (hours, days, weeks), cost_estimate (usd), report_path, confidence_score.

## References

- `sidecar/main.py` — Python NDJSON sidecar for document reading
- `sidecar/office_reader.py` — DOCX/XLSX/PPTX/PDF/TXT/CSV/MD readers
- `sidecar/pdf_reader.py` — PDF-specific: text, tables, OCR, images
- `sidecar/document_processor.py` — chunking, classification, language detect
- `sidecar/embedding_engine.py` — sentence-transformers embeddings
- `sidecar/diagram_generator.py` — Mermaid/PlantUML generation
- `sidecar/document_generator.py` — DOCX/XLSX/PPTX/PDF/MD output
- `connectors/jira-connector.ps1` — Jira API connector
- `connectors/confluence-connector.ps1` — Confluence REST connector
- `invoke-document-analysis.ps1` — main orchestrator script
