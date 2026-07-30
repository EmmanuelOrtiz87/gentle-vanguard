---
name: document-processor
description: Process, extract and analyze content from PDF, DOCX, TXT and other document formats. Use when reading documents, extracting text, analyzing reports, parsing contracts, or processing documentation.
triggers:
  - process document
  - extract text
  - read PDF
  - parse DOCX
  - analyze document
  - extract content
  - document parsing
---

# Document Processor Skill

## Overview

Process and extract structured content from documents (PDF, DOCX, TXT).
Extracts text, tables, metadata, and generates summaries.

## Supported Formats

| Format | Extension | Capability |
|--------|-----------|------------|
| PDF | .pdf | Full text extraction, metadata, page structure |
| Word | .docx | Full text, styles, tables, images (refs) |
| Text | .txt, .md, .rst | Direct reading, structure analysis |
| CSV | .csv, .tsv | Structured data, table extraction |
| JSON/YAML | .json, .yaml, .yml | Schema validation, content extraction |
| HTML | .html, .htm | DOM extraction, text cleaning |

## Usage Flow

```
Document received
    │
    ├── Invalid file? ──────────────→ Error with remediation
    │
    ├── PDF ────────────────────────→ pdf-parse / pdftotext
    │
    ├── DOCX ───────────────────────→ docx-parser
    │
    ├── TXT/MD/RST ─────────────────→ Direct read
    │
    ├── CSV/TSV ────────────────────→ Structured parsing
    │
    └── JSON/YAML ──────────────────→ Schema validation
                │
                └── Extract: text | tables | metadata | summary
```

## Extraction Modes

### 1. Text Extraction
```bash
# Extract all text
npx tsx src/document-processor.ts extract "document.pdf"

# Extract specific pages
npx tsx src/document-processor.ts extract "document.pdf" --pages 1,5-10

# Extract with OCR fallback
npx tsx src/document-processor.ts extract "scanned.pdf" --ocr
```

### 2. Table Extraction
```bash
# Extract tables to CSV
npx tsx src/document-processor.ts tables "report.pdf" --output tables.csv

# Extract tables to JSON
npx tsx src/document-processor.ts tables "spreadsheet.xlsx" --format json
```

### 3. Metadata Extraction
```bash
# Get document metadata
npx tsx src/document-processor.ts meta "document.pdf"

# Output: author, creation date, modification date, page count, etc.
```

### 4. Summary Generation
```bash
# Generate executive summary
npx tsx src/document-processor.ts summarize "long-document.pdf"

# Options: --max-length 500, --focus technical
```

## Response Format

```typescript
interface DocumentResult {
  source: string;
  format: 'pdf' | 'docx' | 'txt' | 'csv' | 'json';
  success: boolean;
  text?: string;
  pages?: {
    number: number;
    text: string;
    tables?: TableData[];
  }[];
  metadata?: {
    title?: string;
    author?: string;
    created?: string;
    modified?: string;
    pageCount?: number;
    wordCount?: number;
  };
  tables?: TableData[];
  errors?: string[];
  warnings?: string[];
}

interface TableData {
  page?: number;
  index: number;
  headers: string[];
  rows: string[][];
}
```

## Error Handling

| Error | Remediation |
|-------|-------------|
| File not found | Check path, suggest alternatives |
| Permission denied | Suggest `sudo` or file permissions |
| Corrupted PDF | Try recovery mode, suggest repair tools |
| Encrypted PDF | Request password or skip |
| Missing dependencies | Auto-install or provide install command |
| OCR required | Suggest Tesseract installation |

## Integration with Other Skills

- **data-analyst**: Send tables for analysis
- **technical-writer**: Extract source material
- **spec-driven-development**: Parse requirements documents
- **code-review**: Extract code from documentation

## Examples

### Example 1: Extract PDF to Markdown
```bash
$ npx tsx src/document-processor.ts extract "spec.pdf" --format md

Output:
# System Requirements Specification

## 1. Introduction
Extracted text...

## 2. Functional Requirements
...
```

### Example 2: Analyze Contract
```bash
$ npx tsx src/document-processor.ts analyze "contract.pdf" --focus clauses

Key clauses found:
- Term: 24 months
- Payment terms: Net 30
- Termination: 30 days notice
```

### Example 3: Batch Process
```bash�$ npx tsx src/document-processor.ts batch "./documents/*.pdf" --output ./extracted/

Processing: report1.pdf ✓
Processing: report2.pdf ✓
Processing: scanned.pdf (OCR) ✓
```

## Dependencies

Downloaded on first use:
- `pdf-parse` - PDF text extraction
- `docx` - DOCX parsing
- `xlsx` - Excel/CSV parsing
- `tesseract.js` - OCR (optional)

## Performance

| File Size | Format | Typical Time |
|-----------|--------|--------------|
| <1 MB | PDF | 1-2s |
| 1-10 MB | PDF | 3-5s |
| >10 MB | PDF | 5-15s |
| DOCX | Any size | <3s |
| OCR | Per page | 2-5s/page |

## See Also

- `data-analyst` - For analyzing extracted data
- `technical-writer` - For processing to documentation
