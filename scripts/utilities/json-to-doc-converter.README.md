# JSON to Document Converter

Converts JSON output from agents/subagents to the correct document format automatically.

## What It Does

Converts JSON data to **7 output formats** based on what the document needs:

| Input (JSON)               | Output Format     | Output Location                         |
| -------------------------- | ----------------- | --------------------------------------- |
| Session data, task results | **Markdown**      | `docs/sessions/`, `docs/reports/`       |
| Audit results              | **Markdown**      | `docs/audits/`                          |
| Judgment day output        | **Markdown**      | `docs/judgment/`                        |
| Telemetry metrics          | **CSV**           | `reports/MANAGEMENT-REPORT-YYYY-MM.csv` |
| Skill output               | **Markdown**      | `docs/guides/`, `skills/*/SKILL.md`     |
| Any JSON data              | **HTML**          | `reports/html/`                         |
| Any JSON data              | **Text**          | `logs/`                                 |
| Any JSON data              | **JSON** (pretty) | `logs/session-*.json`                   |
| Any JSON data              | **XML**           | `reports/`                              |
| Any JSON data              | **YAML**          | `reports/`                              |

## Supported Output Formats

| Format               | Extension | Best For                                          | Encoding |
| -------------------- | --------- | ------------------------------------------------- | -------- |
| `markdown` (default) | `.md`     | Documentation, reports, skill files               | UTF-8    |
| `csv`                | `.csv`    | Management reports, metrics, telemetry            | UTF-8    |
| `html`               | `.html`   | Web viewing, dashboards, presentations            | UTF-8    |
| `text`               | `.txt`    | Logs, plain text outputs, quick reading           | UTF-8    |
| `json`               | `.json`   | Session data, preserving structure, re-processing | UTF-8    |
| `xml`                | `.xml`    | System integration, structured data exchange      | UTF-8    |
| `yaml`               | `.yaml`   | Configuration files, human-readable data          | UTF-8    |

## Quick Start

### Convert JSON string to Markdown (default)

```powershell
$json = '{"title":"Session Report","user":"emman","project":"gentle-vanguard"}'
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson $json
```

### Convert JSON file to CSV

```powershell
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson "logs/session-2026-04-30-151737.json" -OutputFormat csv
```

### Convert to HTML with custom output path

```powershell
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson $data -OutputFormat html -OutputPath "reports\dashboard.html"
```

### Use a template for Markdown conversión

```powershell
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson $json -OutputFormat markdown -TemplatePath "templates/report-template.md"
```

## How It Determines Output Path

The script auto-determines where to save based on **data type** and **output format**:

| Data Type (JSON `type` field) | Format   | Auto Path                                     |
| ----------------------------- | -------- | --------------------------------------------- |
| `session`                     | markdown | `docs/sessions/session-YYYY-MM-DD-HHmmss.md`  |
| `audit`                       | markdown | `docs/audits/audit-YYYY-MM-DD-HHmmss.md`      |
| `judgment`                    | markdown | `docs/judgment/judgment-YYYY-MM-DD-HHmmss.md` |
| `management-report`           | csv      | `reports/MANAGEMENT-REPORT-YYYY-MM.csv`       |
| `telemetry`                   | csv      | `reports/MANAGEMENT-REPORT-YYYY-MM.csv`       |
| (any other)                   | markdown | `docs/reports/report-YYYY-MM-DD-HHmmss.md`    |

## Orchestrator Integration

### Auto-detection (OpenCode, Cline, Cursor, Windsurf, Continue.dev)

The orchestrator auto-routes JSON outputs to this script:

```powershell
# When an agent returns JSON:
$jsonOutput = Invoke-AgentTask -Task $task
.\scripts\utilities\json-to-doc-converter.ps1 -InputJson $jsonOutput -OutputFormat markdown
```

### Embedded trigger (Claude, Copilot - manual)

When you get JSON from an agent/subagent, run:

```
"Convert this JSON to the correct document format using json-to-doc-converter.ps1"
```

## Templates

Create templates to control Markdown output format:

**Example template** (`templates/report-template.md`):

```markdown
# {{title}}

**Generated**: {{generated}} **Project**: {{project}}

## Details

{{#each items}}

- {{this.key}}: {{this.value}} {{/each}}
```

Use with: `-TemplatePath "templates/report-template.md"`

## Examples

### Example 1: Session report (JSON → Markdown)

**Input:**

```json
{
  "type": "session",
  "sessionId": "session-2026-04-30-01",
  "project": "gentle-vanguard",
  "duration": 45,
  "tokensIn": 15000,
  "tokensOut": 12000
}
```

**Output** (`docs/sessions/session-2026-04-30-01.md`):

```markdown
# Session Report

**Generated**: 2026-04-30 22:30:45

- **type**: session
- **sessionId**: session-2026-04-30-01
- **project**: gentle-vanguard
- **duration**: 45
- **tokensIn**: 15000
- **tokensOut**: 12000
```

### Example 2: Management metrics (JSON → CSV)

**Input:**

```json
{
  "type": "management-report",
  "month": "2026-04",
  "tokensUsed": 450000,
  "costUSD": 12.5,
  "sessionsCount": 15
}
```

**Output** (`reports/MANAGEMENT-REPORT-2026-04.csv`):

```csv
Title,Date,Time,month,tokensUsed,costUSD,sessionsCount
Management Report,2026-04-30,22:30:45,2026-04,450000,12.50,15
```

## Parameters

| Parameter       | Required | Default    | Description                                               |
| --------------- | -------- | ---------- | --------------------------------------------------------- |
| `-InputJson`    | ✅ Yes   | -          | JSON string or path to `.json` file                       |
| `-OutputFormat` | ❌ No    | `markdown` | Output format: markdown, csv, html, text, json, xml, yaml |
| `-OutputPath`   | ❌ No    | Auto       | Custom output path (overrides auto-detection)             |
| `-TemplatePath` | ❌ No    | -          | Path to Markdown template file                            |
| `-Force`        | ❌ No    | -          | Overwrite existing output file                            |

## Error Handling

| Error                      | Cause                       | Solution                                  |
| -------------------------- | --------------------------- | ----------------------------------------- |
| `Input must be valid JSON` | Invalid JSON string or file | Check JSON syntax with `ConvertFrom-Json` |
| `Output path not found`    | Invalid `-OutputPath`       | Verify path exists, create if needed      |
| `Template not found`       | Invalid `-TemplatePath`     | Check file exists at specified path       |

## All Tools Support

✅ **OpenCode** - Native execution  
✅ **Cline** - Via pre-processing script  
✅ **Cursor** - Via pre-processing script  
✅ **Windsurf** - Via pre-processing script  
✅ **Continue.dev** - Via pre-processing script  
✅ **Claude** - Manual: "Convert JSON to document using json-to-doc-converter.ps1"  
✅ **Copilot** - Manual: "Convert JSON to document using json-to-doc-converter.ps1"  
✅ **Antigravity** - Via pre-processing script

## Notes

1. If no `type` field in JSON, saves to `docs/reports/` as markdown
2. CSV format auto-creates headers from JSON keys
3. HTML output includes basic styling (Arial font, table borders)
4. XML output sanitizes keys (removes non-alphanumeric)
5. YAML output uses standard YAML syntax with `---` delimiters

